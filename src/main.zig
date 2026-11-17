const std = @import("std");
const math = @import("math.zig");
const digits = @import("digits.zig");

const termlarm = @import("termlarm");

const PI = 3.14159265358979323846;
const PI2 = 2.0 * PI;

const MAX_DEGREES = 360;

const SPACE = 32;
const NUMBER_SIGN = 35;

const Circle = struct {
    radius: f32,
    step: i32,

    pub fn next(self: *Circle) ?math.Vec2f {
        const target_step = 12;
        if (self.step >= target_step) return null;

        const radi = @as(f32, @floatFromInt(self.step)) / @as(f32, @floatFromInt(target_step)) * PI2;
        const y = std.math.cos(radi) * self.radius;
        const x = std.math.sin(radi) * self.radius;
        self.step += 1;

        return math.Vec2f{
            .y = y,
            .x = x,
        };
    }

    pub fn size(self: *Circle) math.Vec2f {
        return math.Vec2f{
            .x = self.radius * 2.0,
            .y = self.radius * 2.0,
        };
    }

    pub fn reset(self: *Circle) void {
        self.step = 0;
    }
};

const Line = struct {
    x: f32,
    length: f32,

    pub fn next(self: *Line) ?math.Vec2f {
        if (self.x > self.length) return null;
        const x = self.x - self.length / 2.0;
        self.x += self.length;
        return .{
            .y = 0.0,
            .x = x,
        };
    }

    pub fn reset(self: *Line) void {
        self.x = 0.0;
    }
};

const Letter = struct {
    points: []const math.Vec2f,
    step: usize,

    pub fn next(self: *Letter) ?math.Vec2f {
        if (self.step >= self.points.len) return null;
        const p = self.points[self.step];
        self.step += 1;
        return .{
            .x = p.x,
            .y = p.y,
        };
    }

    pub fn size(self: *Letter) math.Vec2f {
        var low_x: f32 = 0;
        var high_x: f32 = 0;
        var low_y: f32 = 0;
        var high_y: f32 = 0;

        for (self.points) |p| {
            if (p.x > high_x) high_x = p.x;
            if (p.x < low_x) low_x = p.x;
            if (p.y > high_y) high_y = p.y;
            if (p.y < low_y) low_y = p.y;
        }

        return math.Vec2f{
            .x = high_x - low_x,
            .y = high_y - low_y,
        };
    }

    pub fn reset(self: *Letter) void {
        self.step = 0;
    }
};

fn LetterFactory(letter: []const math.Vec2f) Letter {
    return .{
        .points = letter,
        .step = 0,
    };
}

const PrimitiveTag = enum {
    line,
    circle,
    letter,
};

const Primitive = union(PrimitiveTag) {
    line: Line,
    circle: Circle,
    letter: Letter,
};

const Shape = struct {
    primitive: Primitive,
    pos: math.Vec2f,
    scale: f32,
    rotation: f32,

    pub fn next(self: *Shape) ?math.Vec2f {
        return switch (self.primitive) {
            inline else => |*primitive| primitive.next(),
        };
    }

    pub fn reset(self: *Shape) void {
        switch (self.primitive) {
            inline else => |*primitive| primitive.reset(),
        }
    }

    pub fn size(self: *Shape) math.Vec2f {
        return switch (self.primitive) {
            .line => |*line| math.Vec2f{ .x = line.length, .y = 1.0 },
            inline else => |*primitive| primitive.size(),
        };
    }

    // if the primitive is connected at the start & end point
    pub fn isClosedPrimitive(self: *Shape) bool {
        return switch (self.primitive) {
            .letter => false,
            inline else => true,
        };
    }
};

pub fn main(init: std.process.Init) !void {
    const io = init.io;
    var arena = init.arena;
    defer arena.deinit();
    const allocator = arena.allocator();

    const out_buffer = try allocator.create([1024]u8);
    const stdout = std.Io.File.stdout();
    var writer = stdout.writer(io, out_buffer);

    const win_size: std.posix.winsize = getTermSize();
    const world_size: math.Vec2f = .{
        .y = win_size.row,
        .x = @as(f32, @floatFromInt(win_size.col)) / 2.0,
    };

    var output = try std.ArrayList(u8).initCapacity(allocator, win_size.row * win_size.col);
    _ = try output.addManyAt(allocator, 0, win_size.row * win_size.col);
    @memset(output.items[0 .. win_size.row * win_size.col], SPACE);

    var circle: Shape = .{
        .primitive = .{ .circle = .{
            .radius = 10,
            .step = 0,
        } },
        .pos = .{
            .y = world_size.y / 2.0,
            .x = world_size.x / 2.0,
        },
        .scale = 1.0,
        .rotation = 0.0,
    };

    var circle_vec: math.Vec2f = .{
        .y = 1.0,
        .x = 0.0,
    };

    var line: Shape = .{
        .primitive = .{ .line = .{
            .x = 0.0,
            .length = 10.0,
        } },
        .pos = .{
            .y = world_size.y / 2.0,
            .x = world_size.x / 2.0,
        },
        .scale = 1.0,
        .rotation = 0.0,
    };

    var line_vec: math.Vec2f = .{
        .y = 0.5,
        .x = 0.25,
    };

    var seven: Shape = .{
        .primitive = .{ .letter = LetterFactory(&digits.THREE) },
        .pos = .{
            .y = world_size.y / 2.0,
            .x = world_size.x / 2.0,
        },
        .scale = 2.0,
        .rotation = 0.0,
    };

    const velocity: f32 = 0.2;
    while (true) {
        circle.pos.x += circle_vec.x * velocity;
        circle.pos.y += circle_vec.y * velocity;
        line.pos.x += line_vec.x * velocity;
        line.pos.y += line_vec.y * velocity;

        if (circle.pos.x + circle.size().x / 2.0 >= world_size.x or circle.pos.x - circle.size().x / 2.0 <= 0) {
            circle_vec.x = -circle_vec.x;
        }
        if (circle.pos.y + circle.size().y / 2.0 >= world_size.y or circle.pos.y - circle.size().y / 2.0 <= 0) {
            circle_vec.y = -circle_vec.y;
        }
        if (line.pos.x + line.size().x / 2.0 >= world_size.x or line.pos.x - line.size().x / 2.0 <= 0) {
            line_vec.x = -line_vec.x;
        }
        if (line.pos.y + line.size().y / 2.0 >= world_size.y or line.pos.y - line.size().y / 2.0 <= 0) {
            line_vec.y = -line_vec.y;
        }

        line.rotation += 0.05;

        drawShapeOntoBuffer(&seven, output.items, win_size);
        drawShapeOntoBuffer(&line, output.items, win_size);
        drawShapeOntoBuffer(&circle, output.items, win_size);
        try drawBufferToStdout(&writer, output.items, win_size);

        try init.io.sleep(std.Io.Duration.fromMilliseconds(16), std.Io.Clock.real);
    }
}

fn bresenham(start: math.Vec2i, end: math.Vec2i, current_point: *math.Vec2i, err: *?i32) ?math.Vec2i {
    const dx: i32 = @intCast(@abs(end.x - start.x));
    const dy: i32 = -@as(i32, @intCast(@abs(end.y - start.y)));
    const sx: i32 = if (start.x < end.x) 1 else -1;
    const sy: i32 = if (start.y < end.y) 1 else -1;

    if (err.* == null) {
        err.* = dx + dy;
    }

    const rasterized_point: math.Vec2i = .{ .y = current_point.y, .x = current_point.x };
    if (current_point.x == end.x and current_point.y == end.y) return null;

    const e2 = 2 * err.*.?;
    if (e2 >= dy) {
        err.*.? += dy;
        current_point.x += sx;
    }
    if (e2 <= dx) {
        err.*.? += dx;
        current_point.y += sy;
    }

    return rasterized_point;
}

fn isWithinBounds(value: i32, upper_limit: i32) bool {
    return value < upper_limit and value >= 0;
}

// TODO: this could be a linear transformation too
fn worldToScreenVec2i(world_pos: math.Vec2f, shape_pos: math.Vec2f) math.Vec2i {
    return .{
        .y = @as(i32, @intFromFloat(@round(world_pos.y + shape_pos.y))),
        .x = @as(i32, @intFromFloat(@round(world_pos.x * 2.0 + shape_pos.x * 2.0))),
    };
}

fn rotate(radi: f32, pos: math.Vec2f) math.Vec2f {
    const matrix = [2][2]f32{
        [_]f32{ @cos(radi), -@sin(radi) },
        [_]f32{ @sin(radi), @cos(radi) },
    };

    return .{
        .x = matrix[0][0] * pos.x + matrix[0][1] * pos.y,
        .y = matrix[1][0] * pos.x + matrix[1][1] * pos.y,
    };
}

// FIXME: do matrix multiplication to merge transformations
fn scale(by: f32, pos: math.Vec2f) math.Vec2f {
    const matrix = [2][2]f32{
        [_]f32{ by, 0.0 },
        [_]f32{ 0.0, by },
    };

    return .{
        .x = matrix[0][0] * pos.x + matrix[0][1] * pos.y,
        .y = matrix[1][0] * pos.x + matrix[1][1] * pos.y,
    };
}

fn rasterizeOntoBuffer(buffer: []u8, p1: math.Vec2i, p2: math.Vec2i, winsize: std.posix.winsize) void {
    var err: ?i32 = null;
    var current_point: math.Vec2i = .{
        .x = p1.x,
        .y = p1.y,
    };
    while (bresenham(p1, p2, &current_point, &err)) |rp| {
        if (isWithinBounds(rp.y, winsize.row) and isWithinBounds(rp.x, winsize.col))
            buffer[@as(usize, @intCast(rp.y * winsize.col + rp.x))] = NUMBER_SIGN;
    }
}

// order of operations:
// 1. calculate points of primitive
// 2. do any transformations to these points
// 3. rasterize into points to be drawn onto screen
// 4. transfer rasterization onto draw buffer
fn drawShapeOntoBuffer(shape: *Shape, buffer: []u8, winsize: std.posix.winsize) void {
    var i: usize = 0;
    var first_point: math.Vec2f = undefined;
    var prev_point: math.Vec2f = undefined;
    while (shape.next()) |s| : (i += 1) {
        if (i == 0) {
            first_point = s;
            prev_point = s;
            continue;
        }

        const p1 = rotate(shape.rotation, scale(shape.scale, prev_point));
        const p2 = rotate(shape.rotation, scale(shape.scale, s));
        rasterizeOntoBuffer(buffer, worldToScreenVec2i(p1, shape.pos), worldToScreenVec2i(p2, shape.pos), winsize);

        prev_point = s;
    }

    if (shape.isClosedPrimitive()) {
        // need to do one last time to connect last point to first point
        // hmm, not really relevant for a line, but whatever!
        const p1 = rotate(shape.rotation, scale(shape.scale, prev_point));
        const p2 = rotate(shape.rotation, scale(shape.scale, first_point));
        rasterizeOntoBuffer(buffer, worldToScreenVec2i(p1, shape.pos), worldToScreenVec2i(p2, shape.pos), winsize);
    }

    shape.reset();
}

fn drawBufferToStdout(writer: *std.Io.File.Writer, buffer: []u8, winsize: std.posix.winsize) !void {
    try writer.interface.writeAll("\x1b[H");

    var row: i32 = 0;
    while (row < winsize.row) {
        const start_pos = @as(usize, @intCast(row * winsize.col));
        const end_pos = @as(usize, @intCast(start_pos + winsize.col));

        try writer.interface.print("{s}", .{buffer[start_pos..end_pos]});
        row += 1;
    }

    try writer.interface.flush();
    @memset(buffer[0 .. winsize.row * winsize.col], SPACE);
}

fn getTermSize() std.posix.winsize {
    var winsize: std.posix.winsize = undefined;
    _ = std.os.linux.ioctl(std.Io.File.stdout().handle, std.os.linux.T.IOCGWINSZ, @intFromPtr(&winsize));
    return winsize;
}

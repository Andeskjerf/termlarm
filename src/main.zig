const std = @import("std");

const termlarm = @import("termlarm");

const PI = 3.14159265358979323846;
const PI2 = 2.0 * PI;

const MAX_DEGREES = 360;

const SPACE = 32;
const NUMBER_SIGN = 35;

const Vec2i = struct {
    y: i32,
    x: i32,
};

const Vec2f = struct {
    y: f32,
    x: f32,
};

const Circle = struct {
    radius: i32,
    step: i32,

    pub fn next(self: *Circle) ?Vec2f {
        const target_step = 50;
        if (self.step >= target_step) return null;

        const radi = @as(f32, @floatFromInt(self.step)) / @as(f32, @floatFromInt(target_step)) * PI2;
        const y = std.math.cos(radi) * @as(f32, @floatFromInt(self.radius));
        const x = std.math.sin(radi) * @as(f32, @floatFromInt(self.radius));
        self.step += 1;

        return Vec2f{
            .y = y,
            .x = x,
        };
    }

    pub fn size(self: *Circle) f32 {
        return @as(f32, @floatFromInt(self.radius)) * 2.0;
    }

    pub fn reset(self: *Circle) void {
        self.step = 0;
    }
};

const Line = struct {
    x: f32,
    length: f32,

    pub fn next(self: *Line) ?Vec2f {
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

const PrimitiveTag = enum {
    line,
    circle,
};

const Primitive = union(PrimitiveTag) {
    line: Line,
    circle: Circle,
};

const Shape = struct {
    primitive: Primitive,
    pos: Vec2f,
    scale: f32,

    pub fn next(self: *Shape) ?Vec2f {
        return switch (self.primitive) {
            inline else => |*primitive| primitive.next(),
        };
    }

    pub fn reset(self: *Shape) void {
        switch (self.primitive) {
            inline else => |*primitive| primitive.reset(),
        }
    }

    pub fn size(self: *Shape) f32 {
        return switch (self.primitive) {
            .line => |*line| line.length,
            .circle => |*circle| circle.size(),
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
    const world_size: Vec2f = .{
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
    };

    var circle_vec: Vec2f = .{
        .y = 0.5,
        .x = 0.5,
    };

    var line: Shape = .{
        .primitive = .{ .line = .{
            .x = 0.0,
            .length = 20.0,
        } },
        .pos = .{
            .y = world_size.y / 2.0,
            .x = world_size.x / 2.0,
        },
        .scale = 1.0,
    };

    const velocity = 1.5;
    while (true) {
        circle.pos.x += circle_vec.x * velocity;
        circle.pos.y += circle_vec.y * velocity;

        if (circle.pos.x + circle.size() / 2.0 >= world_size.x or circle.pos.x - circle.size() / 2.0 <= 0) {
            circle_vec.x = -circle_vec.x;
        }
        if (circle.pos.y + circle.size() / 2.0 >= world_size.y or circle.pos.y - circle.size() / 2.0 <= 0) {
            circle_vec.y = -circle_vec.y;
        }

        drawShapeOntoBuffer(&line, output.items, win_size);
        drawShapeOntoBuffer(&circle, output.items, win_size);
        try drawBufferToStdout(&writer, output.items, win_size);

        try init.io.sleep(std.Io.Duration.fromMilliseconds(16), std.Io.Clock.real);
    }
}

fn getTermSize() std.posix.winsize {
    var winsize: std.posix.winsize = undefined;
    _ = std.os.linux.ioctl(std.Io.File.stdout().handle, std.os.linux.T.IOCGWINSZ, @intFromPtr(&winsize));
    return winsize;
}

fn bresenham(buffer: []?Vec2i, start: Vec2i, end: Vec2i) void {
    const dx: i32 = @intCast(@abs(end.x - start.x));
    const dy: i32 = -@as(i32, @intCast(@abs(end.y - start.y)));
    const sx: i32 = if (start.x < end.x) 1 else -1;
    const sy: i32 = if (start.y < end.y) 1 else -1;
    var err = dx + dy;

    var x = start.x;
    var y = start.y;
    var i: usize = 0;
    while (i < buffer.len) : (i += 1) {
        buffer[i] = .{ .y = y, .x = x };
        if (x == end.x and y == end.y) break;

        const e2 = 2 * err;
        if (e2 >= dy) {
            err += dy;
            x += sx;
        }
        if (e2 <= dx) {
            err += dx;
            y += sy;
        }
    }
}

// order of operations:
// 1. calculate points of primitive
// 2. do any transformations to these points
// 3. rasterize into array of points
// 4. transfer rasterization onto draw buffer
fn drawShapeOntoBuffer(shape: *Shape, buffer: []u8, winsize: std.posix.winsize) void {
    var points: [256]?Vec2i = @splat(null);
    var i: usize = 0;
    while (shape.next()) |p| : (i += 1) {
        // FIXME: a bit jittery...
        // seems like position rounds in a bad way
        const y = @as(i32, @intFromFloat(@round(p.y + shape.pos.y)));
        const x = @as(i32, @intFromFloat(@round(p.x * 2.0 + shape.pos.x * 2.0)));
        points[i] = .{
            .y = y,
            .x = x,
        };
    }
    shape.reset();

    // TODO: we could probably draw the rasterized points directly to the output buffer
    var rasterized_points: [128]?Vec2i = @splat(null);
    for (points, 0..) |p, ii| {
        @memset(&rasterized_points, null);
        const first_point = points[0] orelse break;
        const pp1 = p orelse break;
        const p1: Vec2i = .{
            .y = pp1.y,
            .x = pp1.x,
        };
        const pp2 = points[ii + 1] orelse first_point;
        const p2: Vec2i = .{
            .y = pp2.y,
            .x = pp2.x,
        };

        bresenham(&rasterized_points, p1, p2);
        for (rasterized_points) |rp| {
            const rpp = rp orelse break;
            if (isWithinBounds(rpp.y, winsize.row) and isWithinBounds(rpp.x, winsize.col))
                buffer[@as(usize, @intCast(rpp.y * winsize.col + rpp.x))] = NUMBER_SIGN;
        }
    }
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

fn isWithinBounds(value: i32, upper_limit: i32) bool {
    return value < upper_limit and value >= 0;
}

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
        const target_step = self.radius * 20;
        if (self.step >= target_step) return null;

        const radi = @as(f32, @floatFromInt(self.step)) / @as(f32, @floatFromInt(target_step)) * PI2;
        const y = std.math.cos(radi) * @as(f32, @floatFromInt(self.radius));
        const x = std.math.sin(radi) * @as(f32, @floatFromInt(self.radius));
        self.step += 1;

        return Vec2f{ .y = y, .x = x };
    }

    pub fn size(self: *Circle) f32 {
        return @as(f32, @floatFromInt(self.radius)) * 2.0;
    }

    pub fn reset(self: *Circle) void {
        self.step = 0;
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
    const world_size: Vec2f = .{ .y = win_size.row, .x = @as(f32, @floatFromInt(win_size.col)) / 2.0 };

    var output = try std.ArrayList(u8).initCapacity(allocator, win_size.row * win_size.col);
    _ = try output.addManyAt(allocator, 0, win_size.row * win_size.col);
    @memset(output.items[0 .. win_size.row * win_size.col], SPACE);

    var circle: Circle = .{ .radius = 10, .step = 0 };
    var circle_vec: Vec2f = .{ .y = 0.5, .x = 0.5 };
    var circle_pos: Vec2f = .{ .y = world_size.y / 2.0, .x = world_size.x / 2.0 };
    const velocity = 1.5;
    while (true) {
        circle_pos.x += circle_vec.x * velocity;
        circle_pos.y += circle_vec.y * velocity;

        if (circle_pos.x + @as(f32, @floatFromInt(circle.radius)) >= world_size.x or circle_pos.x - @as(f32, @floatFromInt(circle.radius)) <= 0) {
            circle_vec.x = -circle_vec.x;
        }
        if (circle_pos.y + @as(f32, @floatFromInt(circle.radius)) >= world_size.y or circle_pos.y - @as(f32, @floatFromInt(circle.radius)) <= 0) {
            circle_vec.y = -circle_vec.y;
        }

        drawShapeOntoBuffer(&circle, output.items, circle_pos, win_size);
        try drawBufferToStdout(&writer, output.items, win_size);

        try init.io.sleep(std.Io.Duration.fromMilliseconds(16), std.Io.Clock.real);
    }
}

fn getTermSize() std.posix.winsize {
    var winsize: std.posix.winsize = undefined;
    _ = std.os.linux.ioctl(std.Io.File.stdout().handle, std.os.linux.T.IOCGWINSZ, @intFromPtr(&winsize));
    return winsize;
}

fn drawShapeOntoBuffer(shape: *Circle, buffer: []u8, pos: Vec2f, winsize: std.posix.winsize) void {
    while (shape.next()) |p| {
        const y = @as(i32, @intFromFloat(@round(p.y + pos.y)));
        const x = @as(i32, @intFromFloat(@round(p.x * 2.0 + pos.x * 2.0)));
        if (is_within_bounds(y, winsize.row) and is_within_bounds(x, winsize.col))
            buffer[@as(usize, @intCast(y * winsize.col + x))] = NUMBER_SIGN;
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

fn is_within_bounds(value: i32, upper_limit: i32) bool {
    return value < upper_limit and value >= 0;
}

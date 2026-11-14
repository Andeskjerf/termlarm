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
        const targetStep = self.radius * 20;
        if (self.step >= targetStep) return null;

        const radi = @as(f32, @floatFromInt(self.step)) / @as(f32, @floatFromInt(targetStep)) * PI2;
        const y = std.math.cos(radi) * @as(f32, @floatFromInt(self.radius));
        const x = std.math.sin(radi) * @as(f32, @floatFromInt(self.radius));
        self.step += 1;

        return Vec2f{ .y = y, .x = x };
    }

    pub fn size(self: *Circle) f32 {
        return @as(f32, @floatFromInt(self.radius)) * 2.0;
    }
};

pub fn main(init: std.process.Init) !void {
    const io = init.io;
    var arena = init.arena;
    defer arena.deinit();
    const allocator = arena.allocator();

    const drawBuffer = try allocator.create([1024]u8);
    const stdout = std.Io.File.stdout();
    var writer = stdout.writer(io, drawBuffer);

    var winsize: std.posix.winsize = undefined;
    _ = std.os.linux.ioctl(stdout.handle, std.os.linux.T.IOCGWINSZ, @intFromPtr(&winsize));

    const drawSize: Vec2i = .{ .y = winsize.row, .x = winsize.col };
    var output = try std.ArrayList(u8).initCapacity(allocator, winsize.row * winsize.col);
    _ = try output.addManyAt(allocator, 0, winsize.row * winsize.col);
    @memset(output.items[0 .. winsize.row * winsize.col], SPACE);

    var circleVec: Vec2f = .{ .y = 0.5, .x = 0.5 };
    var circlePos: Vec2f = .{ .y = @as(f32, @floatFromInt(winsize.row)) / 2.0, .x = @as(f32, @floatFromInt(winsize.col)) / 2.0 };
    const velocity = 1.5;
    while (true) {
        try writer.interface.writeAll("\x1b[H");

        var circle: Circle = .{ .radius = 10, .step = 0 };
        while (circle.next()) |p| {
            const y = @as(i32, @intFromFloat(@round(p.y + circlePos.y)));
            const x = @as(i32, @intFromFloat(@round(p.x * 2.0 + circlePos.x)));
            if (is_within_bounds(y, drawSize.y) and is_within_bounds(x, drawSize.x))
                output.items[@as(usize, @intCast(y * drawSize.x + x))] = NUMBER_SIGN;
        }

        var row: i32 = 0;
        while (row < drawSize.y) {
            const startPos = @as(usize, @intCast(row * winsize.col));
            const endPos = @as(usize, @intCast(startPos + winsize.col));

            try writer.interface.print("{s}", .{output.items[startPos..endPos]});
            row += 1;
        }

        circlePos.x += circleVec.x * velocity;
        circlePos.y += circleVec.y * velocity;

        if (@as(i32, @intFromFloat(circlePos.x + circle.size())) >= drawSize.x or @as(i32, @intFromFloat(circlePos.x - circle.size())) <= 0) {
            circleVec.x = -circleVec.x;
        }
        if (@as(i32, @intFromFloat(circlePos.y + @as(f32, @floatFromInt(circle.radius)))) >= winsize.row or @as(i32, @intFromFloat(circlePos.y - @as(f32, @floatFromInt(circle.radius)))) <= 0) {
            circleVec.y = -circleVec.y;
        }

        try writer.interface.flush();
        @memset(output.items[0 .. winsize.row * winsize.col], SPACE);

        try init.io.sleep(std.Io.Duration.fromMilliseconds(16), std.Io.Clock.real);
    }
}

fn is_within_bounds(value: i32, upper_limit: i32) bool {
    return value < upper_limit and value >= 0;
}

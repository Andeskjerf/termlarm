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

    var circleX: f32 = 0;
    var circleY: f32 = 0;
    while (true) {
        try writer.interface.writeAll("\x1b[H");

        var circle: Circle = .{ .radius = 10, .step = 0 };
        while (circle.next()) |p| {
            const y = @as(i32, @intFromFloat(@round(p.y + circleY)));
            const x = @as(i32, @intFromFloat(@round(p.x * 2.0 + circleX)));
            if (is_within_bounds(y, drawSize.y) and is_within_bounds(x, drawSize.x))
                output.items[@as(usize, @intCast(y * drawSize.x + x))] = NUMBER_SIGN;
        }

        var row: i32 = 0;
        while (row < drawSize.y) {
            const startPos = @as(usize, @intCast(row * winsize.col));
            const endPos = @as(usize, @intCast(startPos + winsize.col));

            try writer.interface.print("{s}\n", .{output.items[startPos..endPos]});
            row += 1;
        }

        circleX += 1.5;
        circleY += 0.75;
        if (@as(i32, @intFromFloat(circleX)) >= circle.radius * 2 + drawSize.x) {
            circleX = @as(f32, @floatFromInt(-circle.radius * 2));
        }
        if (@as(i32, @intFromFloat(circleY)) >= circle.radius + drawSize.y) {
            circleY = @as(f32, @floatFromInt(-circle.radius * 2));
        }

        try writer.interface.flush();
        @memset(output.items[0 .. winsize.row * winsize.col], SPACE);

        try init.io.sleep(std.Io.Duration.fromMilliseconds(16), std.Io.Clock.real);
    }
}

fn degrees_to_radian(degree: f32) f32 {
    return degree * PI2 / @as(f32, @floatFromInt(MAX_DEGREES));
}

fn is_within_bounds(value: i32, upper_limit: i32) bool {
    return value < upper_limit and value >= 0;
}

test "degrees_to_radian gives correct degrees" {
    const test_cases = [7][2]f32{
        [_]f32{ 0.0, 0.0 },
        [_]f32{ 30.0, 0.5235988 },
        [_]f32{ 60.0, 1.047198 },
        [_]f32{ 90.0, 1.570796 },
        [_]f32{ MAX_DEGREES / 2, 3.141593 },
        [_]f32{ 270.0, 4.712389 },
        [_]f32{ MAX_DEGREES, 6.283185 },
    };

    for (test_cases) |cases| {
        const case, const expected = cases;
        const radian = degrees_to_radian(case);
        try std.testing.expectApproxEqAbs(expected, radian, 0.000001);
    }
}

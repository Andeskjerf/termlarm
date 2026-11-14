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

// TODO:
// 1. [x] circle should be in its own coordinate space - we should not need to worry about having it above 0
// 2. [ ] circle should NOT take into account the width of characters, like it currently does. renderer should focus on that

const Circle = struct {
    radius: i32,
    step: i32,

    pub fn next(self: *Circle) ?Vec2f {
        const targetStep = self.radius * 20;
        if (self.step >= targetStep) return null;

        const radi = @as(f32, @floatFromInt(self.step)) / @as(f32, @floatFromInt(targetStep)) * PI2;
        const y = std.math.cos(radi) * @as(f32, @floatFromInt(self.radius));
        const x = std.math.sin(radi) * @as(f32, @floatFromInt((self.radius * 2)));
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
    var stdout = std.Io.File.stdout().writer(io, drawBuffer);

    const drawSize: Vec2i = .{ .y = 50, .x = 50 * 2 };
    const output = try allocator.create([drawSize.y * drawSize.x]u8);
    @memset(output[0 .. drawSize.y * drawSize.x], SPACE);

    while (true) {
        try stdout.interface.writeAll("\x1b[H");

        var circle: Circle = .{ .radius = 20, .step = 0 };
        while (circle.next()) |p| {
            const y = @as(i32, @intFromFloat(@round(p.y))) + drawSize.y / 2;
            const x = @as(i32, @intFromFloat(@round(p.x))) + drawSize.x / 2;
            if (is_within_bounds(y, drawSize.y) and is_within_bounds(x, drawSize.x))
                output[@as(usize, @intCast(y * drawSize.x + x))] = NUMBER_SIGN;
        }

        var row: i32 = 0;
        while (row < drawSize.y) {
            const startPos = @as(usize, @intCast(row * drawSize.x));
            const endPos = @as(usize, @intCast(startPos + drawSize.x));

            try stdout.interface.print("{s}\n", .{output[startPos..endPos]});
            row += 1;
        }

        try stdout.interface.flush();
        @memset(output[0 .. drawSize.y * drawSize.x], SPACE);

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

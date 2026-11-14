const std = @import("std");

const termlarm = @import("termlarm");

const PI = 3.14159265358979323846;
const PI2 = 2.0 * PI;

const MAX_DEGREES = 360;

const SPACE = 32;
const NUMBER_SIGN = 35;

const BUFFER_MAX_Y = 1024;
const BUFFER_MAX_X = BUFFER_MAX_Y * 2;

const Vec2 = struct {
    y: i32,
    x: i32,
};

pub fn main(_: std.process.Init) !void {
    const draw_size: Vec2 = .{ .y = 50, .x = 50 * 2 };

    var output: [BUFFER_MAX_Y][BUFFER_MAX_X]u8 = @splat(@splat(SPACE));
    draw_circle(&output, 40, .{ .y = draw_size.y / 2, .x = draw_size.x / 2 });

    for (&output, 0..) |*y, i| {
        if (i >= draw_size.y) {
            break;
        }
        std.debug.print("{s}\n", .{y[0..draw_size.x]});
    }
}

fn draw_circle(buffer: *[BUFFER_MAX_Y][BUFFER_MAX_X]u8, size: i32, pos: Vec2) void {
    const _size: Vec2 = .{ .y = size, .x = size * 2 };

    var i: i16 = 0;
    // TODO: separate steps from degrees
    const steps = MAX_DEGREES;
    while (i < steps) {
        const radi = degrees_to_radian(@floatFromInt(i));

        const y = apply_offset(calculate_position(std.math.cos(radi), _size.y - 1), pos.y, _size.y);
        const x = apply_offset(calculate_position(std.math.sin(radi), _size.x - 1), pos.x, _size.x);

        if (is_within_bounds(y, BUFFER_MAX_Y) and is_within_bounds(x, BUFFER_MAX_X))
            buffer[@as(usize, @intCast(y))][@as(usize, @intCast(x))] = NUMBER_SIGN;

        i += 1;
    }
}

fn degrees_to_radian(degree: f32) f32 {
    return degree * PI2 / @as(f32, @floatFromInt(MAX_DEGREES));
}

fn calculate_position(value: f32, max: i32) i32 {
    const half: f32 = @as(f32, @floatFromInt(max)) / 2.0;
    const pos = (value + 1.0) * half; // [0, max_x]
    return @intFromFloat(@round(pos));
}

fn apply_offset(value: i32, offset: i32, size: i32) i32 {
    return value + (offset - @divFloor(size, 2));
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

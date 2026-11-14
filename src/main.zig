const std = @import("std");
const termlarm = @import("termlarm");

const PI = 3.14159265358979323846;
const PI2 = 2.0 * PI;

const MAX_DEGREES = 360;

const SPACE = 32;
const NUMBER_SIGN = 35;

pub fn main(_: std.process.Init) !void {
    const max_x = 100;
    const max_y = 50;
    var output: [max_y][max_x]u8 = @splat(@splat(SPACE));

    var i: i16 = 0;
    const steps = MAX_DEGREES;
    while (i < steps) {
        const radi = degrees_to_radian(@floatFromInt(i));

        const x: usize = calculate_x_position(radi, max_x - 1);
        const y: usize = calculate_y_position(radi, max_y - 1);

        output[y][x] = NUMBER_SIGN;

        i += 1;
    }

    for (output) |y| {
        for (y) |x| {
            std.debug.print("{c}", .{x});
        }
        std.debug.print("\n", .{});
    }
}

fn degrees_to_radian(degree: f32) f32 {
    if (degree == 0.0) {
        return 0.0;
    }

    return degree * PI2 / @as(f32, @floatFromInt(MAX_DEGREES));
}

fn calculate_x_position(radi: f32, max_x: i32) usize {
    const half: f32 = @as(f32, @floatFromInt(max_x)) / 2.0;
    const x = (std.math.sin(radi) + 1.0) * half; // [0, max_x]
    return @intFromFloat(@round(x));
}

fn calculate_y_position(radi: f32, max_y: i32) usize {
    const half: f32 = @as(f32, @floatFromInt(max_y)) / 2.0;
    const y = (std.math.cos(radi) + 1.0) * half; // [0, max_y]
    return @intFromFloat(@round(y));
}

test "sin calculation" {
    const max_x = 50;
    const radi = degrees_to_radian(1);

    const sin = calculate_x_position(radi, max_x);
    std.debug.print("{d}\n", .{sin});
}

test "degrees_to_radian gives correct degrees" {
    const test_cases = [6][2]f32{
        [_]f32{ 0.0, 0.0 },
        [_]f32{ 30.0, 0.5235988 },
        [_]f32{ 60.0, 1.047198 },
        [_]f32{ 90.0, 1.570796 },
        [_]f32{ 180.0, 3.141593 },
        [_]f32{ 270.0, 4.712389 },
    };

    for (test_cases) |cases| {
        const case, const expected = cases;
        const radian = degrees_to_radian(case);
        try std.testing.expectApproxEqAbs(expected, radian, 0.000001);
    }
}

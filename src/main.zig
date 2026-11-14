const std = @import("std");

const termlarm = @import("termlarm");

const PI = 3.14159265358979323846;
const PI2 = 2.0 * PI;

const MAX_DEGREES = 360;

const SPACE = 32;
const NUMBER_SIGN = 35;

const output_y = 50;
const output_x = output_y * 2;

pub fn main(_: std.process.Init) !void {
    var output: [output_y][output_x]u8 = @splat(@splat(SPACE));
    circle(&output, 40, output_y / 2, output_x / 2);

    for (&output) |*y| {
        for (y) |x| {
            std.debug.print("{c}", .{x});
        }
        std.debug.print("\n", .{});
    }
}

fn circle(buffer: *[output_y][output_x]u8, size: comptime_int, pos_y: i32, pos_x: i32) void {
    const max_y = size;
    const max_x = size * 2;

    var i: i16 = 0;
    // TODO: separate steps from degrees
    const steps = MAX_DEGREES;
    while (i < steps) {
        const radi = degrees_to_radian(@floatFromInt(i));

        const y: usize = apply_offset(calculate_position(std.math.cos(radi), max_y - 1), pos_y, max_y);
        const x: usize = apply_offset(calculate_position(std.math.sin(radi), max_x - 1), pos_x, max_x);

        buffer[y][x] = NUMBER_SIGN;

        i += 1;
    }
}

fn degrees_to_radian(degree: f32) f32 {
    return degree * PI2 / @as(f32, @floatFromInt(MAX_DEGREES));
}

fn calculate_position(value: f32, max: i32) usize {
    const half: f32 = @as(f32, @floatFromInt(max)) / 2.0;
    const pos = (value + 1.0) * half; // [0, max_x]
    return @intFromFloat(@round(pos));
}

fn apply_offset(value: usize, offset: i32, size: i32) usize {
    return value + @as(usize, @intCast(offset - @divFloor(size, 2)));
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

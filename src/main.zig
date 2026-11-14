const std = @import("std");

const termlarm = @import("termlarm");

const PI = 3.14159265358979323846;
const PI2 = 2.0 * PI;

const MAX_DEGREES = 360;

const SPACE = 32;
const NUMBER_SIGN = 35;

const Vec2 = struct {
    y: i32,
    x: i32,
};

// 1. [x] move away from debug print, figure out how to print our circle that way
// 2. [ ] rewrite circle function to return an array of points
// 3. [ ] do transformations before drawing / moving to output buffer
// 4. [ ] take these points and draw em

pub fn main(init: std.process.Init) !void {
    const io = init.io;
    var arena = init.arena;
    defer arena.deinit();
    const allocator = arena.allocator();

    const drawBuffer = try allocator.create([1024]u8);
    var stdout = std.Io.File.stdout().writer(io, drawBuffer);

    const drawSize: Vec2 = .{ .y = 50, .x = 50 * 2 };
    const output = try allocator.create([drawSize.y * drawSize.x]u8);
    @memset(output[0 .. drawSize.y * drawSize.x], SPACE);

    draw_circle(output, 40, .{ .y = drawSize.y / 2, .x = drawSize.x / 2 });

    var row: i32 = 0;
    while (row < drawSize.y) {
        const startPos = @as(usize, @intCast(row * drawSize.x));
        const endPos = @as(usize, @intCast(startPos + drawSize.x));

        try stdout.interface.print("{s}\n", .{output[startPos..endPos]});
        row += 1;
    }
    try stdout.interface.flush();
}

// TODO: rewrite to instead return an array of coordinates
// if it should return an array of coordinates, we need to size it according to some value...
// how expensive is heap allocation really?
// 1. allocate something on the heap for every circle we draw. that lets us create all our shapes before drawing
// 2. reuse a buffer for storing each shape, then immediately transfer it to output buffer & clear shape buffer. this avoids allocating a buffer for each shape
fn draw_circle(buffer: []u8, size: i32, pos: Vec2) void {
    const _size: Vec2 = .{ .y = size, .x = size * 2 };

    var i: i16 = 0;
    // TODO: separate steps from degrees
    const steps = MAX_DEGREES;
    while (i < steps) {
        const radi = degrees_to_radian(@floatFromInt(i));

        // should not deal with offsets in here, that is the responsibility of the canvas
        const y = apply_offset(calculate_position(std.math.cos(radi), _size.y - 1), pos.y, _size.y);
        const x = apply_offset(calculate_position(std.math.sin(radi), _size.x - 1), pos.x, _size.x);

        if (is_within_bounds(y, 50) and is_within_bounds(x, 100))
            buffer[@as(usize, @intCast(y * 100 + x))] = NUMBER_SIGN;

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

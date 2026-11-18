pub const math = @import("math.zig");

pub fn Factory(digit: i8) []const math.Vec2f {
    return switch (digit) {
        0 => &ZERO,
        1 => &ONE,
        2 => &TWO,
        3 => &THREE,
        4 => &FOUR,
        5 => &FIVE,
        6 => &SIX,
        7 => &SEVEN,
        8 => &EIGHT,
        9 => &NINE,
        inline else => &ZERO,
    };
}

pub const ZERO = [_]math.Vec2f{
    .{ .y = -1.0, .x = 0.0 },
    .{ .y = -1.0, .x = 1.0 },
    .{ .y = 1.0, .x = 1.0 },
    .{ .y = 1.0, .x = 0.0 },
    .{ .y = -1.0, .x = 0.0 },
};

pub const ONE = [_]math.Vec2f{
    .{ .y = -1.0, .x = 0.0 },
    .{ .y = 1.0, .x = 0.0 },
};

pub const TWO = [_]math.Vec2f{
    .{ .y = -1.0, .x = 0.0 },
    .{ .y = -1.0, .x = 1.0 },
    .{ .y = 0.0, .x = 1.0 },
    .{ .y = 0.0, .x = 0.0 },
    .{ .y = 1.0, .x = 0.0 },
    .{ .y = 1.0, .x = 1.0 },
};

pub const THREE = [_]math.Vec2f{
    .{ .y = -1.0, .x = 0.0 },
    .{ .y = -1.0, .x = 1.0 },
    .{ .y = 0.0, .x = 1.0 },
    .{ .y = 0.0, .x = 0.0 },
    .{ .y = 0.0, .x = 1.0 },
    .{ .y = 1.0, .x = 1.0 },
    .{ .y = 1.0, .x = 0.0 },
};

pub const FOUR = [_]math.Vec2f{
    .{ .y = -1.0, .x = 0.0 },
    .{ .y = 0.0, .x = 0.0 },
    .{ .y = 0.0, .x = 1.0 },
    .{ .y = -1.0, .x = 1.0 },
    .{ .y = 1.0, .x = 1.0 },
};

pub const FIVE = [_]math.Vec2f{
    .{ .y = -1.0, .x = 1.0 },
    .{ .y = -1.0, .x = 0.0 },
    .{ .y = 0.0, .x = 0.0 },
    .{ .y = 0.0, .x = 1.0 },
    .{ .y = 1.0, .x = 1.0 },
    .{ .y = 1.0, .x = 0.0 },
};

pub const SIX = [_]math.Vec2f{
    .{ .y = -1.0, .x = 1.0 },
    .{ .y = -1.0, .x = 0.0 },
    .{ .y = 0.0, .x = 0.0 },
    .{ .y = 1.0, .x = 0.0 },
    .{ .y = 1.0, .x = 1.0 },
    .{ .y = 0.0, .x = 1.0 },
    .{ .y = 0.0, .x = 0.0 },
};

pub const SEVEN = [_]math.Vec2f{
    .{ .y = -1.0, .x = 0.0 },
    .{ .y = -1.0, .x = 1.0 },
    .{ .y = 1.0, .x = 1.0 },
};

pub const EIGHT = [_]math.Vec2f{
    .{ .y = 0.0, .x = 0.0 },
    .{ .y = -1.0, .x = 0.0 },
    .{ .y = -1.0, .x = 1.0 },
    .{ .y = 0.0, .x = 1.0 },
    .{ .y = 0.0, .x = 0.0 },
    .{ .y = 1.0, .x = 0.0 },
    .{ .y = 1.0, .x = 1.0 },
    .{ .y = 0.0, .x = 1.0 },
};

pub const NINE = [_]math.Vec2f{
    .{ .y = 0.0, .x = 1.0 },
    .{ .y = 0.0, .x = 0.0 },
    .{ .y = -1.0, .x = 0.0 },
    .{ .y = -1.0, .x = 1.0 },
    .{ .y = 1.0, .x = 1.0 },
};

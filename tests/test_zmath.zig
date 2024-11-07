const std = @import("std");
const testing = std.testing;

const zmath = @cImport(@cInclude("zmath.h"));

test "zmath.add() works" {
    try testing.expect(zmath.add(1, 2) == 3);
    try testing.expect(zmath.add(12, 12) == 24);
}

test "zmath.sub() works" {
    try testing.expect(zmath.sub(2, 1) == 1);
    try testing.expect(zmath.sub(12, 12) == 0);
}

const std = @import("std");
const zmath = @import("zmath.zig");

pub fn main() !void {
    const stdio = std.io.getStdOut().writer();

    const a = 10;
    const b = 5;

    const resultAdd = try zmath.add(a, b);
    try stdio.print("{d} + {d} = {d}\n", .{ a, b, resultAdd });

    const resultSub = try zmath.sub(a, b);
    try stdio.print("{d} - {d} = {d}\n", .{ a, b, resultSub });
}

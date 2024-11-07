const std = @import("std");
const zmath = @cImport(@cInclude("zmath.h"));

pub fn main() !void {
    const stdio = std.io.getStdOut().writer();

    const a = 10;
    const b = 5;

    const resultAdd = zmath.add(a, b);
    try stdio.print("{} + {} = {}\n", .{ a, b, resultAdd });

    const resultSub = zmath.sub(a, b);
    try stdio.print("{} - {} = {}\n", .{ a, b, resultSub });
}

const zmath_ext = @import("zmath_ext.zig");

pub fn add(a: i32, b: i32) !i32 {
    const x = @as(c_int, @intCast(a));
    const y = @as(c_int, @intCast(b));
    return zmath_ext.add(x, y);
}

pub fn sub(a: i32, b: i32) !i32 {
    const x = @as(c_int, @intCast(a));
    const y = @as(c_int, @intCast(b));
    return zmath_ext.sub(x, y);
}

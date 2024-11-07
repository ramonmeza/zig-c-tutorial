const zmath = @cImport(@cInclude("zmath.h"));

pub fn add(a: i32, b: i32) !i32 {
    const x = @as(c_int, @intCast(a));
    const y = @as(c_int, @intCast(b));
    return zmath.add(x, y);
}

pub fn sub(a: i32, b: i32) !i32 {
    const x = @as(c_int, @intCast(a));
    const y = @as(c_int, @intCast(b));
    return zmath.sub(x, y);
}

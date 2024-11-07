const zmath_h = @cImport(@cInclude("zmath.h"));

pub extern fn add(a: c_int, b: c_int) c_int;
pub extern fn sub(a: c_int, b: c_int) c_int;

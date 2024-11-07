# Understanding How Zig and C Interact

My journey to understanding how Zig interacts with C and how I, someone not 
well-versed in C, can leverage the power of third-party C libraries.

This journey will include the following:

- [Create a Simple C application](#create-a-simple-c-application)
- [Compiling the application using `zig cc`](#compiling-the-application-using-zig-cc)
- [Leverage Zig's build system to build the C application](#leverage-zigs-build-system-to-build-the-c-application)
- [Create a Zig application that links to the C library](#create-a-zig-application-that-links-to-the-c-library)
- [Create a Zig wrapper around a C Function](#create-a-zig-wrapper-around-a-c-function)
- [Create a Zig binding for the C library](#create-a-zig-binding-for-the-c-library)

- [Testing C code in Zig???](#)

## The Journey
### Create a Simple C Application

This should be straight-forward. I will create a simple math library in C, with 
functions defined in a header file and implemented in the source file.

[`zmath.h`](include/zmath.h)
```
int add(int a, int b);
int sub(int a, int b);
```

[`zmath.c`](src/zmath.c)
```
#include "zmath.h"

int add(int a, int b) {
    return a + b;
}

int sub(int a, int b) {
    return a - b;
}
```

Next I created a simple application to utilize this library.

[`main.c`](src/main.c)
```
#include <stdio.h>
#include "zmath.h"

int main(void) {
    int a = 10;
    int b = 5;
    
    int resultAdd = add(a, b);
    printf("%d + %d = %d\n", a, b, resultAdd);
    
    int resultSub = sub(a, b);
    printf("%d - %d = %d\n", a, b, resultSub);

    return 0;
}
```

### Compiling the application using `zig cc`

If you're familiar with gcc, this is no problem. Here's the command to compile 
this application:

```sh
zig cc -Iinclude src/main.c src/zmath.c -o zig-out/bin/c_compiled_with_zigcc.exe
```
_The nice part about Zig is that it's a cross-compiler, so feel free to ignore that I'm on Windows._

Now run the resulting executable:

```sh
> ./zig-out/bin/c_compiled_with_zigcc.exe
10 + 5 = 15
10 - 5 = 5
```

### Leverage Zig's build system to build the C application

Now we can create a file called `build.zig`, which Zig will use to build our application.

[`build.zig`](build_c_compiled_with_zig_build.zig)
```zig
const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const exe = b.addExecutable(.{
        .name = "c_compiled_with_zig_build",
        .target = target,
        .optimize = optimize,
    });

    exe.addIncludePath(b.path("include"));
    exe.addCSourceFiles(.{
        .files = &[_][]const u8{
            "src/main.c",
            "src/zmath.c"
        }
    });

    exe.linkLibC();

    b.installArtifact(exe);
}
```

Things to note:
- `b.addExecutable()` allows us to create an executable with given options, in this case default target options and optimizations. It also allows us to name our executable.
- `exe.addIncludePath()` takes a `LazyPath`, and it just so happens that `std.Build` (the type of `b`) contains a function to provide a `LazyPath` object given a string.
- `exe.addCSourceFiles()` takes a `struct` that includes a `files` property. This property is a pointer to an array of strings. I'll break down `&[_][]const u8 {}` real quick in plain English:

```zig
&[_][]const u8 {
    "..",
    "...",
    // etc
}

// const u8 is a character
// []const u8 is an array of characters, or a string
// [_] is zig for "create an array with size automatically determined at compile time"
// [_][]const u8 is an array of strings
// & gives us a pointer to an object's memory address
// &[_][]const u8 is a pointer to an array of strings


// a reference to an automatically sized array of array of constants u8 objects.
// a pointer to the address in memory where an array of arrays of u8 exists
```
_Probably overkill of an explanation, but maybe someone will benefit from this._

- Next is `exe.linkLibC()`. This is the extremely convenient way that Zig links to libc. There's also `linkLibCpp()`, which could be useful to keep in mind. If you use a standard library, such as `stdio.h`, make sure to include `linkLibC()`, otherwise you'll get a compilation error when trying to build.

Now we kick off the Zig build process:

```sh
zig build
```

And run the resulting executable:
```sh
./zig-out/bin/c_compiled_with_zig_build.exe
10 + 5 = 15
10 - 5 = 5
```

Same results as compiling with `zig cc`! Very cool. Let's move on to using a bit more Zig.

### Create a Zig application that links to the C library

Basically, I want to recreate my `main.c` in Zig. In this case, this is trivial.

[`main.zig`](src/zig_linked_to_c.zig)
```zig
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
```

Fairly simple to understand. The only gotcha is using printing the output. Next 
we have to modify `build.zig` and point it to our `main.zig` file 
instead of `main.c`.

[`build.zig`](build_zig_linked_to_c.zig)
```zig
const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const exe = b.addExecutable(.{
        .name = "build_zig_linked_to_c",
        .root_source_file = b.path("src/zig_linked_to_c.zig"),
        .target = target,
        .optimize = optimize,
    });

    exe.addIncludePath(b.path("include"));
    exe.addCSourceFile(.{
        .file = b.path("src/zmath.c"),
    });

    exe.linkLibC();

    return exe;
}
```

The only thing to pay attention to here is the `root_source_file` parameter in 
`addExecutable()`. Here we point to a Zig file with `pub fn main() void` 
implemented. This is a drop in replacement of `main.c`, or rather a Zig file 
using a C library.

### Create a Zig wrapper around a C Function

This is a simple example, so wrapping the C function in Zig may be overkill. 
Anywho, the idea is to wrap the call to our C functions in Zig, such that we 
have a Zig interface between our application code and our C code. This allows us 
to handle errors in a Zig fashion and pass proper types to the C code while 
exposing them to the application code.

For this I'll create a new Zig file, `zmath.zig`

`zmath.zig`
```zig
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
```

As you can see, I translate the C types to Zig specific types for use in Zig 
applications. I cast our input parameters to their C equivalent (`c_int`) for 
the C function's parameters. You'll also notice the return type contains `!`, 
meaning we'll return errors. This means within our application, we'll need to 
call the function with `try`.

Let's update our `main.zig` file now

`main.zig`
```zig
const std = @import("std");
const zmath = @import("zmath.zig");

pub fn main() !void {
    const stdio = std.io.getStdOut().writer();

    const a = 10;
    const b = 5;

    const resultAdd = zmath.add(a, b);
    try stdio.print("{} + {} = {}\n", .{ a, b, resultAdd });

    const resultSub = zmath.sub(a, b);
    try stdio.print("{} - {} = {}\n", .{ a, b, resultSub });
}
```

You can see, we use `@import("zmath.zig")` to import our wrapper functions. Then 
we use it just as you'd expect. Lastly, we have to update our `build.zig` file 
to account for these changes.

Our `build.zig` file is the same as last time. We still need to link the C code, 
which is annoying and doesn't reflect how you might link C to Zig in "real-world" 
situations, such as only has a library file. We'll cover linking C library files 
in Zig, but first we'll build our library using Zig's build system.

### Using Zig to build your C Library

We'll use our `zmath` library we wrote in C and build it into a shared libary so 
that we can dynamically link to rather than needing to include the source code 
during build time. Basically, this is the situation you'll be in when using 
distributed code.

Let's write out `build.zig` file:

`build.zig`
```zig
c
```

###

## Bonus!
### Testing C code in Zig
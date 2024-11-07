# Understanding How Zig and C Interact

My journey to understanding how Zig interacts with C and how I, someone not 
well-versed in C, can leverage the power of third-party C libraries.

## What This Doesn't Cover

- Using Zig in C
- Using C
- C at all

## TOC

- [Utilizing This Project](#utilizing-this-project)
    - [Zig Build Commands](#zig-build-commands)
- [The Journey](#the-journey)
    - [Create a Simple C application](#create-a-simple-c-application)
    - [Compiling the application using `zig cc`](#compiling-the-application-using-zig-cc)
    - [Leverage Zig's build system to build the C application](#leverage-zigs-build-system-to-build-the-c-application)
    - [Create a Zig application that links to the C library](#create-a-zig-application-that-links-to-the-c-library)
    - [Create a Zig wrapper around a C Function](#create-a-zig-wrapper-around-a-c-function)
    - [Using Zig to build a C Library](#using-zig-to-build-a-c-library)
- [Side Quests](#side-quests)
    - [Testing C code in Zig](#testing-c-code-in-zig)
- [Resources](#resources)

## Utilizing this Project

### Zig Build Commands
```sh
zig build [steps] [options]

Steps:
  install (default)            Copy build artifacts to prefix path
  uninstall                    Remove build artifacts from prefix path
  c_app                        Run a C application built with Zig's build system.
  zig_app                      Run a Zig application linked to C source code.
  zmath_static                 Create a static library from C source code.
  zmath_shared                 Create a shared library from C source code.
  zig_app_shared               Run a Zig application that is linked to a shared library.
  zig_app_static               Run a Zig application that is linked to a static library.
  tests                        Run a Zig tests of C source code.
```

## The Journey
### Create a Simple C Application

Let's create a simple math library in C, with functions declared in a header 
file and implemented in the source file.

[`zmath.h`](include/zmath.h)
```c
extern int add(int a, int b);
extern int sub(int a, int b);
```
_Note: `extern` is used here to export our functions._

[`zmath.c`](src/zmath.c)
```c
#include "zmath.h"

int add(int a, int b) {
    return a + b;
}

int sub(int a, int b) {
    return a - b;
}

```

Next I created a simple application to utilize this library.

[`c_app.c`](src/c_app.c)
```c
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

If you're familiar with `gcc`, this is no problem. Here's the command to compile 
this application:

```sh
zig cc -Iinclude src/c_app.c src/zmath.c -o zig-out/bin/c_app.exe
```
_The nice part about Zig is that it's a cross-compiler, so feel free to ignore that I'm on Windows._

Now run the resulting executable:

```sh
> ./zig-out/bin/c_app.exe
10 + 5 = 15
10 - 5 = 5
```

### Leverage Zig's build system to build the C application

Now we can create a file called `build.zig`, which Zig will use to build our application.

[`build.zig`](build_c_app.zig)
```c
const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const exe = b.addExecutable(.{
        .name = "c_app",
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
- `b.addExecutable()` allows us to create an executable with given options, in 
this case default target options and optimizations. It also allows us to name 
our executable.
- `exe.addIncludePath()` takes a `LazyPath`, and it just so happens that 
`std.Build` (the type of `b`) contains a function to return a `LazyPath` object 
given a string.
- `exe.addCSourceFiles()` takes a `struct` that includes a `files` property. 
This property is a pointer to an array of strings. I'll break down 
`&[_][]const u8 {}` real quick in plain English:

```c
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

- Next is `exe.linkLibC()`. This is the extremely convenient way that Zig links 
to libc. There's also `linkLibCpp()`, which could be useful to keep in mind. If 
you use a standard library, such as `stdio.h`, make sure to include `linkLibC()`, 
otherwise you'll get a compilation error when trying to build.

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

Basically, I want to recreate my `c_app.c` in Zig. In this case, this is trivial.

[`zig_app.zig`](src/zig_app.zig)
```c
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

This is fairly simple to understand. What's important is that we are including 
our C headers using Zig's `@cImport()` and `@cInclude()`.

Next we have to modify `build.zig` and point it to our `zig_app.zig` file 
instead of `c_app.c`.

[`build.zig`](build_zig_app.zig)
```c
const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const exe = b.addExecutable(.{
        .name = "build_zig_linked_to_c",
        .root_source_file = b.path("src/zig_app.zig"),
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
implemented. This is a drop in replacement of `c_app.c`, or rather a Zig file 
using a C library (when source code is available).


### Using Zig to build a C Library

Up until now, I've been utilizing the C source code, since it's available to us, 
but this is not always the case. Sometimes we may have a static or shared library 
that we need to link against, rather than compiling the source code ourselves. 
 
_If you want a deeper understanding of static and shared libraries, check out 
the links in the [Resources](#resources) section._

[`build.zig`](build_c_static_lib.zig)
```c
const std = @import("std");

pub fn build(b: *std.Build) *std.Build.Step.Compile {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const lib = b.addStaticLibrary(.{
        .name = "zmath_static",
        .target = target,
        .optimize = optimize,
    });

    lib.addIncludePath(b.path("include"));
    lib.addCSourceFiles(.{ .files = &[_][]const u8{"src/zmath.c"} });

    lib.linkLibC();

    b.installArtifact(lib);
}
```

We add our source files, include directory, link it to libc and install it. 
When we run `zig build`, our library will be compiled to a static library file, 
`zig-out/lib/zmath-static.lib`.

If you want to compile shared libraries instead, there's not much difference. 
Instead of `b.addStaticLibrary()`, use `b.addSharedLibrary()`.

_[See the difference in build.zig](build_c_shared_lib.zig)_

It would be wise to note that here we build our library and then import it from 
a path. If you build from source, use `linkLibrary(*Compile)` rather than 
`linkLibrary2()`, as Zig will compile faster than your OS can save the library 
file, causing it not to be found during build time.

### Create a Zig wrapper around a C Function

This is a simple example, so wrapping the C function in Zig may be overkill. 
Either way, the idea is to wrap the call to our C functions in Zig, such that we 
have a Zig interface between our application code and our C code. This allows us 
to handle errors in a Zig fashion and pass proper types to the C code while 
exposing them to the application code.

For this I'll create a new Zig file, `zmath_ext.zig`

[`zmath_ext.zig`](src/zmath_ext.zig)
```c
const zmath_h = @cImport(@cInclude("zmath.h"));

pub extern fn add(a: c_int, b: c_int) c_int;
pub extern fn sub(a: c_int, b: c_int) c_int;
```

This file is a declaration of external functions we wish to use Zig. We'll next 
create a `zmath.zig`, in which we will create Zig functions that will expose 
Zig data types through our API and cast the parameters to their corresponding C 
data types before calling the C functions.

[`zmath.zig`](src/zmath.zig)
```c
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
```

As you can see, we translate the C types to Zig specific types for use in Zig 
applications. WE cast our input parameters to their C equivalent (`c_int`) for 
the C function's parameters. You'll also notice the return type contains `!`, 
meaning these functions will now return errors. This means within our 
application, we'll need to call the function with `try`.

I'll create a new zig file for trying out the wrapper functions, called 
`zig_c_wrapper.zig`. This is mostly to distinguish between our previous examples, 
but this is just showing we no longer use `@cImport()` directly, and instead 
utilize `zmath.zig` (our wrapper functions), to interact with the C code.

[`zig_c_wrapper.zig`](src/zig_c_wrapper.zig)
```c
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
```

You should be able to use the same `build.zig` file as before to run this.


## Side Quests

Some extra thoughts I have about integrating Zig and C together.

### Testing C code in Zig

I was curious if I could use Zig's testing features to test C code. There's 
literally no reason why you couldn't, so here's how you do it.

[`test_zmath.zig`](tests/test_zmath.zig)
```c
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
```
_Strive to write good tests, this is just a proof of concept._

`build.zig`
```c
const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const tests_exe = b.addTest(.{
        .name = "test_zmath",
        .root_source_file = b.path("tests/test_zmath.zig"),
        .target = target,
        .optimize = optimize,
    });

    tests_exe.addIncludePath(b.path("include"));
    tests_exe.addCSourceFile(.{
        .file = b.path("src/zmath.c"),
    });

    tests_exe.linkLibC();

    b.installArtifact(tests_exe);
}
```

## Resources
- https://mtlynch.io/notes/zig-call-c-simple/
What initially made me want to tackle this subject, this article is a great 
starting point for understanding C and Zig.

- [Wikipedia article for "Shared Library"](https://en.wikipedia.org/wiki/Shared_library)
- [Wikipedia article for "Static Library"](https://en.wikipedia.org/wiki/Static_library)


## Thanks

That's it. It was a long journey, but one that came with lots of learning and 
experimenting. Zig is wonderful and being able to use C code without having to 
use C is a game changer for me.

Thanks for sticking around and reading. If you have feedback or suggestions, 
please don't hesitate to create an issue and we can work through it together.

- Ramon

const std = @import("std");

pub fn build(b: *std.Build, target: std.Build.ResolvedTarget, optimize: std.builtin.OptimizeMode) *std.Build.Step.Compile {
    const lib = b.addSharedLibrary(.{
        .name = "zmath-shared",
        .target = target,
        .optimize = optimize,
    });

    lib.addIncludePath(b.path("include"));
    lib.addCSourceFiles(.{ .files = &[_][]const u8{"src/zmath.c"} });

    lib.linkLibC();

    return lib;
}

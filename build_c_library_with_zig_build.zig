const std = @import("std");

pub fn build(b: *std.Build, target: std.Build.ResolvedTarget, optimize: std.builtin.OptimizeMode) *std.Build.Step.Compile {
    const exe = b.addExecutable(.{
        .name = "c_library_with_zig_build",
        .target = target,
        .optimize = optimize,
    });

    exe.addIncludePath(b.path("include"));
    exe.addCSourceFiles(.{ .files = &[_][]const u8{ "src/main.c", "src/zmath.c" } });

    exe.linkLibC();

    return exe;
}

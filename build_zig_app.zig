const std = @import("std");

pub fn build(b: *std.Build, target: std.Build.ResolvedTarget, optimize: std.builtin.OptimizeMode) *std.Build.Step.Compile {
    const exe = b.addExecutable(.{
        .name = "zig_app",
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

const std = @import("std");

pub fn build(b: *std.Build, target: std.Build.ResolvedTarget, optimize: std.builtin.OptimizeMode) *std.Build.Step.Compile {
    const exe = b.addExecutable(.{
        .name = "zig_app_shared",
        .root_source_file = b.path("src/zig_c_wrapper.zig"),
        .target = target,
        .optimize = optimize,
    });

    exe.addObjectFile(b.path("zig-out/lib/zmath-shared.lib"));

    return exe;
}

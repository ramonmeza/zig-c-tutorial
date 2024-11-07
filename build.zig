const std = @import("std");

const module_ex1 = @import("build_c_application_with_zig_build.zig");
const module_ex2 = @import("build_zig_linked_to_c.zig");
const module_ex3 = @import("build_zig_c_wrapper.zig");
const module_ex4 = @import("build_c_static_library_with_zig_build.zig");
const module_ex5 = @import("build_c_shared_library_with_zig_build.zig");
// const module_ex6 = @import("build_zig_linked_to_c_static_lib.zig");
// const module_ex7 = @import("build_zig_linked_to_c_shared_lib.zig");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    // ex1
    const ex1 = module_ex1.build(b, target, optimize);
    const run_ex1 = b.addRunArtifact(ex1);

    b.installArtifact(ex1);

    const run_ex1_step = b.step("ex1", "Run a C application build with Zig's build system.");
    run_ex1_step.dependOn(&run_ex1.step);

    // ex2
    const ex2 = module_ex2.build(b, target, optimize);
    const run_ex2 = b.addRunArtifact(ex2);

    b.installArtifact(ex2);

    const run_ex2_step = b.step("ex2", "Run a Zig application linked to C source code.");
    run_ex2_step.dependOn(&run_ex2.step);

    // ex3
    const ex3 = module_ex3.build(b, target, optimize);
    const run_ex3 = b.addRunArtifact(ex3);

    b.installArtifact(ex3);

    const run_ex3_step = b.step("ex3", "Run a Zig application with an abstraction layer between the C source code.");
    run_ex3_step.dependOn(&run_ex3.step);

    // ex4
    const ex4 = module_ex4.build(b, target, optimize);
    const install_ex4 = b.addInstallArtifact(ex4, .{});

    b.installArtifact(ex4);

    const install_ex4_step = b.step("ex4", "Create a shared library file from C source code.");
    install_ex4_step.dependOn(&install_ex4.step);

    // ex5
    const ex5 = module_ex5.build(b, target, optimize);
    const install_ex5 = b.addInstallArtifact(ex5, .{});

    b.installArtifact(ex5);

    const install_ex5_step = b.step("ex5", "Create a static library file from C source code.");
    install_ex5_step.dependOn(&install_ex5.step);

    // ex6
    // const ex6 = module_ex6.build(b, target, optimize);
    // const run_ex6 = b.addInstallArtifact(ex6, .{});

    // b.installArtifact(ex6);

    // const run_ex6_step = b.step("ex6", "Run a Zig application that is statically linked to a C library.");
    // run_ex6_step.dependOn(&run_ex6.step);

    // ex7
    // const ex7 = module_ex7.build(b, target, optimize);
    // const run_ex7 = b.addInstallArtifact(ex7, .{});

    // b.installArtifact(ex7);

    // const run_ex7_step = b.step("ex7", "Run a Zig application that is dynamically linked to a C library.");
    // run_ex7_step.dependOn(&run_ex7.step);
}

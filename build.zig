const std = @import("std");

const module_c_app = @import("build_c_app.zig");
const module_zig_app = @import("build_zig_app.zig");
const module_lib_static = @import("build_c_static_lib.zig");
const module_lib_shared = @import("build_c_shared_lib.zig");
const module_zig_app_static = @import("build_zig_app_static.zig");
const module_zig_app_shared = @import("build_zig_app_shared.zig");
const module_tests = @import("build_test_zmath.zig");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    // c_app
    const c_app = module_c_app.build(b, target, optimize);
    const run_c_app = b.addRunArtifact(c_app);

    b.installArtifact(c_app);

    const run_c_app_step = b.step("c_app", "Run a C application built with Zig's build system.");
    run_c_app_step.dependOn(&run_c_app.step);

    // zig_app
    const zig_app = module_zig_app.build(b, target, optimize);
    const run_zig_app = b.addRunArtifact(zig_app);

    b.installArtifact(zig_app);

    const run_zig_app_step = b.step("zig_app", "Run a Zig application linked to C source code.");
    run_zig_app_step.dependOn(&run_zig_app.step);

    // zmath_static
    const lib_static = module_lib_static.build(b, target, optimize);
    const install_lib_static = b.addInstallArtifact(lib_static, .{});

    b.installArtifact(lib_static);

    const install_lib_static_step = b.step("zmath_static", "Create a static library from C source code.");
    install_lib_static_step.dependOn(&install_lib_static.step);

    // zmath_shared
    const lib_shared = module_lib_shared.build(b, target, optimize);
    const install_lib_shared = b.addInstallArtifact(lib_shared, .{});

    b.installArtifact(lib_shared);

    const install_lib_shared_step = b.step("zmath_shared", "Create a shared library from C source code.");
    install_lib_shared_step.dependOn(&install_lib_shared.step);

    // zig_app_shared
    const zig_app_shared = module_zig_app_shared.build(b, target, optimize);
    const run_zig_app_shared = b.addInstallArtifact(zig_app_shared, .{});

    b.installArtifact(zig_app_shared);

    const run_zig_app_shared_step = b.step("zig_app_shared", "Run a Zig application that is linked to a shared library.");
    run_zig_app_shared_step.dependOn(&install_lib_shared.step); // create and install shared library
    run_zig_app_shared_step.dependOn(&run_zig_app_shared.step);

    // zig_app_static
    const zig_app_static = module_zig_app_static.build(b, target, optimize);
    const run_zig_app_static = b.addInstallArtifact(zig_app_static, .{});

    b.installArtifact(zig_app_static);

    const run_zig_app_static_step = b.step("zig_app_static", "Run a Zig application that is linked to a static library.");
    run_zig_app_static_step.dependOn(&install_lib_static.step); // create and install static library
    run_zig_app_static_step.dependOn(&run_zig_app_static.step);

    // tests
    const tests = module_tests.build(b, target, optimize);
    const run_tests = b.addRunArtifact(tests);

    b.installArtifact(tests);

    const run_tests_step = b.step("tests", "Run a Zig tests of C source code.");
    run_tests_step.dependOn(&run_tests.step);
}

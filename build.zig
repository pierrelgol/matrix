const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const exe_mod = b.createModule(.{
        .target = target,
        .optimize = optimize,
        .root_source_file = b.path("src/main.zig"),
    });

    const exe = b.addExecutable(.{
        .name = "matrix",
        .root_module = exe_mod,
    });

    b.installArtifact(exe);

    const exe_run = b.addRunArtifact(exe);
    exe_run.step.dependOn(b.getInstallStep());

    if (b.args) |args| {
        exe_run.addArgs(args);
    }

    const run_step = b.step("run", "Run the app");
    run_step.dependOn(&exe_run.step);

    const exe_test = b.addTest(.{
        .root_module = exe_mod,
    });

    const exe_test_run = b.addRunArtifact(exe_test);
    const test_step = b.step("test", "Test the app");
    test_step.dependOn(&exe_test_run.step);

    const exe_check = b.addExecutable(.{
        .name = "matrix",
        .root_module = exe_mod,
    });

    const exe_check_step = b.step("check", "Check the app");
    exe_check_step.dependOn(&exe_check.step);
}

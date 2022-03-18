const std = @import("std");

pub fn build(b: *std.build.Builder) void {
    // Standard target options allows the person running `zig build` to choose
    // what target to build for. Here we do not override the defaults, which
    // means any target is allowed, and the default is native. Other options
    // for restricting supported target set are available.
    const target = b.standardTargetOptions(.{});

    // Standard release options allow the person running `zig build` to select
    // between Debug, ReleaseSafe, ReleaseFast, and ReleaseSmall.
    const mode = b.standardReleaseOptions();

    const example0 = b.addExecutable("example-0", "src/example-0.zig");
    example0.linkSystemLibrary("gtk4");
    example0.setTarget(target);
    example0.setBuildMode(mode);
    example0.install();

    // const example1 = b.addExecutable("example-1", "src/example-1.zig");
    // example1.linkSystemLibrary("gtk4");
    // example1.setTarget(target);
    // example1.setBuildMode(mode);
    // example1.install();

    // const example2 = b.addExecutable("example-2", "src/example-2.zig");
    // example2.linkSystemLibrary("gtk4");
    // example2.setTarget(target);
    // example2.setBuildMode(mode);
    // example2.install();

    // const example4 = b.addExecutable("example-4", "src/example-4.zig");
    // example4.linkSystemLibrary("gtk4");
    // example4.setTarget(target);
    // example4.setBuildMode(mode);
    // example4.install();

    const run_cmd_0 = example0.run();
    run_cmd_0.step.dependOn(b.getInstallStep());

    // const run_cmd_1 = example1.run();
    // run_cmd_1.step.dependOn(b.getInstallStep());

    // const run_cmd_2 = example2.run();
    // run_cmd_2.step.dependOn(b.getInstallStep());

    // const run_cmd_4 = example4.run();
    // run_cmd_4.step.dependOn(b.getInstallStep());

    const run_step_0 = b.step("example0", "Run example 0");
    run_step_0.dependOn(&run_cmd_0.step);

    // const run_step_1 = b.step("example1", "Run example 1");
    // run_step_1.dependOn(&run_cmd_1.step);

    // const run_step_2 = b.step("example2", "Run example 2");
    // run_step_2.dependOn(&run_cmd_2.step);

    // const run_step_4 = b.step("example4", "Run example 4");
    // run_step_4.dependOn(&run_cmd_4.step);
}

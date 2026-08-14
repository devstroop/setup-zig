const std = @import("std");

// zig 0.15+ replaced root_source_file with root_module; detect at comptime
// so one fixture works across every Zig version the action installs.
const use_root_module = !@hasField(std.Build.ExecutableOptions, "root_source_file");

pub fn build(b: *std.Build) void {
    const exe = if (use_root_module) blk: {
        const mod = b.createModule(.{
            .root_source_file = b.path("src/main.zig"),
            .target = b.graph.host,
            .optimize = .Debug,
        });
        break :blk b.addExecutable(.{ .name = "hello", .root_module = mod });
    } else b.addExecutable(.{
        .name = "hello",
        .root_source_file = b.path("src/main.zig"),
        .target = b.graph.host,
        .optimize = .Debug,
    });

    b.installArtifact(exe);
    const run_cmd = b.addRunArtifact(exe);
    if (@hasField(std.Build, "args")) {
        if (b.args) |args| run_cmd.addArgs(args);
    }
    const run_step = b.step("run", "Run the hello binary");
    run_step.dependOn(&run_cmd.step);
}
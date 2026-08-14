const std = @import("std");

pub fn main() !void {
    std.debug.print("setup-zig: hello from Zig {s}\n", .{@import("builtin").zig_version_string});
}

const std = @import("std");

const Vector = @import("vector.zig").Vector;
const Matrix = @import("matrix.zig").Matrix;

comptime {
    std.testing.refAllDecls(@import("vector.zig"));
    std.testing.refAllDecls(@import("matrix.zig"));
}

pub fn main(init: std.process.Init) !void {
    _ = init;
}

const std = @import("std");
const Vector = @import("vector.zig").Vector;

pub fn Matrix(comptime T: type, N: usize, M: usize) type {
    return struct {
        const Mat = @This();
        pub const Vec = Vector(T, N);
        items: [M]Vec,

        pub const zero: Mat = blk: {
            var items: [M]Vec = undefined;
            for (0..M) |i| {
                items[i] = .zero;
            }
            break :blk .init(items);
        };

        pub const identity: Mat = blk: {
            if (!isSquare()) @compileError("Identity matrix only available for square matrix");
            var items: [M]Vec = undefined;
            for (0..M, 0..N) |i, j| {
                items[i] = .zero;
                items[i].items[j] = 1;
            }
            break :blk .init(items);
        };

        pub fn fromScalar(comptime v: T) Mat {
            return result: {
                var items: [M]Vec = undefined;
                for (0..M) |i| {
                    items[i] = .fromScalar(v);
                }
                break :result Mat.init(items);
            };
        }

        pub fn init(items: [M]Vec) Mat {
            return .{
                .items = items,
            };
        }

        pub fn get(m: Mat, i: usize, j: usize) T {
            return m.items[i].items[j];
        }

        pub fn set(m: Mat, i: usize, j: usize) T {
            return m.items[i].items[j];
        }

        pub fn row(m: Mat, comptime index: usize) Vec {
            comptime if (index >= M) @compileError("Index out of bound for type '" ++ @typeName(Mat) ++ "'");
            return m.items[index];
        }

        pub fn col(m: Mat, comptime index: usize) Vec {
            comptime if (index >= N) @compileError("Index out of bound for type '" ++ @typeName(Mat) ++ "'");
            var result: Vec = .zero;
            inline for (0..N) |i| {
                result.items[i] = m.items[index].items[i];
            }
            return result;
        }

        pub fn isSquare() bool {
            return M == N;
        }

        pub fn format(
            self: @This(),
            writer: *std.Io.Writer,
        ) std.Io.Writer.Error!void {
            try writer.writeByte('[');
            inline for (0..M) |i| {
                if (i + 1 == M) {
                    try writer.print("{f}]", .{self.row(i)});
                } else {
                    try writer.print("{f}]\n[", .{self.row(i)});
                }
            }
        }
    };
}

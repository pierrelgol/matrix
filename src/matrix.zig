const std = @import("std");
const Vector = @import("vector.zig").Vector;

const std = @import("std");
const Vector = @import("vector.zig").Vector;

pub fn Matrix(comptime T: type, comptime N: usize, comptime M: usize) type {
    return struct {
        const Mat = @This();
        pub const RowVec = Vector(T, N);
        pub const ColVec = Vector(T, M);

        items: [M]RowVec,

        pub const zero: Mat = blk: {
            var items: [M]RowVec = undefined;
            for (0..M) |i| {
                items[i] = RowVec.zero;
            }
            break :blk .init(items);
        };

        pub const identity: Mat = blk: {
            if (M != N) @compileError("Identity matrix only available for square matrices");

            var items: [M]RowVec = undefined;
            for (0..M) |i| {
                items[i] = RowVec.zero;
                items[i].items[i] = 1;
            }
            break :blk .init(items);
        };

        pub fn fromScalar(v: T) Mat {
            var items: [M]RowVec = undefined;
            for (0..M) |i| {
                items[i] = RowVec.fromScalar(v);
            }
            return .init(items);
        }

        pub fn init(items: [M]RowVec) Mat {
            return .{ .items = items };
        }

        pub fn rows(_: Mat) usize {
            return M;
        }

        pub fn cols(_: Mat) usize {
            return N;
        }

        pub fn isSquare() bool {
            return M == N;
        }

        pub fn get(m: Mat, i: usize, j: usize) T {
            std.debug.assert(i < M);
            std.debug.assert(j < N);
            return m.items[i].items[j];
        }

        pub fn set(m: *Mat, i: usize, j: usize, v: T) void {
            std.debug.assert(i < M);
            std.debug.assert(j < N);
            m.items[i].items[j] = v;
        }

        pub fn setRow(m: *Mat, index: usize, v: RowVec) void {
            std.debug.assert(index < M);
            m.items[index] = v;
        }

        pub fn setCol(m: *Mat, index: usize, v: ColVec) void {
            std.debug.assert(index < N);
            for (0..M) |i| {
                m.items[i].items[index] = v.items[i];
            }
        }

        pub fn row(m: Mat, index: usize) RowVec {
            std.debug.assert(index < M);
            return m.items[index];
        }

        pub fn col(m: Mat, index: usize) ColVec {
            std.debug.assert(index < N);

            var result: ColVec = ColVec.zero;
            for (0..M) |i| {
                result.items[i] = m.items[i].items[index];
            }
            return result;
        }

        pub fn add(m: Mat, v: RowVec) Mat {
            var mat: Mat = Mat.zero;
            for (0..M) |i| {
                mat.items[i] = m.items[i].add(v);
            }
            return mat;
        }

        pub fn broadcastSubstract(m: Mat, v: RowVec) Mat {
            var mat: Mat = Mat.zero;
            for (0..M) |i| {
                mat.items[i] = m.items[i].substract(v);
            }
            return mat;
        }

        pub fn broadcastMultiply(m: Mat, v: RowVec) Mat {
            var mat: Mat = Mat.zero;
            for (0..M) |i| {
                mat.items[i] = m.items[i].multiply(v);
            }
            return mat;
        }

        pub fn broadcastDivide(m: Mat, v: RowVec) Mat {
            var mat: Mat = Mat.zero;
            for (0..M) |i| {
                mat.items[i] = m.items[i].divide(v);
            }
            return mat;
        }

        pub fn broadcastModulo(m: Mat, v: RowVec) Mat {
            var mat: Mat = Mat.zero;
            for (0..M) |i| {
                mat.items[i] = m.items[i].modulo(v);
            }
            return mat;
        }

        pub fn multiplyVector(m: Mat, v: RowVec) ColVec {
            var result: ColVec = .zero;

            for (0..M) |i| {
                result.items[i] = dotProduct(m.row(i), v);
            }

            return result;
        }

        pub fn multiply(a: Mat, b: Mat) Mat {
            var result: Mat = .zero;
            for (0..M) |i| {
                result.setRow(i, .dotProduct(m.row(i), b.col(j)));
            }
            return result;
        }

        pub fn format(
            self: Mat,
            writer: *std.Io.Writer,
        ) std.Io.Writer.Error!void {
            for (0..M) |i| {
                try writer.print("[{f}]", .{self.items[i]});
                if (i + 1 != M) try writer.writeByte('\n');
            }
        }
    };
}

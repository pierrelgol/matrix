const std = @import("std");
const mem = std.mem;
const builtin = @import("builtin");

fn ensureValid(comptime T: type, comptime N: usize) void {
    switch (@typeInfo(T)) {
        .int, .float, .comptime_int, .comptime_float => {},
        else => @compileError("Vector only support familly type Float and Integer"),
    }
    if (N < 2) {
        @compileError("Vector only valid from N >= 2");
    }
}

pub fn Vector(comptime T: type, comptime N: usize) type {
    ensureValid(T, N);
    return struct {
        const Vec = @This();
        const VecType = @Vector(N, T);
        items: VecType,

        pub const zero: Vec = .fromScalar(0);
        pub const identity: Vec = .fromScalar(1);

        pub fn init(items: [N]T) Vec {
            var self: Vec = undefined;
            self.items = items;
            return self;
        }

        pub fn len(_: Vec) usize {
            return N;
        }

        pub fn add(a: Vec, b: Vec) Vec {
            return .{ .items = a.items + b.items };
        }

        pub fn substract(a: Vec, b: Vec) Vec {
            return .{ .items = a.items - b.items };
        }

        pub fn multiply(a: Vec, b: Vec) Vec {
            return .{ .items = a.items * b.items };
        }

        pub fn divide(a: Vec, b: Vec) Vec {
            return .{ .items = a.items / b.items };
        }

        pub fn modulo(a: Vec, b: Vec) Vec {
            return .{ .items = a.items % b.items };
        }

        pub fn fromScalar(item: T) Vec {
            return .{ .items = @splat(item) };
        }

        pub fn negate(a: Vec) Vec {
            return a.multiply(.fromScalar(-1));
        }

        pub fn inverse(a: Vec) Vec {
            return a.divide(.fromScalar(1));
        }

        pub fn abs(a: Vec) Vec {
            return .init(@bitCast(@abs(a.items)));
        }

        pub fn scale(a: Vec, k: T) Vec {
            return a.multiply(.fromScalar(k));
        }

        pub fn sum(a: Vec) T {
            return @reduce(.Add, a.items);
        }

        pub fn squareRoot(a: Vec) Vec {
            return .{ .items = @sqrt(a.items) };
        }

        pub fn dotProduct(a: Vec, b: Vec) T {
            return sum(.multiply(a, b));
        }

        pub fn manhattanNorm(a: Vec) T {
            return sum(abs(a));
        }

        pub fn euclideanNorm(a: Vec) T {
            return @sqrt(sum(.multiply(a, a)));
        }

        pub fn maxNorm(a: Vec) T {
            return @reduce(.Max, abs(a).items);
        }

        pub fn equal(a: Vec, b: Vec) bool {
            return @reduce(.And, a.items == b.items);
        }

        pub fn cos(a: Vec, b: Vec) T {
            comptime {
                switch (@typeInfo(T)) {
                    .float, .comptime_float => {},
                    else => @compileError("cos requires a float vector type"),
                }
            }

            const dot = dotProduct(a, b);
            const norm_a = euclideanNorm(a);
            const norm_b = euclideanNorm(b);
            const denom = norm_a * norm_b;

            if (@abs(denom) < std.math.floatEps(T)) {
                return std.math.nan(T);
            }

            var result = dot / denom;

            if (result > 1) result = 1;
            if (result < -1) result = -1;

            return result;
        }

        pub fn shuffle(a: Vec, b: Vec, comptime mask: @Vector(N, i32)) Vec {
            return .{ .items = @shuffle(T, a.items, b.items, mask) };
        }

        pub fn crossProduct(a: Vec, b: Vec) Vec {
            comptime {
                if (N != 3) @compileError("Invalid length Vec.len() must be == 3");
            }
            const a_yzx = shuffle(a, a, .{ 1, 2, 0 });
            const a_zxy = shuffle(a, a, .{ 2, 0, 1 });
            const b_yzx = shuffle(b, b, .{ 1, 2, 0 });
            const b_zxy = shuffle(b, b, .{ 2, 0, 1 });
            return substract(multiply(a_yzx, b_zxy), multiply(a_zxy, b_yzx));
        }

        pub fn fusedMultiplyAdd(a: Vec, b: Vec, c: Vec) Vec {
            return .init(@mulAdd(VecType, a.items, b.items, c.items));
        }

        pub fn linearInterpolation(a: Vec, b: Vec, t: T) Vec {
            return .fusedMultiplyAdd(b.substract(a), .fromScalar(t), a);
        }

        pub fn linearCombination(vectors: []const Vec, scalars: []const T) Vec {
            std.debug.assert(vectors.len == scalars.len);
            std.debug.assert(vectors.len > 0);

            var result = Vec.zero;

            for (vectors, scalars) |v, a| {
                result = fusedMultiplyAdd(v, .fromScalar(a), result);
            }

            return result;
        }

        pub fn format(
            self: @This(),
            writer: *std.Io.Writer,
        ) std.Io.Writer.Error!void {
            try writer.writeByte('[');
            inline for (0..N) |i| {
                if (i + 1 == N) {
                    try writer.print("{d}", .{self.items[i]});
                } else {
                    try writer.print("{d},", .{self.items[i]});
                }
            }
            try writer.writeByte(']');
        }
    };
}

const testing = std.testing;

test "add" {
    const Vec = Vector(u32, 3);
    const v0: Vec = .init(.{ 1, 2, 3 });
    const v1: Vec = .init(.{ 1, 2, 3 });
    const expected: Vec = .init(.{ 2, 4, 6 });

    try testing.expect(v0.add(v1).equal(expected));
}

test "sub" {
    const Vec = Vector(u32, 3);
    const v0: Vec = .init(.{ 1, 2, 3 });
    const v1: Vec = .init(.{ 1, 2, 3 });
    const expected: Vec = .init(.{ 0, 0, 0 });

    try testing.expect(v0.substract(v1).equal(expected));
}

test "division" {
    const Vec = Vector(f32, 3.0);
    const v0: Vec = .init(.{ 2.0, 4.0, 8.0 });
    const v1: Vec = .fromScalar(2.0);
    const expected: Vec = .init(.{ 1.0, 2.0, 4.0 });

    try testing.expect(v0.divide(v1).equal(expected));
}

test "multiply" {
    const Vec = Vector(f32, 3.0);
    const v0: Vec = .init(.{ 2.0, 4.0, 8.0 });
    const v1: Vec = .fromScalar(2.0);
    const expected: Vec = .init(.{ 4.0, 8.0, 16.0 });

    try testing.expect(v0.multiply(v1).equal(expected));
}

test "fma" {
    const Vec = Vector(f32, 3);
    const a: Vec = .init(.{ 2.0, 3.0, 4.0 });
    const b: Vec = .init(.{ 5.0, 6.0, 7.0 });
    const c: Vec = .init(.{ 1.0, 1.0, 1.0 });

    const result = Vec.fusedMultiplyAdd(a, b, c);
    const expected: Vec = .init(.{ 11.0, 19.0, 29.0 });

    try std.testing.expect(result.equal(expected));
}

test "lerp" {
    const Vec = Vector(f32, 3);
    const a: Vec = .init(.{ 0.0, 0.0, 0.0 });
    const b: Vec = .init(.{ 10.0, 20.0, 30.0 });

    const result = a.linearInterpolation(b, 0.5);
    const expected: Vec = .init(.{ 5.0, 10.0, 15.0 });

    try std.testing.expect(result.equal(expected));
}

test "linear combination" {
    const Vec = Vector(f32, 3);

    const v0: Vec = .init(.{ 1, 0, 0 });
    const v1: Vec = .init(.{ 0, 1, 0 });
    const v2: Vec = .init(.{ 0, 0, 1 });

    const vectors = [_]Vec{ v0, v1, v2 };
    const scalars = [_]f32{ 2, 3, 4 };

    const result = Vec.linearCombination(&vectors, &scalars);
    const expected: Vec = .init(.{ 2, 3, 4 });

    try std.testing.expect(result.equal(expected));
}

test "dot - integers basic" {
    const Vec = Vector(i32, 3);

    const a: Vec = .init(.{ 1, 2, 3 });
    const b: Vec = .init(.{ 4, 5, 6 });

    try std.testing.expect(Vec.dotProduct(a, b) == 32);
}

test "manhattan norm - basic" {
    const Vec = Vector(i32, 3);

    const v: Vec = .init(.{ 1, -2, 3 });

    try std.testing.expect(Vec.manhattanNorm(v) == 6);
}

test "manhattan norm - zero" {
    const Vec = Vector(i32, 4);

    const v: Vec = Vec.zero;

    try std.testing.expect(Vec.manhattanNorm(v) == 0);
}

test "euclidean norm - basic" {
    const Vec = Vector(f32, 3);

    const v: Vec = .init(.{ 3.0, 4.0, 0.0 });

    try std.testing.expectApproxEqAbs(Vec.euclideanNorm(v), 5.0, 1e-6);
}

test "euclidean norm - unit vector" {
    const Vec = Vector(f32, 3);

    const v: Vec = .init(.{ 1.0, 0.0, 0.0 });

    try std.testing.expectApproxEqAbs(Vec.euclideanNorm(v), 1.0, 1e-6);
}

test "euclidean norm - zero" {
    const Vec = Vector(f32, 3);

    const v: Vec = Vec.zero;

    try std.testing.expectApproxEqAbs(Vec.euclideanNorm(v), 0.0, 1e-6);
}

test "max norm - basic" {
    const Vec = Vector(i32, 4);

    const v: Vec = .init(.{ 1, -7, 3, 2 });

    try std.testing.expect(Vec.maxNorm(v) == 7);
}

test "max norm - zero" {
    const Vec = Vector(i32, 3);

    const v: Vec = Vec.zero;

    try std.testing.expect(Vec.maxNorm(v) == 0);
}

test "cos - identical vectors" {
    const Vec = Vector(f32, 3);

    const a: Vec = .init(.{ 1.0, 2.0, 3.0 });

    const result = Vec.cos(a, a);

    // cos(0) = 1
    try std.testing.expectApproxEqAbs(result, 1.0, 1e-6);
}

test "cos - orthogonal vectors" {
    const Vec = Vector(f32, 3);

    const x: Vec = .init(.{ 1.0, 0.0, 0.0 });
    const y: Vec = .init(.{ 0.0, 1.0, 0.0 });

    const result = Vec.cos(x, y);

    // cos(90°) = 0
    try std.testing.expectApproxEqAbs(result, 0.0, 1e-6);
}

test "cos - opposite vectors" {
    const Vec = Vector(f32, 3);

    const a: Vec = .init(.{ 1.0, 2.0, 3.0 });
    const b: Vec = .init(.{ -1.0, -2.0, -3.0 });

    const result = Vec.cos(a, b);

    // cos(180°) = -1
    try std.testing.expectApproxEqAbs(result, -1.0, 1e-6);
}

test "cross - i x j = k" {
    const Vec = Vector(i32, 3);

    const i: Vec = .init(.{ 1, 0, 0 });
    const j: Vec = .init(.{ 0, 1, 0 });
    const k: Vec = .init(.{ 0, 0, 1 });

    try std.testing.expect(Vec.crossProduct(i, j).equal(k));
}

test "cross - j x k = i" {
    const Vec = Vector(i32, 3);

    const i: Vec = .init(.{ 1, 0, 0 });
    const j: Vec = .init(.{ 0, 1, 0 });
    const k: Vec = .init(.{ 0, 0, 1 });

    try std.testing.expect(Vec.crossProduct(j, k).equal(i));
}

test "cross - k x i = j" {
    const Vec = Vector(i32, 3);

    const i: Vec = .init(.{ 1, 0, 0 });
    const j: Vec = .init(.{ 0, 1, 0 });
    const k: Vec = .init(.{ 0, 0, 1 });

    try std.testing.expect(Vec.crossProduct(k, i).equal(j));
}

test "cross - anti commutative" {
    const Vec = Vector(i32, 3);

    const a: Vec = .init(.{ 1, 2, 3 });
    const b: Vec = .init(.{ 4, 5, 6 });

    const ab = Vec.crossProduct(a, b);
    const ba = Vec.crossProduct(b, a);

    try std.testing.expect(ab.equal(ba.negate()));
}

test "cross - known values" {
    const Vec = Vector(i32, 3);

    const a: Vec = .init(.{ 1, 2, 3 });
    const b: Vec = .init(.{ 4, 5, 6 });

    const expected: Vec = .init(.{ -3, 6, -3 });

    try std.testing.expect(Vec.crossProduct(a, b).equal(expected));
}

test "cross - orthogonal to inputs" {
    const Vec = Vector(f32, 3);

    const a: Vec = .init(.{ 1.0, 2.0, 3.0 });
    const b: Vec = .init(.{ 4.0, 5.0, 6.0 });

    const c = Vec.crossProduct(a, b);

    try std.testing.expectApproxEqAbs(Vec.dotProduct(c, a), 0.0, 1e-6);
    try std.testing.expectApproxEqAbs(Vec.dotProduct(c, b), 0.0, 1e-6);
}

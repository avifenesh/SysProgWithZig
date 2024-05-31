const expect = @import("std").testing.expect;
const expectEqual = @import("std").testing.expectEqual;
const std = @import("std");
const eql = std.mem.eql;
// # Comptime #

fn fibonacci(n: u16) u16 {
    if (n == 0 or n == 1) return n;
    return fibonacci(n - 1) + fibonacci(n - 2);
}

test "comptime blocks" {
    const x = comptime fibonacci(10);
    const y = comptime blk: {
        break :blk fibonacci(10);
    };
    try expect(x == 55);
    try expect(y == 55);
}

test "comptime int" {
    const a = 12;
    const b = a + 10;
    const c: u4 = a;
    const d: f32 = b;

    try expect(c == 12);
    try expect(d == 22.0);
    try expectEqual(d, 22);
}

test "branching on types" {
    const a = 5;
    const b: if (a < 10) f32 else i32 = 5;
    try expect(b == 5);
    try expect(@TypeOf(b) == f32);
}

fn Matrix(comptime T: type, comptime width: comptime_int, comptime height: comptime_int) type {
    return [height][width]T;
}

test "comptime type" {
    try expect(Matrix(f32, 4, 4) == [4][4]f32);
    try expect(Matrix(u8, 4, 4) == [4][4]u8);
}

fn addSmallInts(comptime T: type, a: T, b: T) T {
    return switch (@typeInfo(T)) {
        .ComptimeInt => a + b,
        .Int => |info| if (info.bits <= 16)
            a + b
        else
            @compileError("ints too large"),
        else => @compileError("only ints accepted"),
    };
}

test "typeinfo switch" {
    const x = addSmallInts(u16, 20, 30);
    const y = addSmallInts(i16, 20, 30);
    try expect(@TypeOf(y) == i16);
    try expect(y == 50);
    try expect(@TypeOf(x) == u16);
    try expect(x == 50);
}

fn GetBiggerInt(comptime T: type) type {
    return @Type(.{ .Int = .{
        .bits = @typeInfo(T).Int.bits + 1,
        .signedness = @typeInfo(T).Int.signedness,
    } });
}

test "@Type" {
    try expectEqual(GetBiggerInt(u8), u9);
    try expectEqual(GetBiggerInt(i8), i9);
    try expectEqual(GetBiggerInt(u16), u17);
}

fn Vec(comptime count: comptime_int, comptime T: type) type {
    return struct {
        data: [count]T,
        const Self = @This();

        fn abs(self: Self) Self {
            var tmp = Self{ .data = undefined };
            for (self.data, 0..) |elem, i| {
                tmp.data[i] = if (elem < 0) -elem else elem;
            }
            return tmp;
        }

        fn init(data: [count]T) Self {
            return Self{ .data = data };
        }
    };
}

test "generic vector" {
    const x = Vec(3, f32).init([_]f32{ 10, -10, 5 });
    const y = x.abs();
    try expect(eql(f32, &y.data, &[_]f32{ 10, 10, 5 }));
}

fn plusOne(x: anytype) @TypeOf(x) {
    return x + 1;
}

test "inferred function parameter" {
    try expectEqual(plusOne(5), 6);
    const y: u32 = 5;
    try expectEqual(@TypeOf(plusOne(y)), u32);
}

test "++" {
    const x: [4]u8 = undefined;
    const y = x[0..];

    const a: [6]u8 = undefined;
    const b = a[0..];

    const new = y ++ b;
    try expectEqual(@TypeOf(new), *const [10]u8);
    try expectEqual(new.len, 10);
}

test "**" {
    const pattern = [_]u8{ 0xCC, 0xAA };
    const memory = pattern ** 3;
    try expect(eql(u8, &memory, &[_]u8{ 0xCC, 0xAA, 0xCC, 0xAA, 0xCC, 0xAA }));
}

// # Payloads Capture #

test "optional if" {
    const maybe_num: ?usize = 10;
    if (maybe_num) |num| {
        try expect(@TypeOf(num) == usize);
        try expect(num == 10);
    } else {
        unreachable;
    }
}

test "error union if" {
    const ent_num: error{UnknownEntity}!u32 = 5;
    if (ent_num) |num| {
        try expect(@TypeOf(num) == u32);
        try expect(num == 5);
    } else |err| {
        _ = err catch {};
        unreachable;
    }
}

test "while optional" {
    var i: ?u32 = 10;
    while (i) |num| : (i.? -= 1) {
        try expect(@TypeOf(num) == u32);
        if (num == 1) {
            i = null;
            break;
        }
    }
    try expect(i == null);
}

var number_left2: u32 = undefined;

fn eventuallyErrorSequence() !u32 {
    return if (number_left2 == 0) error.ReachedZero else blk: {
        number_left2 -= 1;
        break :blk number_left2;
    };
}

test "while error union capture" {
    var sum: u32 = 0;
    number_left2 = 3;
    while (eventuallyErrorSequence()) |num| {
        sum += num;
    } else |err| {
        try expect(err == error.ReachedZero);
    }
}

test "for capture" {
    const x = [_]i8{ 1, 5, 120, -5 };
    for (x) |v| try expectEqual(@TypeOf(v), i8);
}

const Info = union(enum) {
    a: u32,
    b: []const u8,
    c,
    d: u32,
};

test "switch capture" {
    const b = Info{ .a = 10 };
    const x = switch (b) {
        .b => |str| blk: {
            try expectEqual(@TypeOf(str), []const u8);
            break :blk 1;
        },
        .c => 2,
        .a, .d => |num| blk: {
            try expectEqual(@TypeOf(num), u32);
            break :blk num * 2;
        },
    };
    try expect(x == 20);
}

test "for with pointer capture" {
    var data = [_]u8{
        1,
        2,
        3,
    };
    for (&data) |*byte| byte.* += 1;
    try expect(eql(u8, &data, &[_]u8{ 2, 3, 4 }));
}

// # Inline Loops # -> unadvisable for performance, compiler is smarter than you usually

test "inline for" {
    const types = [_]type{ i8, i16, i32, i64, u8, u16, u32, u64, f32, f64 }; // 1, 2, 4, 8, 1, 2, 4, 8, 4, 8
    var sum: usize = 0;
    inline for (types) |T| sum += @sizeOf(T);
    try expectEqual(sum, 42);
}

test "inline while" {
    comptime var sum = 0;
    comptime var i = 0;
    inline while (i < 10) : (i += 1) sum += i;
    try expectEqual(sum, 45);
}

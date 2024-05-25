const expect = @import("std").testing.expect;
const expectEqual = @import("std").testing.expectEqual;
const expectError = @import("std").testing.expectError;
const std = @import("std");
const math = std.math;

// # Slices #

fn total(values: []const u8) usize {
    var sum: usize = 0;
    for (values) |v| sum += v;
    return sum;
}

test "slices" {
    const array = [_]u8{ 1, 2, 3, 4, 5 };
    const slice = array[1..4];
    try expect(total(slice) == 9);
}

test "slice type" {
    const array = [_]u8{ 1, 2, 3, 4, 5 };
    const slice = array[0..3];
    try expectEqual(@TypeOf(slice), *const [3]u8);
}

test "slicing till end or till length" {
    var array = [_]u8{ 1, 2, 3, 4, 5 };
    const slice1 = array[2..array.len];
    const slice2 = array[2..];
    try expect(slice1.len == slice2.len);
}

// # Enums #

const Direction = enum { north, south, west, east };

const EnumWithValue = enum(u2) {
    zero,
    one,
    two,
    pub fn returnEnumValue(self: EnumWithValue) u2 {
        return @intFromEnum(self);
    }
};

test "get value of enum" {
    try expectEqual(EnumWithValue.one.returnEnumValue(), 1);
    try expectEqual(EnumWithValue.returnEnumValue(.two), 2);
}

const Mode = enum {
    var count: u32 = 0;
    on,
    off,
    pub fn increase_count_and_return() u32 {
        Mode.count += 1;
        return count;
    }
};

test "globally count" {
    Mode.count += 1;
    try expect(Mode.count == 1);
    try expect(@intFromEnum(Mode.on) == 0);
    try expectEqual(Mode.increase_count_and_return(), 2);
}

// # Structs #

const FamilyAges = struct {
    me: u16 = 29,
    she: u16 = 30,
    him: u16,
    pub fn returnHisAge(self: FamilyAges) u16 {
        return self.him;
    }
};

test "some games with structs" {
    var myAges = FamilyAges{ .him = 47 };
    try expect(myAges.returnHisAge() == 47);
    myAges.me = 30;
    try expect(myAges.me == myAges.she);
}

// # Unions #

const Result = union { int: i64, float: f64, bool: bool };

test "Switch to get result type" {
    const value: i64 = 65;
    const tets_val = switch (@TypeOf(value)) {
        i64 => Result{ .int = value },
        f64 => Result{ .float = value },
        bool => Result{ .bool = value },
        else => unreachable,
    };
    try expect(tets_val.int == 65);
    try expectEqual(tets_val.int, value);
}

const Direct = union(Direction) { north: u8, south: i64, west: f32, east: bool };

test "switch on tagged union" {
    var value = Direct{ .north = 2 };
    switch (value) {
        .east => |*b| b.* = !b.*,
        .north => |*u| u.* += 1,
        .west => |*f| f.* *= 3.5,
        .south => |*i| i.* *= -1,
    }
    try expect(value.north == 3);
}

const AnotherDirect = union(enum) { north: u8, south: i64, west: f32, east: bool, none };

// # Integer Rules #

const decimal_integer: i32 = 12;
const octal_integer: i32 = 0o14;
const hex_integer: i32 = 0xC;
const binary_integer: i32 = 0b1100;

test "integer rules" {
    try expectEqual(decimal_integer, octal_integer);
    try expectEqual(hex_integer, binary_integer);
    try expect(decimal_integer == hex_integer and hex_integer == octal_integer and octal_integer == binary_integer);
}

// Under score in integer literals

const underscored_integer: i32 = 1_000_000;
const underscored_float: f32 = 1_000_000.0;
const binary_mask: i32 = 0b1111_0100_0010_0100_0000;

test "underscore in integer literals" {
    try expectEqual(underscored_integer, 1000000);
    try expectEqual(underscored_float, 1000000.0);
    try expectEqual(binary_mask, 0b1111_0100_0010_0100_0000);
    try expectEqual(underscored_integer, binary_mask);
    try expectEqual(underscored_float, binary_mask);
    try expectEqual(underscored_integer, underscored_float);
}

// Integer widening

const IntsError = error{OverFlow};

fn addOne(variable: i8) IntsError!void {
    if (variable == math.maxInt(i8)) return IntsError.OverFlow;
    var new_var: i8 = variable;
    new_var += 1;
}

test "integer widening" {
    const i8_val: i8 = 127;
    const i16_val: i16 = i8_val;
    const i32_val: i32 = i16_val;
    const i64_val: i64 = i32_val;
    try expectEqual(i8_val, i16_val);
    try expectEqual(i16_val, i32_val);
    try expectEqual(i32_val, i64_val);
    try expectEqual(addOne(i8_val), IntsError.OverFlow);
}

test "@intCast" {
    const x: u64 = 200;
    const y = @as(u8, @intCast(x));
    try expectEqual(@TypeOf(y), u8);
}

// Overflow operators

test "well defined overflow" {
    var a: u8 = 255;
    a +%= 1;
    try expectEqual(a, 0);
}

// # Floats #
// its basically same as integers

// # Labeled Blocks #

test "labeled block" {
    const count = blk: {
        var sum: u32 = 0;
        var i: u32 = 0;
        while (i < 10) : (i += 1) sum += i;
        break :blk sum;
    };
    try expectEqual(count, 45);
    try expect(@TypeOf(count) == u32);
}

// # Labelled Loops #

test "labeled loop" {
    var count: usize = 0;
    outer: for ([_]i32{
        1,
        2,
        3,
        4,
        5,
        6,
        7,
        8,
    }) |_| {
        for ([_]i32{
            1,
            2,
            3,
            4,
            5,
        }) |_| {
            count += 1;
            continue :outer;
        }
    }
    try expectEqual(count, 8);
}

// # Loops as Expressions #

fn rangeHasNumber(begin: usize, end: usize, number: usize) bool {
    var i = begin;
    return while (i < end) : (i += 1) {
        if (i == number) break true;
    } else false;
}

test "while loop expression" {
    try expect(rangeHasNumber(0, 10, 5));
}

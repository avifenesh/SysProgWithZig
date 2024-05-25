const expect = @import("std").testing.expect;
const expectEqual = @import("std").testing.expectEqual;
const std = @import("std");

// Slices

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

// Enums

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

// Structs

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

// Unions

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

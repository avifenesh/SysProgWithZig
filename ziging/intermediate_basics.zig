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

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

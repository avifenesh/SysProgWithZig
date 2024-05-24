const std = @import("std");
const expect = std.testing.expect;
const expectEqual = std.testing.expectEqual;

test "test" {
    try expect(3 > 2);
}

test "test2" {
    try expect(1 + 1 == 2);
}

test "test3" {
    try expectEqual(1 + 1, 3);
}

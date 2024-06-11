const std = @import("std");
const count_words = @import("count_words.zig");
const utils = @import("utils.zig");
const expect = std.testing.expect;
const eql = std.mem.eql;

test "parse_args" {
    var args = [_][]const u8{ "-cw", "file.txt" };
    const expected = "file.txt";
    const result = try utils.parseArgs(&args);
    try expect(eql(u8, expected, result));
}

test "count_words" {
    const path = "plain.txt";
    const expected = 26;
    const result = count_words.countWords(path);
    try expect(result == expected);
}

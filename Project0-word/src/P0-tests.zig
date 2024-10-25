const std = @import("std");
const count_words = @import("count_words.zig");
const utils = @import("utils.zig");
const expect = std.testing.expect;
const eql = std.mem.eql;
const log = std.log;
const dir = std.fs.cwd();

test "parse_args" {
    var args = [_][]const u8{ "-cw", "test_file.txt" };
    const expected = "test_file.txt";
    const result = try utils.parseArgs(&args);
    try expect(eql(u8, expected, result));
}

test "count_words" {
    const path = "test_plain.txt";
    const expected = 423;
    const result = try count_words.countWords(path);
    try expect(result == expected);
}

const std = @import("std");
const print = std.debug.print;
const split = std.mem.splitScalar;
const utils = @import("utils.zig");

pub fn countWords(file_path: []const u8) u64 {
    const file = std.fs.cwd().openFile(file_path, .{ .mode = .read_only }) catch |err| {
        print("Error opening file: {}\n", .{err});
        return 0;
    };
    defer file.close();
    var buffer: [1024]u8 = undefined;
    var words_count: u64 = 0;
    const reader = file.reader();
    while (true) {
        var line: []const u8 = undefined;
        const line_options = utils.nextLine(reader, &buffer) catch |err| {
            print("Error reading line: {}\n", .{err});
            break;
        };
        if (line_options) |value| {
            line = value;
        } else {
            break;
        }
        var words = split(u8, line, ' ');
        while (words.next() != null) words_count += 1;
    }
    print("Words count: {}\n", .{words_count});
    return words_count;
}

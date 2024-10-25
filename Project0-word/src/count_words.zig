const std = @import("std");
const print = std.debug.print;
const split = std.mem.splitScalar;
const utils = @import("utils.zig");
const log = std.log;
const continueToNextLine = utils.continueToNextLine;

pub fn countWords(file_path: []const u8) !u64 {
    const file = std.fs.cwd().openFile(file_path, .{ .mode = .read_only }) catch |err| {
        print("Error opening file: {}\n", .{err});
        return 0;
    };
    defer file.close();
    var buffer: [1024]u8 = undefined;
    var words_count: u64 = 0;
    const reader = file.reader();

    var line_options = try utils.nextLine(reader, &buffer);
    while (line_options != null) {
        if (continueToNextLine(line_options.?)) {
            line_options = try utils.nextLine(reader, &buffer) orelse return words_count;
            continue;
        }
        var words = split(u8, line_options.?, ' ');
        while (words.next() != null) words_count += 1;
        line_options = try utils.nextLine(reader, &buffer);
    }
    return words_count;
}

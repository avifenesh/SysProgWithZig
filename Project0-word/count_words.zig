const std = @import("std");
const heap = std.heap;
const os_tag = @import("builtin").os.tag;
const Reader = std.fs.File.Reader;
const print = std.debug.print;
const split = std.mem.splitScalar;

pub fn main(file_path: []const u8) void {
    const file = std.fs.cwd().openFile(file_path, .{ .mode = .read_only }) catch |err| {
        print("Error opening file: {}\n", .{err});
        return;
    };
    defer file.close();
    var buffer: [1024]u8 = undefined;
    var words_count: u64 = 0;
    const reader = file.reader();
    while (true) {
        var line: []const u8 = undefined;
        const line_options = nextLine(reader, &buffer) catch |err| {
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
}

fn nextLine(reader: Reader, buffer: []u8) !?[]const u8 {
    const line = reader.readUntilDelimiterOrEof(buffer, '\n') catch |err| {
        print("Err: {}\n", .{err});
        return err;
    };
    if (os_tag == .windows) {
        return std.mem.trimRight(u8, line, '\r');
    } else {
        return line;
    }
}

const std = @import("std");
const heap = std.heap;
const count_words = @import("count_words.zig").main;
const eql = std.mem.eql;
const os_tag = @import("builtin").os.tag;

pub fn main() !void {
    const stdout = std.io.getStdOut();
    var general_purpose_allocator = heap.GeneralPurposeAllocator(.{}){};
    const gpa = general_purpose_allocator.allocator();
    const args = try std.process.argsAlloc(gpa);
    defer std.process.argsFree(gpa, args);

    if (args.len <= 0) {
        const stdin = std.io.getStdIn();
        defer stdin.close();
        try stdout.writeAll(
            \\ 
            \\ please provide one of available command: -cw <file> or --help
            \\
        );
        const line = nextLine(stdin.reader(), &gpa) catch |err| {
            std.debug.print("Error reading from stdin: {}\n", .{err});
            return;
        };
        var args_iter = std.mem.split(u8, line, " ");
        const stdin_args = try gpa.alloc([]u8, args_iter.rest().len);
        while (args_iter.next()) |arg| {
            const converted_arg: []u8 = try gpa.alloc(u8, arg.len);
            std.mem.copyForwards(u8, converted_arg, arg);
            stdin_args[args_iter.index.?] = converted_arg;
        }
        defer gpa.free(stdin_args);
        const path = parseArgs(stdin_args) catch |err| {
            std.debug.print("{}\n", .{err});
            std.process.exit(1);
        };
        count_words(path);
    }

    const path = parseArgs(args) catch |err| {
        std.debug.print("{}\n", .{err});
        return;
    };
    count_words(path);
}

fn parseArgs(args: [][]u8) error{ InvalidCommand, ErrorWritingToStdout, Retry }![]const u8 {
    const stdout = std.io.getStdOut();
    defer stdout.close();
    if (eql(u8, args[1], "--cw")) {
        return args[2];
    } else if (eql(u8, args[1], "--help")) {
        stdout.writeAll(
            \\ 
            \\ --cw <file> count words in a file
            \\ --help print this help
            \\
        ) catch |err| {
            std.debug.print("Error writing to stdout: {any}\n", .{err});
            return error.ErrorWritingToStdout;
        };
        return error.Retry;
    } else {
        std.debug.print("Unknown command: {any}\n", .{args[0]});
        return error.InvalidCommand;
    }
}

fn nextLine(reader: anytype, allocator: *const std.mem.Allocator) error{
    OutOfMemory,
}![]u8 {
    var read_line = false;
    var buffer_size: usize = 256;
    while (!read_line) {
        const buffer = allocator.alloc(u8, buffer_size) catch |err| {
            return err;
        };
        defer allocator.free(buffer);
        const line = reader.readUntilDelimiterOrEof(buffer, '\n');
        if (@TypeOf(line) == []u8) {
            read_line = true;
            if (os_tag == .windows) {
                return std.mem.trimRight(u8, line, '\r');
            } else {
                return line;
            }
        } else {
            if (buffer_size > 1024) {
                return error.OutOfMemory;
            }
            buffer_size *= 2;
        }
    }
    return error.OutOfMemory;
}

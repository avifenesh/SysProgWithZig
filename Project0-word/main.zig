const std = @import("std");
const heap = std.heap;
const count_words = @import("count_words.zig");
const utils = @import("utils.zig");
const print = std.debug.print;

pub fn main() !void {
    const stdout = std.io.getStdOut();
    var general_purpose_allocator = heap.GeneralPurposeAllocator(.{}){};
    const gpa = general_purpose_allocator.allocator();
    const args = try std.process.argsAlloc(gpa);
    defer std.process.argsFree(gpa, args);

    var buffer: [1024]u8 = undefined;

    if (args.len > 1) {
        const args_without_prog_name = args[1..];
        const path = utils.parseArgs(args_without_prog_name) catch |err| {
            const exit_message = printErrMessageAndExit(err);
            std.process.exit(exit_message);
        };
        count_words.countWords(path);
    } else {
        const stdin = std.io.getStdIn();
        defer stdin.close();
        try stdout.writeAll(
            \\ 
            \\ Please provide one of available command: -cw <file> or --help
            \\
        );
        const is_line = utils.nextLine(stdin.reader(), &buffer) catch |err| {
            print("Error reading from stdin: {}\n", .{err});
            return;
        };
        var line: []const u8 = undefined;
        if (is_line) |value| {
            line = value;
        } else {
            try stdout.writeAll(
                \\ 
                \\ No arguments provided. 
                \\
            );
            return;
        }

        var args_iter = std.mem.splitAny(u8, line, " ");
        const stdin_args = try gpa.alloc([]const u8, args_iter.rest().len);
        defer gpa.free(stdin_args);
        var i: u8 = 0;
        while (args_iter.next()) |arg| {
            stdin_args[i] = arg;
            i += 1;
        }
        const path = utils.parseArgs(stdin_args) catch |err| {
            const exit_message = printErrMessageAndExit(err);
            std.process.exit(exit_message);
        };
        count_words.countWords(path);
    }
}

fn printErrMessageAndExit(err: error{ InvalidCommand, ErrorWritingToStdout, Retry, OutOfMemory }) u8 {
    switch (err) {
        error.InvalidCommand => {
            print("Invalid command. Optional args are:\nFor counting words in a file: -cw <file> \nFor help: --help \n", .{});
            return 1;
        },
        error.Retry => {
            print("Please try again\n", .{});
            return 0;
        },
        error.ErrorWritingToStdout => {
            print("Error writing to stdout: {}\n", .{err});
            return 1;
        },
        error.OutOfMemory => {
            print("Out of memory: {}\n", .{err});
            return 1;
        },
    }
    return;
}

const std = @import("std");
const Reader = std.fs.File.Reader;
const print = std.debug.print;
const os_tag = @import("builtin").os.tag;
const eql = std.mem.eql;

pub fn nextLine(reader: Reader, buffer: []u8) !?[]const u8 {
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

pub fn parseArgs(args: [][]const u8) error{ InvalidCommand, ErrorWritingToStdout, Retry }![]const u8 {
    const stdout = std.io.getStdOut();
    defer stdout.close();
    if (eql(u8, args[0], "-cw")) {
        return args[1];
    } else if (eql(u8, args[0], "--help")) {
        stdout.writeAll("Optional args are:\nFor counting words in a file: -cw <file> \nFor help: --help \n") catch |err| {
            std.debug.print("Error writing to stdout: {any}\n", .{err});
            return error.ErrorWritingToStdout;
        };
        return error.Retry;
    } else {
        std.debug.print("Unknown command: {any}\n", .{args[0]});
        return error.InvalidCommand;
    }
}

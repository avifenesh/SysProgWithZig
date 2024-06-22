const std = @import("std");
const Reader = std.fs.File.Reader;
const print = std.debug.print;
const os_tag = @import("builtin").os.tag;
const eql = std.mem.eql;
const File = std.fs.File;
const CreateFlags = File.CreateFlags;
const isAlphabetic = std.ascii.isAlphabetic;
const isWhitespace = std.ascii.isWhitespace;
const expect = @import("std").testing.expect;
const test_allocator = std.testing.allocator;

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

// TODO: Add different path encoding for different OS
// TODO: Break this function into smaller functions
pub fn cleanFile(path: []u8, buffer: []u8) ![]u8 {
    var general_purpose_allocator = std.heap.GeneralPurposeAllocator(.{}){};
    const gpa = general_purpose_allocator.allocator();
    var slices = [_][]const u8{ path, ".cleaned" };
    var file_read: File = try std.fs.cwd().openFile(path, .{});
    defer file_read.close();
    const file_reader = file_read.reader();
    const new_file_sub_path = std.mem.concat(gpa, u8, &slices) catch unreachable;
    var new_file: File = try std.fs.cwd().createFile(new_file_sub_path, CreateFlags{ .truncate = true });
    defer new_file.close();
    const writer = new_file.writer();
    while (try file_reader.readUntilDelimiterOrEof(buffer, '\n')) |line| {
        if (line.len == 0) {
            continue;
        }
        if (eql(u8, line, " ")) {
            continue;
        }
        if (eql(u8, line, "\n")) {
            continue;
        }
        if (eql(u8, line, "\r")) {
            continue;
        }
        if (eql(u8, line, "\t")) {
            continue;
        }
        if (line[0] == '#') {
            continue;
        }
        if (line.len > 0) {
            var word: [1024]u8 = undefined;
            var i: usize = 0;
            var c: usize = 0;
            while (i < line.len) {
                const char = line[i];
                if (isAlphabetic(char)) {
                    word[c] = char;
                    c += 1;
                } else if (isWhitespace(char)) {
                    if (c > 0) {
                        const string = std.ascii.lowerString(word[0..c], word[0..c]);
                        writer.writeAll(string) catch |err| {
                            return err;
                        };
                        writer.writeAll("\n") catch |err| {
                            return err;
                        };
                        c = 0;
                    }
                }
                i += 1;
            }
        }
    }

    return new_file_sub_path;
}

test "clean file" {
    var file_path = "test_file.txt".*;
    var file: File = try std.fs.cwd().createFile(&file_path, CreateFlags{ .truncate = true, .read = true });
    defer file.close();
    var writer = file.writer();
    writer.writeAll("Hello, this is a test file\n") catch |err| {
        std.debug.print("Error writing to file: {any}\n", .{err});
        return err;
    };
    writer.writeAll("This is a test file\n") catch |err| {
        std.debug.print("Error writing to file: {any}\n", .{err});
        return err;
    };
    writer.writeAll("This is a test file\n") catch |err| {
        std.debug.print("Error writing to file: {any}\n", .{err});
        return err;
    };
    writer.writeAll("This is a test file\n") catch |err| {
        std.debug.print("Error writing to file: {any}\n", .{err});
        return err;
    };
    var buffer: [1024]u8 = undefined;
    const cleaned_file: []const u8 = try cleanFile(&file_path, &buffer);
    const cleaned_file_read = try std.fs.cwd().openFile(cleaned_file, .{});
    defer cleaned_file_read.close();
    const cleaned_file_reader = cleaned_file_read.reader();
    var cleaned_buffer: [1024]u8 = undefined;

    const expected: [6][:0]u8 = .{ @constCast("hello"), @constCast("this"), @constCast("is"), @constCast("a"), @constCast("test"), @constCast("file") };
    std.debug.print("expected: {s}\n", .{expected[0..expected.len]});
    var foundExpected = false;
    while (try nextLine(cleaned_file_reader, &cleaned_buffer)) |line| {
        std.debug.print("line: {s}\n", .{line});
        inner: for (&expected) |expectedValue| {
            std.debug.print("{s}\n", .{expectedValue});
            if (eql(u8, line, expectedValue)) {
                std.debug.print("found expected: {s}\n", .{expectedValue});
                foundExpected = true;
                break :inner;
            }
        }
        try expect(foundExpected);
        foundExpected = false;
    }
}

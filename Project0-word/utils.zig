const std = @import("std");
const Reader = std.fs.File.Reader;
const print = std.debug.print;
const os_tag = @import("builtin").os.tag;
const File = std.fs.File;
const CreateFlags = File.CreateFlags;
const isAlphabetic = std.ascii.isAlphabetic;
const isWhitespace = std.ascii.isWhitespace;
const expect = @import("std").testing.expect;
const test_allocator = std.testing.allocator;
const unicode = std.unicode;
const cwd = std.fs.cwd;
const mem = std.mem;
const eql = mem.eql;
const GPA = std.heap.GeneralPurposeAllocator;
const Allocator = std.mem.Allocator;

pub fn nextLine(reader: anytype, buffer: []u8) !?[]const u8 {
    const line = (try reader.readUntilDelimiterOrEof(buffer, '\n')) orelse return null;
    if (os_tag == .windows) {
        return mem.trimRight(u8, line, "\r");
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
            print("Error writing to stdout: {any}\n", .{err});
            return error.ErrorWritingToStdout;
        };
        return error.Retry;
    } else {
        print("Unknown command: {any}\n", .{args[0]});
        return error.InvalidCommand;
    }
}

pub fn cleanFile(path: []u8, buffer: []u8) ![]u8 {
    var general_purpose_allocator = GPA(.{}){};
    const gpa = general_purpose_allocator.allocator();
    var encoded_path_buffer = gpa.alloc(u8, path.len) catch unreachable;
    const encoded_file_sub_path = try encodePathForOs(path, encoded_path_buffer);
    defer gpa.free(encoded_path_buffer);
    var file_read: File = try cwd().openFile(encoded_file_sub_path, .{});
    defer file_read.close();
    const file_reader = file_read.reader();

    const new_file_sub_path = mem.concat(gpa, u8, &.{ path, ".cleaned" }) catch unreachable;
    gpa.free(encoded_path_buffer);
    encoded_path_buffer = gpa.alloc(u8, new_file_sub_path.len) catch unreachable;
    const encoded_new_file_sub_path = try encodePathForOs(new_file_sub_path, encoded_path_buffer);
    var new_file: File = try cwd().createFile(encoded_new_file_sub_path, CreateFlags{ .truncate = true });
    defer new_file.close();
    const writer = new_file.writer();

    while (try file_reader.readUntilDelimiterOrEof(buffer, '\n')) |line| {
        if (continueToNextLine(line)) {
            continue;
        }
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
    return new_file_sub_path;
}

fn encodePathForOs(path: []u8, encoded_path_buffer: []u8) ![]u8 {
    if (os_tag == .windows) {
        var i: usize = 0;
        while (i < path.len) : (i += 1) {
            const codepoint = try unicode.utf8Decode(path[i .. i + 1]);
            _ = try unicode.wtf8Encode(codepoint, encoded_path_buffer[i..]);
        }
        return encoded_path_buffer;
    } else {
        return path;
    }
}

fn continueToNextLine(line: []u8) bool {
    if (line.len == 0) {
        return true;
    }
    if (eql(u8, line, " ")) {
        return true;
    }
    if (eql(u8, line, "\n")) {
        return true;
    }
    if (eql(u8, line, "\r")) {
        return true;
    }
    if (eql(u8, line, "\t")) {
        return true;
    }
    if (line[0] == '#') {
        return true;
    }
    if (line.len == 0) {
        return true;
    }
    return false;
}

test "clean file" {
    var file_path = "test_file.txt".*;
    var file: File = try std.fs.cwd().createFile(&file_path, CreateFlags{ .truncate = true, .read = true });
    defer file.close();
    var writer = file.writer();
    writer.writeAll("Hello, this is a test file\n") catch |err| {
        print("Error writing to file: {any}\n", .{err});
        return err;
    };
    writer.writeAll("This is a test file\n") catch |err| {
        print("Error writing to file: {any}\n", .{err});
        return err;
    };
    writer.writeAll("This is a test file\n") catch |err| {
        print("Error writing to file: {any}\n", .{err});
        return err;
    };
    writer.writeAll("This is a test file\n") catch |err| {
        print("Error writing to file: {any}\n", .{err});
        return err;
    };
    var buffer: [1024]u8 = undefined;
    const cleaned_file: []const u8 = cleanFile(&file_path, &buffer) catch |err| {
        print("Error cleaning file: {any}\n", .{err});
        return err;
    };
    const cleaned_file_read = try cwd().openFile(cleaned_file, .{});
    defer cleaned_file_read.close();
    const cleaned_file_reader = cleaned_file_read.reader();
    var cleaned_buffer: [1024]u8 = undefined;

    const expected: [6][:0]u8 = .{ @constCast("hello"), @constCast("this"), @constCast("is"), @constCast("a"), @constCast("test"), @constCast("file") };
    print("expected: {s}\n", .{expected[0..expected.len]});
    var foundExpected = false;
    while (try nextLine(cleaned_file_reader, &cleaned_buffer)) |line| {
        print("line: {s}\n", .{line});
        inner: for (&expected) |expectedValue| {
            print("{s}\n", .{expectedValue});
            if (eql(u8, line, expectedValue)) {
                print("found expected: {s}\n", .{expectedValue});
                foundExpected = true;
                break :inner;
            }
        }
        try expect(foundExpected);
        foundExpected = false;
    }
}

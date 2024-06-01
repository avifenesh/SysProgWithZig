const std = @import("std");
const heap = std.heap;
const expect = std.testing.expect;
const expectEqual = std.testing.expectEqual;
const eql = std.mem.eql;
const ArrayList = std.ArrayList;
const test_allocator = std.testing.allocator;
const fs = std.fs;
const os_tag = @import("builtin").os.tag;

// # Allocators #

test "allocation" {
    const allocator = heap.page_allocator; // create a new heap allocator, using the page allocator which allocates memory in pages

    const memory = try allocator.alloc(u8, 100); // allocate 100 bytes of memory (u8 is a byte)
    defer allocator.free(memory); // best-practice: free the memory when we're out of the scope

    try expect(@TypeOf(memory) == []u8); // memory is a slice of u8
    try expectEqual(memory.len, 100); // memory has 100 elements
}

test "fixed buffer allocation" {
    var buffer: [1000]u8 = undefined; // create a fixed buffer of 1000 bytes
    var fba = heap.FixedBufferAllocator.init(&buffer); // create a new heap allocator, using the fixed buffer allocator which allocates memory from a fixed buffer
    const allocator = fba.allocator(); // get the allocator from the fixed buffer allocator

    const memory = try allocator.alloc(u8, 100); // allocate 100 bytes of memory
    defer allocator.free(memory); // best-practice: free the memory when we're out of the scope

    try expect(@TypeOf(memory) == []u8); // memory is a slice of u8
    try expectEqual(memory.len, 100); // memory has 100 elements

    try expect(buffer.len - fba.end_index == 900); // Ensure 900 bytes remaining in the fixed buffer

    // Try to allocate more than the fixed buffer size
    _ = allocator.alloc(u8, 1000) catch |err| {
        try expectEqual(err, error.OutOfMemory);
    };
}

test "arena allocator" {
    var arena = heap.ArenaAllocator.init(heap.page_allocator); // create a new heap allocator, using the arena allocator which allow you to allocate many times and free all at once
    defer arena.deinit(); // best-practice: deinit the arena when we're out of the scope
    const allocator = arena.allocator();

    _ = try allocator.alloc(u8, 1);
    _ = try allocator.alloc(u8, 10);
    _ = try allocator.alloc(u8, 100);
}

test "allocator create/destroy" {
    const byte = heap.page_allocator.create(u8) catch |err| {
        std.debug.print("Failed to allocate memory: {}\n", .{err});
        return;
    };
    defer heap.page_allocator.destroy(byte);

    byte.* = 128;
    try expectEqual(byte.*, 128);
}

test "GPA" {
    var gpa = heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();
    defer {
        const deinit_status = gpa.deinit();
        // fail test; can't in defer as defer is executed after we return
        if (deinit_status == .leak) expect(false) catch @panic("TEST FAIL");
    }
    const bytes = try allocator.alloc(u8, 100);
    defer allocator.free(bytes);
}

// # ArrayList #

test "arrayList" {
    var list = ArrayList(u8).init(test_allocator);
    defer list.deinit();

    try list.append('H');
    try list.append('e');
    try list.append('l');
    try list.append('l');
    try list.append('o');
    try list.appendSlice(" World!");

    try expect(eql(u8, list.items, "Hello World!"));
}

// # Filesystem #

test "createFile, write, seeTo, read" {
    const file_name = "junk-file.txt";
    const file = try fs.cwd().createFile(file_name, .{ .read = true });
    defer {
        file.close();
        fs.cwd().deleteFile(file_name) catch unreachable;
    }
    const bytes_written = try file.write("Hello, World!");
    try expectEqual(bytes_written, 13);

    var buffer: [100]u8 = undefined;
    try file.seekTo(0);
    const bytes_read = try file.readAll(&buffer);

    try expect(eql(u8, buffer[0..bytes_read], "Hello, World!"));
}

test "file stat" {
    const file_name = "junk-file.txt";
    const file = try fs.cwd().createFile(file_name, .{ .read = true });
    defer {
        file.close();
        fs.cwd().deleteFile(file_name) catch unreachable;
    }
    const stat = try file.stat();
    try expectEqual(stat.size, 0);
    try expectEqual(stat.kind, .file);
    try expect(stat.ctime <= std.time.nanoTimestamp());
}

test "make directory" {
    const dir_name = "junk-dir";
    try fs.cwd().makeDir(dir_name);
    var iter_dir = try fs.cwd().openDir(dir_name, .{ .iterate = true });
    defer {
        iter_dir.close();
        fs.cwd().deleteTree(dir_name) catch unreachable;
    }
    _ = try iter_dir.createFile("x", .{});
    _ = try iter_dir.createFile("y", .{});
    _ = try iter_dir.createFile("z", .{});

    var files_count: usize = 0;
    var iter = iter_dir.iterate();
    while (try iter.next()) |entry| {
        if (entry.kind == .file) files_count += 1;
    }
    try expectEqual(files_count, 3);
}

// # Readers and Writers #

test "io reader" {
    var list = ArrayList(u8).init(test_allocator);
    defer list.deinit();
    const bytes_written = try list.writer().write("Hello, World!");
    try expectEqual(bytes_written, 13);
    try expect(eql(u8, list.items, "Hello, World!"));
}

test "io reader usage" {
    const message = "Hello File!";
    const file_name = "junk-file.txt";
    const file = try fs.cwd().createFile(file_name, .{ .read = true });
    defer {
        file.close();
        fs.cwd().deleteFile(file_name) catch unreachable;
    }
    try file.writeAll(message);
    try file.seekTo(0);

    const content = try file.reader().readAllAlloc(test_allocator, message.len);
    defer test_allocator.free(content);

    try expect(eql(u8, content, message));
}

fn nextLine(reader: anytype, buffer: []u8) !?[]const u8 {
    const line = (try reader.readUntilDelimiterOrEof(buffer, '\n')) orelse return null;
    if (os_tag == .windows) {
        return std.mem.trimRight(u8, line, '\r');
    } else {
        return line;
    }
}

test "read until next line" {
    const stdout = std.io.getStdOut();
    defer stdout.close();
    const stdin = std.io.getStdIn();
    defer stdin.close();

    try stdout.writeAll(
        \\ 
        \\ Enter your name: 
    );

    var buffer: [100]u8 = undefined;
    const input = (try nextLine(stdin.reader(), &buffer)).?;
    try stdout.writer().print("Your name is: \"{s}\"\n", .{input});
}

const MyByteList = struct {
    data: [100]u8 = undefined,
    items: []u8 = &[_]u8{},

    const Writer = std.io.Writer(
        *MyByteList,
        error{EndOfBuffer},
        appendWrite,
    );

    fn appendWrite(self: *MyByteList, data: []const u8) error{EndOfBuffer}!usize {
        if (self.items.len + data.len > self.data.len) {
            return error.EndOfBuffer;
        }
        @memcpy(self.data[self.items.len..][0..data.len], data);
        self.items = self.data[0 .. self.items.len + data.len];
        return data.len;
    }

    fn writer(self: *MyByteList) Writer {
        return .{ .context = self };
    }
};

test "custom writer" {
    var bytes = MyByteList{};
    _ = try bytes.writer().write("Hello");
    _ = try bytes.writer().write(" Writer!");
    try expect(eql(u8, bytes.items, "Hello Writer!"));
}

const std = @import("std");
const heap = std.heap;
const expect = std.testing.expect;
const expectEqual = std.testing.expectEqual;
const eql = std.mem.eql;
const ArrayList = std.ArrayList;
const test_allocator = std.testing.allocator;

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

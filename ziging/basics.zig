const expect = @import("std").testing.expect;
const expectEqual = @import("std").testing.expectEqual;
const std = @import("std");

// assignments
const constant: i32 = 24;
var mutable: i32 = 24;

const constant3 = @as(i32, 24);
var mutable3 = @as(i32, 24);

const IDK: i16 = undefined;
var idk: i16 = undefined;

// Arrays
const arr = [5]u8{ 'a', 'b', 'c', 'd', 'e' };
var arr2 = [_]u8{ 'a', 'b', 'c', 'd', 'e' };

const length = arr.length;

// If statements
test "if statements" {
    const a = true;
    var x: u16 = 0;
    if (a) {
        x += 1;
    } else {
        x += 2;
    }
    try expect(x == 1);
}

test "if statement expression" {
    const a = true;
    var x: u16 = 0;
    x += if (a) 1 else 2;
    try expect(x == 1);
}

// While loops
test "while loops" {
    var x: u16 = 0;
    while (x < 10) {
        x += 1;
    }
    try expect(x == 10);
}

test "while with continue expression" {
    var sum: u8 = 0;
    var i: u8 = 1;
    while (i <= 10) : (i += 1) {
        sum += i;
    }
    try expect(sum == 55);
}

test "while with continue" {
    var sum: u8 = 0;
    var i: u8 = 0;
    while (i <= 3) : (i += 1) {
        if (i == 2) continue;
        sum += i;
    }
    try expect(sum == 4);
}

test "while with break" {
    var sum: u8 = 0;
    var i: u8 = 0;
    while (i <= 3) : (i += 1) {
        if (i == 2) break;
        sum += i;
    }
    try expect(sum == 1);
}

// For loops
test "for" {
    const string = [_]u8{ 'a', 'b', 'c', 'd', 'e' };
    for (string, 0..) |character, index| {
        _ = character;
        _ = index;
    }
    for (string) |character| {
        _ = character;
    }
    for (string, 0..) |_, index| {
        _ = index;
    }
    for (string) |_| {}
}

// Functions
fn addFive(x: u32) u32 {
    return x + 5;
}
test "functions" {
    const y = addFive(5);
    try expect(@TypeOf(y) == u32);
    try expect(y == 10);
}

fn fibonacci(n: u16) u16 {
    if (n == 0 or n == 1) return n;
    return fibonacci(n - 1) + fibonacci(n - 2);
}

test "fibonacci" {
    const y = fibonacci(10);
    try expectEqual(y, 55);
}

// Defer
test "defer" {
    var x: i16 = 5;
    {
        defer x += 2;
        try expect(x == 5);
    }
    try expect(x == 7);
}

test "multi defer" {
    var x: f32 = 5;
    {
        defer x += 2;
        defer x /= 2;
        try expect(x == 5);
    }
    try expect(x == 4.5);
}

// Errors

const FileOpenError = error{
    AccessDenied,
    OutOfMemory,
    FileNotFound,
};

const AllocationError = error{
    OutOfMemory,
};

test "coerce error from a subset to a superset" {
    const err = AllocationError.OutOfMemory;
    try expect(err == FileOpenError.OutOfMemory);
}

test "error union" {
    const maybe_error: AllocationError!u16 = 10;
    const no_error = maybe_error catch 0;
    try expect(no_error == 10);
    try expectEqual(@TypeOf(no_error), u16);
}

fn failFunction() error{Oops}!void {
    return error.Oops;
}

test "return an error" {
    failFunction() catch |err| {
        try expect(err == error.Oops);
        return;
    };
}

fn failFn() error{Oops}!i32 {
    try failFunction();
    return 12;
}

test "try" {
    const v = failFn() catch |err| {
        try expect(err == error.Oops);
        return;
    };
    try expect(v == 12);
}

var problems: u32 = 98;

fn failFnCounter() error{Oops}!void {
    errdefer problems += 1;
    try failFunction();
}

test "errdefer" {
    failFnCounter() catch |err| {
        try expect(err == error.Oops);
        try expect(problems == 99);
        return;
    };
}

fn createFile() !void {
    return error.AccessDenied;
}

test "inferred error set" {
    const x: error{AccessDenied}!void = createFile();
    _ = x catch {};
}

const A = error{ NotDir, PathNotFound };
const B = error{ OutOfMemory, PathNotFound };
const C = A || B;

// Switch
test "switch statement" {
    var x: i8 = 10;
    switch (x) {
        -1...1 => x = -x,
        10, 100 => x = @divExact(x, 10),
        else => {},
    }
    try expect(x == 1);
}

test "switch expression" {
    var x: i8 = 10;
    x = switch (x) {
        -1...1 => -x,
        10, 100 => @divExact(x, 10),
        else => x,
    };
    try expect(x == 1);
}

// Runtime safety

// Fails - in test, it is out of bound, in some builds it will pass since we sets runtime safety to false
test "out of bounds" {
    return error.SkipZigTest;
    // @setRuntimeSafety(false);
    // const a = [3]u8{ 1, 2, 3 };
    // const index: u8 = 5;
    // const b = a[index];
    // _ = b;
}

// Fails - unreachable is reachable
test "unreachable" {
    // const x: i32 = 1;
    // const y: i32 = if (x == 2) 5 else unreachable;
    // _ = y;
    return error.SkipZigTest;
}

fn asciiToUpper(x: u8) u8 {
    return switch (x) {
        'a'...'z' => x + 'A' - 'a',
        'A'...'Z' => x,
        else => unreachable,
    };
}

test "unreachable switch" {
    try expect(asciiToUpper('a') == 'A');
    try expectEqual('A', 'A');
}

// Pointers

fn increment(num: *u8) void {
    num.* += 1;
}

test "Pointers" {
    var x: u8 = 1;
    increment(&x);
    try expectEqual(x, 2);
}

// Fails - pointer cannot point to 0
test "naughty pointer" {
    return error.SkipZigTest;
    // const x: u16 = 0;
    // const y: *u8 = @ptrFromInt(x);
    // _ = y;
}

// Fails - pointer to const cannot assign to constant (dah)
test "const pointers" {
    return error.SkipZigTest;
    // const x: u8 = 1;
    // const y = &x;
    // y.* = 1;
}

// Pointer sized integers

test "usize" {
    try expect(@sizeOf(usize) == @sizeOf(*u8));
    try expect(@sizeOf(isize) == @sizeOf(*u8));
}

// Many item pointers

test "pointer to many" {
    var pointer_to_many: [*]u8 = undefined;
    var arr3 = [3]u8{ 'a', 'b', 'c' };
    const slice_of_an_arr = arr3[1..3];
    pointer_to_many = slice_of_an_arr;
    slice_of_an_arr[0] = 'a';
    pointer_to_many[1] = 'b';
    try expectEqual(pointer_to_many, slice_of_an_arr);
    try expectEqual(pointer_to_many[0], 'a');
    try expectEqual(slice_of_an_arr[1], 'b');
}

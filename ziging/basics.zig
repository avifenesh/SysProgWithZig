const expect = @import("std").testing.expect;
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

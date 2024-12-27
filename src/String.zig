// MIT License
//
// Copyright (c) 2024 Dok8tavo
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in all
// copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
// SOFTWARE.
//

bytes: []const u8 = "",

const std = @import("std");
const t = @import("testing.zig");

const String = @This();

pub inline fn print(string: *String, comptime fmt: []const u8, args: anytype) void {
    string.writeAll(std.fmt.comptimePrint(fmt, args));
}
pub inline fn writeBytesNTimes(string: *String, bytes: []const u8, n: usize) void {
    string.bytes = string.bytes ++ (bytes ** n);
}
pub inline fn writeByteNTimes(string: *String, byte: u8, n: usize) void {
    string.bytes = string.bytes ++ (&[1]u8{byte} ** n);
}
pub inline fn writeByte(string: *String, byte: u8) void {
    string.bytes = string.bytes ++ &[1]u8{byte};
}
pub inline fn writeAll(string: *String, bytes: []const u8) void {
    _ = string.write(bytes);
}
pub inline fn write(string: *String, bytes: []const u8) usize {
    string.bytes = string.bytes ++ bytes;
    return bytes.len;
}

test print {
    comptime {
        var string = String{};
        string.print("Hello {s}!", .{"world"});

        t.comptryEqualStrings(string.bytes, "Hello world!");
    }
}

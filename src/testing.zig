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

const compat = @import("compat.zig");
const std = @import("std");

pub const NoReturn = enum {};

pub inline fn compileError(fmt: []const u8, args: anytype) noreturn {
    @compileError(std.fmt.comptimePrint(fmt, args));
}

pub inline fn Payload(error_union: anytype) type {
    const info = compat.typeInfo(@TypeOf(error_union));
    return switch (info) {
        .error_union => |eu| eu.payload,
        .error_set => NoReturn,
        else => unreachable,
    };
}

pub inline fn ErrorSet(error_union: anytype) type {
    const info = compat.typeInfo(@TypeOf(error_union));
    return switch (info) {
        .error_union => |eu| eu.error_set,
        .error_set => @TypeOf(error_union),
        else => NoReturn,
    };
}

pub inline fn compTry(error_union: anytype) Payload(error_union) {
    return error_union catch |err| compileError("`{s}.{s}`", .{
        @typeName(ErrorSet(error_union)),
        @errorName(err),
    });
}

pub inline fn compTryEqualStrings(a: []const u8, b: []const u8) void {
    if (a.len != b.len) compileError(
        "The two compared strings aren't even the same length: {} and {}",
        .{ a.len, b.len },
    );

    const array_a: *const [a.len]u8 = @ptrCast(a.ptr);
    const array_b: *const [b.len]u8 = @ptrCast(b.ptr);
    const vector_a: @Vector(a.len, u8) = array_a.*;
    const vector_b: @Vector(b.len, u8) = array_b.*;
    const equals = @reduce(.And, vector_a == vector_b);
    if (!equals) compileError(
        "The two compared strings don't have the same content:\na: \"{}\"\nb: \"{}\"",
        .{ a, b },
    );
}

pub inline fn comptryIsTrue(value: bool) void {
    if (!value)
        @compileError("Comptried `false`!");
}

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

const compat = @import("compat.zig");
const std = @import("std");
const t = @import("testing.zig");

const String = @This();
const EnumLiteral = @TypeOf(.enum_literal);

pub inline fn from(any: anytype) String {
    const Any = @TypeOf(any);
    const info = compat.typeInfo(Any);

    return switch (info) {
        .enum_literal, .@"enum" => from(@tagName(any)),
        .type => from(@typeName(any)),
        .error_set => from(@errorName(any)),
        .int,
        .comptime_int,
        .bool,
        => from(std.fmt.comptimePrint("{}", .{any})),
        .pointer => |p| switch (p.size) {
            .many => if (p.child != u8) t.compileError(
                \\Can't make a `String` instance from a many-pointer of `{s}`!
                \\Try from a many-pointer of bytes instead.
            , .{@typeName(p.child)}) else if (p.sentinel) |sentinel| {
                var index: u32 = 0;
                const max = std.math.maxInt(u32);
                @setEvalBranchQuota(max);
                while (index != max) : (index += 1) {
                    if (any[index] == @as(*const u8, @ptrCast(sentinel)).*) break;
                } else @compileError("The given many-pointer is weirdly long!");

                return String{ .bytes = any[0..index] };
            } else @compileError(
                \\Can't make a `String` instance from a non sentinel-terminated many-pointer!
                \\Try giving it a sentinel first.
            ),
            .one => {
                const child_info = compat.typeInfo(p.child);
                if (child_info != .array) t.compileError(
                    "Can't make a `String` instance from a pointer to `{s}`!",
                    .{@typeName(p.child)},
                );

                if (child_info.array.child != u8) t.compileError(
                    "Can't make a `String` instance from a pointer to an array of `{s}`!",
                    .{@typeName(child_info.array.child)},
                );

                return String{ .bytes = any };
            },
            .slice => if (p.child == u8) String{ .bytes = any } else t.compileError(
                \\Can't make a `String` instance from a slice of `{s}`!
                \\Try from a slice of bytes instead.
            , .{@typeName(p.child)}),
            .c => @compileError(
                \\Can't make a `String` instance from a c-pointer!
                \\Try converting it into a slice or a many-pointer first.
            ),
        },
        .@"struct" => if (Any == String) any else t.compileError(
            "Can't make a `String` instance from a `{s}` instance!",
            .{@typeName(Any)},
        ),
        else => t.compileError(
            "Can't make a `String` instance from a `{s}` instance!",
            .{@typeName(Any)},
        ),
    };
}

pub inline fn eql(string: String, other: anytype) bool {
    const other_string = String.from(other);
    if (other_string.bytes.len != string.bytes.len)
        return false;

    const len = string.bytes.len;
    const array1: *const [len]u8 = @ptrCast(string.bytes.ptr);
    const array2: *const [len]u8 = @ptrCast(other_string.bytes.ptr);
    const vector1: @Vector(len, u8) = array1.*;
    const vector2: @Vector(len, u8) = array2.*;
    return @reduce(.And, vector1 == vector2);
}

pub inline fn concat(string: String, other: anytype) String {
    const other_string = String.from(other);
    return String{ .bytes = string.bytes ++ other_string.bytes };
}

// == Testing ==
test concat {
    comptime {
        const hello = String.from("Hello");
        const hello_world = hello.concat(" world!");
        t.comptryIsTrue(hello_world.eql("Hello world!"));
    }
}

test eql {
    comptime {
        const hello_world = String.from("Hello world!");
        t.comptryIsTrue(hello_world.eql("Hello world!"));
        t.comptryIsTrue(!hello_world.eql("Goodbye world!"));
    }
}

test from {
    comptime {
        const enum_literal = String.from(.hello_world);
        t.comptryEqualStrings(enum_literal.bytes, "hello_world");

        const enum_variant = String.from(enum { goodbye_world }.goodbye_world);
        t.comptryEqualStrings(enum_variant.bytes, "goodbye_world");

        const type_name = String.from([]const u8);
        t.comptryEqualStrings(type_name.bytes, "[]const u8");

        const error_name = String.from(error.ThisIsAnError);
        t.comptryEqualStrings(error_name.bytes, "ThisIsAnError");

        const int = String.from(@as(u32, 42));
        t.comptryEqualStrings(int.bytes, "42");

        const comptime_int_too = String.from(69);
        t.comptryEqualStrings(comptime_int_too.bytes, "69");

        const boolean = String.from(true);
        t.comptryEqualStrings(boolean.bytes, "true");

        const slice = String.from(@as([]const u8, "I'm a Barbie girl"));
        t.comptryEqualStrings(slice.bytes, "I'm a Barbie girl");

        const pointer_to_array = String.from("In the Barbie world");
        t.comptryEqualStrings(pointer_to_array.bytes, "In the Barbie world");

        const many_pointer = String.from(@as([*:0]const u8, "Life in plastic"));
        t.comptryEqualStrings(many_pointer.bytes, "Life in plastic");

        const even_string = String.from(String{ .bytes = "It's fantastic" });
        t.comptryEqualStrings(even_string.bytes, "It's fantastic");
    }
}

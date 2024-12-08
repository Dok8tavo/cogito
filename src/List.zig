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

inner: type = @Type(.{ .Struct = .{
    .decls = &.{},
    .fields = &.{},
    .is_tuple = true,
    .layout = .auto,
} }),

const t = @import("testing.zig");
const std = @import("std");

const List = @This();
const ItemInfo = std.builtin.Type.StructField;

pub inline fn from(tuple: anytype) List {
    const Tuple = @TypeOf(tuple);
    const tuple_info = @typeInfo(Tuple);

    var tuple_struct_info = if (tuple_info == .Struct) tuple_info.Struct else t.compileError(
        "A list must be made from a `.Struct`, not a `.{s}` like `{s}`!",
        .{ @tagName(tuple_info), @typeName(Tuple) },
    );

    if (!tuple_struct_info.is_tuple) t.compileError(
        "A list must be made from a tuple, not a struct like `{s}`!",
        .{@typeName(Tuple)},
    );

    var fields: []const ItemInfo = &.{};
    for (tuple_struct_info.fields) |field| {
        fields = fields ++ &[_]ItemInfo{.{
            .alignment = field.alignment,
            .default_value = @ptrCast(&@field(tuple, field.name)),
            .is_comptime = true,
            .name = field.name,
            .type = field.type,
        }};
    }

    tuple_struct_info.fields = fields;

    return List{ .inner = @Type(tuple_info) };
}

pub inline fn size(list: List) usize {
    return list.info().fields.len;
}

// == Accessing items ==
pub inline fn Get(list: List, index: usize) type {
    return if (index < list.size()) list.info().fields[index].type else noreturn;
}

pub inline fn get(list: List, index: usize) ?Get(list, index) {
    return if (index < list.size())
        @field(list.inner{}, list.info().fields[index].name)
    else
        null;
}

// == Inserting items ==
pub const InsertError = error{IndexOutOfBounds};

pub inline fn insert(list: *List, item: anytype, index: usize) void {
    var struct_info = list.info();

    struct_info.fields = struct_info.fields[0..index] ++ &[_]ItemInfo{.{
        .alignment = @alignOf(@TypeOf(item)),
        .default_value = @ptrCast(&item),
        .is_comptime = true,
        .name = std.fmt.comptimePrint("{}", .{index}),
        .type = @TypeOf(item),
    }};

    if (index != list.info().fields.len)
        struct_info.fields = struct_info.fields[0..index] ++ list.info().fields[index..];

    list.* = List{ .inner = @Type(.{ .Struct = struct_info }) };
}

pub inline fn insertOrErr(list: *List, item: anytype, index: usize) InsertError!void {
    if (list.size() < index)
        return InsertError.IndexOutOfBounds;
    list.insert(item, index);
}

// == Testing ==
test insert {
    comptime {
        var list = List{};
        t.compTry(std.testing.expect(!@hasField(list.inner, "0")));

        list.insert("Hello world!", 0);

        t.compTry(std.testing.expect(@hasField(list.inner, "0")));
        t.compTry(std.testing.expectEqualStrings(
            "Hello world!",
            @field(list.inner{}, "0"),
        ));
    }
}

test get {
    comptime {
        const list = List.from(.{ 2, 3, 5, 7 });

        t.compTry(std.testing.expectEqual(2, list.get(0)));
        t.compTry(std.testing.expectEqual(3, list.get(1)));
        t.compTry(std.testing.expectEqual(5, list.get(2)));
        t.compTry(std.testing.expectEqual(7, list.get(3)));
        t.compTry(std.testing.expectEqual(null, list.get(4)));
    }
}

test insertOrErr {
    comptime {
        var list = List.from(.{});

        t.compTry(std.testing.expectError(
            InsertError.IndexOutOfBounds,
            list.insertOrErr("Index is out of bounds!", 10_000),
        ));

        t.compTry(list.insertOrErr("Index isn't out of bounds!", 0));
        t.compTry(std.testing.expectEqualStrings(
            "Index isn't out of bounds!",
            @field(list.inner{}, "0"),
        ));
    }
}

inline fn info(comptime list: List) std.builtin.Type.Struct {
    return @typeInfo(list.inner).Struct;
}

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

pub const IndexError = error{IndexOutOfBounds};

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

pub inline fn insert(list: *List, item: anytype, index: usize) void {
    var fields: []const ItemInfo = &.{};

    for (list.inner{}, 0..) |item2, index2| {
        if (index2 == index) {
            fields = fields ++ &[_]ItemInfo{.{
                .alignment = @alignOf(@TypeOf(item)),
                .default_value = @ptrCast(&item),
                .is_comptime = true,
                .name = std.fmt.comptimePrint("{}", .{index}),
                .type = @TypeOf(item),
            }};
        }

        const new_index = index2 + @intFromBool(index <= index2);
        fields = fields ++ &[_]ItemInfo{.{
            .alignment = @alignOf(@TypeOf(item2)),
            .default_value = @ptrCast(&item2),
            .is_comptime = true,
            .name = std.fmt.comptimePrint("{}", .{new_index}),
            .type = @TypeOf(item2),
        }};
    }

    if (list.size() == index) {
        fields = fields ++ &[_]ItemInfo{.{
            .alignment = @alignOf(@TypeOf(item)),
            .default_value = @ptrCast(&item),
            .is_comptime = true,
            .name = std.fmt.comptimePrint("{}", .{index}),
            .type = @TypeOf(item),
        }};
    }

    list.* = List{ .inner = @Type(.{ .Struct = .{
        .decls = &.{},
        .fields = fields,
        .is_tuple = true,
        .layout = .auto,
    } }) };
}

pub inline fn insertOrErr(list: *List, item: anytype, index: usize) IndexError!void {
    if (list.size() < index)
        return IndexError.IndexOutOfBounds;
    list.insert(item, index);
}

pub inline fn append(list: *List, item: anytype) void {
    list.insert(item, list.size());
}

pub inline fn prepend(list: *List, item: anytype) void {
    list.insert(item, 0);
}

// == Removing items ==
pub inline fn remove(list: *List, index: usize) void {
    var new_info = list.info();
    new_info.fields = if (index != 0) new_info.fields[0..index] else &.{};
    for (index + 1..list.size()) |index2| {
        var field = list.info().fields[index2];
        field.name = std.fmt.comptimePrint("{}", .{index2 - 1});
        new_info.fields = new_info.fields ++ &[_]ItemInfo{field};
    }

    list.* = List{ .inner = @Type(.{ .Struct = new_info }) };
}

pub inline fn removeOrErr(list: *List, index: usize) IndexError!void {
    if (list.size() <= index)
        return IndexError.IndexOutOfBounds;
    list.remove(index);
}

pub inline fn removeOrLeave(list: *List, index: usize) void {
    list.removeOrErr(index) catch {};
}

// == Combine lists ==
pub inline fn concat(list: List, other: List) List {
    var new_list = list;
    for (0..other.size()) |i|
        new_list.append((other.inner{})[i]);
    return new_list;
}

// == Testing ==
test removeOrErr {
    comptime {
        var list = List.from(.{ 'a', 'b', 'c' });

        const remove1 = list.removeOrErr(2);
        const remove2 = list.removeOrErr(2);

        t.compTry(std.testing.expectEqualDeep({}, remove1));
        t.compTry(std.testing.expectEqualDeep(IndexError.IndexOutOfBounds, remove2));
    }
}
test removeOrLeave {
    comptime {
        var list = List.from(.{ .a, .b, .c });

        list.removeOrLeave(2);
        t.compTry(std.testing.expectEqualDeep(.{ .a, .b }, list.inner{}));

        list.removeOrLeave(2);
        t.compTry(std.testing.expectEqualDeep(.{ .a, .b }, list.inner{}));
    }
}

test remove {
    comptime {
        var list = List.from(.{ "Hello", "How", "are", "you" });

        list.remove(2);
        t.compTry(std.testing.expectEqualDeep(.{ "Hello", "How", "you" }, list.inner{}));

        list.remove(1);
        t.compTry(std.testing.expectEqualDeep(.{ "Hello", "you" }, list.inner{}));
    }
}

test concat {
    comptime {
        const list1 = List.from(.{ 1, 2, 3 });
        const list2 = List.from(.{ "viva", "l'Algérie" });
        const list3 = list1.concat(list2);

        t.compTry(std.testing.expectEqualDeep(
            list3.inner{},
            .{ 1, 2, 3, "viva", "l'Algérie" },
        ));
    }
}

test prepend {
    comptime {
        var list = List{};

        list.prepend(7);
        list.prepend(5);
        list.prepend(3);
        list.prepend(2);

        t.compTry(std.testing.expectEqual(2, list.get(0)));
        t.compTry(std.testing.expectEqual(3, list.get(1)));
        t.compTry(std.testing.expectEqual(5, list.get(2)));
        t.compTry(std.testing.expectEqual(7, list.get(3)));
        t.compTry(std.testing.expectEqual(null, list.get(4)));
    }
}

test append {
    comptime {
        var list = List{};

        list.append(2);
        list.append(3);
        list.append(5);
        list.append(7);

        t.compTry(std.testing.expectEqual(2, list.get(0)));
        t.compTry(std.testing.expectEqual(3, list.get(1)));
        t.compTry(std.testing.expectEqual(5, list.get(2)));
        t.compTry(std.testing.expectEqual(7, list.get(3)));
        t.compTry(std.testing.expectEqual(null, list.get(4)));
    }
}

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
            IndexError.IndexOutOfBounds,
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

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

backing_tuple: type = compat.TypeFrom(.{ .@"struct" = .{ .is_tuple = true } }),

const compat = @import("compat.zig");
const t = @import("testing.zig");
const std = @import("std");

const List = @This();
const ItemInfo = compat.Type.Struct.Field;

pub const IndexError = error{IndexOutOfBounds};

pub inline fn from(tuple: anytype) List {
    const Tuple = @TypeOf(tuple);
    const tuple_info = compat.typeInfo(Tuple);

    var tuple_struct_info = if (tuple_info == .@"struct")
        tuple_info.@"struct"
    else
        t.compileError(
            "A list must be made from a `.Struct`, not a `.{s}` like `{s}`!",
            .{ @tagName(tuple_info.intoStd()), @typeName(Tuple) },
        );

    if (!tuple_struct_info.is_tuple) t.compileError(
        "A list must be made from a tuple, not a struct like `{s}`!",
        .{@typeName(Tuple)},
    );

    var fields: []const ItemInfo = &.{};
    for (tuple_struct_info.fields) |field| {
        fields = fields ++ &[_]ItemInfo{.{
            .default_value = @ptrCast(&@field(tuple, field.name)),
            .is_comptime = true,
            .name = field.name,
            .type = field.type,
        }};
    }

    tuple_struct_info.fields = fields;

    return List{ .backing_tuple = compat.TypeFrom(tuple_info) };
}

pub inline fn size(list: List) usize {
    return list.info().fields.len;
}

// == Accessing items ==
pub inline fn Get(list: List, index: usize) type {
    return if (index < list.size()) list.info().fields[index].type else t.NoReturn;
}

pub inline fn get(list: List, index: usize) ?Get(list, index) {
    return if (index < list.size())
        @field(list.backing_tuple{}, list.info().fields[index].name)
    else
        null;
}

// == Setting items ==
pub inline fn set(list: *List, index: usize, value: anytype) void {
    var new_info = list.info();
    new_info.fields = if (index != 0) list.info().fields[0..index] else &.{};
    new_info.fields = new_info.fields ++ &[_]ItemInfo{.{
        .default_value = @ptrCast(&value),
        .is_comptime = true,
        .name = std.fmt.comptimePrint("{}", .{index}),
        .type = @TypeOf(value),
    }};

    if (index + 1 != list.size())
        new_info.fields = new_info.fields ++ list.info().fields[index + 1 ..];

    list.* = List{ .backing_tuple = compat.TypeFrom(.{ .@"struct" = new_info }) };
}

pub inline fn setOrError(list: *List, index: usize, value: anytype) IndexError!void {
    if (list.size() <= index)
        return IndexError.IndexOutOfBounds;
    list.set(index, value);
}

pub inline fn getSet(list: *List, index: usize, value: anytype) ?Get(list.*, index) {
    return if (list.get(index)) |old_value| {
        list.set(index, value);
        return old_value;
    } else null;
}

// == Popping items ==
pub inline fn Pop(list: *const List) type {
    return if (list.size() == 0) t.NoReturn else list.Get(list.size() - 1);
}

pub inline fn pop(list: *List) ?Pop(list) {
    return if (list.size() == 0) null else {
        const index = list.size() - 1;
        defer list.remove(index);
        return (list.backing_tuple{})[index];
    };
}

// == Inserting items ==
pub inline fn insert(list: *List, item: anytype, index: usize) void {
    var fields: []const ItemInfo = &.{};

    for (list.backing_tuple{}, 0..) |item2, index2| {
        if (index2 == index) {
            fields = fields ++ &[_]ItemInfo{.{
                .default_value = @ptrCast(&item),
                .is_comptime = true,
                .name = std.fmt.comptimePrint("{}", .{index}),
                .type = @TypeOf(item),
            }};
        }

        const new_index = index2 + @intFromBool(index <= index2);
        fields = fields ++ &[_]ItemInfo{.{
            .default_value = @ptrCast(&item2),
            .is_comptime = true,
            .name = std.fmt.comptimePrint("{}", .{new_index}),
            .type = @TypeOf(item2),
        }};
    }

    if (list.size() == index) {
        fields = fields ++ &[_]ItemInfo{.{
            .default_value = @ptrCast(&item),
            .is_comptime = true,
            .name = std.fmt.comptimePrint("{}", .{index}),
            .type = @TypeOf(item),
        }};
    }

    list.* = List{ .backing_tuple = compat.TypeFrom(.{ .@"struct" = .{
        .fields = fields,
        .is_tuple = true,
    } }) };
}

pub inline fn insertOrError(list: *List, item: anytype, index: usize) IndexError!void {
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

    list.* = List{ .backing_tuple = compat.TypeFrom(.{ .@"struct" = new_info }) };
}

pub inline fn removeOrError(list: *List, index: usize) IndexError!void {
    if (list.size() <= index)
        return IndexError.IndexOutOfBounds;
    list.remove(index);
}

pub inline fn removeOrLeave(list: *List, index: usize) void {
    list.removeOrError(index) catch {};
}

// == Combine lists ==
pub inline fn concat(list: List, other: List) List {
    var new_list = list;
    for (0..other.size()) |i|
        new_list.append((other.backing_tuple{})[i]);
    return new_list;
}

// == Testing ==
const expect = std.testing.expectEqualDeep;
test getSet {
    comptime {
        var list = List.from(.{ .hello, .world });
        const hello = list.getSet(0, .goodbye);

        t.comptry(expect(.hello, hello));
        t.comptry(expect(.{ .goodbye, .world }, list.backing_tuple{}));
    }
}

test setOrError {
    comptime {
        var list = List.from(.{ 0, 1, 2 });
        const set_or_err = list.setOrError(3, "This isn't right!");
        t.comptry(expect(IndexError.IndexOutOfBounds, set_or_err));
    }
}

test set {
    comptime {
        var list = List.from(.{ 'l', 'o', 'u' });
        list.set(2, "l");

        t.comptry(expect(.{ 'l', 'o', "l" }, list.backing_tuple{}));
    }
}

test pop {
    comptime {
        var list = List.from(.{ 3, 10, 5, 16, 8, 4, 2, 1, 4, 2, 1 });

        t.comptry(expect(1, list.pop()));
        t.comptry(expect(2, list.pop()));
        t.comptry(expect(4, list.pop()));
        t.comptry(expect(1, list.pop()));
        t.comptry(expect(2, list.pop()));
        t.comptry(expect(4, list.pop()));
        t.comptry(expect(8, list.pop()));
        t.comptry(expect(16, list.pop()));
        t.comptry(expect(5, list.pop()));
        t.comptry(expect(10, list.pop()));
        t.comptry(expect(3, list.pop()));
        t.comptry(expect(null, list.pop()));
    }
}

test removeOrError {
    comptime {
        var list = List.from(.{ 'a', 'b', 'c' });

        const remove1 = list.removeOrError(2);
        const remove2 = list.removeOrError(2);

        t.comptry(expect({}, remove1));
        t.comptry(expect(IndexError.IndexOutOfBounds, remove2));
    }
}

test removeOrLeave {
    comptime {
        var list = List.from(.{ .a, .b, .c });

        list.removeOrLeave(2);
        t.comptry(expect(.{ .a, .b }, list.backing_tuple{}));

        list.removeOrLeave(2);
        t.comptry(expect(.{ .a, .b }, list.backing_tuple{}));
    }
}

test remove {
    comptime {
        var list = List.from(.{ "Hello", "How", "are", "you" });

        list.remove(2);
        t.comptry(expect(.{ "Hello", "How", "you" }, list.backing_tuple{}));

        list.remove(1);
        t.comptry(expect(.{ "Hello", "you" }, list.backing_tuple{}));
    }
}

test concat {
    comptime {
        const list1 = List.from(.{ 1, 2, 3 });
        const list2 = List.from(.{ "viva", "l'Algérie" });
        const list3 = list1.concat(list2);

        t.comptry(expect(
            list3.backing_tuple{},
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

        t.comptry(expect(2, list.get(0)));
        t.comptry(expect(3, list.get(1)));
        t.comptry(expect(5, list.get(2)));
        t.comptry(expect(7, list.get(3)));
        t.comptry(expect(null, list.get(4)));
    }
}

test append {
    comptime {
        var list = List{};

        list.append(2);
        list.append(3);
        list.append(5);
        list.append(7);

        t.comptry(expect(2, list.get(0)));
        t.comptry(expect(3, list.get(1)));
        t.comptry(expect(5, list.get(2)));
        t.comptry(expect(7, list.get(3)));
        t.comptry(expect(null, list.get(4)));
    }
}

test insert {
    comptime {
        var list = List{};
        t.comptry(expect(.{}, list.backing_tuple{}));

        list.insert("Hello world!", 0);

        t.comptry(expect(.{"Hello world!"}, list.backing_tuple{}));
    }
}

test get {
    comptime {
        const list = List.from(.{ 2, 3, 5, 7 });

        t.comptry(expect(2, list.get(0)));
        t.comptry(expect(3, list.get(1)));
        t.comptry(expect(5, list.get(2)));
        t.comptry(expect(7, list.get(3)));
        t.comptry(expect(null, list.get(4)));
    }
}

test insertOrError {
    comptime {
        var list = List.from(.{});

        t.comptry(expect(
            IndexError.IndexOutOfBounds,
            list.insertOrError("Index is out of bounds!", 10_000),
        ));

        t.comptry(list.insertOrError("Index isn't out of bounds!", 0));
        t.comptry(expect(.{"Index isn't out of bounds!"}, list.backing_tuple{}));
    }
}

inline fn info(comptime list: List) compat.Type.Struct {
    return compat.typeInfo(list.backing_tuple).@"struct";
}

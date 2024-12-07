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

type: type = @Type(.{ .Struct = .{
    .fields = &.{},
    .decls = &.{},
    .is_tuple = false,
    .layout = .auto,
} }),

const root = @import("root.zig");
const std = @import("std");

const KeyValue = std.builtin.Type.StructField;
const Map = @This();

pub fn from(comptime kv_struct: anytype) Map {
    const KVStruct = @TypeOf(kv_struct);
    const kv_info = @typeInfo(KVStruct);

    var kv_struct_info = if (kv_info == .Struct) kv_info.Struct else root.compileError(
        "A map must be made from a `.Struct`, not a `.{s}` like `{s}`!",
        .{ @tagName(kv_info), @typeName(KVStruct) },
    );

    if (kv_struct_info.is_tuple) root.compileError(
        "A map must be made from a struct, not a tuple like `{s}`!",
        .{@typeName(KVStruct)},
    );

    var fields: []const KeyValue = &.{};
    for (kv_struct_info.fields) |field| {
        fields = fields ++ &[_]KeyValue{.{
            .alignment = field.alignment,
            .default_value = @ptrCast(&@field(kv_struct, field.name)),
            .is_comptime = true,
            .name = field.name,
            .type = field.type,
        }};
    }

    kv_struct_info.fields = fields;

    return Map{ .type = @Type(kv_info) };
}

pub fn size(comptime map: Map) usize {
    return map.info().fields.len;
}

// == Accessing items ==
pub fn has(comptime map: Map, comptime key: anytype) bool {
    return @hasField(map.type, intoString(key));
}

pub fn Get(comptime map: Map, comptime key: anytype) type {
    return if (map.has(key))
        @TypeOf(@field(map.type{}, intoString(key)))
    else
        @Type(.NoReturn);
}

pub fn get(comptime map: Map, comptime key: anytype) ?Get(map, key) {
    return if (map.has(key)) @field(map.type{}, intoString(key)) else null;
}

// == Adding items ==
pub const AddError = error{
    KeyAlreadyExists,
};

pub fn addOrErr(
    comptime map: *Map,
    comptime key: anytype,
    comptime value: anytype,
) AddError!void {
    if (map.has(key))
        return AddError.KeyAlreadyExists;
    map.add(key, value);
}

pub fn addOrLeave(
    comptime map: *Map,
    comptime key: anytype,
    comptime value: anytype,
) void {
    if (!map.has(key))
        map.add(key, value);
}

pub fn addOrReplace(
    comptime map: *Map,
    comptime key: anytype,
    comptime value: anytype,
) void {
    map.replaceOrErr(key, value) catch map.add(key, value);
}

pub fn add(
    comptime map: *Map,
    comptime key: anytype,
    comptime value: anytype,
) void {
    const Value = @TypeOf(value);
    var struct_info = map.info();
    struct_info.fields = map.info().fields ++ &[_]KeyValue{.{
        .alignment = @alignOf(Value),
        .name = intoString(key) ++ "\x00",
        .default_value = @ptrCast(&value),
        .is_comptime = true,
        .type = Value,
    }};

    map.type = @Type(.{ .Struct = struct_info });
}

// == Removing items ==
pub const RemoveError = error{
    KeyDoesNotExist,
};

pub fn remove(comptime map: *Map, comptime key: anytype) void {
    var struct_info = map.info();
    const new_length = map.size() - 1;
    for (0..new_length) |index| {
        if (std.mem.eql(u8, struct_info.fields[index].name, intoString(key))) {
            struct_info.fields = map.info().fields[0..index] ++ map.info().fields[index + 1 ..];
            break;
        }
    } else struct_info.fields = map.info().fields[0..new_length];

    map.type = @Type(.{ .Struct = struct_info });
}

pub fn removeOrErr(comptime map: *Map, comptime key: anytype) RemoveError!void {
    if (!map.has(key))
        return RemoveError.KeyDoesNotExist;
    map.remove(key);
}

pub fn removeOrLeave(comptime map: *Map, comptime key: anytype) void {
    if (map.has(key))
        map.remove(key);
}

// == Popping items ==
pub fn pop(comptime map: *Map, comptime key: anytype) Get(map.*, key) {
    defer map.remove(key);
    return map.get(key).?;
}

pub fn popOrErr(comptime map: *Map, comptime key: anytype) RemoveError!Get(map.*, key) {
    if (!map.has(key))
        return RemoveError.KeyDoesNotExist;
    return map.pop(key);
}

pub fn popOrLeave(comptime map: *Map, comptime key: anytype) ?Get(map.*, key) {
    return if (map.has(key))
        map.pop(key)
    else
        null;
}

// == Replacing items ==
pub fn replace(
    comptime map: *Map,
    comptime key: anytype,
    comptime value: anytype,
) void {
    map.remove(key);
    map.add(key, value);
}

pub fn replaceOrErr(
    comptime map: *Map,
    comptime key: anytype,
    comptime value: anytype,
) RemoveError!void {
    if (!map.has(key))
        return RemoveError.KeyDoesNotExist;
    map.replace(key, value);
}

pub fn replaceOrLeave(
    comptime map: *Map,
    comptime key: anytype,
    comptime value: anytype,
) void {
    if (map.has(key))
        map.replace(key, value);
}

// == Iterating ==
pub const KeyIterator = struct {
    index: usize = 0,
    map: Map = .{},

    pub fn peek(comptime iterator: KeyIterator) ?[:0]const u8 {
        return if (iterator.map.size() <= iterator.index)
            null
        else
            iterator.map.info().fields[iterator.index].name;
    }

    pub fn next(comptime iterator: *KeyIterator) ?[:0]const u8 {
        return if (iterator.peek()) |key| {
            iterator.index += 1;
            return key;
        } else null;
    }
};

pub fn iterateKeys(comptime map: Map) KeyIterator {
    return KeyIterator{ .map = map };
}

pub const ValueIterator = struct {
    index: usize = 0,
    map: Map = .{},

    pub fn Peek(comptime iterator: ValueIterator) type {
        return if (iterator.map.size() <= iterator.index)
            @Type(.NoReturn)
        else
            iterator.map.info().fields[iterator.index].type;
    }

    pub fn peek(comptime iterator: ValueIterator) ?Peek(iterator) {
        return if (iterator.map.size() <= iterator.index)
            null
        else
            iterator.map.get(iterator.map.info().fields[iterator.index].name);
    }

    pub fn next(comptime iterator: *ValueIterator) ?Peek(iterator.*) {
        return if (iterator.peek()) |value| {
            iterator.index += 1;
            return value;
        } else null;
    }
};

pub fn iterateValues(comptime map: Map) ValueIterator {
    return ValueIterator{ .map = map };
}

pub const Iterator = struct {
    index: usize = 0,
    map: Map = .{},

    pub fn Peek(comptime iterator: Iterator) type {
        return if (iterator.map.size() <= iterator.index)
            @Type(.NoReturn)
        else
            struct { [:0]const u8, iterator.map.info().fields[iterator.index].type };
    }

    pub fn peek(comptime iterator: Iterator) ?Peek(iterator) {
        if (iterator.map.size() <= iterator.index) return null;

        const key = iterator.map.info().fields[iterator.index].name;
        return .{ key, @field((iterator.map.type{}), key) };
    }

    pub fn next(comptime iterator: *Iterator) ?Peek(iterator.*) {
        return if (iterator.peek()) |key_value| {
            iterator.index += 1;
            return key_value;
        } else null;
    }
};

pub fn iterate(comptime map: Map) Iterator {
    return Iterator{ .map = map };
}

// == Testing ==
test add {
    comptime {
        var map = Map{};
        map.add(.key, "value");
        try std.testing.expectEqualStrings("value", @field(map.type{}, "key"));
    }
}

test addOrErr {
    comptime {
        var map = Map.from(.{ .key1 = 1 });
        const add_key1 = map.addOrErr(.key1, 2); // this is an error
        const add_key2 = map.addOrErr(.key2, 3); // this isn't

        try std.testing.expectError(AddError.KeyAlreadyExists, add_key1);
        try std.testing.expectEqual(void{}, add_key2);

        try std.testing.expectEqual(1, (map.type{}).key1);
        try std.testing.expectEqual(3, (map.type{}).key2);
    }
}

test addOrLeave {
    comptime {
        var map = Map.from(.{ .key1 = 1 });
        map.addOrLeave(.key1, 2); // does nothing
        map.addOrLeave(.key2, 3);

        try std.testing.expectEqual(1, (map.type{}).key1);
        try std.testing.expectEqual(3, (map.type{}).key2);
    }
}

test addOrReplace {
    comptime {
        var map = Map.from(.{ .key = 1 });
        map.addOrReplace(.key, 2);
        map.addOrReplace(.not_key, 3);

        try std.testing.expectEqual(2, (map.type{}).key);
        try std.testing.expectEqual(3, (map.type{}).not_key);
    }
}

test remove {
    comptime {
        var map = Map.from(.{ .key = 1 });

        try std.testing.expect(@hasField(map.type, "key"));
        map.remove(.key);
        try std.testing.expect(!@hasField(map.type, "key"));
    }
}

test removeOrErr {
    comptime {
        var map = Map.from(.{ .key = 1 });

        try std.testing.expect(@hasField(map.type, "key"));
        try std.testing.expect(!@hasField(map.type, "not_key"));

        const remove_key = map.removeOrErr(.key);
        const remove_not_key = map.removeOrErr(.not_key);

        try std.testing.expect(!@hasField(map.type, "key"));
        try std.testing.expect(!@hasField(map.type, "not_key"));

        try std.testing.expectEqual(void{}, remove_key);
        try std.testing.expectError(RemoveError.KeyDoesNotExist, remove_not_key);
    }
}

test removeOrLeave {
    comptime {
        var map = Map.from(.{ .key = 1 });

        try std.testing.expect(@hasField(map.type, "key"));
        try std.testing.expect(!@hasField(map.type, "not_key"));

        map.removeOrLeave(.key);
        map.removeOrLeave(.not_key);

        try std.testing.expect(!@hasField(map.type, "key"));
        try std.testing.expect(!@hasField(map.type, "not_key"));
    }
}

test replace {
    comptime {
        var map = Map.from(.{ .key = 1 });

        try std.testing.expectEqual(1, (map.type{}).key);
        map.replace(.key, "not even a `comptime_int`");
        try std.testing.expectEqualStrings("not even a `comptime_int`", (map.type{}).key);
    }
}

test replaceOrErr {
    comptime {
        var map = Map.from(.{ .key = 1 });

        try std.testing.expectEqual(1, (map.type{}).key);
        try std.testing.expect(!@hasField(map.type, "not_key"));

        const replace_key = map.replaceOrErr(.key, 2);
        const replace_not_key = map.replaceOrErr(.not_key, 2);

        try std.testing.expectEqual(2, (map.type{}).key);
        try std.testing.expect(!@hasField(map.type, "not_key"));

        try std.testing.expectEqual(void{}, replace_key);
        try std.testing.expectError(RemoveError.KeyDoesNotExist, replace_not_key);
    }
}

test replaceOrLeave {
    comptime {
        var map = Map.from(.{ .key = 1 });

        try std.testing.expectEqual(1, (map.type{}).key);
        try std.testing.expect(!@hasField(map.type, "not_key"));

        map.replaceOrLeave(.key, 2);
        map.replaceOrLeave(.not_key, 2);

        try std.testing.expectEqual(2, (map.type{}).key);
        try std.testing.expect(!@hasField(map.type, "not_key"));
    }
}

test has {
    comptime {
        var map = Map.from(.{ .key = 1 });
        try std.testing.expect(map.has(.key));
        try std.testing.expect(!map.has(.not_key));
    }
}

test Get {
    comptime {
        const map = Map.from(.{ .key = 1 });
        try std.testing.expectEqual(comptime_int, Map.Get(map, .key));
        try std.testing.expectEqual(noreturn, Map.Get(map, .not_key));
    }
}

test get {
    comptime {
        const map = Map.from(.{ .key = 1 });
        try std.testing.expectEqual(1, map.get(.key));
        try std.testing.expectEqual(null, map.get(.not_key));
    }
}

test pop {
    comptime {
        var map = Map.from(.{ .key = 1 });
        try std.testing.expectEqual(1, map.pop(.key));
        try std.testing.expect(!map.has(.key));
    }
}

test popOrErr {
    comptime {
        var map = Map.from(.{ .key = 1 });
        try std.testing.expectEqual(1, map.popOrErr(.key));
        try std.testing.expectError(RemoveError.KeyDoesNotExist, map.popOrErr(.key));
    }
}

test popOrLeave {
    comptime {
        var map = Map.from(.{ .key = 1 });
        try std.testing.expect(map.has(.key));

        const pop1 = map.popOrLeave(.key);
        try std.testing.expect(!map.has(.key));

        const pop2 = map.popOrLeave(.key);
        try std.testing.expect(!map.has(.key));

        try std.testing.expectEqual(1, pop1);
        try std.testing.expectEqual(null, pop2);
    }
}

test iterate {
    comptime {
        const map = Map.from(.{ .key1 = 1, .key2 = 2 });
        var iterator = map.iterate();

        const peek1 = iterator.peek() orelse
            return error.UnexpectedNull;

        try std.testing.expectEqualStrings("key1", peek1[0]);
        try std.testing.expectEqual(1, peek1[1]);

        const peek2 = iterator.peek() orelse
            return error.UnexpectedNull;

        try std.testing.expectEqualStrings("key1", peek2[0]);
        try std.testing.expectEqual(1, peek2[1]);

        const next1 = iterator.next() orelse
            return error.UnexpectedNull;

        try std.testing.expectEqualStrings("key1", next1[0]);
        try std.testing.expectEqual(1, next1[1]);

        const peek3 = iterator.peek() orelse
            return error.UnexpectedNull;

        try std.testing.expectEqualStrings("key2", peek3[0]);
        try std.testing.expectEqual(2, peek3[1]);

        const next2 = iterator.next() orelse
            return error.UnexpectedNull;

        try std.testing.expectEqualStrings("key2", next2[0]);
        try std.testing.expectEqual(2, next2[1]);

        try std.testing.expectEqual(null, iterator.peek());
        try std.testing.expectEqual(null, iterator.next());
    }
}

test iterateKeys {
    comptime {
        const map = Map.from(.{ .key1 = 1, .key2 = 2 });
        var iterator = map.iterateKeys();

        const peek1 = iterator.peek() orelse
            return error.UnexpectedNull;

        try std.testing.expectEqualStrings("key1", peek1);

        const peek2 = iterator.peek() orelse
            return error.UnexpectedNull;

        try std.testing.expectEqualStrings("key1", peek2);

        const next1 = iterator.next() orelse
            return error.UnexpectedNull;

        try std.testing.expectEqualStrings("key1", next1);

        const peek3 = iterator.peek() orelse
            return error.UnexpectedNull;

        try std.testing.expectEqualStrings("key2", peek3);

        const next2 = iterator.next() orelse
            return error.UnexpectedNull;

        try std.testing.expectEqualStrings("key2", next2);

        try std.testing.expectEqual(null, iterator.peek());
        try std.testing.expectEqual(null, iterator.next());
    }
}

test iterateValues {
    comptime {
        const map = Map.from(.{ .key1 = 1, .key2 = 2 });
        var iterator = map.iterateValues();

        const peek1 = iterator.peek() orelse
            return error.UnexpectedNull;

        try std.testing.expectEqual(1, peek1);

        const peek2 = iterator.peek() orelse
            return error.UnexpectedNull;

        try std.testing.expectEqual(1, peek2);

        const next1 = iterator.next() orelse
            return error.UnexpectedNull;

        try std.testing.expectEqual(1, next1);

        const peek3 = iterator.peek() orelse
            return error.UnexpectedNull;

        try std.testing.expectEqual(2, peek3);

        const next2 = iterator.next() orelse
            return error.UnexpectedNull;

        try std.testing.expectEqual(2, next2);

        try std.testing.expectEqual(null, iterator.peek());
        try std.testing.expectEqual(null, iterator.next());
    }
}

pub fn intoString(comptime any: anytype) []const u8 {
    const Any = @TypeOf(any);
    switch (Any) {
        []const u8, []u8, [:0]const u8, [:0]u8 => return any,
        @TypeOf(.enum_literal) => return @tagName(any),
        else => if (@typeInfo(Any) == .Pointer) {
            const pointer_info = @typeInfo(Any).Pointer;
            if (pointer_info.size == .One) {
                const child_info = @typeInfo(pointer_info.child);
                if (child_info == .Array and child_info.Array.child == u8)
                    return any;
            }
        },
    }

    root.compileError("Can't convert `{s}` into a string!", .{@typeName(Any)});
}

fn info(comptime map: Map) std.builtin.Type.Struct {
    return @typeInfo(map.type).Struct;
}

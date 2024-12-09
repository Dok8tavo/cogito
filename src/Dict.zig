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
    .fields = &.{},
    .decls = &.{},
    .is_tuple = false,
    .layout = .auto,
} }),

const std = @import("std");
const t = @import("testing.zig");

const KeyValueInfo = std.builtin.Type.StructField;
const Dict = @This();

pub inline fn from(kv_struct: anytype) Dict {
    const KVStruct = @TypeOf(kv_struct);
    const kv_info = @typeInfo(KVStruct);

    var kv_struct_info = if (kv_info == .Struct) kv_info.Struct else t.compileError(
        "A dict must be made from a `.Struct`, not a `.{s}` like `{s}`!",
        .{ @tagName(kv_info), @typeName(KVStruct) },
    );

    if (kv_struct_info.is_tuple) t.compileError(
        "A dict must be made from a struct, not a tuple like `{s}`!",
        .{@typeName(KVStruct)},
    );

    var fields: []const KeyValueInfo = &.{};
    for (kv_struct_info.fields) |field| {
        fields = fields ++ &[_]KeyValueInfo{.{
            .alignment = field.alignment,
            .default_value = @ptrCast(&@field(kv_struct, field.name)),
            .is_comptime = true,
            .name = field.name,
            .type = field.type,
        }};
    }

    kv_struct_info.fields = fields;

    return Dict{ .inner = @Type(kv_info) };
}

pub inline fn size(dict: Dict) usize {
    return dict.info().fields.len;
}

// == Accessing items ==
pub inline fn has(dict: Dict, key: anytype) bool {
    return @hasField(dict.inner, intoString(key));
}

pub inline fn Get(dict: anytype, key: anytype) type {
    return if (dict.has(key))
        @TypeOf(@field(dict.inner{}, intoString(key)))
    else
        t.NoReturn;
}

pub inline fn get(dict: Dict, key: anytype) ?Get(dict, key) {
    return if (dict.has(key)) @field(dict.inner{}, intoString(key)) else null;
}

// == Adding items ==
pub const AddError = error{KeyAlreadyExists};

pub inline fn addOrError(dict: *Dict, key: anytype, value: anytype) AddError!void {
    if (dict.has(key))
        return AddError.KeyAlreadyExists;
    dict.add(key, value);
}

pub inline fn addOrLeave(dict: *Dict, key: anytype, value: anytype) void {
    if (!dict.has(key))
        dict.add(key, value);
}

pub inline fn addOrReplace(dict: *Dict, key: anytype, value: anytype) void {
    dict.setOrError(key, value) catch dict.add(key, value);
}

pub inline fn add(dict: *Dict, key: anytype, value: anytype) void {
    const Value = @TypeOf(value);
    var struct_info = dict.info();
    struct_info.fields = dict.info().fields ++ &[_]KeyValueInfo{.{
        .alignment = @alignOf(Value),
        .name = intoString(key) ++ "\x00",
        .default_value = @ptrCast(&value),
        .is_comptime = true,
        .type = Value,
    }};

    dict.inner = @Type(.{ .Struct = struct_info });
}

// == Removing items ==
pub const RemoveError = error{KeyDoesNotExist};

pub inline fn remove(dict: *Dict, key: anytype) void {
    var struct_info = dict.info();
    const new_length = dict.size() - 1;
    for (0..new_length) |index| {
        if (std.mem.eql(u8, struct_info.fields[index].name, intoString(key))) {
            struct_info.fields = dict.info().fields[0..index] ++ dict.info().fields[index + 1 ..];
            break;
        }
    } else struct_info.fields = dict.info().fields[0..new_length];

    dict.inner = @Type(.{ .Struct = struct_info });
}

pub inline fn removeOrError(dict: *Dict, key: anytype) RemoveError!void {
    if (!dict.has(key))
        return RemoveError.KeyDoesNotExist;
    dict.remove(key);
}

pub inline fn removeOrLeave(dict: *Dict, key: anytype) void {
    if (dict.has(key))
        dict.remove(key);
}

// == Popping items ==
pub inline fn pop(dict: *Dict, key: anytype) Get(dict, key) {
    defer dict.remove(key);
    return @field(dict.inner{}, intoString(key));
}

pub inline fn popOrError(dict: *Dict, key: anytype) RemoveError!Get(dict, key) {
    if (!dict.has(key))
        return RemoveError.KeyDoesNotExist;
    return dict.pop(key);
}

pub inline fn popOrLeave(dict: *Dict, key: anytype) ?Get(dict, key) {
    return if (dict.has(key))
        dict.pop(key)
    else
        null;
}

// == Replacing items ==
pub inline fn set(dict: *Dict, key: anytype, value: anytype) void {
    dict.remove(key);
    dict.add(key, value);
}

pub inline fn setOrError(dict: *Dict, key: anytype, value: anytype) RemoveError!void {
    if (!dict.has(key))
        return RemoveError.KeyDoesNotExist;
    dict.set(key, value);
}

pub inline fn setOrLeave(dict: *Dict, key: anytype, value: anytype) void {
    if (dict.has(key))
        dict.set(key, value);
}

// == Iterating ==
pub const KeyIterator = struct {
    index: usize = 0,
    dict: Dict = .{},

    pub inline fn peek(iterator: KeyIterator) ?[:0]const u8 {
        return if (iterator.dict.size() <= iterator.index)
            null
        else
            iterator.dict.info().fields[iterator.index].name;
    }

    pub inline fn next(iterator: *KeyIterator) ?[:0]const u8 {
        return if (iterator.peek()) |key| {
            iterator.index += 1;
            return key;
        } else null;
    }
};

pub inline fn iterateKeys(dict: Dict) KeyIterator {
    return KeyIterator{ .dict = dict };
}

pub const ValueIterator = struct {
    index: usize = 0,
    dict: Dict = .{},

    pub inline fn Peek(iterator: ValueIterator) type {
        return if (iterator.dict.size() <= iterator.index)
            t.NoReturn
        else
            iterator.dict.info().fields[iterator.index].type;
    }

    pub inline fn peek(iterator: ValueIterator) ?Peek(iterator) {
        return if (iterator.dict.size() <= iterator.index)
            null
        else
            iterator.dict.get(iterator.dict.info().fields[iterator.index].name);
    }

    pub inline fn next(iterator: *ValueIterator) ?Peek(iterator.*) {
        return if (iterator.peek()) |value| {
            iterator.index += 1;
            return value;
        } else null;
    }
};

pub inline fn iterateValues(dict: Dict) ValueIterator {
    return ValueIterator{ .dict = dict };
}

pub const Iterator = struct {
    index: usize = 0,
    dict: Dict = .{},

    pub inline fn Peek(iterator: Iterator) type {
        return if (iterator.dict.size() <= iterator.index)
            t.NoReturn
        else
            struct { [:0]const u8, iterator.dict.info().fields[iterator.index].type };
    }

    pub inline fn peek(iterator: Iterator) ?Peek(iterator) {
        if (iterator.dict.size() <= iterator.index) return null;

        const key = iterator.dict.info().fields[iterator.index].name;
        return .{ key, @field((iterator.dict.inner{}), key) };
    }

    pub inline fn next(iterator: *Iterator) ?Peek(iterator.*) {
        return if (iterator.peek()) |key_value| {
            iterator.index += 1;
            return key_value;
        } else null;
    }
};

pub inline fn iterate(dict: Dict) Iterator {
    return Iterator{ .dict = dict };
}

// == Testing ==
test add {
    comptime {
        var dict = Dict{};
        dict.add(.key, "value");
        t.compTry(std.testing.expectEqualStrings("value", @field(dict.inner{}, "key")));
    }
}

test addOrError {
    comptime {
        var dict = Dict.from(.{ .key1 = 1 });
        const add_key1 = dict.addOrError(.key1, 2); // this is an error
        const add_key2 = dict.addOrError(.key2, 3); // this isn't

        t.compTry(std.testing.expectError(AddError.KeyAlreadyExists, add_key1));
        t.compTry(std.testing.expectEqual(void{}, add_key2));

        t.compTry(std.testing.expectEqual(1, (dict.inner{}).key1));
        t.compTry(std.testing.expectEqual(3, (dict.inner{}).key2));
    }
}

test addOrLeave {
    comptime {
        var dict = Dict.from(.{ .key1 = 1 });
        dict.addOrLeave(.key1, 2); // does nothing
        dict.addOrLeave(.key2, 3);

        t.compTry(std.testing.expectEqual(1, (dict.inner{}).key1));
        t.compTry(std.testing.expectEqual(3, (dict.inner{}).key2));
    }
}

test addOrReplace {
    comptime {
        var dict = Dict.from(.{ .key = 1 });
        dict.addOrReplace(.key, 2);
        dict.addOrReplace(.not_key, 3);

        t.compTry(std.testing.expectEqual(2, (dict.inner{}).key));
        t.compTry(std.testing.expectEqual(3, (dict.inner{}).not_key));
    }
}

test remove {
    comptime {
        var dict = Dict.from(.{ .key = 1 });

        t.compTry(std.testing.expect(@hasField(dict.inner, "key")));
        dict.remove(.key);
        t.compTry(std.testing.expect(!@hasField(dict.inner, "key")));
    }
}

test removeOrError {
    comptime {
        var dict = Dict.from(.{ .key = 1 });

        t.compTry(std.testing.expect(@hasField(dict.inner, "key")));
        t.compTry(std.testing.expect(!@hasField(dict.inner, "not_key")));

        const remove_key = dict.removeOrError(.key);
        const remove_not_key = dict.removeOrError(.not_key);

        t.compTry(std.testing.expect(!@hasField(dict.inner, "key")));
        t.compTry(std.testing.expect(!@hasField(dict.inner, "not_key")));

        t.compTry(std.testing.expectEqual(void{}, remove_key));
        t.compTry(std.testing.expectError(RemoveError.KeyDoesNotExist, remove_not_key));
    }
}

test removeOrLeave {
    comptime {
        var dict = Dict.from(.{ .key = 1 });

        t.compTry(std.testing.expect(@hasField(dict.inner, "key")));
        t.compTry(std.testing.expect(!@hasField(dict.inner, "not_key")));

        dict.removeOrLeave(.key);
        dict.removeOrLeave(.not_key);

        t.compTry(std.testing.expect(!@hasField(dict.inner, "key")));
        t.compTry(std.testing.expect(!@hasField(dict.inner, "not_key")));
    }
}

test set {
    comptime {
        var dict = Dict.from(.{ .key = 1 });

        t.compTry(std.testing.expectEqual(1, (dict.inner{}).key));
        dict.set(.key, "not even a `comptime_int`");
        t.compTry(std.testing.expectEqualStrings("not even a `comptime_int`", (dict.inner{}).key));
    }
}

test setOrError {
    comptime {
        var dict = Dict.from(.{ .key = 1 });

        t.compTry(std.testing.expectEqual(1, (dict.inner{}).key));
        t.compTry(std.testing.expect(!@hasField(dict.inner, "not_key")));

        const set_key = dict.setOrError(.key, 2);
        const set_not_key = dict.setOrError(.not_key, 2);

        t.compTry(std.testing.expectEqual(2, (dict.inner{}).key));
        t.compTry(std.testing.expect(!@hasField(dict.inner, "not_key")));

        t.compTry(std.testing.expectEqual(void{}, set_key));
        t.compTry(std.testing.expectError(RemoveError.KeyDoesNotExist, set_not_key));
    }
}

test setOrLeave {
    comptime {
        var dict = Dict.from(.{ .key = 1 });

        t.compTry(std.testing.expectEqual(1, (dict.inner{}).key));
        t.compTry(std.testing.expect(!@hasField(dict.inner, "not_key")));

        dict.setOrLeave(.key, 2);
        dict.setOrLeave(.not_key, 2);

        t.compTry(std.testing.expectEqual(2, (dict.inner{}).key));
        t.compTry(std.testing.expect(!@hasField(dict.inner, "not_key")));
    }
}

test has {
    comptime {
        var dict = Dict.from(.{ .key = 1 });
        t.compTry(std.testing.expect(dict.has(.key)));
        t.compTry(std.testing.expect(!dict.has(.not_key)));
    }
}

test Get {
    comptime {
        const dict = Dict.from(.{ .key = 1 });
        t.compTry(std.testing.expectEqual(comptime_int, Dict.Get(dict, .key)));
        t.compTry(std.testing.expectEqual(t.NoReturn, Dict.Get(dict, .not_key)));
    }
}

test get {
    comptime {
        const dict = Dict.from(.{ .key = 1 });
        t.compTry(std.testing.expectEqual(1, dict.get(.key)));
        t.compTry(std.testing.expectEqual(null, dict.get(.not_key)));
    }
}

test pop {
    comptime {
        var dict = Dict.from(.{ .key = 1 });
        t.compTry(std.testing.expectEqual(1, dict.pop(.key)));
        t.compTry(std.testing.expect(!dict.has(.key)));
    }
}

test popOrError {
    comptime {
        var dict = Dict.from(.{ .key = 1 });
        t.compTry(std.testing.expectEqual(1, dict.popOrError(.key)));
        t.compTry(std.testing.expectError(RemoveError.KeyDoesNotExist, dict.popOrError(.key)));
    }
}

test popOrLeave {
    comptime {
        var dict = Dict.from(.{ .key = 1 });
        try std.testing.expect(dict.has(.key));

        const pop1 = dict.popOrLeave(.key);
        t.compTry(std.testing.expect(!dict.has(.key)));

        const pop2 = dict.popOrLeave(.key);
        t.compTry(std.testing.expect(!dict.has(.key)));

        t.compTry(std.testing.expectEqual(1, pop1));
        t.compTry(std.testing.expectEqual(null, pop2));
    }
}

test iterate {
    comptime {
        const dict = Dict.from(.{ .key1 = 1, .key2 = 2 });
        var iterator = dict.iterate();

        const peek1 = iterator.peek() orelse
            t.compTry(error.UnexpectedNull);

        t.compTry(std.testing.expectEqualStrings("key1", peek1[0]));
        t.compTry(std.testing.expectEqual(1, peek1[1]));

        const peek2 = iterator.peek() orelse
            t.compTry(error.UnexpectedNull);

        t.compTry(std.testing.expectEqualStrings("key1", peek2[0]));
        t.compTry(std.testing.expectEqual(1, peek2[1]));

        const next1 = iterator.next() orelse
            t.compTry(error.UnexpectedNull);

        t.compTry(std.testing.expectEqualStrings("key1", next1[0]));
        t.compTry(std.testing.expectEqual(1, next1[1]));

        const peek3 = iterator.peek() orelse
            t.compTry(error.UnexpectedNull);

        t.compTry(std.testing.expectEqualStrings("key2", peek3[0]));
        t.compTry(std.testing.expectEqual(2, peek3[1]));

        const next2 = iterator.next() orelse
            t.compTry(error.UnexpectedNull);

        t.compTry(std.testing.expectEqualStrings("key2", next2[0]));
        t.compTry(std.testing.expectEqual(2, next2[1]));

        t.compTry(std.testing.expectEqual(null, iterator.peek()));
        t.compTry(std.testing.expectEqual(null, iterator.next()));
    }
}

test iterateKeys {
    comptime {
        const dict = Dict.from(.{ .key1 = 1, .key2 = 2 });
        var iterator = dict.iterateKeys();

        const peek1 = iterator.peek() orelse
            t.compTry(error.UnexpectedNull);

        t.compTry(std.testing.expectEqualStrings("key1", peek1));

        const peek2 = iterator.peek() orelse
            t.compTry(error.UnexpectedNull);

        t.compTry(std.testing.expectEqualStrings("key1", peek2));

        const next1 = iterator.next() orelse
            t.compTry(error.UnexpectedNull);

        t.compTry(std.testing.expectEqualStrings("key1", next1));

        const peek3 = iterator.peek() orelse
            t.compTry(error.UnexpectedNull);

        t.compTry(std.testing.expectEqualStrings("key2", peek3));

        const next2 = iterator.next() orelse
            t.compTry(error.UnexpectedNull);

        t.compTry(std.testing.expectEqualStrings("key2", next2));

        t.compTry(std.testing.expectEqual(null, iterator.peek()));
        t.compTry(std.testing.expectEqual(null, iterator.next()));
    }
}

test iterateValues {
    comptime {
        const dict = Dict.from(.{ .key1 = 1, .key2 = 2 });
        var iterator = dict.iterateValues();

        const peek1 = iterator.peek() orelse
            t.compTry(error.UnexpectedNull);

        t.compTry(std.testing.expectEqual(1, peek1));

        const peek2 = iterator.peek() orelse
            t.compTry(error.UnexpectedNull);

        t.compTry(std.testing.expectEqual(1, peek2));

        const next1 = iterator.next() orelse
            t.compTry(error.UnexpectedNull);

        t.compTry(std.testing.expectEqual(1, next1));

        const peek3 = iterator.peek() orelse
            t.compTry(error.UnexpectedNull);

        t.compTry(std.testing.expectEqual(2, peek3));

        const next2 = iterator.next() orelse
            t.compTry(error.UnexpectedNull);

        t.compTry(std.testing.expectEqual(2, next2));

        t.compTry(std.testing.expectEqual(null, iterator.peek()));
        t.compTry(std.testing.expectEqual(null, iterator.next()));
    }
}

inline fn intoString(comptime any: anytype) []const u8 {
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

    t.compileError("Can't convert `{s}` into a string!", .{@typeName(Any)});
}

inline fn info(comptime dict: Dict) std.builtin.Type.Struct {
    return @typeInfo(dict.inner).Struct;
}

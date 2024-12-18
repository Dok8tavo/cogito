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

backing_struct: type = compat.TypeFrom(.{ .@"struct" = .{} }),

const compat = @import("compat.zig");
const std = @import("std");
const t = @import("testing.zig");

const KeyValue = compat.Type.Struct.Field;
const Dict = @This();

pub inline fn from(kv_struct: anytype) Dict {
    const KVStruct = @TypeOf(kv_struct);
    const kv_info = compat.typeInfo(KVStruct);

    var kv_struct_info = switch (kv_info) {
        .@"struct" => |@"struct"| @"struct",
        else => t.compileError(
            "A dict must be made from a `struct`, not a `.{s}` like `{s}`!",
            .{ @tagName(kv_info.intoStd()), @typeName(KVStruct) },
        ),
    };

    if (kv_struct_info.is_tuple) t.compileError(
        "A dict must be made from a `struct`, not a tuple like `{s}`!",
        .{@typeName(KVStruct)},
    );

    var fields: []const KeyValue = &.{};
    for (kv_struct_info.fields) |field| {
        fields = fields ++ &[_]KeyValue{.{
            .default_value = @ptrCast(&@field(kv_struct, field.name)),
            .is_comptime = true,
            .name = field.name,
            .type = field.type,
        }};
    }

    kv_struct_info.fields = fields;

    return Dict{ .backing_struct = compat.TypeFrom(kv_info) };
}

pub inline fn size(dict: Dict) usize {
    return dict.info().fields.len;
}

// == Accessing items ==
pub inline fn has(dict: Dict, key: anytype) bool {
    return @hasField(dict.backing_struct, intoString(key));
}

pub inline fn Get(dict: anytype, key: anytype) type {
    return if (dict.has(key))
        @TypeOf(@field(dict.backing_struct{}, intoString(key)))
    else
        t.NoReturn;
}

pub inline fn get(dict: Dict, key: anytype) ?Get(dict, key) {
    return if (dict.has(key)) @field(dict.backing_struct{}, intoString(key)) else null;
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
    var @"struct" = dict.info();
    @"struct".fields = dict.info().fields ++ &[_]KeyValue{.{
        .name = intoString(key),
        .default_value = @ptrCast(&value),
        .is_comptime = true,
        .type = Value,
    }};

    dict.backing_struct = compat.TypeFrom(.{ .@"struct" = @"struct" });
}

// == Removing items ==
pub const RemoveError = error{KeyDoesNotExist};

pub inline fn remove(dict: *Dict, key: anytype) void {
    var @"struct" = dict.info();
    const new_length = dict.size() - 1;
    for (0..new_length) |index| {
        if (std.mem.eql(u8, @"struct".fields[index].name, intoString(key))) {
            @"struct".fields = dict.info().fields[0..index] ++ dict.info().fields[index + 1 ..];
            break;
        }
    } else @"struct".fields = dict.info().fields[0..new_length];

    dict.backing_struct = compat.TypeFrom(.{ .@"struct" = @"struct" });
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
    return @field(dict.backing_struct{}, intoString(key));
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

// == Setting items ==
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

    pub inline fn peek(iterator: KeyIterator) ?[]const u8 {
        return if (iterator.dict.size() <= iterator.index)
            null
        else
            iterator.dict.info().fields[iterator.index].name;
    }

    pub inline fn next(iterator: *KeyIterator) ?[]const u8 {
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
            struct { []const u8, iterator.dict.info().fields[iterator.index].type };
    }

    pub inline fn peek(iterator: Iterator) ?Peek(iterator) {
        if (iterator.dict.size() <= iterator.index) return null;

        const key = iterator.dict.info().fields[iterator.index].name;
        return .{ key, @field((iterator.dict.backing_struct{}), key) };
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
        t.comptryEqualStrings("value", @field(dict.backing_struct{}, "key"));
    }
}

test addOrError {
    comptime {
        var dict = Dict.from(.{ .key1 = 1 });
        const add_key1 = dict.addOrError(.key1, 2); // this is an error
        const add_key2 = dict.addOrError(.key2, 3); // this isn't

        t.comptry(std.testing.expectError(AddError.KeyAlreadyExists, add_key1));
        t.comptry(std.testing.expectEqual(void{}, add_key2));

        t.comptry(std.testing.expectEqual(1, (dict.backing_struct{}).key1));
        t.comptry(std.testing.expectEqual(3, (dict.backing_struct{}).key2));
    }
}

test addOrLeave {
    comptime {
        var dict = Dict.from(.{ .key1 = 1 });
        dict.addOrLeave(.key1, 2); // does nothing
        dict.addOrLeave(.key2, 3);

        t.comptry(std.testing.expectEqual(1, (dict.backing_struct{}).key1));
        t.comptry(std.testing.expectEqual(3, (dict.backing_struct{}).key2));
    }
}

test addOrReplace {
    comptime {
        var dict = Dict.from(.{ .key = 1 });
        dict.addOrReplace(.key, 2);
        dict.addOrReplace(.not_key, 3);

        t.comptry(std.testing.expectEqual(2, (dict.backing_struct{}).key));
        t.comptry(std.testing.expectEqual(3, (dict.backing_struct{}).not_key));
    }
}

test remove {
    comptime {
        var dict = Dict.from(.{ .key = 1 });

        t.comptry(@hasField(dict.backing_struct, "key"));
        dict.remove(.key);
        t.comptry(!@hasField(dict.backing_struct, "key"));
    }
}

test removeOrError {
    comptime {
        var dict = Dict.from(.{ .key = 1 });

        t.comptry(@hasField(dict.backing_struct, "key"));
        t.comptry(!@hasField(dict.backing_struct, "not_key"));

        const remove_key = dict.removeOrError(.key);
        const remove_not_key = dict.removeOrError(.not_key);

        t.comptry(!@hasField(dict.backing_struct, "key"));
        t.comptry(!@hasField(dict.backing_struct, "not_key"));

        t.comptry(std.testing.expectEqual(void{}, remove_key));
        t.comptry(std.testing.expectError(RemoveError.KeyDoesNotExist, remove_not_key));
    }
}

test removeOrLeave {
    comptime {
        var dict = Dict.from(.{ .key = 1 });

        t.comptry(@hasField(dict.backing_struct, "key"));
        t.comptry(!@hasField(dict.backing_struct, "not_key"));

        dict.removeOrLeave(.key);
        dict.removeOrLeave(.not_key);

        t.comptry(!@hasField(dict.backing_struct, "key"));
        t.comptry(!@hasField(dict.backing_struct, "not_key"));
    }
}

test set {
    comptime {
        var dict = Dict.from(.{ .key = 1 });

        t.comptry(std.testing.expectEqual(1, (dict.backing_struct{}).key));
        dict.set(.key, "not even a `comptime_int`");
        t.comptryEqualStrings("not even a `comptime_int`", (dict.backing_struct{}).key);
    }
}

test setOrError {
    comptime {
        var dict = Dict.from(.{ .key = 1 });

        t.comptry(std.testing.expectEqual(1, (dict.backing_struct{}).key));
        t.comptry(!@hasField(dict.backing_struct, "not_key"));

        const set_key = dict.setOrError(.key, 2);
        const set_not_key = dict.setOrError(.not_key, 2);

        t.comptry(std.testing.expectEqual(2, (dict.backing_struct{}).key));
        t.comptry(!@hasField(dict.backing_struct, "not_key"));

        t.comptry(std.testing.expectEqual(void{}, set_key));
        t.comptry(std.testing.expectError(RemoveError.KeyDoesNotExist, set_not_key));
    }
}

test setOrLeave {
    comptime {
        var dict = Dict.from(.{ .key = 1 });

        t.comptry(std.testing.expectEqual(1, (dict.backing_struct{}).key));
        t.comptry(!@hasField(dict.backing_struct, "not_key"));

        dict.setOrLeave(.key, 2);
        dict.setOrLeave(.not_key, 2);

        t.comptry(std.testing.expectEqual(2, (dict.backing_struct{}).key));
        t.comptry(!@hasField(dict.backing_struct, "not_key"));
    }
}

test has {
    comptime {
        var dict = Dict.from(.{ .key = 1 });
        t.comptry(dict.has(.key));
        t.comptry(!dict.has(.not_key));
    }
}

test Get {
    comptime {
        const dict = Dict.from(.{ .key = 1 });
        t.comptry(std.testing.expectEqual(comptime_int, Dict.Get(dict, .key)));
        t.comptry(std.testing.expectEqual(t.NoReturn, Dict.Get(dict, .not_key)));
    }
}

test get {
    comptime {
        const dict = Dict.from(.{ .key = 1 });
        t.comptry(std.testing.expectEqual(1, dict.get(.key)));
        t.comptry(std.testing.expectEqual(null, dict.get(.not_key)));
    }
}

test pop {
    comptime {
        var dict = Dict.from(.{ .key = 1 });
        t.comptry(std.testing.expectEqual(1, dict.pop(.key)));
        t.comptry(!dict.has(.key));
    }
}

test popOrError {
    comptime {
        var dict = Dict.from(.{ .key = 1 });
        t.comptry(std.testing.expectEqual(1, dict.popOrError(.key)));
        t.comptry(std.testing.expectError(RemoveError.KeyDoesNotExist, dict.popOrError(.key)));
    }
}

test popOrLeave {
    comptime {
        var dict = Dict.from(.{ .key = 1 });
        t.comptry(dict.has(.key));

        const pop1 = dict.popOrLeave(.key);
        t.comptry(!dict.has(.key));

        const pop2 = dict.popOrLeave(.key);
        t.comptry(!dict.has(.key));

        t.comptry(std.testing.expectEqual(1, pop1));
        t.comptry(std.testing.expectEqual(null, pop2));
    }
}

test iterate {
    comptime {
        const dict = Dict.from(.{ .key1 = 1, .key2 = 2 });
        var iterator = dict.iterate();

        const peek1 = iterator.peek() orelse
            t.comptry(error.UnexpectedNull);

        t.comptryEqualStrings("key1", peek1[0]);
        t.comptry(std.testing.expectEqual(1, peek1[1]));

        const peek2 = iterator.peek() orelse
            t.comptry(error.UnexpectedNull);

        t.comptryEqualStrings("key1", peek2[0]);
        t.comptry(std.testing.expectEqual(1, peek2[1]));

        const next1 = iterator.next() orelse
            t.comptry(error.UnexpectedNull);

        t.comptryEqualStrings("key1", next1[0]);
        t.comptry(std.testing.expectEqual(1, next1[1]));

        const peek3 = iterator.peek() orelse
            t.comptry(error.UnexpectedNull);

        t.comptryEqualStrings("key2", peek3[0]);
        t.comptry(std.testing.expectEqual(2, peek3[1]));

        const next2 = iterator.next() orelse
            t.comptry(error.UnexpectedNull);

        t.comptryEqualStrings("key2", next2[0]);
        t.comptry(std.testing.expectEqual(2, next2[1]));

        t.comptry(std.testing.expectEqual(null, iterator.peek()));
        t.comptry(std.testing.expectEqual(null, iterator.next()));
    }
}

test iterateKeys {
    comptime {
        const dict = Dict.from(.{ .key1 = 1, .key2 = 2 });
        var iterator = dict.iterateKeys();

        const peek1 = iterator.peek() orelse
            t.comptry(error.UnexpectedNull);

        t.comptryEqualStrings("key1", peek1);

        const peek2 = iterator.peek() orelse
            t.comptry(error.UnexpectedNull);

        t.comptryEqualStrings("key1", peek2);

        const next1 = iterator.next() orelse
            t.comptry(error.UnexpectedNull);

        t.comptryEqualStrings("key1", next1);

        const peek3 = iterator.peek() orelse
            t.comptry(error.UnexpectedNull);

        t.comptryEqualStrings("key2", peek3);

        const next2 = iterator.next() orelse
            t.comptry(error.UnexpectedNull);

        t.comptryEqualStrings("key2", next2);

        t.comptry(std.testing.expectEqual(null, iterator.peek()));
        t.comptry(std.testing.expectEqual(null, iterator.next()));
    }
}

test iterateValues {
    comptime {
        const dict = Dict.from(.{ .key1 = 1, .key2 = 2 });
        var iterator = dict.iterateValues();

        const peek1 = iterator.peek() orelse
            t.comptry(error.UnexpectedNull);

        t.comptry(std.testing.expectEqual(1, peek1));

        const peek2 = iterator.peek() orelse
            t.comptry(error.UnexpectedNull);

        t.comptry(std.testing.expectEqual(1, peek2));

        const next1 = iterator.next() orelse
            t.comptry(error.UnexpectedNull);

        t.comptry(std.testing.expectEqual(1, next1));

        const peek3 = iterator.peek() orelse
            t.comptry(error.UnexpectedNull);

        t.comptry(std.testing.expectEqual(2, peek3));

        const next2 = iterator.next() orelse
            t.comptry(error.UnexpectedNull);

        t.comptry(std.testing.expectEqual(2, next2));

        t.comptry(std.testing.expectEqual(null, iterator.peek()));
        t.comptry(std.testing.expectEqual(null, iterator.next()));
    }
}

inline fn intoString(comptime any: anytype) []const u8 {
    const Any = @TypeOf(any);
    switch (Any) {
        []const u8, []u8, [:0]const u8, [:0]u8 => return any,
        @TypeOf(.enum_literal) => return @tagName(any),
        else => if (compat.typeInfo(Any) == .pointer_info) {
            const pointer_info = compat.typeInfo(Any).pointer;
            if (pointer_info.size == .One) {
                const child_info = compat.typeInfo(pointer_info.child);
                if (child_info == .array_info and child_info.array.child == u8)
                    return any;
            }
        },
    }

    t.compileError("Can't convert `{s}` into a string!", .{@typeName(Any)});
}

inline fn info(comptime dict: Dict) compat.Type.Struct {
    return compat.typeInfo(dict.backing_struct).@"struct";
}

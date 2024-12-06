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
    var kv_info = @typeInfo(KVStruct);

    if (kv_info != .Struct) root.compileError(
        "A map must be made from a `.Struct`, not a `.{s}` like `{s}`!",
        .{ @tagName(kv_info), @typeName(KVStruct) },
    );

    if (kv_info.Struct.is_tuple) root.compileError(
        "A map must be made from a struct, not a tuple like `{s}`!",
        .{@typeName(KVStruct)},
    );

    var fields: []const KeyValue = &.{};
    for (kv_info.Struct.fields) |field| {
        fields = fields ++ &[_]KeyValue{.{
            .alignment = field.alignment,
            .default_value = @ptrCast(&@field(kv_struct, field.name)),
            .is_comptime = true,
            .name = field.name,
            .type = field.type,
        }};
    }

    kv_info.Struct.fields = fields;

    return Map{ .type = @Type(kv_info) };
}

// == Accessing items ==
pub fn has(comptime map: Map, comptime key: []const u8) bool {
    return @hasField(map.type, key);
}

pub fn Get(comptime map: Map, comptime key: [:0]const u8) type {
    return if (map.has(key))
        @TypeOf(@field(map.type{}, key))
    else
        @Type(.NoReturn);
}

pub fn get(comptime map: Map, comptime key: [:0]const u8) ?Get(map, key) {
    return if (map.has(key)) @field(map.type{}, key) else null;
}

// == Adding items ==
pub const AddError = error{
    KeyAlreadyExists,
};

pub fn addOrErr(
    comptime map: *Map,
    comptime key: []const u8,
    comptime value: anytype,
) AddError!void {
    if (map.has(key))
        return AddError.KeyAlreadyExists;
    map.add(key, value);
}

pub fn addOrLeave(
    comptime map: *Map,
    comptime key: []const u8,
    comptime value: anytype,
) void {
    if (!map.has(key))
        map.add(key, value);
}

pub fn addOrReplace(
    comptime map: *Map,
    comptime key: []const u8,
    comptime value: anytype,
) void {
    if (map.has(key))
        map.remove(key);
    map.add(key, value);
}

pub fn add(
    comptime map: *Map,
    comptime key: []const u8,
    comptime value: anytype,
) void {
    const Value = @TypeOf(value);
    var struct_info = map.info();
    struct_info.fields = map.info().fields ++ &[_]KeyValue{.{
        .alignment = @alignOf(Value),
        .name = key ++ "\x00",
        .default_value = @ptrCast(&value),
        .is_comptime = true,
        .type = Value,
    }};

    map.type = @Type(.{ .Struct = struct_info });
}

// == Removing items ==
const RemoveError = error{
    KeyDoesNotExist,
};

pub fn remove(comptime map: *Map, comptime key: []const u8) void {
    var struct_info = map.info();
    const new_length = map.length() - 1;
    for (0..new_length) |index| {
        if (std.mem.eql(u8, struct_info.fields[index].name, key)) {
            struct_info.fields = map.info().fields[0..index] ++ map.info().fields[index + 1 ..];
            break;
        }
    } else struct_info.fields = map.info().fields[0..new_length];

    map.type = @Type(.{ .Struct = struct_info });
}

pub fn removeOrErr(comptime map: *Map, comptime key: []const u8) RemoveError!void {
    if (!map.has(key))
        return RemoveError.KeyDoesNotExist;
    map.remove(key);
}

pub fn removeOrLeave(comptime map: *Map, comptime key: []const u8) void {
    if (map.has(key))
        map.remove(key);
}

// == Replacing items ==
pub fn replace(
    comptime map: *Map,
    comptime key: []const u8,
    comptime value: anytype,
) void {
    map.remove(key);
    map.add(key, value);
}

pub fn replaceOrErr(
    comptime map: *Map,
    comptime key: []const u8,
    comptime value: anytype,
) RemoveError!void {
    if (!map.has(key))
        return RemoveError.KeyDoesNotExist;
    map.replace(key, value);
}

pub fn replaceOrLeave(
    comptime map: *Map,
    comptime key: []const u8,
    comptime value: anytype,
) void {
    if (map.has(key))
        map.replace(key, value);
}

// == inner functions ==
fn length(comptime map: Map) usize {
    return map.info().fields.len;
}

fn info(comptime map: Map) std.builtin.Type.Struct {
    return @typeInfo(map.type).Struct;
}

// == Testing ==
test add {
    comptime {
        var map = Map{};
        map.add("key", "value");
        try std.testing.expectEqualStrings("value", @field(map.type{}, "key"));
    }
}

test addOrErr {
    comptime {
        var map = Map.from(.{ .key1 = 1 });
        const add_key1 = map.addOrErr("key1", 2); // this is an error
        const add_key2 = map.addOrErr("key2", 3); // this isn't

        try std.testing.expectError(AddError.KeyAlreadyExists, add_key1);
        try std.testing.expectEqual(void{}, add_key2);

        try std.testing.expectEqual(1, (map.type{}).key1);
        try std.testing.expectEqual(3, (map.type{}).key2);
    }
}

test addOrLeave {
    comptime {
        var map = Map.from(.{ .key1 = 1 });
        map.addOrLeave("key1", 2); // does nothing
        map.addOrLeave("key2", 3);

        try std.testing.expectEqual(1, (map.type{}).key1);
        try std.testing.expectEqual(3, (map.type{}).key2);
    }
}

test remove {
    comptime {
        var map = Map.from(.{ .key = 1 });

        try std.testing.expect(@hasField(map.type, "key"));
        map.remove("key");
        try std.testing.expect(!@hasField(map.type, "key"));
    }
}

test removeOrErr {
    comptime {
        var map = Map.from(.{ .key = 1 });

        try std.testing.expect(@hasField(map.type, "key"));
        try std.testing.expect(!@hasField(map.type, "not_key"));

        const remove_key = map.removeOrErr("key");
        const remove_not_key = map.removeOrErr("not_key");

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

        map.removeOrLeave("key");
        map.removeOrLeave("not_key");

        try std.testing.expect(!@hasField(map.type, "key"));
        try std.testing.expect(!@hasField(map.type, "not_key"));
    }
}

test replace {
    comptime {
        var map = Map.from(.{ .key = 1 });

        try std.testing.expectEqual(1, (map.type{}).key);
        map.replace("key", "not even a `comptime_int`");
        try std.testing.expectEqualStrings("not even a `comptime_int`", (map.type{}).key);
    }
}

test has {
    comptime {
        var map = Map.from(.{ .key = 1 });
        try std.testing.expect(map.has("key"));
        try std.testing.expect(!map.has("not_key"));
    }
}

test Get {
    comptime {
        const map = Map.from(.{ .key = 1 });
        try std.testing.expectEqual(comptime_int, Map.Get(map, "key"));
        try std.testing.expectEqual(noreturn, Map.Get(map, "not_key"));
    }
}

test get {
    comptime {
        const map = Map.from(.{ .key = 1 });
        try std.testing.expectEqual(1, map.get("key"));
        try std.testing.expectEqual(null, map.get("not_key"));
    }
}

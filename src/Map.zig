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

pub fn from(comptime from_struct: anytype) Map {
    const FromStruct = @TypeOf(from_struct);
    var struct_info = @typeInfo(FromStruct);

    if (struct_info != .Struct) root.compileError(
        "A map must be made from a `.Struct`, not a `.{s}` like `{s}`!",
        .{ @tagName(struct_info), @typeName(FromStruct) },
    );

    if (struct_info.Struct.is_tuple) root.compileError(
        "A map must be made from a struct, not a tuple like `{s}`!",
        .{@typeName(FromStruct)},
    );

    var fields: []const KeyValue = &.{};
    for (struct_info.Struct.fields) |field| {
        fields = fields ++ &[_]KeyValue{.{
            .alignment = field.alignment,
            .default_value = @ptrCast(&@field(from_struct, field.name)),
            .is_comptime = true,
            .name = field.name,
            .type = field.type,
        }};
    }

    struct_info.Struct.fields = fields;

    return Map{ .type = @Type(struct_info) };
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

// == Adding multiple items ==
pub fn concatMap(comptime map: *Map, comptime other_map: Map) void {
    var map_info = map.info();
    const other_map_info = other_map.info();
    map_info.fields = map_info.fields ++ other_map_info.fields;
    map.type = @Type(.{ .Struct = map_info });
}

pub fn concatMapOrErr(comptime map: *Map, comptime other_map: Map) AddError!void {
    for (other_map.info().fields) |field| if (map.has(field.name))
        return AddError.KeyAlreadyExists;
    map.concatMap(other_map);
}

pub fn concatMapOrLeave(comptime map: *Map, comptime other_map: Map) AddError!void {
    for (other_map.info().fields) |field| if (!map.has(field.name))
        map.addOrLeave(field.name, @as(*const field.type, @ptrCast(field.default_value)).*);
}

pub fn concat(comptime map: *Map, comptime items: anytype) void {
    return map.concatMap(Map.from(items));
}

pub fn concatOrErr(comptime map: *Map, comptime items: anytype) AddError!void {
    return map.concatMapOrErr(Map.from(items));
}

pub fn concatOrLeave(comptime map: *Map, comptime items: anytype) void {
    return map.concatMapOrLeave(Map.from(items));
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

test add {
    comptime {
        var map = Map{};
        map.add("key", "value");
        try std.testing.expectEqualStrings("value", @field(map.type{}, "key"));
    }
}

test addOrErr {
    comptime {
        var map = Map.from(.{ .key = 1 });
        try std.testing.expectError(
            AddError.KeyAlreadyExists,
            map.addOrErr("key", 2),
        );

        try std.testing.expectEqual(
            1,
            @field(map.type{}, "key"),
        );

        try map.addOrErr("key2", 2);

        try std.testing.expectEqual(
            2,
            @field(map.type{}, "key2"),
        );
    }
}
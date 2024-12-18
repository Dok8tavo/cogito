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

info: StructInfo = .{},

const compat = @import("compat.zig");
const std = @import("std");
const t = @import("testing.zig");

const FieldInfo = StructInfo.Field;
const Layout = compat.Type.Layout;
const StructGen = @This();
const StructInfo = compat.Type.Struct;

pub inline fn Type(gen: StructGen) type {
    return compat.TypeFrom(.{ .@"struct" = gen.info });
}

pub inline fn from(any_struct: anytype) StructGen {
    const AnyStruct = @TypeOf(any_struct);
    if (StructGen == AnyStruct)
        return any_struct;
    if (compat.Type.Struct == AnyStruct)
        return StructGen{ .info = any_struct };
    if (compat.Type == AnyStruct) return switch (any_struct) {
        .@"struct" => |@"struct"| StructGen{ .info = @"struct" },
        else => t.compileError("Expected `.struct`, got `.{s}` instead!", .{@tagName(any_struct)}),
    };

    // compat.Type
    if (AnyStruct == type) {
        const info = compat.typeInfo(any_struct);
        return StructGen.from(info);
    }
    // compat.Type
    if (AnyStruct == std.builtin.Type)
        return StructGen.from(compat.Type.fromStd(any_struct));
    // compat.Type.Struct
    if (AnyStruct == std.builtin.Type.Struct)
        return StructGen.from(compat.Type.Struct.fromStd(any_struct));

    const info = compat.typeInfo(AnyStruct);
    return StructGen.from(info);
}

// == Layout ==
pub inline fn setLayout(gen: *StructGen, layout: Layout) void {
    gen.info.layout = layout;
}

pub inline fn getLayout(gen: StructGen) Layout {
    return gen.info.layout;
}

// == Backing integer ==
pub inline fn setBackingInteger(gen: *StructGen, backing_integer: ?type) void {
    gen.info.backing_integer = backing_integer;
}

pub inline fn getBackingInteger(gen: StructGen) ?type {
    return gen.info.backing_integer;
}

// == Add field ==
pub const AddError = error{FieldAlreadyExists};
pub inline fn addField(gen: *StructGen, field: FieldInfo) void {
    gen.info.fields = gen.info.fields ++ &[_]FieldInfo{field};
}

pub inline fn addFieldOrError(gen: *StructGen, field: FieldInfo) AddError!void {
    for (0..gen.info.fields.len) |index|
        if (t.comptimeEqualStrings(field.name, gen.info.fields[index].name))
            return AddError.FieldAlreadyExists;
    gen.addField(field);
}

pub inline fn addOrSetField(gen: *StructGen, field: FieldInfo) void {
    gen.addFieldOrError(field) catch gen.setField(field.name, field);
}

pub inline fn addOrLeaveField(gen: *StructGen, field: FieldInfo) void {
    gen.addFieldOrError(field) catch {};
}

// == Remove field ==
pub const RemoveError = error{FieldDoesNotExist};
pub inline fn removeFieldOrError(gen: *StructGen, field_name: []const u8) RemoveError!void {
    const index = for (0..gen.info.fields.len) |index| {
        if (t.comptimeEqualStrings(field_name, gen.info.fields[index].name))
            break index;
    } else return RemoveError.FieldDoesNotExist;

    var new_fields: []const FieldInfo = if (index != 0) gen.info.fields[0..index] else &.{};

    if (index + 1 != gen.info.fields.len)
        new_fields = new_fields ++ gen.info.fields[index + 1 ..];

    gen.info.fields = new_fields;
}

pub inline fn removeField(gen: *StructGen, field_name: []const u8) void {
    t.comptry(gen.removeFieldOrError(field_name));
}

// == Access field ==
pub inline fn hasField(gen: StructGen, field_name: []const u8) bool {
    return for (0..gen.info.fields.len) |index| {
        if (t.comptimeEqualStrings(field_name, gen.info.fields[index].name))
            break true;
    } else false;
}

pub inline fn getField(gen: *StructGen, field_name: []const u8) ?FieldInfo {
    return for (0..gen.info.fields.len) |index| {
        if (t.comptimeEqualStrings(field_name, gen.info.fields[index].name))
            break gen.info.fields[index];
    } else null;
}

pub inline fn setField(gen: *StructGen, field_name: []const u8, new: anytype) void {
    for (0..gen.info.fields.len) |index| {
        if (t.comptimeEqualStrings(field_name, gen.info.fields[index].name)) {
            const New = @TypeOf(new);
            var new_field = gen.info.fields[index];
            if (@hasField(New, "alignment"))
                new_field.alignment = new.alignment;
            if (@hasField(New, "default_value"))
                new_field.default_value = new.default_value;
            if (@hasField(New, "is_comptime"))
                new_field.is_comptime = new.is_comptime;
            if (@hasField(New, "name"))
                new_field.name = new.name;
            if (@hasField(New, "type"))
                new_field.type = new.type;
            var new_fields: []const FieldInfo =
                if (index != 0) gen.info.fields[0..index] else &.{};

            new_fields = new_fields ++ &[_]FieldInfo{new_field};

            if (index + 1 != gen.info.fields.len)
                new_fields = new_fields ++ gen.info.fields[index + 1 ..];

            gen.info.fields = new_fields;
            return;
        }
    } else t.compileError("Couldn't find field named `{s}`!", .{field_name});
}

// == Ordering fields ==
inline fn hasBiggerAlignement(a: FieldInfo, b: FieldInfo) bool {
    const a_alignment = a.alignment orelse @alignOf(a.type);
    const b_alignment = b.alignment orelse @alignOf(b.type);
    return b_alignment < a_alignment;
}
inline fn hasBiggerSize(a: FieldInfo, b: FieldInfo) bool {
    const a_size = @bitSizeOf(a.type);
    const b_size = @bitSizeOf(b.type);
    return b_size < a_size;
}
pub inline fn hasBiggerAlignementOrSize(a: FieldInfo, b: FieldInfo) bool {
    return hasBiggerAlignement(a, b) or hasBiggerSize(a, b);
}

pub inline fn sortFieldsByIsFirst(gen: *StructGen, isFirst: fn (FieldInfo, FieldInfo) bool) void {
    const sort = struct {
        pub fn call(fields: []const FieldInfo) ?usize {
            if (fields.len == 0) return null;
            if (fields.len == 1) return 0;
            var first_index: usize = 0;
            for (fields[1..], 1..) |field, index| {
                const first_field = fields[first_index];
                if (isFirst(field, first_field))
                    first_index = index;
            }

            return first_index;
        }
    };

    return gen.sortFieldsByFirstIn(sort.call);
}

pub inline fn sortFieldsByFirstIn(gen: *StructGen, first: fn ([]const FieldInfo) ?usize) void {
    const sort = struct {
        pub fn call(fields: []const FieldInfo) []const FieldInfo {
            if (fields.len == 0 or fields.len == 1) return fields;
            var sorted: [fields.len]FieldInfo = @as(*const [fields.len]FieldInfo, @ptrCast(fields)).*;
            for (0..fields.len) |index| {
                const first_index = first(sorted[index..]).?;
                std.mem.swap(FieldInfo, &sorted[index], &sorted[index + first_index]);
            }
            return &sorted;
        }
    };

    return gen.sortFields(sort.call);
}

pub inline fn sortFields(gen: *StructGen, sort: fn ([]const FieldInfo) []const FieldInfo) void {
    gen.info.fields = sort(gen.info.fields);
}

// == Testing ==
test addOrLeaveField {
    comptime {
        var struct_gen = StructGen{};
        t.comptry(!struct_gen.hasField("a"));

        struct_gen.addOrLeaveField(.{ .name = "a", .type = void });
        t.comptry(struct_gen.hasField("a"));
        t.comptry(struct_gen.getField("a").?.type == void);

        struct_gen.addOrLeaveField(.{ .name = "a", .type = u8 });
        t.comptry(struct_gen.hasField("a"));
        t.comptry(struct_gen.getField("a").?.type == void);
    }
}

test from {
    comptime {
        const Abc = struct {
            a: u1 = 0,
            b: u2 = 0,
            c: u3 = 0,
        };

        const abc = Abc{};

        const abc_info = compat.typeInfo(Abc);
        const abc_std_info = @typeInfo(Abc);

        const abc_struct_info = abc_info.@"struct";
        const abc_std_struct_info = if (@hasField(std.builtin.Type, "Struct"))
            abc_std_info.Struct
        else
            abc_std_info.@"struct";

        const gen_type = StructGen.from(Abc);
        const gen_instance = StructGen.from(abc);
        const gen_info = StructGen.from(abc_info);
        const gen_std_info = StructGen.from(abc_std_info);
        const gen_struct_info = StructGen.from(abc_struct_info);
        const gen_std_struct_info = StructGen.from(abc_std_struct_info);

        t.comptry(gen_type.hasField("a"));
        t.comptry(gen_type.hasField("b"));
        t.comptry(gen_type.hasField("c"));

        t.comptry(gen_instance.hasField("a"));
        t.comptry(gen_instance.hasField("b"));
        t.comptry(gen_instance.hasField("c"));

        t.comptry(gen_info.hasField("a"));
        t.comptry(gen_info.hasField("b"));
        t.comptry(gen_info.hasField("c"));

        t.comptry(gen_std_info.hasField("a"));
        t.comptry(gen_std_info.hasField("b"));
        t.comptry(gen_std_info.hasField("c"));

        t.comptry(gen_struct_info.hasField("a"));
        t.comptry(gen_struct_info.hasField("b"));
        t.comptry(gen_struct_info.hasField("c"));

        t.comptry(gen_std_struct_info.hasField("a"));
        t.comptry(gen_std_struct_info.hasField("b"));
        t.comptry(gen_std_struct_info.hasField("c"));
    }
}

test sortFields {
    const alphabetical = struct {
        fn isFirst(field_a: FieldInfo, field_b: FieldInfo) bool {
            const a = field_a.name;
            const b = field_b.name;
            const min = @min(a.len, b.len);
            return for (a[0..min], b[0..min]) |c, d| {
                if (c < d) break true;
                if (d < c) break false;
            } else a.len < b.len;
        }
    };

    comptime {
        var struct_gen = StructGen{};
        struct_gen.addField(.{ .name = "e", .type = void });
        struct_gen.addField(.{ .name = "d", .type = void });
        struct_gen.addField(.{ .name = "c", .type = void });
        struct_gen.addField(.{ .name = "b", .type = void });
        struct_gen.addField(.{ .name = "a", .type = void });

        t.comptryEqualStrings(struct_gen.info.fields[0].name, "e");
        t.comptryEqualStrings(struct_gen.info.fields[1].name, "d");
        t.comptryEqualStrings(struct_gen.info.fields[2].name, "c");
        t.comptryEqualStrings(struct_gen.info.fields[3].name, "b");
        t.comptryEqualStrings(struct_gen.info.fields[4].name, "a");

        struct_gen.sortFieldsByIsFirst(alphabetical.isFirst);

        t.comptryEqualStrings(struct_gen.info.fields[0].name, "a");
        t.comptryEqualStrings(struct_gen.info.fields[1].name, "b");
        t.comptryEqualStrings(struct_gen.info.fields[2].name, "c");
        t.comptryEqualStrings(struct_gen.info.fields[3].name, "d");
        t.comptryEqualStrings(struct_gen.info.fields[4].name, "e");
    }
}

test removeFieldOrError {
    comptime {
        var struct_gen = StructGen{};
        struct_gen.addField(.{ .name = "my field", .type = bool });
        t.comptry(struct_gen.removeFieldOrError("my field"));
        t.comptry(struct_gen.removeFieldOrError("my other field") == RemoveError.FieldDoesNotExist);
    }
}

test removeField {
    comptime {
        var struct_gen = StructGen{};
        struct_gen.addField(.{ .name = "my field", .type = bool });
        struct_gen.addField(.{ .name = "my other field", .type = bool });
        t.comptry(struct_gen.hasField("my field"));
        t.comptry(struct_gen.hasField("my other field"));
        struct_gen.removeField("my field");
        t.comptry(!struct_gen.hasField("my field"));
        t.comptry(struct_gen.hasField("my other field"));
    }
}

test hasField {
    comptime {
        var struct_gen = StructGen{};
        struct_gen.addField(.{ .name = "my field", .type = bool });
        t.comptry(struct_gen.hasField("my field"));
        t.comptry(!struct_gen.hasField("my other field"));
        struct_gen.addField(.{ .name = "my other field", .type = bool });
        t.comptry(struct_gen.hasField("my other field"));
    }
}
test addFieldOrError {
    comptime {
        var struct_gen = StructGen{};
        t.comptry(struct_gen.addFieldOrError(.{ .name = "my field", .type = bool }));
        t.comptry(struct_gen.addFieldOrError(.{ .name = "my field", .type = bool }) == AddError.FieldAlreadyExists);
    }
}

test addOrSetField {
    comptime {
        var struct_gen = StructGen{};

        struct_gen.addOrSetField(.{ .name = "my field", .type = bool });
        const MyFieldBool = struct_gen.Type();

        t.comptry(@hasField(MyFieldBool, "my field"));
        t.comptry(@TypeOf(@field(@as(MyFieldBool, undefined), "my field")) == bool);

        struct_gen.addOrSetField(.{ .name = "my field", .type = u8 });
        const MyFieldByte = struct_gen.Type();

        t.comptry(@hasField(MyFieldByte, "my field"));
        t.comptry(@TypeOf(@field(@as(MyFieldByte, undefined), "my field")) == u8);
    }
}

test setField {
    comptime {
        var struct_gen = StructGen{};
        struct_gen.addField(.{ .name = "my field", .type = bool });
        struct_gen.setField("my field", .{ .name = "your field" });

        t.comptry(struct_gen.getField("my field") == null);
        const your_field = t.comptry(struct_gen.getField("your field"));
        t.comptry(bool == your_field.type);
    }
}

test getField {
    comptime {
        var struct_gen = StructGen{};
        struct_gen.addField(.{ .name = "my field", .type = u8 });

        const field: FieldInfo = t.comptry(struct_gen.getField("my field"));
        t.comptry(field.alignment == null);
        t.comptry(field.default_value == null);
        t.comptry(!field.is_comptime);
        t.comptryEqualStrings("my field", field.name);
        t.comptry(field.type == u8);

        t.comptry(struct_gen.getField("not my field") == null);
    }
}

test addField {
    comptime {
        var struct_gen = StructGen{};
        const EmptyStruct = struct_gen.Type();

        struct_gen.addField(.{ .name = "some_field", .type = void });
        const NonEmptyStruct = struct_gen.Type();

        t.comptry(!@hasField(EmptyStruct, "some_field"));
        t.comptry(@hasField(NonEmptyStruct, "some_field"));
    }
}

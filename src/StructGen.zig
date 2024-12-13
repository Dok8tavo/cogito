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
pub inline fn addField(gen: *StructGen, field: FieldInfo) void {
    gen.info.fields = gen.info.fields ++ &[_]FieldInfo{field};
}

pub inline fn getField(gen: *StructGen, field_name: []const u8) ?FieldInfo {
    return for (0..gen.info.fields.len) |index| {
        if (t.comptimeEqualStrings(field_name, gen.info.fields[index].name))
            break gen.info.fields[index];
    } else null;
}

pub inline fn setField(gen: *StructGen, field_name: []const u8, new: anytype) void {
    for (0..gen.info.fields) |index| {
        if (t.comptimeEqualStrings(field_name, gen.info.fields[index].name)) {
            const New = @TypeOf(new);
            if (@hasField(New, "alignment"))
                gen.info.fields[index].alignment = new.alignment;
            if (@hasField(New, "default_value"))
                gen.info.fields[index].default_value = new.default_value;
            if (@hasField(new, "is_comptime"))
                gen.info.fields[index].is_comptime = new.is_comptime;
            if (@hasField(New, "name"))
                gen.info.fields[index].name = new.name;
            if (@hasField(New, "type"))
                gen.info.fields[index].type = new.type;
            return;
        }
    } else t.compileError("Couldn't find field named `{s}`!", .{field_name});
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

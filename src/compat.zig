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

const std = @import("std");
const t = @import("testing.zig");

const StdType = std.builtin.Type;
const EnumLiteral = @TypeOf(.enum_literal);

pub inline fn TypeFrom(info: Type) type {
    return @Type(info.intoStd());
}

pub inline fn typeInfo(T: type) Type {
    return Type.fromStd(@typeInfo(T));
}

pub const Type = union(enum) {
    type: void,
    void: void,
    bool: void,
    noreturn: void,
    int: StdType.Int,
    float: StdType.Float,
    pointer: Pointer,
    array: Array,
    @"struct": Struct,
    comptime_float: void,
    comptime_int: void,
    undefined: void,
    null: void,
    optional: StdType.Optional,
    error_union: StdType.ErrorUnion,
    error_set: StdType.ErrorSet,
    @"enum": Enum,
    @"union": Union,
    @"fn": Fn,
    @"opaque": StdType.Opaque,
    frame: StdType.Frame,
    @"anyframe": StdType.AnyFrame,
    vector: StdType.Vector,
    enum_literal: void,

    pub inline fn fromStd(std_info: StdType) Type {
        return if (isEither(std_info, .{ .type, .Type }))
            .type
        else if (isEither(std_info, .{ .void, .Void }))
            .void
        else if (isEither(std_info, .{ .bool, .Bool }))
            .bool
        else if (isEither(std_info, .{ .noreturn, .NoReturn }))
            .noreturn
        else if (isEither(std_info, .{ .int, .Int })) Type{
            .int = eitherUnionAccess(std_info, .{ .int, .Int }),
        } else if (isEither(std_info, .{ .float, .Float })) Type{
            .float = eitherUnionAccess(std_info, .{ .float, .Float }),
        } else if (isEither(std_info, .{ .pointer, .Pointer })) Type{
            .pointer = Pointer.fromStd(eitherUnionAccess(std_info, .{ .pointer, .Pointer })),
        } else if (isEither(std_info, .{ .array, .Array })) Type{
            .array = Array.fromStd(eitherUnionAccess(std_info, .{ .array, .Array })),
        } else if (isEither(std_info, .{ .@"struct", .Struct })) Type{
            .@"struct" = Struct.fromStd(eitherUnionAccess(std_info, .{ .@"struct", .Struct })),
        } else if (isEither(std_info, .{ .comptime_float, .ComptimeFloat }))
            .comptime_float
        else if (isEither(std_info, .{ .comptime_int, .ComptimeInt }))
            .comptime_int
        else if (isEither(std_info, .{ .undefined, .Undefined }))
            .undefined
        else if (isEither(std_info, .{ .null, .Null }))
            .null
        else if (isEither(std_info, .{ .optional, .Optional })) Type{
            .optional = eitherUnionAccess(std_info, .{ .optional, .Optional }),
        } else if (isEither(std_info, .{ .error_union, .ErrorUnion })) Type{
            .error_union = eitherUnionAccess(std_info, .{ .error_union, .ErrorUnion }),
        } else if (isEither(std_info, .{ .error_set, .ErrorSet })) Type{
            .error_set = eitherUnionAccess(std_info, .{ .error_set, .ErrorSet }),
        } else if (isEither(std_info, .{ .@"enum", .Enum })) Type{
            .@"enum" = Enum.fromStd(eitherUnionAccess(std_info, .{ .@"enum", .Enum })),
        } else if (isEither(std_info, .{ .@"union", .Union })) Type{
            .@"union" = Union.fromStd(eitherUnionAccess(std_info, .{ .@"union", .Union })),
        } else if (isEither(std_info, .{ .@"fn", .Fn })) Type{
            .@"fn" = Fn.fromStd(eitherUnionAccess(std_info, .{ .@"fn", .Fn })),
        } else if (isEither(std_info, .{ .@"opaque", .Opaque })) Type{
            .@"opaque" = eitherUnionAccess(std_info, .{ .@"opaque", .Opaque }),
        } else if (isEither(std_info, .{ .frame, .Frame })) Type{
            .frame = eitherUnionAccess(std_info, .{ .frame, .Frame }),
        } else if (isEither(std_info, .{ .@"anyframe", .AnyFrame })) Type{
            .@"anyframe" = eitherUnionAccess(std_info, .{ .@"anyframe", .AnyFrame }),
        } else if (isEither(std_info, .{ .vector, .Vector })) Type{
            .vector = eitherUnionAccess(std_info, .{ .vector, .Vector }),
        } else //if (isEither(info, &.{ "enum_literal", "EnumLiteral"}))
        .enum_literal;
    }

    pub inline fn intoStd(info: Type) StdType {
        return eitherUnionVariant(StdType, switch (info) {
            .type => .{ .type, .Type },
            .void => .{ .void, .Void },
            .bool => .{ .bool, .Bool },
            .noreturn => .{ .noreturn, .NoReturn },
            .int => .{ .int, .Int },
            .float => .{ .float, .Float },
            .pointer => .{ .pointer, .Pointer },
            .array => .{ .array, .Array },
            .@"struct" => .{ .@"struct", .Struct },
            .comptime_float => .{ .comptime_float, .ComptimeFloat },
            .comptime_int => .{ .comptime_int, .ComptimeInt },
            .undefined => .{ .undefined, .Undefined },
            .null => .{ .null, .Null },
            .optional => .{ .optional, .Optional },
            .error_union => .{ .error_union, .ErrorUnion },
            .error_set => .{ .error_set, .ErrorSet },
            .@"enum" => .{ .@"enum", .Enum },
            .@"union" => .{ .@"union", .Union },
            .@"fn" => .{ .@"fn", .Fn },
            .@"opaque" => .{ .@"opaque", .Opaque },
            .frame => .{ .frame, .Frame },
            .@"anyframe" => .{ .@"anyframe", .Anyframe },
            .vector => .{ .vector, .Vector },
            .enum_literal => .{ .enum_literal, .EnumLiteral },
        }, switch (info) {
            .type => {},
            .void => {},
            .bool => {},
            .noreturn => {},
            .int => |int| int,
            .float => |float| float,
            .pointer => |pointer| pointer.intoStd(),
            .array => |array| array.intoStd(),
            .@"struct" => |@"struct"| @"struct".intoStd(),
            .comptime_float => {},
            .comptime_int => {},
            .undefined => {},
            .null => {},
            .optional => |optional| optional,
            .error_union => |error_union| error_union,
            .error_set => |error_set| error_set,
            .@"enum" => |@"enum"| @"enum".intoStd(),
            .@"union" => |@"union"| @"union".intoStd(),
            .@"fn" => |@"fn"| @"fn".intoStd(),
            .@"opaque" => |@"opaque"| @"opaque",
            .frame => |frame| frame,
            .@"anyframe" => |@"anyframe"| @"anyframe",
            .vector => |vector| vector,
            .enum_literal => {},
        });
    }

    pub const Enum = struct {
        decls: []const StdType.Declaration = &.{},
        is_exhaustive: bool = true,
        tag_type: ?type = null,
        variants: []const Variant,

        pub inline fn fromStd(std_info: StdType.Enum) Enum {
            var variants: []const Variant = &.{};
            for (std_info.fields) |field|
                variants = variants ++ &[_]Variant{Variant.fromStd(field)};
            return Enum{
                .decls = std_info.decls,
                .is_exhaustive = std_info.is_exhaustive,
                .tag_type = std_info.tag_type,
                .variants = variants,
            };
        }

        pub inline fn intoStd(info: Enum) StdType.Enum {
            var variants: []const StdType.EnumField = &.{};
            var preceding_value = 0;
            for (info.variants) |variant|
                variants = variants ++ &[_]StdType.EnumField{variant.intoStd(&preceding_value)};
            return StdType.Enum{
                .decls = info.decls,
                .fields = variants,
                .is_exhaustive = info.is_exhaustive,
                .tag_type = info.tag_type orelse blk: {
                    var max: ?comptime_int = null;
                    var min: ?comptime_int = null;
                    for (variants) |variant| {
                        const yes_min = min orelse variant.value;
                        const yes_max = max orelse variant.value;
                        if (yes_max < variant.value)
                            max = variant.value
                        else if (variant.value < yes_min)
                            min = variant.value;
                    }

                    break :blk std.math.IntFittingRange(min orelse 0, max orelse 0);
                },
            };
        }

        pub const Variant = struct {
            name: []const u8,
            value: ?comptime_int = null,

            pub inline fn fromStd(field: StdType.EnumField) Variant {
                return Variant{
                    .name = field.name ++ "\x00",
                    .value = field.value,
                };
            }

            pub inline fn intoStd(variant: Variant, preceding_value: *comptime_int) StdType.EnumField {
                return StdType.EnumField{
                    .name = Variant.name ++ "\x00",
                    .value = variant.value orelse blk: {
                        defer preceding_value.value += 1;
                        break :blk preceding_value.value;
                    },
                };
            }
        };
    };

    pub const Array = struct {
        len: usize,
        child: type,
        sentinel: ?*const anyopaque = null,

        pub inline fn fromStd(std_info: StdType.Array) Array {
            return Array{
                .len = std_info.len,
                .child = std_info.child,
                .sentinel = std_info.sentinel,
            };
        }

        pub inline fn intoStd(info: Array) StdType.Array {
            return StdType.Array{
                .len = info.len,
                .child = info.child,
                .sentinel = info.sentinel,
            };
        }
    };

    pub const Fn = struct {
        calling_convention: CallingConvention = .unspecified,
        is_generic: bool = false,
        is_var_args: bool = false,
        return_type: type = void,
        params: []const Param = &.{},

        pub inline fn fromStd(std_info: StdType.Fn) Fn {
            var params: []const Param = &.{};
            for (std_info.params) |param|
                params = params ++ &[_]Param{Param.fromStd(param)};
            return Fn{
                .calling_convention = CallingConvention.fromStd(std_info.calling_convention),
                .is_generic = std_info.is_generic,
                .is_var_args = std_info.is_var_args,
                .return_type = std_info.return_type orelse
                    @compileError("Encountered a function without a return type??"),
                .params = params,
            };
        }

        pub inline fn intoStd(info: Fn) StdType.Fn {
            var params: []const StdType.Fn.Param = &.{};
            for (info.params) |param|
                params = params ++ &[_]StdType.Fn.Param{param.intoStd()};
            return StdType.Fn{
                .calling_convention = info.calling_convention.intoStd(),
                .is_generic = info.is_generic,
                .is_var_args = info.is_var_args,
                .params = params,
                .return_type = info.return_type,
            };
        }

        pub const Param = struct {
            is_generic: bool = false,
            is_noalias: bool = false,
            type: ?type,

            pub inline fn fromStd(std_info: StdType.Fn.Param) Param {
                return Param{
                    .is_generic = std_info.is_generic,
                    .is_noalias = std_info.is_noalias,
                    .type = std_info.type,
                };
            }

            pub inline fn intoStd(info: Param) StdType.Fn.Param {
                return StdType.Fn.Param{
                    .is_generic = info.is_generic,
                    .is_noalias = info.is_noalias,
                    .type = info.type,
                };
            }
        };

        pub const CallingConvention = enum {
            unspecified,
            c,
            naked,
            @"async",
            @"inline",
            interrupt,
            signal,
            stdcall,
            fastcall,
            vectorcall,
            thiscall,
            apcs,
            aapcs,
            aapcsvfp,
            sys_v,
            win64,
            kernel,
            fragment,
            vertex,

            pub inline fn fromStd(std_info: std.builtin.CallingConvention) CallingConvention {
                return if (isEither(std_info, .{ .unspecified, .Unspecified }))
                    .unspecified
                else if (isEither(std_info, .{ .c, .C }))
                    .c
                else if (isEither(std_info, .{ .naked, .Naked }))
                    .naked
                else if (isEither(std_info, .{ .@"async", .Async }))
                    .@"async"
                else if (isEither(std_info, .{ .@"inline", .Inline }))
                    .@"inline"
                else if (isEither(std_info, .{ .interrupt, .Interrupt }))
                    .interrupt
                else if (isEither(std_info, .{ .signal, .Signal }))
                    .signal
                else if (isEither(std_info, .{ .stdcall, .Stdcall }))
                    .stdcall
                else if (isEither(std_info, .{ .fastcall, .Fastcall }))
                    .fastcall
                else if (isEither(std_info, .{ .vectorcall, .Vectorcall }))
                    .vectorcall
                else if (isEither(std_info, .{ .thiscall, .Thiscall }))
                    .thiscall
                else if (isEither(std_info, .{ .apcs, .APCS }))
                    .apcs
                else if (isEither(std_info, .{ .aapcs, .AAPCS }))
                    .aapcs
                else if (isEither(std_info, .{ .aapcsvfp, .AAPCSVFP }))
                    .aapcsvfp
                else if (isEither(std_info, .{ .sys_v, .SysV }))
                    .sys_v
                else if (isEither(std_info, .{ .win64, .Win64 }))
                    .win64
                else if (isEither(std_info, .{ .kernel, .Kernel }))
                    .kernel
                else if (isEither(std_info, .{ .fragment, .Fragment }))
                    .fragment
                else //if (isEither(std_info, .{ .vertex, .Vertex }))
                    .vertex;
            }

            pub inline fn intoStd(info: CallingConvention) std.builtin.CallingConvention {
                return eitherEnumVariant(std.builtin.CallingConvention, switch (info) {
                    .unspecified => .{ .unspecified, .Unspecified },
                    .c => .{ .c, .C },
                    .naked => .{ .naked, .Naked },
                    .@"async" => .{ .@"async", .Async },
                    .@"inline" => .{ .@"inline", .Inline },
                    .interrupt => .{ .interrupt, .Interrupt },
                    .signal => .{ .signal, .Signal },
                    .stdcall => .{ .stdcall, .Stdcall },
                    .fastcall => .{ .fastcall, .Fastcall },
                    .vectorcall => .{ .vectorcall, .Vectorcall },
                    .thiscall => .{ .thiscall, .Thiscall },
                    .apcs => .{ .apcs, .APCS },
                    .aapcs => .{ .aapcs, .AAPCS },
                    .aapcsvfp => .{ .aapcsvfp, .AAPCSVFP },
                    .sys_v => .{ .sys_v, .SysV },
                    .win64 => .{ .win64, .Win64 },
                    .kernel => .{ .kernel, .Kernel },
                    .fragment => .{ .fragment, .Fragment },
                    .vertex => .{ .vertex, .Vertex },
                });
            }
        };
    };

    pub const Union = struct {
        decls: []const StdType.Declaration = &.{},
        layout: Layout = .auto,
        tag_type: ?type = null,
        variants: []const VariantInfo,

        pub inline fn fromStd(std_info: StdType.Union) Union {
            var variants: []const VariantInfo = &.{};
            for (std_info.fields) |field|
                variants = variants ++ &[_]VariantInfo{VariantInfo.fromStd(field)};
            return Union{
                .decls = std_info.decls,
                .layout = Layout.fromStd(std_info.layout),
                .tag_type = std_info.tag_type,
                .variants = variants,
            };
        }

        pub inline fn intoStd(info: Union) StdType.Union {
            var fields: []const StdType.UnionField = &.{};
            for (info.variants) |variant|
                fields = fields ++ &[_]StdType.UnionField{variant.intoStd()};
            return StdType.Union{
                .decls = info.decls,
                .fields = fields,
                .layout = info.layout.intoStd(),
                .tag_type = info.tag_type,
            };
        }

        pub const VariantInfo = struct {
            alignment: ?u16 = null,
            name: []const u8,
            type: type,

            pub inline fn fromStd(std_info: StdType.UnionField) VariantInfo {
                return VariantInfo{
                    .alignment = std_info.alignment,
                    .name = std_info.name,
                    .type = std_info.type,
                };
            }

            pub inline fn intoStd(info: VariantInfo) StdType.UnionField {
                return StdType.UnionField{
                    .alignment = info.alignment,
                    .name = info.name,
                    .type = info.type,
                };
            }
        };
    };

    pub const Struct = struct {
        backing_integer: ?type = null,
        decls: []const StdType.Declaration = &.{},
        fields: []const Field = &.{},
        is_tuple: bool = false,
        layout: Layout = .auto,

        pub inline fn fromStd(std_info: StdType.Struct) Struct {
            var fields: []const Field = &.{};
            for (std_info.fields) |field|
                fields = fields ++ &[_]Field{Field.fromStd(field)};
            return Struct{
                .backing_integer = std_info.backing_integer,
                .decls = std_info.decls,
                .fields = fields,
                .is_tuple = std_info.is_tuple,
                .layout = Layout.fromStd(std_info.layout),
            };
        }

        pub inline fn intoStd(info: Struct) StdType.Struct {
            var fields: []const StdType.StructField = &.{};
            for (info.fields) |field|
                fields = fields ++ &[_]StdType.StructField{field.intoStd()};
            return StdType.Struct{
                .backing_integer = info.backing_integer,
                .decls = info.decls,
                .fields = fields,
                .is_tuple = info.is_tuple,
                .layout = info.layout.intoStd(),
            };
        }

        pub const Field = struct {
            alignment: ?u16 = null,
            default_value: ?*const anyopaque = null,
            is_comptime: bool = false,
            name: []const u8,
            type: type,

            pub inline fn fromStd(std_info: StdType.StructField) Field {
                return Field{
                    .alignment = std_info.alignment,
                    .default_value = std_info.default_value,
                    .is_comptime = std_info.is_comptime,
                    .name = std_info.name,
                    .type = std_info.type,
                };
            }

            pub inline fn intoStd(info: Field) StdType.StructField {
                return StdType.StructField{
                    .alignment = info.alignment orelse @alignOf(info.type),
                    .default_value = info.default_value,
                    .is_comptime = info.is_comptime,
                    .name = info.name ++ "\x00",
                    .type = info.type,
                };
            }
        };
    };

    pub const Layout = enum {
        auto,
        @"packed",
        @"extern",

        pub inline fn fromStd(std_info: StdType.ContainerLayout) Layout {
            return if (isEither(std_info, .{ .auto, .Auto }))
                .auto
            else if (isEither(std_info, .{ .@"packed", .Packed }))
                .@"packed"
            else //if (isEither(info, &.{"extern", "Extern"}))
                .@"extern";
        }

        pub inline fn intoStd(info: Layout) StdType.ContainerLayout {
            return eitherEnumVariant(StdType.ContainerLayout, &switch (info) {
                .auto => .{ .auto, .Auto },
                .@"packed" => .{ .@"packed", .Packed },
                .@"extern" => .{ .@"extern", .Extern },
            });
        }
    };

    pub const Pointer = struct {
        address_space: std.builtin.AddressSpace = .generic,
        alignment: u16,
        child: type,
        is_allowzero: bool = false,
        is_const: bool = true,
        is_volatile: bool = false,
        sentinel: ?*const anyopaque = null,
        size: Pointer.Size = .one,

        pub inline fn fromStd(std_info: StdType.Pointer) Pointer {
            return Pointer{
                .address_space = std_info.address_space,
                .alignment = std_info.alignment,
                .child = std_info.child,
                .is_allowzero = std_info.is_allowzero,
                .is_const = std_info.is_const,
                .is_volatile = std_info.is_volatile,
                .sentinel = std_info.sentinel,
                .size = Size.fromStd(std_info.size),
            };
        }

        pub inline fn intoStd(info: Pointer) StdType.Pointer {
            return StdType.Pointer{
                .address_space = info.address_space,
                .alignment = info.alignment,
                .child = info.child,
                .is_allowzero = info.is_allowzero,
                .is_const = info.is_const,
                .is_volatile = info.is_volatile,
                .sentinel = info.sentinel,
                .size = info.size.intoStd(),
            };
        }

        pub const Size = enum {
            c,
            many,
            one,
            slice,

            pub inline fn fromStd(std_info: StdType.Pointer.Size) Size {
                return if (isEither(std_info, .{ .c, .C }))
                    .c
                else if (isEither(std_info, .{ .many, .Many }))
                    .many
                else if (isEither(std_info, .{ .one, .One }))
                    .one
                else //if (isEither(info, &.{ "slice", "Slice" }))
                    .slice;
            }

            pub inline fn intoStd(info: Size) StdType.Pointer.Size {
                return eitherEnumVariant(StdType.Pointer.Size, &switch (info) {
                    .c => .{ .c, .C },
                    .many => .{ .many, .Many },
                    .one => .{ .one, .One },
                    .slice => .{ .slice, .Slice },
                });
            }
        };
    };
};

fn selectVariant(SumType: type, variants: anytype) []const u8 {
    var selected_variant: ?[]const u8 = null;
    for (variants) |v| {
        const variant_name = @tagName(v);
        if (@hasField(SumType, variant_name)) {
            if (selected_variant) |sv| t.compileError(
                "The sum type `{s}` has both `.{s}` and `.{s}` variants!",
                .{ @typeName(SumType), sv, variant_name },
            );

            selected_variant = variant_name;
        }
    }

    return selected_variant orelse t.compileError("The sum type `{s}` has none of the variants selected!", .{@typeName(SumType)});
}

fn eitherEnumVariant(Enum: type, variants: anytype) Enum {
    return @field(Enum, selectVariant(Enum, variants));
}

fn eitherUnionVariant(Union: type, variants: anytype, payload: anytype) Union {
    return @unionInit(Union, selectVariant(Union, variants), payload);
}

fn eitherUnionAccess(
    union_value: anytype,
    variants: anytype,
) EitherUnionAccess(@TypeOf(union_value), variants) {
    return @field(union_value, selectVariant(@TypeOf(union_value), variants));
}

fn EitherUnionAccess(Union: type, variants: anytype) type {
    return @TypeOf(@field(@as(Union, undefined), selectVariant(Union, variants)));
}

fn isEither(value: anytype, variants: anytype) bool {
    const tag = @tagName(value);
    @setEvalBranchQuota(10_000);
    return for (variants) |variant| {
        if (streq(tag, @tagName(variant))) break true;
    } else false;
}

fn streq(a: []const u8, b: []const u8) bool {
    if (a.len != b.len) return false;
    const array_a: *const [a.len]u8 = @ptrCast(a.ptr);
    const array_b: *const [b.len]u8 = @ptrCast(b.ptr);
    const vector_a: @Vector(a.len, u8) = array_a.*;
    const vector_b: @Vector(b.len, u8) = array_b.*;
    return @reduce(.And, vector_a == vector_b);
}

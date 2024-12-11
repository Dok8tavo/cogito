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

pub inline fn Type(info: TypeInfo) type {
    return @Type(info.intoStd());
}

pub inline fn typeInfo(T: type) TypeInfo {
    return TypeInfo.fromStd(@typeInfo(T));
}

pub const TypeInfo = union(enum) {
    type_info: void,
    void_info: void,
    bool_info: void,
    noreturn_info: void,
    int_info: StdType.Int,
    float_info: StdType.Float,
    pointer_info: PointerInfo,
    array_info: ArrayInfo,
    struct_info: StructInfo,
    comptime_float_info: void,
    comptime_int_info: void,
    undefined_info: void,
    null_info: void,
    optional_info: StdType.Optional,
    error_union_info: StdType.ErrorUnion,
    error_set_info: StdType.ErrorSet,
    enum_info: EnumInfo,
    union_info: UnionInfo,
    fn_info: FnInfo,
    opaque_info: StdType.Opaque,
    frame_info: StdType.Frame,
    anyframe_info: StdType.AnyFrame,
    vector_info: StdType.Vector,
    enum_literal_info: void,

    pub inline fn fromStd(std_info: StdType) TypeInfo {
        return if (isEither(std_info, &.{ "type", "Type" }))
            .type_info
        else if (isEither(std_info, &.{ "void", "Void" }))
            .void_info
        else if (isEither(std_info, &.{ "bool", "Bool" }))
            .bool_info
        else if (isEither(std_info, &.{ "noreturn", "NoReturn" }))
            .noreturn_info
        else if (isEither(std_info, &.{ "int", "Int" })) TypeInfo{
            .int_info = eitherUnionAccess(std_info, &.{ "int", "Int" }),
        } else if (isEither(std_info, &.{ "float", "Float" })) TypeInfo{
            .float_info = eitherUnionAccess(std_info, &.{ "float", "Float" }),
        } else if (isEither(std_info, &.{ "pointer", "Pointer" })) TypeInfo{
            .pointer_info = PointerInfo.fromStd(eitherUnionAccess(std_info, &.{ "pointer", "Pointer" })),
        } else if (isEither(std_info, &.{ "array", "Array" })) TypeInfo{
            .array_info = ArrayInfo.fromStd(eitherUnionAccess(std_info, &.{ "array", "Array" })),
        } else if (isEither(std_info, &.{ "struct", "Struct" })) TypeInfo{
            .struct_info = StructInfo.fromStd(eitherUnionAccess(std_info, &.{ "struct", "Struct" })),
        } else if (isEither(std_info, &.{ "comptime_float", "ComptimeFloat" }))
            .comptime_float_info
        else if (isEither(std_info, &.{ "comptime_int", "ComptimeInt" }))
            .comptime_int_info
        else if (isEither(std_info, &.{ "undefined", "Undefined" }))
            .undefined_info
        else if (isEither(std_info, &.{ "null", "Null" }))
            .null_info
        else if (isEither(std_info, &.{ "optional", "Optional" })) TypeInfo{
            .optional_info = eitherUnionAccess(std_info, &.{ "optional", "Optional" }),
        } else if (isEither(std_info, &.{ "error_union", "ErrorUnion" })) TypeInfo{
            .error_union_info = eitherUnionAccess(std_info, &.{ "error_union", "ErrorUnion" }),
        } else if (isEither(std_info, &.{ "error_set", "ErrorSet" })) TypeInfo{
            .error_set_info = eitherUnionAccess(std_info, &.{ "error_set", "ErrorSet" }),
        } else if (isEither(std_info, &.{ "enum", "Enum" })) TypeInfo{
            .enum_info = EnumInfo.fromStd(eitherUnionAccess(std_info, &.{ "enum", "Enum" })),
        } else if (isEither(std_info, &.{ "union", "Union" })) TypeInfo{
            .union_info = UnionInfo.fromStd(eitherUnionAccess(std_info, &.{ "union", "Union" })),
        } else if (isEither(std_info, &.{ "fn", "Fn" })) TypeInfo{
            .fn_info = FnInfo.fromStd(eitherUnionAccess(std_info, &.{ "fn", "Fn" })),
        } else if (isEither(std_info, &.{ "opaque", "Opaque" })) TypeInfo{
            .opaque_info = eitherUnionAccess(std_info, &.{ "opaque", "Opaque" }),
        } else if (isEither(std_info, &.{ "frame", "Frame" })) TypeInfo{
            .frame_info = eitherUnionAccess(std_info, &.{ "frame", "Frame" }),
        } else if (isEither(std_info, &.{ "anyframe", "AnyFrame" })) TypeInfo{
            .anyframe_info = eitherUnionAccess(std_info, &.{ "anyframe", "AnyFrame" }),
        } else if (isEither(std_info, &.{ "vector", "Vector" })) TypeInfo{
            .vector_info = eitherUnionAccess(std_info, &.{ "vector", "Vector" }),
        } else //if (isEither(info, &.{ "enum_literal", "EnumLiteral"}))
        .enum_literal_info;
    }

    pub inline fn intoStd(info: TypeInfo) StdType {
        return eitherUnionVariant(StdType, &switch (info) {
            .type_info => .{ "type", "Type" },
            .void_info => .{ "void", "Void" },
            .bool_info => .{ "bool", "Bool" },
            .noreturn_info => .{ "noreturn", "NoReturn" },
            .int_info => .{ "int", "Int" },
            .float_info => .{ "float", "Float" },
            .pointer_info => .{ "pointer", "Pointer" },
            .array_info => .{ "array", "Array" },
            .struct_info => .{ "struct", "Struct" },
            .comptime_float_info => .{ "comptime_float", "ComptimeFloat" },
            .comptime_int_info => .{ "comptime_int", "ComptimeInt" },
            .undefined_info => .{ "undefined", "Undefined" },
            .null_info => .{ "null", "Null" },
            .optional_info => .{ "optional", "Optional" },
            .error_union_info => .{ "error_union", "ErrorUnion" },
            .error_set_info => .{ "error_set", "ErrorSet" },
            .enum_info => .{ "enum", "Enum" },
            .union_info => .{ "union", "Union" },
            .fn_info => .{ "fn", "Fn" },
            .opaque_info => .{ "opaque", "Opaque" },
            .frame_info => .{ "frame", "Frame" },
            .anyframe_info => .{ "anyframe", "Anyframe" },
            .vector_info => .{ "vector", "Vector" },
            .enum_literal_info => .{ "enum_literal", "EnumLiteral" },
        }, switch (info) {
            .type_info => {},
            .void_info => {},
            .bool_info => {},
            .noreturn_info => {},
            .int_info => |int_info| int_info,
            .float_info => |float_info| float_info,
            .pointer_info => |pointer_info| pointer_info.intoStd(),
            .array_info => |array_info| array_info.intoStd(),
            .struct_info => |struct_info| struct_info.intoStd(),
            .comptime_float_info => {},
            .comptime_int_info => {},
            .undefined_info => {},
            .null_info => {},
            .optional_info => |optional_info| optional_info,
            .error_union_info => |error_union_info| error_union_info,
            .error_set_info => |error_set_info| error_set_info,
            .enum_info => |enum_info| enum_info.intoStd(),
            .union_info => |union_info| union_info.intoStd(),
            .fn_info => |fn_info| fn_info.intoStd(),
            .opaque_info => |opaque_info| opaque_info,
            .frame_info => |frame_info| frame_info,
            .anyframe_info => |anyframe_info| anyframe_info,
            .vector_info => |vector_info| vector_info,
            .enum_literal_info => {},
        });
    }

    pub const EnumInfo = struct {
        decls: []const StdType.Declaration = &.{},
        is_exhaustive: bool = true,
        tag_type: ?type = null,
        variants: []const VariantInfo,

        pub inline fn fromStd(std_info: StdType.Enum) EnumInfo {
            var variants: []const VariantInfo = &.{};
            for (std_info.fields) |field|
                variants = variants ++ &[_]VariantInfo{VariantInfo.fromStd(field)};
            return EnumInfo{
                .decls = std_info.decls,
                .is_exhaustive = std_info.is_exhaustive,
                .tag_type = std_info.tag_type,
                .variants = variants,
            };
        }

        pub inline fn intoStd(info: EnumInfo) StdType.Enum {
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

        pub const VariantInfo = struct {
            name: []const u8,
            value: ?comptime_int = null,

            pub inline fn fromStd(field: StdType.EnumField) VariantInfo {
                return VariantInfo{
                    .name = field.name ++ "\x00",
                    .value = field.value,
                };
            }

            pub inline fn intoStd(variant: VariantInfo, preceding_value: *comptime_int) StdType.EnumField {
                return StdType.EnumField{
                    .name = VariantInfo.name ++ "\x00",
                    .value = variant.value orelse blk: {
                        defer preceding_value.value += 1;
                        break :blk preceding_value.value;
                    },
                };
            }
        };
    };

    pub const ArrayInfo = struct {
        len: usize,
        child: type,
        sentinel: ?*const anyopaque = null,

        pub inline fn fromStd(std_info: StdType.Array) ArrayInfo {
            return ArrayInfo{
                .len = std_info.len,
                .child = std_info.child,
                .sentinel = std_info.sentinel,
            };
        }

        pub inline fn intoStd(info: ArrayInfo) StdType.Array {
            return StdType.Array{
                .len = info.len,
                .child = info.child,
                .sentinel = info.sentinel,
            };
        }
    };

    pub const FnInfo = struct {
        calling_convention: CallingConvention = .cc_unspecified,
        is_generic: bool = false,
        is_var_args: bool = false,
        return_type: type = void,
        params: []const ParamInfo = &.{},

        pub inline fn fromStd(std_info: StdType.Fn) FnInfo {
            var params: []const ParamInfo = &.{};
            for (std_info.params) |param|
                params = params ++ &[_]ParamInfo{ParamInfo.fromStd(param)};
            return FnInfo{
                .calling_convention = CallingConvention.fromStd(std_info.calling_convention),
                .is_generic = std_info.is_generic,
                .is_var_args = std_info.is_var_args,
                .return_type = std_info.return_type orelse
                    @compileError("Encountered a function without a return type??"),
                .params = params,
            };
        }

        pub inline fn intoStd(info: FnInfo) StdType.Fn {
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

        pub const ParamInfo = struct {
            param_is_generic: bool = false,
            param_is_noalias: bool = false,
            param_type: ?type,

            pub inline fn fromStd(std_info: StdType.Fn.Param) ParamInfo {
                return ParamInfo{
                    .param_is_generic = std_info.is_generic,
                    .param_is_noalias = std_info.is_noalias,
                    .param_type = @field(std_info, "type"),
                };
            }

            pub inline fn intoStd(info: ParamInfo) StdType.Fn.Param {
                var std_info: StdType.Fn.Param = undefined;
                std_info.is_generic = info.param_is_generic;
                std_info.is_noalias = info.param_is_noalias;
                @field(std_info, "type") = info.param_type;
                return std_info;
            }
        };

        pub const CallingConvention = enum {
            cc_unspecified,
            cc_c,
            cc_naked,
            cc_async,
            cc_inline,
            cc_interrupt,
            cc_signal,
            cc_stdcall,
            cc_fastcall,
            cc_vectorcall,
            cc_thiscall,
            cc_apcs,
            cc_aapcs,
            cc_aapcsvfp,
            cc_sys_v,
            cc_win64,
            cc_kernel,
            cc_fragment,
            cc_vertex,

            pub inline fn fromStd(std_info: std.builtin.CallingConvention) CallingConvention {
                return if (isEither(std_info, &.{ "unspecified", "Unspecified" }))
                    .cc_unspecified
                else if (isEither(std_info, &.{ "c", "C" }))
                    .cc_c
                else if (isEither(std_info, &.{ "naked", "Naked" }))
                    .cc_naked
                else if (isEither(std_info, &.{ "async", "Async" }))
                    .cc_async
                else if (isEither(std_info, &.{ "inline", "Inline" }))
                    .cc_inline
                else if (isEither(std_info, &.{ "interrupt", "Interrupt" }))
                    .cc_interrupt
                else if (isEither(std_info, &.{ "signal", "Signal" }))
                    .cc_signal
                else if (isEither(std_info, &.{ "stdcall", "Stdcall" }))
                    .cc_stdcall
                else if (isEither(std_info, &.{ "fastcall", "Fastcall" }))
                    .cc_fastcall
                else if (isEither(std_info, &.{ "vectorcall", "Vectorcall" }))
                    .cc_vectorcall
                else if (isEither(std_info, &.{ "thiscall", "Thiscall" }))
                    .cc_thiscall
                else if (isEither(std_info, &.{ "apcs", "APCS" }))
                    .cc_apcs
                else if (isEither(std_info, &.{ "aapcs", "AAPCS" }))
                    .cc_aapcs
                else if (isEither(std_info, &.{ "aapcsvfp", "AAPCSVFP" }))
                    .cc_aapcsvfp
                else if (isEither(std_info, &.{ "sys_v", "SysV" }))
                    .cc_sys_v
                else if (isEither(std_info, &.{ "win64", "Win64" }))
                    .cc_win64
                else if (isEither(std_info, &.{ "kernel", "Kernel" }))
                    .cc_kernel
                else if (isEither(std_info, &.{ "fragment", "Fragment" }))
                    .cc_fragment
                else //if (isEither(std_info, &.{ "vertex", "Vertex" }))
                    .cc_vertex;
            }

            pub inline fn intoStd(info: CallingConvention) std.builtin.CallingConvention {
                return eitherEnumVariant(std.builtin.CallingConvention, &switch (info) {
                    .cc_unspecified => .{ "unspecified", "Unspecified" },
                    .cc_c => .{ "c", "C" },
                    .cc_naked => .{ "naked", "Naked" },
                    .cc_async => .{ "async", "Async" },
                    .cc_inline => .{ "inline", "Inline" },
                    .cc_interrupt => .{ "interrupt", "Interrupt" },
                    .cc_signal => .{ "signal", "Signal" },
                    .cc_stdcall => .{ "stdcall", "Stdcall" },
                    .cc_fastcall => .{ "fastcall", "Fastcall" },
                    .cc_vectorcall => .{ "vectorcall", "Vectorcall" },
                    .cc_thiscall => .{ "thiscall", "Thiscall" },
                    .cc_apcs => .{ "apcs", "APCS" },
                    .cc_aapcs => .{ "aapcs", "AAPCS" },
                    .cc_aapcsvfp => .{ "aapcsvfp", "AAPCSVFP" },
                    .cc_sys_v => .{ "sys_v", "SysV" },
                    .cc_win64 => .{ "win64", "Win64" },
                    .cc_kernel => .{ "kernel", "Kernel" },
                    .cc_fragment => .{ "fragment", "Fragment" },
                    .cc_vertex => .{ "vertex", "Vertex" },
                });
            }
        };
    };

    pub const UnionInfo = struct {
        decls: []const StdType.Declaration = &.{},
        layout: Layout = .auto_layout,
        tag_type: ?type = null,
        variants: []const VariantInfo,

        pub inline fn fromStd(std_info: StdType.Union) UnionInfo {
            var variants: []const VariantInfo = &.{};
            for (std_info.fields) |field|
                variants = variants ++ &[_]VariantInfo{VariantInfo.fromStd(field)};
            return UnionInfo{
                .decls = std_info.decls,
                .layout = Layout.fromStd(std_info.layout),
                .tag_type = std_info.tag_type,
                .variants = variants,
            };
        }

        pub inline fn intoStd(info: UnionInfo) StdType.Union {
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
            variant_alignment: ?u16 = null,
            variant_name: []const u8,
            variant_type: type,

            pub inline fn fromStd(std_info: StdType.UnionField) VariantInfo {
                return VariantInfo{
                    .variant_alignment = std_info.alignment,
                    .variant_name = std_info.name,
                    .variant_type = @field(std_info, "type"),
                };
            }

            pub inline fn intoStd(info: VariantInfo) StdType.UnionField {
                var std_info: StdType.UnionField = undefined;
                std_info.alignment = info.variant_alignment orelse @alignOf(info.variant_type);
                std_info.name = info.variant_name ++ "\x00";
                @field(std_info, "type") = info.variant_type;
                return std_info;
            }
        };
    };

    pub const StructInfo = struct {
        backing_integer: ?type = null,
        decls: []const StdType.Declaration = &.{},
        fields: []const FieldInfo = &.{},
        is_tuple: bool = false,
        layout: Layout = .auto_layout,

        pub inline fn fromStd(std_info: StdType.Struct) StructInfo {
            var fields: []const FieldInfo = &.{};
            for (std_info.fields) |field|
                fields = fields ++ &[_]FieldInfo{FieldInfo.fromStd(field)};
            return StructInfo{
                .backing_integer = std_info.backing_integer,
                .decls = std_info.decls,
                .fields = fields,
                .is_tuple = std_info.is_tuple,
                .layout = Layout.fromStd(std_info.layout),
            };
        }

        pub inline fn intoStd(info: StructInfo) StdType.Struct {
            var std_info: StdType.Struct = undefined;
            std_info.backing_integer = info.backing_integer;
            std_info.decls = info.decls;

            var fields: []const StdType.StructField = &.{};
            for (info.fields) |field|
                fields = fields ++ &[_]StdType.StructField{field.intoStd()};
            std_info.fields = fields;

            std_info.is_tuple = info.is_tuple;
            std_info.layout = info.layout.intoStd();
            return std_info;
        }

        pub const FieldInfo = struct {
            field_alignment: ?u16 = null,
            field_default_value: ?*const anyopaque = null,
            field_is_comptime: bool = false,
            field_name: []const u8,
            field_type: type,

            pub inline fn fromStd(std_info: StdType.StructField) FieldInfo {
                return FieldInfo{
                    .field_alignment = std_info.alignment,
                    .field_default_value = std_info.default_value,
                    .field_is_comptime = std_info.is_comptime,
                    .field_name = std_info.name,
                    .field_type = @field(std_info, "type"),
                };
            }

            pub inline fn intoStd(info: FieldInfo) StdType.StructField {
                var std_info: StdType.StructField = undefined;
                std_info.alignment = info.field_alignment orelse @alignOf(info.field_type);
                std_info.default_value = info.field_default_value;
                std_info.is_comptime = info.field_is_comptime;
                std_info.name = info.field_name ++ "\x00";
                @field(std_info, "type") = info.field_type;
                return std_info;
            }
        };
    };

    pub const Layout = enum {
        auto_layout,
        packed_layout,
        extern_layout,

        pub inline fn fromStd(std_info: StdType.ContainerLayout) Layout {
            return if (isEither(std_info, &.{ "auto", "Auto" }))
                .auto_layout
            else if (isEither(std_info, &.{ "packed", "Packed" }))
                .packed_layout
            else //if (isEither(info, &.{"extern", "Extern"}))
                .extern_layout;
        }

        pub inline fn intoStd(info: Layout) StdType.ContainerLayout {
            return eitherEnumVariant(StdType.ContainerLayout, &switch (info) {
                .auto_layout => .{ "auto", "Auto" },
                .packed_layout => .{ "packed", "Packed" },
                .extern_layout => .{ "extern", "Extern" },
            });
        }
    };

    pub const PointerInfo = struct {
        address_space: std.builtin.AddressSpace = .generic,
        alignment: u16,
        child: type,
        is_allowzero: bool = false,
        is_const: bool = true,
        is_volatile: bool = false,
        sentinel: ?*const anyopaque = null,
        size: PointerInfo.Size = .one,

        pub inline fn fromStd(std_info: StdType.Pointer) PointerInfo {
            return PointerInfo{
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

        pub inline fn intoStd(info: PointerInfo) StdType.Pointer {
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
                return if (isEither(std_info, &.{ "c", "C" }))
                    .c
                else if (isEither(std_info, &.{ "many", "Many" }))
                    .many
                else if (isEither(std_info, &.{ "one", "One" }))
                    .one
                else //if (isEither(info, &.{ "slice", "Slice" }))
                    .slice;
            }

            pub inline fn intoStd(info: Size) StdType.Pointer.Size {
                return eitherEnumVariant(StdType.Pointer.Size, &switch (info) {
                    .c => .{ "c", "C" },
                    .many => .{ "many", "Many" },
                    .one => .{ "one", "One" },
                    .slice => .{ "slice", "Slice" },
                });
            }
        };
    };
};

fn selectVariant(SumType: type, variants: []const []const u8) []const u8 {
    var selected_variant: ?[]const u8 = null;
    for (variants) |v| {
        if (@hasField(SumType, v)) {
            if (selected_variant) |sv| t.compileError(
                "The sum type `{s}` has both `.{s}` and `.{s}` variants!",
                .{ @typeName(SumType), sv, v },
            );

            selected_variant = v;
        }
    }

    return selected_variant orelse t.compileError("The sum type `{s}` has none of the variants selected!", .{@typeName(SumType)});
}

fn eitherEnumVariant(Enum: type, variants: []const []const u8) Enum {
    return @field(Enum, selectVariant(Enum, variants));
}

fn eitherUnionVariant(Union: type, variants: []const []const u8, payload: anytype) Union {
    return @unionInit(Union, selectVariant(Union, variants), payload);
}

fn eitherUnionAccess(
    union_value: anytype,
    variants: []const []const u8,
) EitherUnionAccess(@TypeOf(union_value), variants) {
    return @field(union_value, selectVariant(@TypeOf(union_value), variants));
}

fn EitherUnionAccess(Union: type, variants: []const []const u8) type {
    return @TypeOf(@field(@as(Union, undefined), selectVariant(Union, variants)));
}

fn isEither(value: anytype, variants: []const []const u8) bool {
    const tag = @tagName(value);
    @setEvalBranchQuota(10_000);
    return for (variants) |variant| {
        if (streq(tag, variant)) break true;
    } else false;
}

fn streq(a: []const u8, b: []const u8) bool {
    return a.len == b.len and for (a, b) |c, d| {
        if (c != d) break false;
    } else true;
}

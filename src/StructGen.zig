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

const StructInfo = compat.Type.Struct;
const StructGen = @This();

pub inline fn Type(gen: StructGen) type {
    return compat.TypeFrom(.{ .@"struct" = gen.info });
}

pub inline fn setLayout(gen: *StructGen, layout: compat.Type.Layout) void {
    gen.info.layout = layout;
}

pub inline fn getLayout(gen: StructGen) compat.Type.Layout {
    return gen.info.layout;
}

pub inline fn setBackingInteger(gen: *StructGen, backing_integer: ?type) void {
    gen.info.backing_integer = backing_integer;
}

pub inline fn getBackingInteger(gen: StructGen) ?type {
    return gen.info.backing_integer;
}

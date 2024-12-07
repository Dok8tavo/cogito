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

map: Map = .{},

const Map = @import("Map.zig");
const Set = @This();

pub fn has(comptime set: Set, comptime item: []const u8) bool {
    return set.map.has(item);
}

pub fn size(comptime set: Set) usize {
    return set.map.size();
}

// == Adding items ==
pub fn add(comptime set: *Set, comptime item: []const u8) void {
    set.map.add(item, {});
}

pub fn addOrErr(comptime set: *Set, comptime item: []const u8) Map.AddError!void {
    try set.map.addOrErr(item, {});
}

pub fn addOrLeave(comptime set: *Set, comptime item: []const u8) void {
    set.map.addOrLeave(item, {});
}

// == Removing items ==
pub fn remove(comptime set: *Set, comptime item: []const u8) void {
    set.map.remove(item);
}

pub fn removeOrErr(comptime set: *Set, comptime item: []const u8) Map.RemoveError!void {
    try set.map.removeOrErr(item);
}

pub fn removeOrLeave(comptime set: *Set, comptime item: []const u8) void {
    set.map.removeOrLeave(item);
}

// == Combining sets ==
pub fn combination(comptime set1: Set, comptime set2: Set) Set {
    comptime {
        var combine_set = set1;

        for (set2.map.info().fields) |field|
            combine_set.add(field.name);
    }
}

pub fn combinationOrErr(comptime set1: Set, comptime set2: Set) Map.AddError!Set {
    comptime {
        if (!set1.isDisjoint(set2))
            return Map.AddError.KeyAlreadyExists;
        return set1.combination(set2);
    }
}

pub fn combinationOrLeave(comptime set1: Set, comptime set2: Set) Set {
    comptime {
        var combine_set = set1;

        for (set2.map.info().fields) |field|
            combine_set.addOrLeave(field.name);
    }
}

pub fn intersection(comptime set1: Set, comptime set2: Set) Set {
    comptime {
        var intersection_set = Set{};

        for (set1.map.info().fields) |field|
            if (set2.has(field.name))
                intersection_set.add(field.name);
    }
}

pub fn isDisjoint(comptime set1: Set, comptime set2: Set) bool {
    comptime return for (set1.map.info().fields) |field| {
        if (set2.has(field.name))
            break false;
    } else true;
}

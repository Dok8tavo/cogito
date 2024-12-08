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

const std = @import("std");
const t = @import("testing.zig");

const Map = @import("Map.zig");
const Set = @This();

pub inline fn from(comptime items: anytype) Set {
    var set = Set{};
    for (items) |item| set.add(item);
    return set;
}

pub inline fn has(comptime set: Set, comptime item: anytype) bool {
    return set.map.has(item);
}

pub inline fn size(comptime set: Set) usize {
    return set.map.size();
}

// == Adding items ==
pub inline fn add(comptime set: *Set, comptime item: anytype) void {
    set.map.add(item, {});
}

pub inline fn addOrErr(comptime set: *Set, comptime item: anytype) Map.AddError!void {
    try set.map.addOrErr(item, {});
}

pub inline fn addOrLeave(comptime set: *Set, comptime item: anytype) void {
    set.map.addOrLeave(item, {});
}

pub inline fn addOrRemove(comptime set: *Set, comptime item: anytype) void {
    set.addOrErr(item) catch set.remove(item);
}

// == Removing items ==
pub inline fn remove(comptime set: *Set, comptime item: anytype) void {
    set.map.remove(item);
}

pub inline fn removeOrErr(comptime set: *Set, comptime item: anytype) Map.RemoveError!void {
    try set.map.removeOrErr(item);
}

pub inline fn removeOrLeave(comptime set: *Set, comptime item: anytype) void {
    set.map.removeOrLeave(item);
}

// == Combining sets ==
pub inline fn combine(comptime set1: Set, comptime set2: Set) Set {
    var combine_set = set1;
    var iterator = set2.map.iterateKeys();

    while (iterator.next()) |key|
        combine_set.add(key);

    return combine_set;
}

pub inline fn combineOrErr(comptime set1: Set, comptime set2: Set) Map.AddError!Set {
    if (!set1.isDisjoint(set2))
        return Map.AddError.KeyAlreadyExists;
    return set1.combine(set2);
}

pub inline fn combineOrLeave(comptime set1: Set, comptime set2: Set) Set {
    var combine_set = set1;
    var iterator = set2.map.iterateKeys();

    while (iterator.next()) |key|
        combine_set.addOrLeave(key);
    return combine_set;
}

pub inline fn intersection(comptime set1: Set, comptime set2: Set) Set {
    var intersection_set = Set{};
    var iterator = set1.map.iterateKeys();

    while (iterator.next()) |key|
        if (set2.has(key))
            intersection_set.add(key);
    return intersection_set;
}

pub inline fn isDisjoint(comptime set1: Set, comptime set2: Set) bool {
    var iterator = set1.map.iterateKeys();
    return while (iterator.next()) |key| {
        if (set2.has(key)) break false;
    } else true;
}

// == Testing ==
test has {
    comptime {
        const set = Set.from(.{.item});
        t.compTry(std.testing.expect(set.has(.item)));
        t.compTry(std.testing.expect(!set.has(.not_item)));
    }
}

test size {
    comptime {
        var set = Set{};
        t.compTry(std.testing.expectEqual(0, set.size()));

        set.add(.item_1);
        t.compTry(std.testing.expectEqual(1, set.size()));

        set.add(.item_2);
        t.compTry(std.testing.expectEqual(2, set.size()));
    }
}

test add {
    comptime {
        var set = Set{};
        t.compTry(std.testing.expect(!set.has(.item)));

        set.add(.item_1);
        t.compTry(std.testing.expect(set.has(.item_1)));

        set.add(.item_2);
        t.compTry(std.testing.expect(set.has(.item_1)));
        t.compTry(std.testing.expect(set.has(.item_2)));
    }
}

test addOrErr {
    comptime {
        var set = Set{};

        const not_err = set.addOrErr(.item);
        const yes_err = set.addOrErr(.item);

        t.compTry(std.testing.expectEqual({}, not_err));
        t.compTry(std.testing.expectEqual(Map.AddError.KeyAlreadyExists, yes_err));
    }
}

test addOrLeave {
    comptime {
        var set = Set{};

        t.compTry(std.testing.expect(!set.has(.item)));

        set.addOrLeave(.item);
        t.compTry(std.testing.expect(set.has(.item)));

        set.addOrLeave(.item);
        t.compTry(std.testing.expect(set.has(.item)));
    }
}

test addOrRemove {
    comptime {
        var set = Set{};
        t.compTry(std.testing.expect(!set.has(.item)));

        set.addOrRemove(.item);
        t.compTry(std.testing.expect(set.has(.item)));

        set.addOrRemove(.item);
        t.compTry(std.testing.expect(!set.has(.item)));

        set.addOrRemove(.item);
        t.compTry(std.testing.expect(set.has(.item)));
    }
}

test remove {
    comptime {
        var set = Set.from(.{.item});
        t.compTry(std.testing.expect(set.has(.item)));

        set.remove(.item);
        t.compTry(std.testing.expect(!set.has(.item)));
    }
}

test removeOrErr {
    comptime {
        var set = Set.from(.{.item});
        t.compTry(std.testing.expect(set.has(.item)));

        const not_err = set.removeOrErr(.item);
        const yes_err = set.removeOrErr(.item);

        t.compTry(std.testing.expectEqual({}, not_err));
        t.compTry(std.testing.expectEqual(Map.RemoveError.KeyDoesNotExist, yes_err));
    }
}

test removeOrLeave {
    comptime {
        var set = Set.from(.{.item});
        t.compTry(std.testing.expect(set.has(.item)));

        set.removeOrLeave(.item);
        t.compTry(std.testing.expect(!set.has(.item)));

        set.removeOrLeave(.item);
        t.compTry(std.testing.expect(!set.has(.item)));
    }
}

test isDisjoint {
    comptime {
        const set1 = Set.from(.{ .a, .b });
        const set2 = Set.from(.{ .b, .c });
        const set3 = Set.from(.{ .c, .d });

        t.compTry(std.testing.expect(!set1.isDisjoint(set2)));
        t.compTry(std.testing.expect(set1.isDisjoint(set3)));
        t.compTry(std.testing.expect(!set2.isDisjoint(set3)));
    }
}

test combine {
    comptime {
        const set1 = Set.from(.{ .a, .b });
        const set2 = Set.from(.{ .c, .d });

        const set3 = set1.combine(set2);

        t.compTry(std.testing.expect(set3.has(.a)));
        t.compTry(std.testing.expect(set3.has(.b)));
        t.compTry(std.testing.expect(set3.has(.c)));
        t.compTry(std.testing.expect(set3.has(.d)));
    }
}

test combineOrErr {
    comptime {
        const set1 = Set.from(.{ .a, .b });
        const set2 = Set.from(.{ .b, .c });
        const set3 = Set.from(.{ .c, .d });

        t.compTry(std.testing.expectError(Map.AddError.KeyAlreadyExists, set1.combineOrErr(set2)));

        const set4 = t.compTry(set1.combineOrErr(set3));

        t.compTry(std.testing.expect(set4.has(.a)));
        t.compTry(std.testing.expect(set4.has(.b)));
        t.compTry(std.testing.expect(set4.has(.c)));
        t.compTry(std.testing.expect(set4.has(.d)));

        t.compTry(std.testing.expectError(Map.AddError.KeyAlreadyExists, set2.combineOrErr(set3)));
    }
}

test combineOrLeave {
    comptime {
        const set1 = Set.from(.{ .a, .b });
        const set2 = Set.from(.{ .b, .c });
        const set3 = Set.from(.{ .c, .d });

        const set12 = set1.combineOrLeave(set2);
        const set23 = set2.combineOrLeave(set3);
        const set13 = set1.combineOrLeave(set3);

        t.compTry(std.testing.expect(set12.has(.a)));
        t.compTry(std.testing.expect(set12.has(.b)));
        t.compTry(std.testing.expect(set12.has(.c)));
        t.compTry(std.testing.expect(!set12.has(.d)));

        t.compTry(std.testing.expect(!set23.has(.a)));
        t.compTry(std.testing.expect(set23.has(.b)));
        t.compTry(std.testing.expect(set23.has(.c)));
        t.compTry(std.testing.expect(set23.has(.d)));

        t.compTry(std.testing.expect(set13.has(.a)));
        t.compTry(std.testing.expect(set13.has(.b)));
        t.compTry(std.testing.expect(set13.has(.c)));
        t.compTry(std.testing.expect(set13.has(.d)));
    }
}

test intersection {
    comptime {
        const set1 = Set.from(.{ .a, .b });
        const set2 = Set.from(.{ .b, .c });
        const set3 = Set.from(.{ .c, .d });

        const set12 = set1.intersection(set2);
        const set23 = set2.intersection(set3);
        const set13 = set1.intersection(set3);

        const set123 = set12.intersection(set23);

        t.compTry(std.testing.expect(!set12.has(.a)));
        t.compTry(std.testing.expect(set12.has(.b)));
        t.compTry(std.testing.expect(!set12.has(.c)));
        t.compTry(std.testing.expect(!set12.has(.d)));

        t.compTry(std.testing.expect(!set13.has(.a)));
        t.compTry(std.testing.expect(!set13.has(.b)));
        t.compTry(std.testing.expect(!set13.has(.c)));
        t.compTry(std.testing.expect(!set13.has(.d)));

        t.compTry(std.testing.expect(!set23.has(.a)));
        t.compTry(std.testing.expect(!set23.has(.b)));
        t.compTry(std.testing.expect(set23.has(.c)));
        t.compTry(std.testing.expect(!set23.has(.d)));

        t.compTry(std.testing.expect(!set123.has(.a)));
        t.compTry(std.testing.expect(!set123.has(.b)));
        t.compTry(std.testing.expect(!set123.has(.c)));
        t.compTry(std.testing.expect(!set123.has(.d)));
    }
}

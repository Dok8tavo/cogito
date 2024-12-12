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

backing_dict: Dict = .{},

const std = @import("std");
const t = @import("testing.zig");

const Dict = @import("Dict.zig");
const Set = @This();

pub inline fn from(items: anytype) Set {
    var set = Set{};
    for (items) |item| set.add(item);
    return set;
}

pub inline fn has(set: Set, item: anytype) bool {
    return set.backing_dict.has(item);
}

pub inline fn size(set: Set) usize {
    return set.backing_dict.size();
}

// == Adding items ==
pub inline fn add(set: *Set, item: anytype) void {
    set.backing_dict.add(item, {});
}

pub inline fn addOrError(set: *Set, item: anytype) Dict.AddError!void {
    try set.backing_dict.addOrError(item, {});
}

pub inline fn addOrLeave(set: *Set, item: anytype) void {
    set.backing_dict.addOrLeave(item, {});
}

pub inline fn addOrRemove(set: *Set, item: anytype) void {
    set.addOrError(item) catch set.remove(item);
}

// == Removing items ==
pub inline fn remove(set: *Set, item: anytype) void {
    set.backing_dict.remove(item);
}

pub inline fn removeOrError(set: *Set, item: anytype) Dict.RemoveError!void {
    try set.backing_dict.removeOrError(item);
}

pub inline fn removeOrLeave(set: *Set, item: anytype) void {
    set.backing_dict.removeOrLeave(item);
}

// == Combining sets ==
pub inline fn combine(set1: Set, set2: Set) Set {
    var combine_set = set1;
    var iterator = set2.backing_dict.iterateKeys();

    while (iterator.next()) |key|
        combine_set.add(key);

    return combine_set;
}

pub inline fn combineOrError(set1: Set, set2: Set) Dict.AddError!Set {
    if (!set1.isDisjoint(set2))
        return Dict.AddError.KeyAlreadyExists;

    return set1.combine(set2);
}

pub inline fn combineOrLeave(set1: Set, set2: Set) Set {
    var combine_set = set1;
    var iterator = set2.backing_dict.iterateKeys();

    while (iterator.next()) |key|
        combine_set.addOrLeave(key);

    return combine_set;
}

pub inline fn intersection(set1: Set, set2: Set) Set {
    var intersection_set = Set{};
    var iterator = set1.backing_dict.iterateKeys();

    while (iterator.next()) |key|
        if (set2.has(key))
            intersection_set.add(key);

    return intersection_set;
}

pub inline fn isDisjoint(set1: Set, set2: Set) bool {
    var iterator = set1.backing_dict.iterateKeys();

    return while (iterator.next()) |key| {
        if (set2.has(key)) break false;
    } else true;
}

// == Testing ==
test has {
    comptime {
        const set = Set.from(.{.item});
        t.comptryIsTrue(set.has(.item));
        t.comptryIsTrue(!set.has(.not_item));
    }
}

test size {
    comptime {
        var set = Set{};
        t.comptry(std.testing.expectEqual(0, set.size()));

        set.add(.item_1);
        t.comptry(std.testing.expectEqual(1, set.size()));

        set.add(.item_2);
        t.comptry(std.testing.expectEqual(2, set.size()));
    }
}

test add {
    comptime {
        var set = Set{};
        t.comptryIsTrue(!set.has(.item));

        set.add(.item_1);
        t.comptryIsTrue(set.has(.item_1));

        set.add(.item_2);
        t.comptryIsTrue(set.has(.item_1));
        t.comptryIsTrue(set.has(.item_2));
    }
}

test addOrError {
    comptime {
        var set = Set{};

        const not_err = set.addOrError(.item);
        const yes_err = set.addOrError(.item);

        t.comptry(std.testing.expectEqual({}, not_err));
        t.comptry(std.testing.expectEqual(Dict.AddError.KeyAlreadyExists, yes_err));
    }
}

test addOrLeave {
    comptime {
        var set = Set{};

        t.comptryIsTrue(!set.has(.item));

        set.addOrLeave(.item);
        t.comptryIsTrue(set.has(.item));

        set.addOrLeave(.item);
        t.comptryIsTrue(set.has(.item));
    }
}

test addOrRemove {
    comptime {
        var set = Set{};
        t.comptryIsTrue(!set.has(.item));

        set.addOrRemove(.item);
        t.comptryIsTrue(set.has(.item));

        set.addOrRemove(.item);
        t.comptryIsTrue(!set.has(.item));

        set.addOrRemove(.item);
        t.comptryIsTrue(set.has(.item));
    }
}

test remove {
    comptime {
        var set = Set.from(.{.item});
        t.comptryIsTrue(set.has(.item));

        set.remove(.item);
        t.comptryIsTrue(!set.has(.item));
    }
}

test removeOrError {
    comptime {
        var set = Set.from(.{.item});
        t.comptryIsTrue(set.has(.item));

        const not_err = set.removeOrError(.item);
        const yes_err = set.removeOrError(.item);

        t.comptry(std.testing.expectEqual({}, not_err));
        t.comptry(std.testing.expectEqual(Dict.RemoveError.KeyDoesNotExist, yes_err));
    }
}

test removeOrLeave {
    comptime {
        var set = Set.from(.{.item});
        t.comptryIsTrue(set.has(.item));

        set.removeOrLeave(.item);
        t.comptryIsTrue(!set.has(.item));

        set.removeOrLeave(.item);
        t.comptryIsTrue(!set.has(.item));
    }
}

test isDisjoint {
    comptime {
        const set1 = Set.from(.{ .a, .b });
        const set2 = Set.from(.{ .b, .c });
        const set3 = Set.from(.{ .c, .d });

        t.comptryIsTrue(!set1.isDisjoint(set2));
        t.comptryIsTrue(set1.isDisjoint(set3));
        t.comptryIsTrue(!set2.isDisjoint(set3));
    }
}

test combine {
    comptime {
        const set1 = Set.from(.{ .a, .b });
        const set2 = Set.from(.{ .c, .d });

        const set3 = set1.combine(set2);

        t.comptryIsTrue(set3.has(.a));
        t.comptryIsTrue(set3.has(.b));
        t.comptryIsTrue(set3.has(.c));
        t.comptryIsTrue(set3.has(.d));
    }
}

test combineOrError {
    comptime {
        const set1 = Set.from(.{ .a, .b });
        const set2 = Set.from(.{ .b, .c });
        const set3 = Set.from(.{ .c, .d });

        t.comptry(std.testing.expectError(Dict.AddError.KeyAlreadyExists, set1.combineOrError(set2)));

        const set4 = t.comptry(set1.combineOrError(set3));

        t.comptryIsTrue(set4.has(.a));
        t.comptryIsTrue(set4.has(.b));
        t.comptryIsTrue(set4.has(.c));
        t.comptryIsTrue(set4.has(.d));

        t.comptry(std.testing.expectError(Dict.AddError.KeyAlreadyExists, set2.combineOrError(set3)));
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

        t.comptryIsTrue(set12.has(.a));
        t.comptryIsTrue(set12.has(.b));
        t.comptryIsTrue(set12.has(.c));
        t.comptryIsTrue(!set12.has(.d));

        t.comptryIsTrue(!set23.has(.a));
        t.comptryIsTrue(set23.has(.b));
        t.comptryIsTrue(set23.has(.c));
        t.comptryIsTrue(set23.has(.d));

        t.comptryIsTrue(set13.has(.a));
        t.comptryIsTrue(set13.has(.b));
        t.comptryIsTrue(set13.has(.c));
        t.comptryIsTrue(set13.has(.d));
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

        t.comptryIsTrue(!set12.has(.a));
        t.comptryIsTrue(set12.has(.b));
        t.comptryIsTrue(!set12.has(.c));
        t.comptryIsTrue(!set12.has(.d));

        t.comptryIsTrue(!set13.has(.a));
        t.comptryIsTrue(!set13.has(.b));
        t.comptryIsTrue(!set13.has(.c));
        t.comptryIsTrue(!set13.has(.d));

        t.comptryIsTrue(!set23.has(.a));
        t.comptryIsTrue(!set23.has(.b));
        t.comptryIsTrue(set23.has(.c));
        t.comptryIsTrue(!set23.has(.d));

        t.comptryIsTrue(!set123.has(.a));
        t.comptryIsTrue(!set123.has(.b));
        t.comptryIsTrue(!set123.has(.c));
        t.comptryIsTrue(!set123.has(.d));
    }
}

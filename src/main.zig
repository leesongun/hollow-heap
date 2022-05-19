//!testing doc comment
//https://github.com/ziglang/zig/issues/1108

//and potentially
//https://github.com/ziglang/zig/issues/3952

const std = @import("std");
const Allocator = std.mem.Allocator;
const assert = std.debug.assert;

const K = usize;
const max_rank = 50;
const Rank = std.math.IntFittingRange(0, max_rank);

const Self = *@This();
pub const Queue = ?Self;

key: K,
child: ?Self = null,
//younger sibling
next: ?Self = null,
//second parent
mom: ?Self = null,
rank: Rank = 0,

fn add_child(noalias self: Self, noalias child: Self) Self {
    child.next = self.child;
    self.child = child;
    return self;
}

fn is_hollow(self: Self) bool {
    return self.mom != null;
}

//make hollow node
//not recommended
pub fn empty(allocator: Allocator) Self {
    const ret = allocator.create(@This()) catch unreachable;
    ret.* = .{ .key = null };
    return ret;
}

pub fn new(k: K, allocator: Allocator) Self {
    const ret = allocator.create(@This()) catch unreachable;
    ret.* = .{ .key = k };
    return ret;
}

pub fn delete(self: Self) void {
    assert(self.mom == null);
    self.mom = self;
}

//normalize
pub fn min(self: Self) K {
    assert(self.mom == null);
    return self.key;
}

//add meld?
pub fn link(noalias a: Self, noalias b: Self) Self {
    //change to cmp operator
    return if (a.key >= b.key) b.add_child(a) else a.add_child(b);
}

//create is enough, don't need whole Allocator
/// decrease-key
pub fn decrease(self: Self, entry: Self, newkey: K, allocator: Allocator) Self {
    //this is simply optimization, unnecessary
    if (self == entry) {
        self.key = newkey;
        return self;
    }
    //todo : proper error handling
    const v = allocator.create(@This()) catch unreachable;
    v.* = .{
        .key = newkey,
        .child = entry,
        .rank = entry.rank -| 2,
    };
    entry.mom = v;
    return link(v, self);
}

pub fn normalize(self: Self, allocator: Allocator) ?Self {
    if (self.mom == null) return self;
    var A = [1]?Self{null} ** max_rank;
    var real_max_rank: Rank = 0;

    var h: ?Self = self;
    while (h) |v| {
        defer allocator.destroy(v);
        h = v.next;
        //loop for all child of h
        var ww = v.child;
        while (ww) |w| {
            var u = w;
            ww = w.next;
            //case d
            if (u.mom == null) {
                u.next = null;
                //do ranked link
                while (A[u.rank]) |x| {
                    assert(x != u);
                    u = link(u, x);
                    A[u.rank] = null;
                    u.rank += 1;
                }
                A[u.rank] = u;
                if (u.rank >= real_max_rank) {
                    real_max_rank = u.rank + 1;
                }
            } //case a
            else if (u.mom == u) {
                // h.child = u.next;
                // assert(u.next == null);
                u.next = h;
                h = u;
            } else {
                //case b
                if (u.mom == v) {
                    ww = null;
                }
                //case c
                else u.next = null;
                u.mom = u;
            }
        }
    }

    return fold_links(A[0..real_max_rank]);
}

//unranked-links
fn fold_links(arr: []?Self) ?Self {
    var ret: ?Self = null;
    for (arr) |x| {
        if (x) |y| {
            ret = if (ret) |t| link(t, y) else y;
        }
    }
    return ret;
}

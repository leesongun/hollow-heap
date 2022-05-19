//!testing doc comment
//https://github.com/ziglang/zig/issues/1108

//and potentially
//https://github.com/ziglang/zig/issues/3952

//! requires somewhat allocator
//! to remove

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

fn is_full(self: Self) bool {
    return self.mom == null;
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
    assert(entry.mom == null);
    //todo : proper error handling
    entry.mom = allocator.create(@This()) catch unreachable;
    entry.mom.?.* = .{
        .key = newkey,
        .child = entry,
        .rank = entry.rank -| 2,
    };
    return entry.mom.?.link(self);
}

pub fn normalize(self: Self, allocator: Allocator) ?Self {
    if (self.mom == null) return self;
    var A = [1]?Self{null} ** max_rank;
    var real_max_rank: Rank = 0;

    var parent: ?Self = self;
    while (parent) |p| {
        //if nothing changes, try next sibling
        parent = p.next;
        defer allocator.destroy(p);

        //loop for all child
        var child = p.child;
        while (child) |c| {
            child = c.next;
            //case d
            if (c.mom == null) {
                c.next = null;
                var cc = c;

                //do ranked link
                for (A[c.rank..]) |*y| {
                    if (y.*) |z| {
                        cc = cc.link(z);
                        cc.rank += 1;
                        y.* = null;
                    } else {
                        y.* = cc;
                        break;
                    }
                } else unreachable;
                if (cc.rank > real_max_rank) {
                    real_max_rank = cc.rank;
                }
            } else if (c.mom == c) {
                c.next = parent;
                parent = c;
            } else {
                if (c.mom == p) {
                    child = null;
                } else c.next = null;
                c.mom = c;
            }
        }
    }

    return unranked_links(A[0 .. real_max_rank + 1]);
}
// is it better to simply reserve rank 0/rank -1 for hollow node?

//doing only one step of normalization
//just to show how it works
// pub fn normalize_one_step(){

// }

//don't remove hollow nodes that is guaranteed to have higher node than others
//requires hollow node's key to be valid
// pub fn normalize_early_stop(self: Self, allocator: Allocator) ?Self {

// }

//unranked-links
fn unranked_links(arr: []?Self) ?Self {
    var ret: ?Self = null;
    for (arr) |x| {
        if (x) |y| {
            ret = if (ret) |t| y.link(t) else y;
        }
    }
    return ret;
}

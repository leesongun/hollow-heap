//https://github.com/ziglang/zig/issues/1108

//and potentially
//https://github.com/ziglang/zig/issues/3952

const std = @import("std");
const Allocator = std.mem.Allocator;
const assert = std.debug.assert;

const K = usize;
const max_rank = 50;
const Rank = std.math.IntFittingRange(0, max_rank);

//change to *@This()?
const Self = *@This();

key: ?K,
child: ?Self = null,
//younger sibling
next: ?Self = null,
//second parent
mom: ?Self = null,
rank: Rank = 0,

fn add_child(noalias self: Self, noalias child: Self) void {
    child.next = self.child;
    self.child = child;
}

pub fn new(k: K, allocator: Allocator) Self {
    const ret = allocator.create(@This()) catch unreachable;
    ret.* = .{ .key = k };
    return ret;
}

pub fn delete(self: Self) void {
    self.key = null;
}

//normalize
pub fn min(self: Self) K {
    return self.?.key;
}

//meld
pub fn link(noalias a: Self, noalias b: Self) Self {
    //change to cmp operator
    //just simply let hollow node as -inf key
    if (a.key.? >= b.key.?) { //or when b is hollow
        b.add_child(a);
        return b;
    } else {
        a.add_child(b);
        return a;
    }
}

pub fn meld(noalias a: Self, noalias b: Self) Self {
    //change to cmp operator
    //just simply let hollow node as -inf key
    if (b == null or (a != null and a.key.? >= b.key.?)) { //or when b is hollow
        b.add_child(a);
        return b;
    } else {
        a.add_child(b);
        return a;
    }
}
//add meld?

//create is enough, don't need whole Allocator
pub fn decrease(self: Self, entry: Self, newkey: K, allocator: Allocator) Self {
    //this is simply optimization,
    //unnecessary it seems
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
    entry.key = null;
    entry.mom = v;
    return link(v, self);
}

pub fn normalize(self: Self, allocator: Allocator) ?Self {
    if (self.key != null) return self;
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
            if (u.key == null) {
                //case a
                if (u.mom == null) {
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
                    u.mom = null;
                }
            }
            //case d
            else {
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

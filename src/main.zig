//https://github.com/ziglang/zig/issues/1108
//https://github.com/ziglang/zig/issues/5611

//and potentially
//https://github.com/ziglang/zig/issues/3952

const std = @import("std");
const Allocator = std.mem.Allocator;
const assert = std.debug.assert;

const K = usize;
const V = usize;
const max_rank = 32;
const Rank = std.math.IntFittingRange(0, max_rank);

//change to *@This()?
const Self = @This();

//do we really need independent item?
//can't we merge it to key?
key: K,
//item = min
//recommend using pointer
item: ?V,
child: ?*Self = null,
//younger sibling
next: ?*Self = null,
//second parent
mom: ?*Self = null,
rank: Rank = 0,

pub fn new(k: K, v: V, allocator: Allocator) *Self {
    const ret = allocator.create(Self) catch unreachable;
    ret.* = Self{
        .key = k,
        .item = v,
    };
    return ret;
}

//normalize
fn min(noalias self: *Self) V {
    return self.item orelse unreachable;
}
fn add_child(noalias self: *Self, noalias child: *Self) void {
    child.*.next = self.child;
    self.*.child = child;
}
fn is_hollow() void {
    unreachable;
}
//meld
pub fn link(noalias a: *Self, noalias b: *Self) *Self {
    //change to cmp operator
    if (a.key >= b.key) {
        b.add_child(a);
        return b;
    } else {
        a.add_child(b);
        return a;
    }
}
//add meld?

//create is enough, don't need whole Allocator
pub fn decrease(self: *Self, entry: *Self, newkey: K, allocator: Allocator) *Self {
    //this is simply optimization,
    //unnecessary it seems
    if (self == entry) {
        self.key = newkey;
        return self;
    }
    //todo : proper error handling
    const v = allocator.create(Self) catch unreachable;
    v.* = Self{
        .key = newkey,
        .item = entry.item,
        .child = entry,
        .rank = entry.rank -| 2,
    };
    entry.item = null;
    entry.mom = v;
    return link(v, self);
}

pub fn delete(self: *Self) void {
    self.item = null;
}

pub fn normalize(self: *Self, allocator: Allocator) ?*Self {
    if (self.item != null) return self;

    var h: ?*Self = self;
    var A = [1]?*Self{null} ** max_rank;
    var real_max_rank: Rank = 0;
    while (h) |v| {
        h = v.next;
        //loop for all child of h
        var ww = v.child;
        while (ww) |w| {
            var u = w;
            ww = w.next;
            //one of case a,b,c
            if (u.item == null) {
                //case a
                if (u.mom == null) {
                    u.next = h;
                    h = u;
                } else {
                    //case b
                    if (u.mom == v) {
                        //v is last child
                        ww = null;
                    }
                    //case c
                    else {
                        u.next = null;
                    }
                    u.mom = null;
                }
            }
            //case d
            else {
                //do ranked link
                while (A[u.rank]) |x| {
                    u = link(u, x);
                    A[u.rank] = null;
                    u.rank += 1;
                }
                A[u.rank] = u;
                if (u.rank >= real_max_rank) {
                    real_max_rank = u.rank + 1;
                }
            }
            allocator.destroy(v);
        }
    }
    //do unranked links
    var ret = h; // which is null
    //up to real_max_rank in paper
    //don't really matter in reality?
    for (A[0..real_max_rank]) |x| {
        if (x) |y| {
            ret = if (ret) |t| link(t, y) else y;
            //deleting A[i] don't have any meaning
        }
    }
    return ret;
}

//https://github.com/ziglang/zig/issues/1108
//https://github.com/ziglang/zig/issues/5611

//and potentially
//https://github.com/ziglang/zig/issues/3952

const K = u32;
const V = u32;
const std = @import("std");
const Allocator = mem.Allocator;
const max_rank = 32;

//change to *@This()?
const Self = @This();
const Rank = std.math.IntFittingRange(0, max_rank);

//do we really need independent item?
//can't we merge it to key?
key: K,
//item = min
item: ?*V,
child: ?*Self = null,
//younger sibling
next: ?*Self = null,
//second parent
mom: ?*Self = null,
rank: Rank = 0,

// pub fn new(k: K, v: V, allocator:Allocator) Self {
//     return .{

//     };
// }

//noalias
fn add_child(noalias self: *Self, noalias child: *Self) void {
    child.*.next = self.child;
    self.*.child = child;
}
fn is_hollow() void {
    unreachable;
}
//meld
pub fn link(noalias a: *Self, noalias b: *Self) *Self {
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
    const v = try allocator.create(Self) catch unreachable;
    v.* = Self{
        .key = newkey,
        .item = entry.item,
        .child = entry,
        .rank = u.rank -| 2,
    };
    entry.item = null;
    entry.mom = v;
    return link(v, self);
}

pub fn delete(self: *Self, a: *Self, allocator: Allocator) ?*Self {
    a.item = null;
    // Non-minimum deletion
    if (self.item != null) return h;
    //from this point a==self

    var h = self;
    var A = [1]?*Self{null} ** max_rank;
    var real_max_rank: Rank = 0;
    while (true) {
        const v = h; //what is this doing?

        //loop for all child of h
        var w = h.child;
        while (w != null) {
            var u = w;
            w = w.next;
            //one of case a,b,c
            if (u.item == null) {
                //case a
                if (u.ep == null) {
                    u.next = h;
                    h = u;
                } else {
                    //case b
                    if (u.ep == v) {
                        //v is last child
                        w = null;
                    }
                    //case c
                    else {
                        u.next = null;
                    }
                    u.ep = null;
                }
            }
            //case d
            else {
                //do ranked link
                while (A[u.rank] != null) {
                    u = link(u, A[u.rank]);
                    A[u.rank] = null;
                    u.rank += 1;
                }
                A[u.rank] = u;
                if (u.rank == real_max_rank) {
                    real_max_rank += 1;
                }
            }
            allocator.destroy(v);
        }
        //make this in defer?
        h = h.next orelse break;
    }
    //do unranked links
    var ret = h; // which is null
    //up to real_max_rank in paper
    //don't really matter in reality?
    for (A[0..real_max_rank]) |x| {
        if (x) |y| {
            if (ret == null) {
                ret = y;
            } else {
                ret = link(ret, y);
            }
            //deleting A[i] don't have any meaning
        }
    }
    return ret;
}

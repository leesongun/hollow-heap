//https://github.com/ziglang/zig/issues/1108

const K = u32;
const V = u32;
const Allocator = @import("std").mem.Allocator;
//change to *@This()?
const Self = @This();

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
rank: u32 = 0,

// pub fn new(k: K, v: V) Self {
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
    var max_rank: u32 = 0;
    var h = self;
    
    //loop for all child
    while (true) {
        //temporarily use ep to track A
        var w = h.child;
        var v = h;
        if(h.next == null)break;
        h = h.next;
        while (w != null) {
            var u = w;
            w = w.next;
            if (u.item == null) {
                if (u.ep == null) {
                    u.next = h;
                    h = u;
                } else {
                    unreachable;
                }
            } else {
                do_ranked_lists(u);
            }
            free(v);
        }
    }
    return h;
}

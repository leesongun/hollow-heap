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
const const_Self = *const @This();
pub const Queue = ?Self;

key: K,
child: ?Self = null,
//younger sibling
next: ?Self = null,
//second parent
//its sole purpose is to know whether access comes from first or second parent
//of which it is last node
mom: ?const_Self = null,
rank: Rank = 0,

fn add_child(noalias self: Self, noalias child: Self) Self {
    child.next = self.child;
    self.child = child;
    return self;
}

fn is_full(self: Self) bool {
    return self.mom == null;
}

/// @brief
/// @param K
/// @param
pub fn new(k: K, allocator: Allocator) Self {
    const ret = allocator.create(@This()) catch unreachable;
    ret.* = .{ .key = k };
    return ret;
}

/// @brief delete an entry
/// @param entry entry to delete
pub fn delete(entry: Self) void {
    assert(entry.mom == null);
    entry.mom = entry;
}

//normalize before
/// @brief minimum key, requires full root
/// @param root root
/// @return minimum key, key of root entry
pub fn min(root: Self) K {
    assert(root.mom == null);
    return root.key;
}

//add meld?
//tie behavior is important for early stop
//if tie, use later as root
/// @brief meld two heaps
/// @param a first heap root
/// @param b second heap root
/// @return new heap root, equal to eiter a or b
/// if key ties, use later as root
pub fn link(noalias a: Self, noalias b: Self) Self {
    //change to cmp operator
    return if (a.key >= b.key) b.add_child(a) else a.add_child(b);
}

//create is enough, don't need whole Allocator
/// @brief decrease key of an entry
/// @param root heap root
/// @param entry entry to decrease
/// @param newkey new key
/// @param allocator allocator to allocate new node
/// @return new heap root and new entry
pub fn decrease(root: Self, entry: Self, newkey: K, allocator: Allocator) [2]Self {
    //this is simply optimization, unnecessary
    assert(newkey <= entry.key);
    if (root == entry) {
        root.key = newkey;
        return .{ root, root };
    }
    assert(entry.mom == null);
    //todo : proper error handling
    const v = allocator.create(@This()) catch unreachable;
    v.* = .{
        .key = newkey,
        .child = entry,
        .rank = entry.rank -| 2,
    };
    entry.mom = v;
    return .{ v.link(root), v };
}

/// @brief recursively remove hollow roots
/// @param root heap root
/// @param allocator allocator
/// @return new heap root
pub fn normalize(root: Self, allocator: Allocator) ?Self {
    if (root.mom == null) return root;
    var A = [1]?Self{null} ** max_rank;
    var real_max_rank: Rank = 0;

    var parent: ?Self = root;
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
                        //give hint to llvm
                        assert(cc.rank == z.rank);
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
//tie behavior of meld is important
//known_key : suspsected minimum
//lesser than actual `known_key` : too early stop, possibly result in hollow root
//larger than actual `known_key` : later stop, possibly result in slight eager contraction of hollow root
//`slight` : because we update known_key &
// first child is likely to have high rank
// so it is likely to have low key
// so heuristically speaking, low keys are considered first
// which means known_key is updated very fast
pub fn normalize_early_stop(root: Self, known_key: K, allocator: Allocator) ?Self {
    if (root.mom == null) return root;
    var A = [1]?Self{null} ** max_rank;
    var real_max_rank: Rank = 0;
    var min_key = known_key;

    var parent: ?Self = root;
    while (parent) |p| {
        //if nothing changes, try next sibling
        parent = p.next;
        defer allocator.destroy(p);

        //loop for all child
        var child = p.child;
        while (child) |c| {
            child = c.next;
            //case d
            if (c.mom == null or (c.key >= min_key and c.mom == c)) {
                //update is unneeded if min_key is correct
                if (c.mom == null and c.key < min_key) {
                    min_key = c.key;
                }
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

const Queue = @import("main.zig");
const std = @import("std");
const prng = std.rand.DefaultPrng;
const alloc = std.heap.page_allocator;
const expectEqual = std.testing.expectEqual;
const N = 255;

test "heapsort" {
    var rand = prng.init(1);
    var data: [N]usize = undefined;
    for (data) |*x, i| {
        x.* = i;
    }
    rand.random().shuffle(usize, &data);
    var head = Queue.new(data[0], alloc);
    for (data[1..]) |x| {
        var temp = Queue.new(x, alloc);
        head = Queue.link(head, temp);
    }
    for (data) |_, i| {
        try expectEqual(head.key, i);
        head.delete();
        if (i != N - 1) {
            head = head.normalize(alloc).?;
        }
    }
    // rand.Random.bytes(256);
}

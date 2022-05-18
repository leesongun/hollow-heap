const Queue = @import("main.zig");
const std = @import("std");
const prng = std.rand.DefaultPrng;
const alloc = std.heap.page_allocator;
const expectEqual = std.testing.expectEqual;
test "heapsort" {
    var rand = prng.init(1);
    var data : [255]u8 = undefined;
    for (data) |*x, i|{
        x.* = i;
    }
    rand.Random.shuffle(u8, &data);
    var head = Queue.new(data[0], data[0], alloc);
    for (data[1..]) |x|{
        var temp = Queue.new(x, x, alloc);
        head = Queue.link(head, temp);
    }
    for(data) |_, i|{
        expectEqual(head.*.key, i);
        head.delete();
        head.normalize(alloc);
    }
    // rand.Random.bytes(256);
}

const Queue = @import("main.zig");
const std = @import("std");
const prng = std.rand.DefaultPrng;
const alloc = std.heap.page_allocator;
const expectEqual = std.testing.expectEqual;
const N = 255;
const M = 1; //number of decrease key per round

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

test "heapsort with reduce key" {
    var rand = prng.init(1);
    var data: [N]usize = undefined;
    var nodes: [N]*Queue = undefined;

    //initialize shuffled data
    for (data) |*x, i| {
        x.* = i + M * N;
    }
    rand.random().shuffle(usize, &data);

    //make nodes
    for (nodes) |*x, i| {
        x.* = Queue.new(data[i], alloc);
    }

    //meld nodes
    var head = nodes[0];
    for (nodes[1..]) |x| {
        head = head.link(x);
    }

    for (data) |_, i| {
        for (data[i..]) |*x, j| {
            x.* = j + M * (N - i - 1);
        }
        rand.random().shuffle(usize, data[i..]);

        for (nodes[i..]) |*x, j| {
            head = head.decrease(x.*, data[i + j], alloc);

            x.* = x.*.mom orelse x.*;
        }

        try expectEqual(head.key, (N - i - 1) * M);
        // try expectEqual(head.key, N * M + i);
        head.delete();
        head = head.normalize(alloc) orelse {
            try expectEqual(i, (N - 1));
            return;
        };
    }
    // rand.Random.bytes(256);
}

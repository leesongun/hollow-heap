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

test "heapsort with reduce key" {
    var rand = prng.init(1);
    var data: [N]usize = undefined;
    var nodes: [N]?*Queue = undefined;

    //prepare random array
    for (data) |*x, i| {
        x.* = i + N * N;
    }
    rand.random().shuffle(usize, &data);

    //make nodes
    for (nodes) |*x, i| {
        x.* = Queue.new(data[i], alloc);
    }

    //meld nodes
    var head = nodes[0].?;
    for (nodes[1..]) |x| {
        head = head.link(x.?);
    }

    //test `N` rounds
    for (data) |_, i| {
        //prepare random array
        for (data[i..]) |*x, j| {
            x.* = j + N * (N - i - 1);
        }
        rand.random().shuffle(usize, data[i..]);

        //decrease each node
        var t = i;
        for (nodes) |*x| {
            if (x.*) |y| {
                const temp = head.decrease(y, data[t], alloc);
                head = temp[0];
                x.* = temp[1];
                t += 1;
            }
        }

        //test number of non-null nodes
        try expectEqual(t, N);

        //test heap min result
        try expectEqual(head.key, (N - i - 1) * N);

        //remove pointer to going-to-remove node
        for (nodes) |*x| {
            if (x.* == head)
                x.* = null;
        }

        //delete min
        head.delete();

        //normalize, only
        // head = head.normalize(alloc) orelse {
        //     //normalizing-to-empty can only happen when `i == N - 1`
        //     try expectEqual(i, (N - 1));
        //     return;
        // };

        head = head.normalize_early_stop(N * N, alloc) orelse {
            //normalizing-to-empty can only happen when `i == N - 1`
            try expectEqual(i, (N - 1));
            return;
        };
    }
}

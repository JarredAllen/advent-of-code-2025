const std = @import("std");

const Coord = struct {
    x: u32,
    y: u32,
    z: u32,
};

fn coord_from_line(line: []const u8) !Coord {
    var parts = std.mem.splitScalar(u8, line, ',');
    const x = try std.fmt.parseInt(u32, parts.next() orelse return error.MalformedInput, 10);
    const y = try std.fmt.parseInt(u32, parts.next() orelse return error.MalformedInput, 10);
    const z = try std.fmt.parseInt(u32, parts.next() orelse return error.MalformedInput, 10);
    return Coord{ .x = x, .y = y, .z = z };
}

fn box_distance(a: Coord, b: Coord) !u64 {
    return std.math.cast(u64, std.math.pow(i64, try std.math.sub(i33, a.x, b.x), 2) + std.math.pow(i64, try std.math.sub(i33, a.y, b.y), 2) + std.math.pow(i64, try std.math.sub(i33, a.z, b.z), 2)) orelse return error.UnexpectedOutOfRange;
}

fn circuit_distance(a: []const Coord, b: []const Coord) !u64 {
    var min_dist: u64 = std.math.maxInt(u64);
    for (a) |a_box| {
        for (b) |b_box| {
            const dist = try box_distance(a_box, b_box);
            if (dist < min_dist) {
                min_dist = dist;
            }
        }
    }
    return min_dist;
}

fn comp_longer(ctx: void, a: std.array_list.Aligned(Coord, null), b: std.array_list.Aligned(Coord, null)) bool {
    _ = ctx;
    return a.items.len > b.items.len;
}

pub fn easy(allocator: std.mem.Allocator, buffer: []const u8, num_steps: u16) !u64 {
    var boxes = try std.array_list.Aligned(std.array_list.Aligned(Coord, null), null).initCapacity(allocator, std.mem.count(u8, buffer, "\n") + 1);
    defer boxes.deinit(allocator);
    var lines = std.mem.splitScalar(u8, buffer, '\n');
    while (lines.next()) |line| {
        var row = try std.array_list.Aligned(Coord, null).initCapacity(allocator, 1);
        row.appendAssumeCapacity(try coord_from_line(line));
        boxes.appendAssumeCapacity(row);
    }

    var distances = try std.array_list.Aligned(u64, null).initCapacity(allocator, boxes.items.len * boxes.items.len);
    for (0..boxes.items.len - 1) |a_idx| {
        for (a_idx + 1..boxes.items.len) |b_idx| {
            distances.appendAssumeCapacity(try box_distance(boxes.items[a_idx].items[0], boxes.items[b_idx].items[0]));
        }
    }
    std.sort.pdq(u64, distances.items, {}, std.sort.asc(u64));
    const max_distance_to_merge = distances.items[num_steps - 1];
    distances.deinit(allocator);

    while (true) {
        var closest_a: usize = 0;
        var closest_b: usize = 0;
        var closest_dist: u64 = std.math.maxInt(u64);
        for (0..boxes.items.len - 1) |a_idx| {
            for (a_idx + 1..boxes.items.len) |b_idx| {
                const ab_dist = try circuit_distance(boxes.items[a_idx].items, boxes.items[b_idx].items);
                if (ab_dist < closest_dist) {
                    closest_dist = ab_dist;
                    closest_a = a_idx;
                    closest_b = b_idx;
                }
            }
        }
        if (closest_dist > max_distance_to_merge) {
            break;
        }
        // std.debug.print("Merging {any} and {any} with distance {}\n", .{ boxes.items[closest_a].items, boxes.items[closest_b].items, closest_dist });
        var b = boxes.swapRemove(closest_b);
        try boxes.items[closest_a].appendSlice(allocator, b.items);
        b.deinit(allocator);
    }

    // std.debug.print("Number of circuits left: {}\n", .{boxes.items.len});
    std.sort.pdq(std.array_list.Aligned(Coord, null), boxes.items, {}, comp_longer);

    const ans = boxes.items[0].items.len * boxes.items[1].items.len * boxes.items[2].items.len;
    // std.debug.print("Answer: {} ({}, {}, {})\n", .{ ans, boxes.items[0].items.len, boxes.items[1].items.len, boxes.items[2].items.len });

    for (boxes.items) |*box| {
        // We might leak in the presence of an error, but that's okay
        box.deinit(allocator);
    }

    return ans;
}

fn xs_prod(a: []const Coord, b: []const Coord) !u64 {
    var min_dist: u64 = std.math.maxInt(u64);
    var min_xs_prod: u64 = 0;
    for (a) |a_box| {
        for (b) |b_box| {
            const dist = try box_distance(a_box, b_box);
            if (dist < min_dist) {
                min_dist = dist;
                min_xs_prod = a_box.x * b_box.x;
            }
        }
    }
    return min_xs_prod;
}

pub fn hard(allocator: std.mem.Allocator, buffer: []const u8) !u64 {
    var boxes = try std.array_list.Aligned(std.array_list.Aligned(Coord, null), null).initCapacity(allocator, std.mem.count(u8, buffer, "\n") + 1);
    defer boxes.deinit(allocator);
    var lines = std.mem.splitScalar(u8, buffer, '\n');
    while (lines.next()) |line| {
        var row = try std.array_list.Aligned(Coord, null).initCapacity(allocator, 1);
        row.appendAssumeCapacity(try coord_from_line(line));
        boxes.appendAssumeCapacity(row);
    }

    var last_xs_prod: u64 = 0;
    while (boxes.items.len > 1) {
        var closest_a: usize = 0;
        var closest_b: usize = 0;
        var closest_dist: u64 = std.math.maxInt(u64);
        for (0..boxes.items.len - 1) |a_idx| {
            for (a_idx + 1..boxes.items.len) |b_idx| {
                const ab_dist = try circuit_distance(boxes.items[a_idx].items, boxes.items[b_idx].items);
                if (ab_dist < closest_dist) {
                    closest_dist = ab_dist;
                    closest_a = a_idx;
                    closest_b = b_idx;
                }
            }
        }
        if (boxes.items.len == 2) {
            last_xs_prod = try xs_prod(boxes.items[0].items, boxes.items[1].items);
        }
        var b = boxes.swapRemove(closest_b);
        try boxes.items[closest_a].appendSlice(allocator, b.items);
        b.deinit(allocator);
    }

    for (boxes.items) |*box| {
        // We might leak in the presence of an error, but that's okay
        box.deinit(allocator);
    }

    return last_xs_prod;
}

test "easy given example" {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();
    try std.testing.expect(try easy(allocator, "162,817,812\n57,618,57\n906,360,560\n592,479,940\n352,342,300\n466,668,158\n542,29,236\n431,825,988\n739,650,466\n52,470,668\n216,146,977\n819,987,18\n117,168,530\n805,96,715\n346,949,466\n970,615,88\n941,993,340\n862,61,35\n984,92,344\n425,690,689", 10) == 40);
}

test "hard given example" {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();
    try std.testing.expect(try hard(allocator, "162,817,812\n57,618,57\n906,360,560\n592,479,940\n352,342,300\n466,668,158\n542,29,236\n431,825,988\n739,650,466\n52,470,668\n216,146,977\n819,987,18\n117,168,530\n805,96,715\n346,949,466\n970,615,88\n941,993,340\n862,61,35\n984,92,344\n425,690,689") == 25272);
}

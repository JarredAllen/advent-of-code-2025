const std = @import("std");

const Tile = struct {
    x: u32,
    y: u32,
};

fn parse_tile(line: []const u8) !Tile {
    var parts = std.mem.splitScalar(u8, line, ',');
    const x = try std.fmt.parseInt(u32, parts.next() orelse return error.MalformedInput, 10);
    const y = try std.fmt.parseInt(u32, parts.next() orelse return error.MalformedInput, 10);
    return Tile{ .x = x, .y = y };
}

fn rect_area(a: Tile, b: Tile) !u64 {
    const area = (try std.math.sub(i64, a.x, b.x) + 1) * (try std.math.sub(i64, a.y, b.y) + 1);
    if (area < 0) {
        return std.math.cast(u64, -area) orelse 0;
    } else {
        return std.math.cast(u64, area) orelse 0;
    }
}

pub fn easy(allocator: std.mem.Allocator, buffer: []const u8) !u64 {
    var reds = try std.array_list.Aligned(Tile, null).initCapacity(allocator, 16);
    defer reds.deinit(allocator);

    var lines = std.mem.splitScalar(u8, buffer, '\n');
    while (lines.next()) |line| {
        try reds.append(allocator, try parse_tile(line));
    }

    var max_area: u64 = 1;

    for (reds.items) |a| {
        for (reds.items) |b| {
            const area = try rect_area(a, b);
            if (area > max_area) {
                max_area = area;
            }
        }
    }

    return max_area;
}

test "easy given example" {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();
    try std.testing.expect(try easy(allocator, "7,1\n11,1\n11,7\n9,7\n9,5\n2,5\n2,3\n7,3") == 50);
}

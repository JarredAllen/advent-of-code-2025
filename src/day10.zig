const std = @import("std");

const Machine = struct {
    desired_lights: u32,
    buttons: std.array_list.Aligned(u32, null),
    joltages: std.array_list.Aligned(u32, null),

    fn deinit(self: *Machine, allocator: std.mem.Allocator) void {
        self.buttons.deinit(allocator);
        self.joltages.deinit(allocator);
    }

    fn min_presses(self: *const Machine, allocator: std.mem.Allocator) !u64 {
        var frontier = std.hash_map.HashMap(u32, void, std.hash_map.AutoContext(u32), 30).init(allocator);
        try frontier.put(0, {});
        var len: u64 = 1;
        while (true) {
            var next_frontier = std.hash_map.HashMap(u32, void, std.hash_map.AutoContext(u32), 30).init(allocator);
            var frontier_iter = frontier.keyIterator();
            while (frontier_iter.next()) |prev| {
                for (self.buttons.items) |button| {
                    const next = prev.* ^ button;
                    if (next == self.desired_lights) {
                        frontier.deinit();
                        next_frontier.deinit();
                        return len;
                    }
                    try next_frontier.put(next, {});
                }
            }
            frontier.deinit();
            frontier = next_frontier;
            len += 1;
            if (len > 20) {
                frontier.deinit();
                return error.FoundNoPath;
            }
        }
    }
};

fn parse_machine(line: []const u8, allocator: std.mem.Allocator) !Machine {
    var chunks = std.mem.splitScalar(u8, line, ' ');
    const desired_str = chunks.next() orelse return error.Malformed;
    var desired_lights: u32 = 0;
    var light_idx: u32 = 1;
    for (desired_str) |c| {
        switch (c) {
            '.' => {
                light_idx <<= 1;
            },
            '#' => {
                desired_lights |= light_idx;
                light_idx <<= 1;
            },
            else => {},
        }
    }
    var buttons = try std.array_list.Aligned(u32, null).initCapacity(allocator, std.mem.count(u8, line, " "));
    while (chunks.next()) |chunk| {
        if (chunk[0] == '{') {
            var joltages = try std.array_list.Aligned(u32, null).initCapacity(allocator, std.mem.count(u8, chunk, ",") + 1);
            var joltage_chunks = std.mem.splitScalar(u8, chunk[1 .. chunk.len - 1], ',');
            while (joltage_chunks.next()) |joltage_chunk| {
                const joltage = try std.fmt.parseInt(u32, joltage_chunk, 10);
                joltages.appendAssumeCapacity(joltage);
            }
            // We've hit the last chunk, parse and exit.
            return Machine{
                .desired_lights = desired_lights,
                .buttons = buttons,
                .joltages = joltages,
            };
        }
        var button: u32 = 0;
        var button_toggles = std.mem.splitScalar(u8, chunk[1 .. chunk.len - 1], ',');
        while (button_toggles.next()) |button_toggle| {
            const toggle = try std.fmt.parseInt(u5, button_toggle, 10);
            button |= (std.math.cast(u32, 1) orelse 1) << toggle;
        }
        buttons.appendAssumeCapacity(button);
    }
    return error.MalformedInput;
}

pub fn easy(allocator: std.mem.Allocator, buffer: []const u8) !u64 {
    var num_presses: u64 = 0;

    var lines = std.mem.splitScalar(u8, buffer, '\n');
    while (lines.next()) |line| {
        var machine = try parse_machine(line, allocator);
        // std.debug.print("Machine {s}: {}\n", .{ line, machine });
        defer machine.deinit(allocator);
        const machine_presses = try machine.min_presses(allocator);
        // std.debug.print("Machine {s}: {} presses\n", .{ line, machine_presses });
        num_presses += machine_presses;
    }

    return num_presses;
}

test "easy given example" {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();
    try std.testing.expect(try easy(allocator, "[.##.] (3) (1,3) (2) (2,3) (0,2) (0,1) {3,5,4,7}\n[...#.] (0,2,3,4) (2,3) (0,4) (0,1,2) (1,2,3,4) {7,5,12,7,2}\n[.###.#] (0,1,2,3,4) (0,3,4) (0,1,2,4,5) (1,2) {10,11,11,5,10,5}") == 7);
}

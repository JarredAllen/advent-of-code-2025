const std = @import("std");

const Machine = struct {
    desired_lights: u32,
    buttons: std.array_list.Aligned(u32, null),
    joltages: std.array_list.Aligned(u32, null),

    fn deinit(self: *Machine, allocator: std.mem.Allocator) void {
        self.buttons.deinit(allocator);
        self.joltages.deinit(allocator);
    }

    fn min_presses_lights(self: *const Machine, allocator: std.mem.Allocator) !u64 {
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

    fn min_presses_joltages(self: *const Machine, allocator: std.mem.Allocator) !u64 {
        const QueueEntry = struct {
            distance: u32,
            remaining: std.array_list.Aligned(u32, null),

            fn heuristic(this: @This()) u32 {
                return this.distance + std.mem.max(u32, this.remaining.items);
            }

            fn cmpFunc(context: void, a: @This(), b: @This()) std.math.Order {
                _ = context;
                return std.math.order(a.heuristic(), b.heuristic());
            }

            fn push_button(this: @This(), button: u32, alloc: std.mem.Allocator) !@This() {
                var remaining = try std.array_list.Aligned(u32, null).initCapacity(alloc, this.remaining.items.len);
                for (0..this.remaining.items.len) |idx| {
                    if (button & (@as(u32, 1) << (std.math.cast(u5, idx) orelse return error.FailedCast)) != 0) {
                        remaining.appendAssumeCapacity(std.math.sub(u32, this.remaining.items[idx], 1) catch 0);
                    } else {
                        remaining.appendAssumeCapacity(this.remaining.items[idx]);
                    }
                }
                const new_distance = this.distance + 1;
                return .{
                    .distance = new_distance,
                    .remaining = remaining,
                };
            }

            fn is_done(this: @This()) bool {
                for (this.remaining.items) |remaining| {
                    if (remaining > 0) {
                        return false;
                    }
                }
                return true;
            }

            fn deinit(this: *@This(), alloc: std.mem.Allocator) void {
                this.remaining.deinit(alloc);
            }
        };

        var queue = std.PriorityQueue(QueueEntry, void, QueueEntry.cmpFunc).init(allocator, {});
        defer queue.deinit();
        try queue.add(QueueEntry{
            .distance = 0,
            .remaining = self.joltages,
        });
        while (true) {
            var prev_entry = queue.remove();
            defer prev_entry.deinit(allocator);
            for (self.buttons.items) |button| {
                const next_entry = try prev_entry.push_button(button, allocator);
                if (next_entry.is_done()) {
                    return next_entry.distance;
                }
                try queue.add(next_entry);
            }
        }
    }
};

fn joltages_after_press(button: u32, prev: []const u32, allocator: std.mem.Allocator) !std.array_list.Aligned(u32, null) {
    var joltages = try std.array_list.Aligned(u32, null).initCapacity(allocator, prev.len);
    for (0..prev.len) |idx| {
        if (button & (@as(u32, 1) << (std.math.cast(u5, idx) orelse return error.FailedCast)) != 0) {
            joltages.appendAssumeCapacity(prev[idx] + 1);
        } else {
            joltages.appendAssumeCapacity(prev[idx]);
        }
    }
    return joltages;
}
fn joltages_enough(joltages: []const u32, goal: []const u32) bool {
    for (0..joltages.len) |idx| {
        if (joltages[idx] < goal[idx]) {
            return false;
        }
    }
    return true;
}

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
        defer machine.deinit(allocator);
        const machine_presses = try machine.min_presses_lights(allocator);
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

pub fn hard(allocator: std.mem.Allocator, buffer: []const u8) !u64 {
    var num_presses: u64 = 0;

    var lines = std.mem.splitScalar(u8, buffer, '\n');
    while (lines.next()) |line| {
        var machine = try parse_machine(line, allocator);
        defer machine.deinit(allocator);
        const machine_presses = try machine.min_presses_joltages(allocator);
        num_presses += machine_presses;
    }

    return num_presses;
}

test "hard given example" {
    var alloc = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer _ = alloc.deinit();
    const allocator = alloc.allocator();
    try std.testing.expect(try hard(allocator, "[.##.] (3) (1,3) (2) (2,3) (0,2) (0,1) {3,5,4,7}\n[...#.] (0,2,3,4) (2,3) (0,4) (0,1,2) (1,2,3,4) {7,5,12,7,2}\n[.###.#] (0,1,2,3,4) (0,3,4) (0,1,2,4,5) (1,2) {10,11,11,5,10,5}") == 33);
}

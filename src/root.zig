//! By convention, root.zig is the root source file when making a library.
const std = @import("std");

pub fn day1easy(buffer: []const u8) !u16 {
    var dial: i16 = 50;
    var password: u16 = 0;

    var lines = std.mem.splitScalar(u8, buffer, '\n');
    while (lines.next()) |line| {
        if (line.len == 0) continue;
        const turn_size = @mod(try std.fmt.parseInt(i16, line[1..], 10), 100);
        if (line[0] == 'R') {
            dial += turn_size;
        } else {
            dial -= turn_size;
        }
        dial = @mod(dial, 100);
        if (dial == 0) {
            password += 1;
        }
    }
    return password;
}

pub fn day1hard(buffer: []const u8) !u16 {
    var dial: i16 = 50;
    var password: u16 = 0;

    var lines = std.mem.splitScalar(u8, buffer, '\n');
    while (lines.next()) |line| {
        if (line.len == 0) continue;
        const turn_size = try std.fmt.parseInt(u16, line[1..], 10);
        password += turn_size / 100;
        const turn_delta: i8 = @intCast(@mod(turn_size, 100));
        if (line[0] == 'R') {
            dial += turn_delta;
        } else {
            dial -= turn_delta;
        }
        if (dial <= 0 and dial != -turn_delta) {
            password += 1;
        }
        if (dial >= 100) {
            password += 1;
        }
        dial = @mod(dial, 100);
    }
    return password;
}

test "day 1 easy given example" {
    try std.testing.expect(try day1easy("L68\nL30\nR48\nL5\nR60\nL55\nL1\nL99\nR14\nL82\n") == 3);
}

test "day 1 hard given example" {
    try std.testing.expect(try day1hard("L68\nL30\nR48\nL5\nR60\nL55\nL1\nL99\nR14\nL82\n") == 6);
}

pub fn day2easy(allocator: std.mem.Allocator, buffer: []const u8) !u64 {
    var sum: u64 = 0;
    var ranges = std.mem.splitScalar(u8, buffer, ',');
    while (ranges.next()) |range| {
        var bounds = std.mem.splitScalar(u8, range, '-');
        const lower = try std.fmt.parseInt(u64, bounds.next() orelse return error.MalformedInput, 10);
        const upper = try std.fmt.parseInt(u64, bounds.next() orelse return error.MalformedInput, 10);
        for (lower..upper + 1) |id| {
            const id_str = try std.fmt.allocPrint(allocator, "{}", .{id});
            defer allocator.free(id_str);
            if (std.mem.eql(u8, id_str[0 .. id_str.len / 2], id_str[id_str.len / 2 .. id_str.len])) {
                sum += id;
            }
        }
    }
    return sum;
}

pub fn day2hard(allocator: std.mem.Allocator, buffer: []const u8) !u64 {
    var sum: u64 = 0;
    var ranges = std.mem.splitScalar(u8, buffer, ',');
    while (ranges.next()) |range| {
        var bounds = std.mem.splitScalar(u8, range, '-');
        const lower = try std.fmt.parseInt(u64, bounds.next() orelse return error.MalformedInput, 10);
        const upper = try std.fmt.parseInt(u64, bounds.next() orelse return error.MalformedInput, 10);
        for (lower..upper + 1) |id| {
            const id_str = try std.fmt.allocPrint(allocator, "{}", .{id});
            defer allocator.free(id_str);
            for (1..id_str.len / 2 + 1) |chunk_len| {
                const num_chunks = id_str.len / chunk_len;
                if (num_chunks <= 1) {
                    continue;
                }
                if (num_chunks * chunk_len != id_str.len) {
                    continue;
                }
                const first_chunk = id_str[0..chunk_len];
                var any_mismatch = false;
                for (1..num_chunks) |chunk_num| {
                    const chunk = id_str[chunk_num * chunk_len .. (chunk_num + 1) * chunk_len];
                    if (!std.mem.eql(u8, first_chunk, chunk)) {
                        any_mismatch = true;
                        break;
                    }
                }
                if (!any_mismatch) {
                    sum += id;
                    break;
                }
            }
        }
    }
    return sum;
}

test "day 2 easy given example" {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();
    try std.testing.expect(try day2easy(allocator, "11-22,95-115,998-1012,1188511880-1188511890,222220-222224,1698522-1698528,446443-446449,38593856-38593862,565653-565659,824824821-824824827,2121212118-2121212124") == 1227775554);
}

test "day 2 hard given example" {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();
    try std.testing.expect(try day2hard(allocator, "11-22,95-115,998-1012,1188511880-1188511890,222220-222224,1698522-1698528,446443-446449,38593856-38593862,565653-565659,824824821-824824827,2121212118-2121212124") == 4174379265);
}

pub fn day3easy(buffer: []const u8) !u64 {
    var sum: u64 = 0;
    var lines = std.mem.splitScalar(u8, buffer, '\n');
    while (lines.next()) |line| {
        var max_joltage: u64 = 0;
        for (0..line.len - 1) |offset_1| {
            for (offset_1 + 1..line.len) |offset_2| {
                const joltage = (line[offset_1] - '0') * 10 + (line[offset_2] - '0');
                if (joltage > max_joltage) {
                    max_joltage = joltage;
                }
            }
        }
        sum += max_joltage;
    }
    return sum;
}

test "day 3 easy given example" {
    try std.testing.expect(try day3easy("987654321111111\n811111111111119\n234234234234278\n818181911112111") == 357);
}

pub fn day4easy(allocator: std.mem.Allocator, buffer: []const u8) !u32 {
    var count: u32 = 0;
    var map = try std.array_list.Aligned([]const u8, null).initCapacity(allocator, std.mem.count(u8, buffer, "\n") + 1);
    defer map.deinit(allocator);
    var lines = std.mem.splitScalar(u8, buffer, '\n');
    while (lines.next()) |line| {
        map.appendAssumeCapacity(line);
    }
    for (0..map.items.len) |row| {
        for (0..map.items[row].len) |col| {
            if (map.items[row][col] != '@') {
                continue;
            }
            var present_neighbors: u16 = 0;
            if (row > 0 and col > 0 and map.items[row - 1][col - 1] == '@') {
                present_neighbors += 1;
            }
            if (col > 0 and map.items[row][col - 1] == '@') {
                present_neighbors += 1;
            }
            if (row < map.items.len - 1 and col > 0 and map.items[row + 1][col - 1] == '@') {
                present_neighbors += 1;
            }
            if (row < map.items.len - 1 and map.items[row + 1][col] == '@') {
                present_neighbors += 1;
            }
            if (row < map.items.len - 1 and col < map.items[row].len - 1 and map.items[row + 1][col + 1] == '@') {
                present_neighbors += 1;
            }
            if (col < map.items[row].len - 1 and map.items[row][col + 1] == '@') {
                present_neighbors += 1;
            }
            if (row > 0 and col < map.items[row].len - 1 and map.items[row - 1][col + 1] == '@') {
                present_neighbors += 1;
            }
            if (row > 0 and map.items[row - 1][col] == '@') {
                present_neighbors += 1;
            }

            if (present_neighbors < 4) {
                count += 1;
            }
        }
    }
    return count;
}

pub fn day4hard(allocator: std.mem.Allocator, buffer: []const u8) !u32 {
    var count: u32 = 0;
    var map = try std.array_list.Aligned(std.array_list.Aligned(bool, null), null).initCapacity(allocator, std.mem.count(u8, buffer, "\n") + 1);
    var lines = std.mem.splitScalar(u8, buffer, '\n');
    while (lines.next()) |line| {
        var row = try std.array_list.Aligned(bool, null).initCapacity(allocator, line.len);
        for (line) |cell| {
            if (cell == '@') {
                row.appendAssumeCapacity(true);
            } else {
                row.appendAssumeCapacity(false);
            }
        }
        map.appendAssumeCapacity(row);
    }
    while (true) {
        var next_map = try std.array_list.Aligned(std.array_list.Aligned(bool, null), null).initCapacity(allocator, map.items.len);
        var round_count: u16 = 0;
        for (0..map.items.len) |row| {
            var next_row = try std.array_list.Aligned(bool, null).initCapacity(allocator, map.items[row].items.len);
            for (0..map.items[row].items.len) |col| {
                if (!map.items[row].items[col]) {
                    next_row.appendAssumeCapacity(false);
                    continue;
                }
                var present_neighbors: u8 = 0;
                if (row > 0 and col > 0 and map.items[row - 1].items[col - 1]) {
                    present_neighbors += 1;
                }
                if (col > 0 and map.items[row].items[col - 1]) {
                    present_neighbors += 1;
                }
                if (row < map.items.len - 1 and col > 0 and map.items[row + 1].items[col - 1]) {
                    present_neighbors += 1;
                }
                if (row < map.items.len - 1 and map.items[row + 1].items[col]) {
                    present_neighbors += 1;
                }
                if (row < map.items.len - 1 and col < map.items[row].items.len - 1 and map.items[row + 1].items[col + 1]) {
                    present_neighbors += 1;
                }
                if (col < map.items[row].items.len - 1 and map.items[row].items[col + 1]) {
                    present_neighbors += 1;
                }
                if (row > 0 and col < map.items[row].items.len - 1 and map.items[row - 1].items[col + 1]) {
                    present_neighbors += 1;
                }
                if (row > 0 and map.items[row - 1].items[col]) {
                    present_neighbors += 1;
                }

                if (present_neighbors < 4) {
                    round_count += 1;
                    next_row.appendAssumeCapacity(false);
                } else {
                    next_row.appendAssumeCapacity(true);
                }
            }
            next_map.appendAssumeCapacity(next_row);
        }
        if (round_count == 0) {
            for (next_map.items) |*next_row| {
                next_row.deinit(allocator);
            }
            next_map.deinit(allocator);
            break;
        } else {
            count += round_count;
            for (map.items) |*old_row| {
                old_row.deinit(allocator);
            }
            map.deinit(allocator);
            map = next_map;
        }
    }
    for (map.items) |*old_row| {
        old_row.deinit(allocator);
    }
    map.deinit(allocator);
    return count;
}

test "day 4 easy given example" {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();
    try std.testing.expect(try day4easy(allocator, "..@@.@@@@.\n@@@.@.@.@@\n@@@@@.@.@@\n@.@@@@..@.\n@@.@@@@.@@\n.@@@@@@@.@\n.@.@.@.@@@\n@.@@@.@@@@\n.@@@@@@@@.\n@.@.@@@.@.") == 13);
}

test "day 4 hard given example" {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();
    try std.testing.expect(try day4hard(allocator, "..@@.@@@@.\n@@@.@.@.@@\n@@@@@.@.@@\n@.@@@@..@.\n@@.@@@@.@@\n.@@@@@@@.@\n.@.@.@.@@@\n@.@@@.@@@@\n.@@@@@@@@.\n@.@.@@@.@.") == 43);
}

pub fn day5easy(allocator: std.mem.Allocator, buffer: []const u8) !u32 {
    var lines = std.mem.splitSequence(u8, buffer, "\n\n");
    const fresh_ranges = lines.next() orelse return error.MalformedInput;
    const values = lines.next() orelse return error.MalformedInput;

    var fresh = try std.array_list.Aligned([2]u64, null).initCapacity(allocator, std.mem.count(u8, fresh_ranges, "\n") + 1);
    defer fresh.deinit(allocator);
    var fresh_lines = std.mem.splitScalar(u8, fresh_ranges, '\n');
    while (fresh_lines.next()) |line| {
        var bounds = std.mem.splitScalar(u8, line, '-');
        const lower = try std.fmt.parseInt(u64, bounds.next() orelse return error.MalformedInput, 10);
        const upper = try std.fmt.parseInt(u64, bounds.next() orelse return error.MalformedInput, 10);
        fresh.appendAssumeCapacity([_]u64{ lower, upper });
    }

    var count: u16 = 0;

    var values_iter = std.mem.splitScalar(u8, values, '\n');
    while (values_iter.next()) |line| {
        const value = try std.fmt.parseInt(u64, line, 10);
        for (fresh.items) |range| {
            if (value >= range[0] and value <= range[1]) {
                count += 1;
                break;
            }
        }
    }

    return count;
}

pub fn day5hard(allocator: std.mem.Allocator, buffer: []const u8) !u64 {
    var lines = std.mem.splitSequence(u8, buffer, "\n\n");
    const fresh_ranges = lines.next() orelse return error.MalformedInput;

    // Iterate over all ingredient IDs and add them if we're inside any ranges
    // (which we only need track by the number of ranges currently-included).
    // This would take far too long to do via brute-force, but we only need to
    // scan at indices containing a boundary, as those are the only places
    // where we might switch between including and excluding IDs.

    var fresh_lowers = try std.array_list.Aligned(u64, null).initCapacity(allocator, std.mem.count(u8, fresh_ranges, "\n") + 1);
    var fresh_uppers = try std.array_list.Aligned(u64, null).initCapacity(allocator, std.mem.count(u8, fresh_ranges, "\n") + 1);
    defer fresh_lowers.deinit(allocator);
    defer fresh_uppers.deinit(allocator);
    var fresh_lines = std.mem.splitScalar(u8, fresh_ranges, '\n');
    while (fresh_lines.next()) |line| {
        var bounds = std.mem.splitScalar(u8, line, '-');
        const lower = try std.fmt.parseInt(u64, bounds.next() orelse return error.MalformedInput, 10);
        const upper = try std.fmt.parseInt(u64, bounds.next() orelse return error.MalformedInput, 10);
        fresh_lowers.appendAssumeCapacity(lower);
        fresh_uppers.appendAssumeCapacity(upper);
    }
    std.sort.pdq(u64, fresh_lowers.items, {}, std.sort.asc(u64));
    std.sort.pdq(u64, fresh_uppers.items, {}, std.sort.asc(u64));

    var count: u64 = 0;
    var next_upper_idx: u32 = 0;
    var nested_level: u8 = 0;
    var open_idx: u64 = 0;
    // I'm too lazy to figure out how to make an iterator that interleaves the
    // two lists.
    for (fresh_lowers.items) |lower| {
        while (fresh_uppers.items[next_upper_idx] < lower) {
            nested_level -= 1;
            if (nested_level == 0) {
                std.debug.assert(open_idx != 0);
                count += fresh_uppers.items[next_upper_idx] - open_idx + 1;
            }
            next_upper_idx += 1;
        }
        if (nested_level == 0) {
            open_idx = lower;
        }
        nested_level += 1;
    }
    count += fresh_uppers.items[fresh_uppers.items.len - 1] - open_idx + 1;

    return count;
}

test "day 5 easy given example" {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();
    try std.testing.expect(try day5easy(allocator, "3-5\n10-14\n16-20\n12-18\n\n1\n5\n8\n11\n17\n32") == 3);
}

test "day 5 hard given example" {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();
    try std.testing.expect(try day5hard(allocator, "3-5\n10-14\n16-20\n12-18\n\n1\n5\n8\n11\n17\n32") == 14);
}

pub fn day6easy(allocator: std.mem.Allocator, buffer: []const u8) !u64 {
    var worksheet = try std.array_list.Aligned(std.array_list.Aligned(u64, null), null).initCapacity(allocator, std.mem.count(u8, buffer, "\n") + 1);
    defer worksheet.deinit(allocator);
    var lines = std.mem.splitScalar(u8, buffer, '\n');
    var sum: u64 = 0;
    while (lines.next()) |line| {
        var row = try std.array_list.Aligned(u64, null).initCapacity(allocator, std.mem.count(u8, line, " ") + 1);
        var elems = std.mem.splitScalar(u8, line, ' ');
        var elem_idx: u32 = 0;
        while (elems.next()) |elem| {
            if (elem.len == 0) {
                continue;
            }
            if (std.ascii.isDigit(elem[0])) {
                row.appendAssumeCapacity(try std.fmt.parseInt(u64, elem, 10));
            } else {
                if (elem[0] == '+') {
                    var acc: u64 = 0;
                    for (worksheet.items) |worksheet_row| {
                        acc += worksheet_row.items[elem_idx];
                    }
                    sum += acc;
                } else if (elem[0] == '*') {
                    var acc: u64 = 1;
                    for (worksheet.items) |worksheet_row| {
                        acc *= worksheet_row.items[elem_idx];
                    }
                    sum += acc;
                } else {
                    @panic("Unexpect operator");
                }
            }
            elem_idx += 1;
        }
        worksheet.appendAssumeCapacity(row);
    }

    for (worksheet.items) |*row| {
        // We might leak in the presence of an error, but that's okay
        row.deinit(allocator);
    }

    return sum;
}

test "day 6 easy given example" {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();
    try std.testing.expect(try day6easy(allocator, "123 328  51 64\n45 64  387 23\n6 98  215 314\n*   +   *   +  ") == 4277556);
}

pub fn day7easy(allocator: std.mem.Allocator, buffer: []const u8) !u64 {
    var splits: u64 = 0;
    var active_columns = try std.array_list.Aligned(u32, null).initCapacity(allocator, 256);
    defer active_columns.deinit(allocator);
    var lines = std.mem.splitScalar(u8, buffer, '\n');
    while (lines.next()) |line| {
        var col_idx: u32 = 0;
        for (line) |cell| {
            if (cell == 'S') {
                active_columns.appendAssumeCapacity(col_idx);
            } else if (cell == '^') {
                const active_idx = std.mem.indexOfScalar(u32, active_columns.items, col_idx) orelse {
                    col_idx += 1;
                    continue;
                };
                _ = active_columns.swapRemove(active_idx);
                if (!std.mem.containsAtLeastScalar(u32, active_columns.items, 1, col_idx - 1)) {
                    active_columns.appendAssumeCapacity(col_idx - 1);
                }
                if (!std.mem.containsAtLeastScalar(u32, active_columns.items, 1, col_idx + 1)) {
                    active_columns.appendAssumeCapacity(col_idx + 1);
                }
                splits += 1;
            }
            col_idx += 1;
        }
    }
    return splits;
}

pub fn day7hard(allocator: std.mem.Allocator, buffer: []const u8) !u64 {
    // NOTE: Directionally the right idea, but I need to be more efficient
    //
    // I should store the count associated with each index, probably best to figure out their hashmaps.
    var active_columns = std.hash_map.HashMap(u32, u64, std.hash_map.AutoContext(u32), 30).init(allocator);
    defer active_columns.deinit();
    var lines = std.mem.splitScalar(u8, buffer, '\n');
    while (lines.next()) |line| {
        var col_idx: u32 = 0;
        for (line) |cell| {
            if (cell == 'S') {
                try active_columns.put(col_idx, 1);
            } else if (cell == '^') {
                const count = (try active_columns.fetchPut(col_idx, 0) orelse std.hash_map.HashMap(u32, u64, std.hash_map.AutoContext(u32), 30).KV{ .key = 0, .value = 0 }).value;
                if (col_idx > 0) {
                    const old_prev = active_columns.get(col_idx - 1) orelse 0;
                    try active_columns.put(col_idx - 1, old_prev + count);
                }
                if (col_idx < line.len - 1) {
                    const old_prev = active_columns.get(col_idx + 1) orelse 0;
                    try active_columns.put(col_idx + 1, old_prev + count);
                }
            }
            col_idx += 1;
        }
    }

    var timelines: u64 = 0;
    var timelines_iter = active_columns.valueIterator();
    while (timelines_iter.next()) |count| {
        timelines += count.*;
    }
    return timelines;
}

test "day 7 easy given example" {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();
    try std.testing.expect(try day7easy(allocator, ".......S.......\n...............\n.......^.......\n...............\n......^.^......\n...............\n.....^.^.^.....\n...............\n....^.^...^....\n...............\n...^.^...^.^...\n...............\n..^...^.....^..\n...............\n.^.^.^.^.^...^.\n...............") == 21);
}

test "day 7 hard given example" {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();
    try std.testing.expect(try day7hard(allocator, ".......S.......\n...............\n.......^.......\n...............\n......^.^......\n...............\n.....^.^.^.....\n...............\n....^.^...^....\n...............\n...^.^...^.^...\n...............\n..^...^.....^..\n...............\n.^.^.^.^.^...^.\n...............") == 40);
}

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

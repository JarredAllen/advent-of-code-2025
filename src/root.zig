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

const std = @import("std");
const advent_of_code_2025 = @import("advent_of_code_2025");

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();
    var buffer = try allocator.alloc(u8, 65536);
    defer allocator.free(buffer);

    var stdin = std.fs.File.stdin().reader(buffer);

    const read_len = try stdin.read(buffer);
    const input = buffer[0..read_len];

    const day1easy = try advent_of_code_2025.day1easy(input);
    std.debug.print("Day 1 easy: {}\n", .{day1easy});
    const day1hard = try advent_of_code_2025.day1hard(input);
    std.debug.print("Day 1 hard: {}\n", .{day1hard});
}

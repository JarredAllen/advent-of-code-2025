const std = @import("std");
const advent_of_code_2025 = @import("advent_of_code_2025");

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    var args = try std.process.argsWithAllocator(allocator);
    defer args.deinit();

    _ = args.next() orelse return;

    const problem_str = args.next() orelse return error.MissingProblemArgument;
    const problem = try std.fmt.parseInt(u8, problem_str, 10);

    const infile_name = try std.fmt.allocPrint(allocator, "day{}.in", .{problem});
    defer allocator.free(infile_name);
    const input_buf = try std.fs.Dir.readFileAlloc(std.fs.cwd(), allocator, infile_name, 65536);
    defer allocator.free(input_buf);
    const input = std.mem.trim(u8, input_buf, &std.ascii.whitespace);

    switch (problem) {
        1 => {
            const day1easy = try advent_of_code_2025.day1easy(input);
            std.debug.print("Day 1 easy: {}\n", .{day1easy});
            const day1hard = try advent_of_code_2025.day1hard(input);
            std.debug.print("Day 1 hard: {}\n", .{day1hard});
        },
        2 => {
            const day2easy = try advent_of_code_2025.day2easy(allocator, input);
            std.debug.print("Day 2 easy: {}\n", .{day2easy});
            const day2hard = try advent_of_code_2025.day2hard(allocator, input);
            std.debug.print("Day 2 hard: {}\n", .{day2hard});
        },
        3 => {
            const day3easy = try advent_of_code_2025.day3easy(input);
            std.debug.print("Day 3 easy: {}\n", .{day3easy});
        },
        4 => {
            const day4easy = try advent_of_code_2025.day4easy(allocator, input);
            std.debug.print("Day 4 easy: {}\n", .{day4easy});
            const day4hard = try advent_of_code_2025.day4hard(allocator, input);
            std.debug.print("Day 4 hard: {}\n", .{day4hard});
        },
        5 => {
            const day5easy = try advent_of_code_2025.day5easy(allocator, input);
            std.debug.print("Day 5 easy: {}\n", .{day5easy});
            const day5hard = try advent_of_code_2025.day5hard(allocator, input);
            std.debug.print("Day 5 hard: {}\n", .{day5hard});
        },
        6 => {
            const day6easy = try advent_of_code_2025.day6easy(allocator, input);
            std.debug.print("Day 6 easy: {}\n", .{day6easy});
        },
        7 => {
            const day7easy = try advent_of_code_2025.day7easy(allocator, input);
            std.debug.print("Day 7 easy: {}\n", .{day7easy});
            const day7hard = try advent_of_code_2025.day7hard(allocator, input);
            std.debug.print("Day 7 hard: {}\n", .{day7hard});
        },
        else => return error.UnknownProblem,
    }
}

const std = @import("std");

/// As far as the Elf has been able to figure out, you have to figure out which
/// of the numbers you have appear in the list of winning numbers. The first
/// match makes the card worth one point and each match after the first doubles
/// the point value of that card.
///
/// For example:
///
/// Card 1: 41 48 83 86 17 | 83 86  6 31 17  9 48 53
/// Card 2: 13 32 20 16 61 | 61 30 68 82 17 32 24 19
/// Card 3:  1 21 53 59 44 | 69 82 63 72 16 21 14  1
/// Card 4: 41 92 73 84 69 | 59 84 76 51 58  5 54 83
/// Card 5: 87 83 26 28 32 | 88 30 70 12 93 22 82 36
/// Card 6: 31 18 13 56 72 | 74 77 10 23 35 67 36 11
///
/// In the above example, card 1 has five winning numbers (41, 48, 83, 86, and
/// 17) and eight numbers you have (83, 86, 6, 31, 17, 9, 48, and 53). Of the
/// numbers you have, four of them (48, 83, 17, and 86) are winning numbers!
/// That means card 1 is worth 8 points (1 for the first match, then doubled
/// three times for each of the three matches after the first).
///
///     Card 2 has two winning numbers (32 and 61), so it is worth 2 points.
///     Card 3 has two winning numbers (1 and 21), so it is worth 2 points.
///     Card 4 has one winning number (84), so it is worth 1 point.
///     Card 5 has no winning numbers, so it is worth no points.
///     Card 6 has no winning numbers, so it is worth no points.
///
/// So, in this example, the Elf's pile of scratchcards is worth 13 points.
pub fn solve(file: std.fs.File, part: u8) !u32 {
    _ = part;
    var br = std.io.bufferedReader(file.reader());
    return solution1(br.reader().any());
}

test solution1 {
    const data =
        \\ Card 1: 41 48 83 86 17 | 83 86  6 31 17  9 48 53
        \\ Card 2: 13 32 20 16 61 | 61 30 68 82 17 32 24 19
        \\ Card 3:  1 21 53 59 44 | 69 82 63 72 16 21 14  1
        \\ Card 4: 41 92 73 84 69 | 59 84 76 51 58  5 54 83
        \\ Card 5: 87 83 26 28 32 | 88 30 70 12 93 22 82 36
        \\ Card 6: 31 18 13 56 72 | 74 77 10 23 35 67 36 11
    ;
    var input = std.io.fixedBufferStream(data);
    const actual = try solution1(input.reader().any());
    try std.testing.expectEqual(13, actual);
}

test "part 1: test.txt" {
    const file = try std.fs.cwd().openFile("../data/day04/test.txt", .{ .mode = .read_only });
    defer file.close();
    const actual = solve(file, 1);
    try std.testing.expectEqual(13, actual);
}

fn solution1(reader: std.io.AnyReader) !u32 {
    var buffer: [1024]u8 = undefined;
    var result: u32 = 0;
    while (try reader.readUntilDelimiterOrEof(&buffer, '\n')) |line| {
        if (line.len == 0) continue;

        var tokenizer = std.mem.tokenizeAny(u8, line, ":|");
        _ = tokenizer.next();
        const winners = tokenizer.next() orelse {
            std.debug.print("Winners were not found in\n{s}\n", .{line});
            unreachable;
        };
        const numbers = tokenizer.next() orelse {
            std.debug.print("Numbers were not found in\n{s}\n", .{line});
            unreachable;
        };
        result += try calculate(winners, numbers);
    }
    return result;
}

fn calculate(winners: []const u8, numbers: []const u8) !u32 {
    var buffer: [1024]u8 = undefined;
    var bufferedAlloc = std.heap.FixedBufferAllocator.init(&buffer);
    const alloc = bufferedAlloc.allocator();

    var winnersSet = std.BufSet.init(alloc);
    defer winnersSet.deinit();
    var iterator = std.mem.tokenizeScalar(u8, winners, ' ');
    while (iterator.next()) |number| {
        try winnersSet.insert(number);
    }

    iterator = std.mem.tokenizeScalar(u8, numbers, ' ');
    var result: u32 = 0;
    while (iterator.next()) |number| {
        if (winnersSet.contains(number)) {
            result = if (result == 0) 1 else result * 2;
        }
    }
    return result;
}

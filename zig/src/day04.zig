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
/// --- Part Two ---
///
/// There's no such thing as "points". Instead, scratchcards only cause you to win
/// more scratchcards equal to the number of winning numbers you have.
///
/// Specifically, you win copies of the scratchcards below the winning card equal to
/// the number of matches. So, if card 10 were to have 5 matching numbers, you would
/// win one copy each of cards 11, 12, 13, 14, and 15.
///
/// Copies of scratchcards are scored like normal scratchcards and have the same
/// card number as the card they copied. So, if you win a copy of card 10 and it has
/// 5 matching numbers, it would then win a copy of the same cards that the original
/// card 10 won: cards 11, 12, 13, 14, and 15. This process repeats until none of
/// the copies cause you to win any more cards. (Cards will never make you copy a
/// card past the end of the table.)
///
/// This time, the above example goes differently:
///
/// Card 1: 41 48 83 86 17 | 83 86  6 31 17  9 48 53
/// Card 2: 13 32 20 16 61 | 61 30 68 82 17 32 24 19
/// Card 3:  1 21 53 59 44 | 69 82 63 72 16 21 14  1
/// Card 4: 41 92 73 84 69 | 59 84 76 51 58  5 54 83
/// Card 5: 87 83 26 28 32 | 88 30 70 12 93 22 82 36
/// Card 6: 31 18 13 56 72 | 74 77 10 23 35 67 36 11
///
///     Card 1 has four matching numbers, so you win one copy each of the next four cards: cards 2, 3, 4, and 5.
///     Your original card 2 has two matching numbers, so you win one copy each of cards 3 and 4.
///     Your copy of card 2 also wins one copy each of cards 3 and 4.
///     Your four instances of card 3 (one original and three copies) have two matching numbers, so you win four copies each of cards 4 and 5.
///     Your eight instances of card 4 (one original and seven copies) have one matching number, so you win eight copies of card 5.
///     Your fourteen instances of card 5 (one original and thirteen copies) have no matching numbers and win no more cards.
///     Your one instance of card 6 (one original) has no matching numbers and wins no more cards.
///
/// Once all of the originals and copies have been processed, you end up with 1
/// instance of card 1, 2 instances of card 2, 4 instances of card 3, 8 instances of
/// card 4, 14 instances of card 5, and 1 instance of card 6. In total, this example
/// pile of scratchcards causes you to ultimately have 30 scratchcards!
pub fn solve(_: std.mem.Allocator, file: std.fs.File, part: u8) !u32 {
    var part1 = Part1{};
    var part2 = Part2{};
    var solver = if (part == 1) part1.solver() else part2.solver();
    var br = std.io.bufferedReader(file.reader());
    var buffer: [1024]u8 = undefined;
    while (try br.reader().readUntilDelimiterOrEof(&buffer, '\n')) |line| {
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
        try solver.processCard(winners, numbers);
    }
    return solver.result();
}

const Solver = struct {
    const Self = @This();
    state: *anyopaque,
    processCardFn: *const fn (state: *anyopaque, winners: []const u8, numbers: []const u8) anyerror!void,
    resultFn: *const fn (state: *anyopaque) u32,

    pub fn processCard(self: *Self, winners: []const u8, numbers: []const u8) anyerror!void {
        return self.processCardFn(self.state, winners, numbers);
    }

    pub fn result(self: Self) u32 {
        return self.resultFn(self.state);
    }
};

const Part1 = struct {
    result: u32 = 0,

    fn solver(self: *Part1) Solver {
        return .{ .state = self, .processCardFn = processCard, .resultFn = returnResult };
    }

    fn processCard(ptr: *anyopaque, winners: []const u8, numbers: []const u8) anyerror!void {
        var self: *Part1 = @ptrCast(@alignCast(ptr));
        const matchedCount = try matchedCardsCount(winners, numbers);
        if (matchedCount > 0)
            self.result += @as(u32, 1) << @intCast(matchedCount - 1);
    }

    fn returnResult(ptr: *anyopaque) u32 {
        const self: *Part1 = @ptrCast(@alignCast(ptr));
        return self.result;
    }
};

const Part2 = struct {
    processedCards: u32 = 0,
    cards: [250]u32 = [1]u32{1} ** 250,

    fn solver(self: *Part2) Solver {
        return .{ .state = self, .processCardFn = processCard, .resultFn = result };
    }

    fn processCard(ptr: *anyopaque, winners: []const u8, numbers: []const u8) anyerror!void {
        var self: *Part2 = @ptrCast(@alignCast(ptr));
        const matchedCount = try matchedCardsCount(winners, numbers);
        for (0..matchedCount) |i| {
            self.cards[i + self.processedCards + 1] += self.cards[self.processedCards];
        }
        self.processedCards += 1;
    }

    fn result(ptr: *anyopaque) u32 {
        const self: *Part2 = @ptrCast(@alignCast(ptr));
        var res: u32 = 0;
        for (self.cards[0..self.processedCards]) |card| {
            res += card;
        }
        return res;
    }
};

fn matchedCardsCount(winners: []const u8, numbers: []const u8) !u32 {
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
    var count: u32 = 0;
    while (iterator.next()) |number| {
        if (winnersSet.contains(number)) {
            count += 1;
        }
    }
    return count;
}

test "part 1: test.txt" {
    const file = try std.fs.cwd().openFile("../data/day04/test.txt", .{ .mode = .read_only });
    defer file.close();
    const actual = solve(std.testing.allocator, file, 1);
    try std.testing.expectEqual(13, actual);
}

test "part 2: test.txt" {
    const file = try std.fs.cwd().openFile("../data/day04/test.txt", .{ .mode = .read_only });
    defer file.close();
    const actual = solve(std.testing.allocator, file, 2);
    try std.testing.expectEqual(30, actual);
}

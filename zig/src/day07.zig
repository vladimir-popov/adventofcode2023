const std = @import("std");

/// Camel Cards is sort of similar to poker except it's designed to be easier to
/// play while riding a camel.
///
/// In Camel Cards, you get a list of hands, and your goal is to order them
/// based on the strength of each hand. A hand consists of five cards labeled
/// one of A, K, Q, J, T, 9, 8, 7, 6, 5, 4, 3, or 2. The relative strength of
/// each card follows this order, where A is the highest and 2 is the lowest.
///
/// Every hand is exactly one type. From strongest to weakest, they are:
///
/// - Five of a kind, where all five cards have the same label: AAAAA
/// - Four of a kind, where four cards have the same label and one card has a
///   different label: AA8AA
/// - Full house, where three cards have the same label, and the remaining two
///   cards share a different label: 23332
/// - Three of a kind, where three cards have the same label, and the remaining
///   two cards are each different from any other card in the hand: TTT98
/// - Two pair, where two cards share one label, two other cards share a second
///   label, and the remaining card has a third label: 23432
/// - One pair, where two cards share one label, and the other three cards have
///   a different label from the pair and each other: A23A4
/// - High card, where all cards' labels are distinct: 23456
///
/// Hands are primarily ordered based on type; for example, every full house is
/// stronger than any three of a kind.
///
/// If two hands have the same type, a second ordering rule takes effect. Start
/// by comparing the first card in each hand. If these cards are different, the
/// hand with the stronger first card is considered stronger. If the first card
/// in each hand have the same label, however, then move on to considering the
/// second card in each hand. If they differ, the hand with the higher second
/// card wins; otherwise, continue with the third card in each hand, then the
/// fourth, then the fifth.
///
/// So, 33332 and 2AAAA are both four of a kind hands, but 33332 is stronger
/// because its first card is stronger. Similarly, 77888 and 77788 are both a
/// full house, but 77888 is stronger because its third card is stronger (and
/// both hands have the same first and second card).
///
/// To play Camel Cards, you are given a list of hands and their corresponding
/// bid (your puzzle input). For example:
///
///   32T3K 765
///   T55J5 684
///   KK677 28
///   KTJJT 220
///   QQQJA 483
///
/// This example shows five hands; each hand is followed by its bid amount. Each
/// hand wins an amount equal to its bid multiplied by its rank, where the weakest
/// hand gets rank 1, the second-weakest hand gets rank 2, and so on up to the
/// strongest hand. Because there are five hands in this example, the strongest
/// hand will have rank 5 and its bid will be multiplied by 5.
///
/// Now, you can determine the total winnings of this set of hands by adding up
/// the result of multiplying each hand's bid with its rank (765 * 1 + 220 * 2 +
/// 28 * 3 + 684 * 4 + 483 * 5). So the total winnings in this example are 6440.
///
pub fn solve(alloc: std.mem.Allocator, file: std.fs.File, _: u8) !u32 {
    var buffered = std.io.bufferedReader(file.reader());
    var reader = buffered.reader();
    var hands = std.ArrayList(Tuple).init(alloc);
    defer hands.deinit();
    var buf: [1024]u8 = undefined;
    while (try reader.readUntilDelimiterOrEof(&buf, '\n')) |line| {
        var values = std.mem.splitScalar(u8, line, ' ');
        const cards = values.next().?;
        const bid = values.next().?;
        try hands.append(.{ try Hand.parse(cards), try std.fmt.parseInt(u32, bid, 10) });
    }
    std.mem.sort(Tuple, hands.items, {}, lessThanWithBid);
    var result: u32 = 0;
    for (hands.items, 1..) |tuple, k| {
        result += @intCast(tuple[1] * k);
    }
    return result;
}

const Tuple = struct { Hand, u32 };

fn lessThanWithBid(_: void, lhs: Tuple, rhs: Tuple) bool {
    return Hand.lessThan({}, lhs[0], rhs[0]);
}

const Hand = struct {
    pub const CardsType = enum {
        /// where all cards' labels are distinct: 23456
        High_card,
        /// where two cards share one label, and the other three cards have a
        /// different label from the pair and each other: A23A4
        One_pair,
        /// where two cards share one label, two other cards share a second
        /// label, and the remaining card has a third label: 23432
        Two_pair,
        /// where three cards have the same label, and the remaining two cards
        /// are each different from any other card in the hand: TTT98
        Three_of_a_kind,
        /// where three cards have the same label, and the remaining two cards
        /// share a different label: 23332
        Full_house,
        /// where four cards have the same label and one card has a different label: AA8AA
        Four_of_a_kind,
        /// where all five cards have the same label: AAAAA
        Five_of_a_kind,
    };
    cards: [5]u8,

    pub fn parse(cards: []const u8) !Hand {
        var hand = Hand{ .cards = undefined };
        std.mem.copyForwards(u8, &hand.cards, cards);
        return hand;
    }

    pub fn cardsType(self: Hand) CardsType {
        // 2,3,4,5,6,7,8,9,T,J,Q,K,A
        var hist: [13]u8 = [_]u8{0} ** 13;
        for (0..self.cards.len) |i| {
            const j = cardScore(self.cards[i]) - 1;
            hist[j] += 1;
        }
        const two_max = twoMax(&hist);
        return switch (two_max[0]) {
            5 => .Five_of_a_kind,
            4 => .Four_of_a_kind,
            3 => if (two_max[1] == 2)
                .Full_house
            else
                .Three_of_a_kind,
            2 => if (two_max[1] == 2)
                .Two_pair
            else
                .One_pair,
            1 => .High_card,
            else => unreachable,
        };
    }

    test cardsType {
        const fixture = [_]struct { []const u8, CardsType }{
            .{ "AAAAA", .Five_of_a_kind },
            .{ "AA8AA", .Four_of_a_kind },
            .{ "23332", .Full_house },
            .{ "TTT98", .Three_of_a_kind },
            .{ "23432", .Two_pair },
            .{ "A23A4", .One_pair },
            .{ "23456", .High_card },
        };
        for (fixture) |tuple| {
            std.testing.expectEqual(tuple[1], (try Hand.parse(tuple[0])).cardsType()) catch |err| {
                std.log.debug("Expected type {s} for cards {s}", .{ @tagName(tuple[1]), tuple[0] });
                return err;
            };
        }
    }
    fn twoMax(hist: []const u8) struct { u8, u8 } {
        var max: u8 = 0;
        var max2: u8 = 0;
        for (hist) |v| {
            if (v > max) {
                max2 = max;
                max = v;
            } else if (v > max2) {
                max2 = v;
            }
        }
        return .{ max, max2 };
    }

    fn lessThan(_: void, lhs: Hand, rhs: Hand) bool {
        const lt = lhs.cardsType();
        const rt = rhs.cardsType();
        if (lt == rt) {
            for (0..5) |i| {
                const ls = cardScore(lhs.cards[i]);
                const rs = cardScore(rhs.cards[i]);
                if (ls == rs) continue;
                return ls < rs;
            }
        }
        return @intFromEnum(lt) < @intFromEnum(rt);
    }

    test lessThan {
        var hands = [_]Hand{
            try Hand.parse("32T3K"),
            try Hand.parse("T55J5"),
            try Hand.parse("KK677"),
            try Hand.parse("KTJJT"),
            try Hand.parse("QQQJA"),
        };
        const expectation = [_]Hand{
            try Hand.parse("32T3K"),
            try Hand.parse("KTJJT"),
            try Hand.parse("KK677"),
            try Hand.parse("T55J5"),
            try Hand.parse("QQQJA"),
        };

        std.mem.sort(Hand, &hands, {}, Hand.lessThan);

        try std.testing.expectEqualSlices(Hand, &expectation, &hands);
    }
};

fn cardScore(card: u8) u8 {
    return switch (card) {
        '2'...'9' => card - '1',
        'T' => 9,
        'J' => 10,
        'Q' => 11,
        'K' => 12,
        'A' => 13,
        else => 0,
    };
}

test cardScore {
    const all_cards = [_]u8{ '2', '3', '4', '5', '6', '7', '8', '9', 'T', 'J', 'Q', 'K', 'A' };
    for (all_cards) |card| {
        std.testing.expectEqual(card, all_cards[cardScore(card) - 1]) catch |err| {
            std.log.debug("Card {c} score {d}", .{ card, cardScore(card) });
            return err;
        };
    }
}

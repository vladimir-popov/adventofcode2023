const std = @import("std");

/// To make things a little more interesting, the Elf introduces one additional
/// rule. Now, J cards are jokers - wildcards that can act like whatever card
/// would make the hand the strongest type possible.
///
/// To balance this, J cards are now the weakest individual cards, weaker even than 2.
/// The other cards stay in the same order: A, K, Q, T, 9, 8, 7, 6, 5, 4, 3, 2, J.
///
/// J cards can pretend to be whatever card is best for the purpose of
/// determining hand type; for example, QJJQ2 is now considered four of a kind.
/// However, for the purpose of breaking ties between two hands of the same
/// type, J is always treated as J, not the card it's pretending to be: JKKK2
/// is weaker than QQQQ2 because J is weaker than Q.
///
/// Now, the above example goes very differently:
///
///    32T3K 765
///    T55J5 684
///    KK677 28
///    KTJJT 220
///    QQQJA 483
///
///    32T3K is still the only one pair; it doesn't contain any jokers,
///    so its strength doesn't increase.
///    KK677 is now the only two pair, making it the second-weakest hand.
///    T55J5, KTJJT, and QQQJA are now all four of a kind!
///    T55J5 gets rank 3, QQQJA gets rank 4, and KTJJT gets rank 5.
///
/// With the new joker rule, the total winnings in this example are 5905.
///
pub fn solve(alloc: std.mem.Allocator, file: std.fs.File) !u64 {
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
        // J,2,3,4,5,6,7,8,9,T,Q,K,A
        var hist: [13]u8 = [_]u8{0} ** 13;
        for (0..self.cards.len) |i| {
            const l = cardScore(self.cards[i]) - 1;
            hist[l] += 1;
        }
        const two_max = twoMax(hist[1..]);
        return switch (two_max[0] + hist[0]) {
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
            .{ "AAJAA", .Five_of_a_kind },
            .{ "AA8AA", .Four_of_a_kind },
            .{ "QJJQ2", .Four_of_a_kind },
            .{ "23332", .Full_house },
            .{ "TTT98", .Three_of_a_kind },
            .{ "2343J", .Three_of_a_kind },
            .{ "23432", .Two_pair },
            .{ "A23A4", .One_pair },
            .{ "23456", .High_card },
        };
        for (fixture) |tuple| {
            std.testing.expectEqual(tuple[1], (try Hand.parse(tuple[0])).cardsType()) catch |err| {
                std.log.debug("for cards {s}", .{tuple[0]});
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
            try Hand.parse("T55J5"),
            try Hand.parse("QQQJA"),
            try Hand.parse("KK677"),
        };

        std.mem.sort(Hand, &hands, {}, Hand.lessThan);

        try std.testing.expectEqualSlices(Hand, &expectation, &hands);
    }
};

fn cardScore(card: u8) u8 {
    return switch (card) {
        'J' => 1,
        '2'...'9' => card - '0',
        'T' => 10,
        'Q' => 11,
        'K' => 12,
        'A' => 13,
        else => 0,
    };
}

test cardScore {
    const all_cards = [_]u8{ 'J', '2', '3', '4', '5', '6', '7', '8', '9', 'T', 'Q', 'K', 'A' };
    for (all_cards) |card| {
        std.testing.expectEqual(card, all_cards[cardScore(card) - 1]) catch |err| {
            std.log.debug("Card {c} score {d}", .{ card, cardScore(card) });
            return err;
        };
    }
}

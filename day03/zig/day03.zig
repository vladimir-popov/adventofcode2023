/// The engine schematic (your puzzle input) consists of a visual representation of the engine.
/// There are lots of numbers and symbols you don't really understand, but apparently any number
/// adjacent to a symbol, even diagonally, is a "part number" and should be included in your sum.
/// (Periods (.) do not count as a symbol.)
///
/// Here is an example engine schematic:
///
/// 467..114..
/// ...*......
/// ..35..633.
/// ......#...
/// 617*......
/// .....+.58.
/// ..592.....
/// ......755.
/// ...$.*....
/// .664.598..
///
/// In this schematic, two numbers are not part numbers because they are not adjacent to a symbol:
/// 114 (top right) and 58 (middle right). Every other number is adjacent to a symbol and so is
/// a part number; their sum is 4361.
const std = @import("std");

const TokenType = enum { number, symbol };

const Token = struct {
    type: TokenType,
    value: u32,
    start: usize, // inclusive
    end: usize, // exclusive
};

fn readNumber(input: []const u8) usize {
    var count: usize = 0;
    while (count < input.len) {
        const c = input[count];
        if (c < '0' or c > '9') break;
        count += 1;
    }
    return count;
}

fn parseTokens(line: []const u8, tokens: *std.ArrayList(Token)) !void {
    var i: usize = 0;
    while (i < line.len) {
        switch (line[i]) {
            '.' => {
                i += 1;
                continue;
            },
            '0'...'9' => {
                const token = try tokens.addOne();
                token.type = .number;
                token.start = i;
                token.end = i + readNumber(line[i..]);
                token.value = try std.fmt.parseInt(u32, line[token.start..token.end], 10);
                i = token.end;
            },
            else => {
                const token = try tokens.addOne();
                token.type = .symbol;
                token.start = i;
                token.end = i + 1;
                token.value = line[i];
                i = token.end;
            },
        }
    }
}

test parseTokens {
    var gpa: std.heap.GeneralPurposeAllocator(.{}) = .{};
    defer std.debug.assert(gpa.deinit() == .ok);
    const allocator = gpa.allocator();

    var tokens = std.ArrayList(Token).init(allocator);
    defer tokens.deinit();

    try parseTokens("*.123", &tokens);
    try std.testing.expectEqual(2, tokens.items.len);
    try std.testing.expectEqual(0, tokens.items[0].start);
    try std.testing.expectEqual(1, tokens.items[0].end);
    try std.testing.expectEqual(2, tokens.items[1].start);
    try std.testing.expectEqual(5, tokens.items[1].end);

    tokens.clearAndFree();
    try parseTokens("*.123.=", &tokens);
    try std.testing.expectEqual(3, tokens.items.len);
    try std.testing.expectEqual(0, tokens.items[0].start);
    try std.testing.expectEqual(1, tokens.items[0].end);

    try std.testing.expectEqual(2, tokens.items[1].start);
    try std.testing.expectEqual(5, tokens.items[1].end);

    try std.testing.expectEqual(6, tokens.items[2].start);
    try std.testing.expectEqual(7, tokens.items[2].end);

    tokens.clearAndFree();
    try parseTokens("*123.=", &tokens);
    try std.testing.expectEqual(3, tokens.items.len);
    try std.testing.expectEqual(0, tokens.items[0].start);
    try std.testing.expectEqual(1, tokens.items[0].end);

    try std.testing.expectEqual(1, tokens.items[1].start);
    try std.testing.expectEqual(4, tokens.items[1].end);

    try std.testing.expectEqual(5, tokens.items[2].start);
    try std.testing.expectEqual(6, tokens.items[2].end);

    tokens.clearAndFree();
    try parseTokens("*.123=", &tokens);
    try std.testing.expectEqual(3, tokens.items.len);
}

const RingBufferedTokens = struct {
    const Self = @This();

    const size = 3;

    tokens: [size]std.ArrayList(Token),
    handled_lines_count: u8 = 0,

    fn init(allocator: std.mem.Allocator) RingBufferedTokens {
        return RingBufferedTokens{ .tokens = .{ std.ArrayList(Token).init(allocator), std.ArrayList(Token).init(allocator), std.ArrayList(Token).init(allocator) } };
    }

    fn deinit(self: Self) void {
        for (self.tokens) |tokens| {
            tokens.deinit();
        }
    }

    fn get(self: *Self, i: u8) *std.ArrayList(Token) {
        return &self.tokens[i % size];
    }

    fn parseLine(self: *Self, line: []const u8) !void {
        const tokens = self.get(self.handled_lines_count);
        tokens.clearAndFree();
        try parseTokens(line, tokens);
        self.handled_lines_count += 1;
    }

    fn hasSymbolAroundInLine(self: *Self, token: Token, i: u8) bool {
        if (self.handled_lines_count < i) return false;

        for (self.get(i).items) |tokenInLine| {
            switch (tokenInLine.type) {
                .number => continue,
                else => {
                    if (tokenInLine.start > token.end)
                        return false;
                    if (tokenInLine.end < token.start)
                        continue;
                    if (token.start <= tokenInLine.end or token.end >= tokenInLine.start)
                        return true;
                },
            }
        }
        return false;
    }

    fn sumInLine(self: *Self, i: u8) u32 {
        var result: u32 = 0;
        for (self.get(i).items) |token| {
            switch (token.type) {
                .symbol => continue,
                .number => {
                    if (i > 0 and self.hasSymbolAroundInLine(token, i - 1) or self.hasSymbolAroundInLine(token, i) or self.hasSymbolAroundInLine(token, i + 1))
                        result += token.value;
                },
            }
        }
        return result;
    }

    fn printTokens(self: *RingBufferedTokens, i: u8) void {
        for (self.get(i)) |token| {
            std.debug.print("{d}-{d}:{s} ", .{ token.start, token.end, token.value });
        }
    }
};

fn solve(reader: std.io.AnyReader) !u32 {
    var gpa: std.heap.GeneralPurposeAllocator(.{}) = .{};
    defer std.debug.assert(gpa.deinit() == .ok);
    const allocator = gpa.allocator();

    var result: u32 = 0;
    var chars_buffer: [256]u8 = undefined;
    var tokens = RingBufferedTokens.init(allocator);
    defer tokens.deinit();
    while (try reader.readUntilDelimiterOrEof(&chars_buffer, '\n')) |line| {
        try tokens.parseLine(line);
        if (tokens.handled_lines_count == 1)
            continue;
        result += tokens.sumInLine(tokens.handled_lines_count - 2);
    }
    result += tokens.sumInLine(tokens.handled_lines_count - 1);

    return result;
}

test solve {
    var gpa: std.heap.GeneralPurposeAllocator(.{}) = .{};
    defer std.debug.assert(gpa.deinit() == .ok);
    const allocator = gpa.allocator();

    var tokens = std.ArrayList(Token).init(allocator);
    defer tokens.deinit();

    const input =
        \\.&......8........
        \\*.123.=.7..45a..9
        \\................=
    ;
    var buffered = std.io.fixedBufferStream(input);
    const reader = buffered.reader().any();
    try std.testing.expectEqual(123 + 45 + 9, try solve(reader));
}

test "solve test.txt" {
    const file = try std.fs.cwd().openFile("test.txt", .{ .mode = .read_only });
    defer file.close();

    var buffered = std.io.bufferedReader(file.reader());
    const reader = buffered.reader().any();
    try std.testing.expectEqual(4361, solve(reader));
}

pub fn main() !void {
    if (std.os.argv.len != 2) {
        std.debug.print("You have to pass the file name as the single argument", .{});
        std.process.exit(1);
    }
    const file_name = std.mem.span(std.os.argv[1]);
    const file = try std.fs.cwd().openFile(file_name, .{ .mode = .read_only });
    defer file.close();

    var buffered = std.io.bufferedReader(file.reader());
    const reader = buffered.reader().any();

    std.debug.print("The result is {any}", .{try solve(reader)});
}

const std = @import("std");
const ArrayList = std.ArrayList;

/// As you continue your walk, the Elf poses a second question: in each game you played,
/// what is the fewest number of cubes of each color that could have been in the bag
/// to make the game possible?
///
/// Again consider the example games from earlier:
///
/// Game 1: 3 blue, 4 red; 1 red, 2 green, 6 blue; 2 green
/// Game 2: 1 blue, 2 green; 3 green, 4 blue, 1 red; 1 green, 1 blue
/// Game 3: 8 green, 6 blue, 20 red; 5 blue, 4 red, 13 green; 5 green, 1 red
/// Game 4: 1 green, 3 red, 6 blue; 3 green, 6 red; 3 green, 15 blue, 14 red
/// Game 5: 6 red, 1 blue, 3 green; 2 blue, 1 red, 2 green
///
///  -  In game 1, the game could have been played with as few as 4 red, 2 green, and 6 blue cubes.
///     If any color had even one fewer cube, the game would have been impossible.
///  -  Game 2 could have been played with a minimum of 1 red, 3 green, and 4 blue cubes.
///  -  Game 3 must have been played with at least 20 red, 13 green, and 6 blue cubes.
///  -  Game 4 required at least 14 red, 3 green, and 15 blue cubes.
///  -  Game 5 needed no fewer than 6 red, 3 green, and 2 blue cubes in the bag.
///
/// The power of a set of cubes is equal to the numbers of red, green, and blue cubes multiplied together.
/// The power of the minimum set of cubes in game 1 is 48. In games 2-5 it was 12, 1560, 630, and 36, respectively.
/// Adding up these five powers produces the sum 2286.
///
/// For each game, find the minimum set of cubes that must have been present.
/// What is the sum of the power of these sets?
pub fn solve(alloc: std.mem.Allocator, file: std.fs.File, part: u8) !u32 {
    var scanner = scanFile(file, .{});
    if (part == 1)
        return try solvePart1(alloc, &scanner)
    else
        return try solvePart2(alloc, &scanner);
}

const Set = struct {
    red: u8,
    blue: u8,
    green: u8,

    fn is_possible(self: Set) bool {
        return self.red <= 12 and self.green <= 13 and self.blue <= 14;
    }

    fn print(self: Set) void {
        std.debug.print("[ red: {any}, blue: {any}, green: {any} ]\n", .{ self.red, self.blue, self.green });
    }
};

const Game = struct {
    id: u8,
    sets: ArrayList(Set),

    fn init(allocator: std.mem.Allocator) Game {
        return Game{ .id = 0, .sets = ArrayList(Set).init(allocator) };
    }

    fn reset(self: *Game) void {
        self.id = 0;
        self.sets.clearAndFree();
    }

    fn deinit(self: Game) void {
        self.sets.deinit();
    }

    fn createNewSet(self: *Game) !*Set {
        var set = try self.sets.addOne();
        set.red = 0;
        set.blue = 0;
        set.green = 0;
        return set;
    }

    fn is_possible(self: Game) bool {
        for (self.sets.items) |set| {
            if (!set.is_possible())
                return false;
        }
        return true;
    }

    fn fewestNumbers(self: Game) Set {
        var result: Set = Set{ .red = 0, .green = 0, .blue = 0 };
        for (self.sets.items) |set| {
            result.red = @max(result.red, set.red);
            result.green = @max(result.green, set.green);
            result.blue = @max(result.blue, set.blue);
        }
        return result;
    }

    fn read(game: *Game, comptime ScannerType: type, scanner: ScannerType) !bool {
        var set: *Set = undefined;
        var number: u8 = undefined;
        while (try scanner.peekNotEnd()) |b| {
            switch (b) {
                'G' => {
                    try scanner.skipBytes(5);
                    game.id = try scanner.consumeNumber(u8);
                    set = try game.createNewSet();
                },
                'r' => {
                    try scanner.skipBytes(3);
                    set.red = number;
                },
                'b' => {
                    try scanner.skipBytes(4);
                    set.blue = number;
                },
                'g' => {
                    try scanner.skipBytes(5);
                    set.green = number;
                },
                ';' => {
                    set = try game.createNewSet();
                    _ = try scanner.consume();
                },
                '0'...'9' => {
                    number = try scanner.consumeNumber(u8);
                },
                '\n' => {
                    _ = try scanner.consume();
                    break;
                },
                else => {
                    _ = try scanner.consume();
                    continue;
                },
            }
        }
        return game.id != 0;
    }

    fn print(self: Game) void {
        const color = if (self.is_possible()) "\x1b[0;32m" else "\x1b[0;31m";
        std.debug.print("{s}Game {d}:\n", .{ color, self.id });
        for (self.sets.items) |set| {
            set.print();
        }
        std.debug.print("\x1b[0m", .{});
    }
};

fn solvePart1(alloc: std.mem.Allocator, scanner: anytype) !u32 {
    var result: u32 = 0;
    var game = Game.init(alloc);
    defer game.deinit();
    while (try game.read(@TypeOf(scanner), scanner)) : (game.reset()) {
        if (!game.is_possible())
            continue;
        result += game.id;
    }
    return result;
}

test "Part 1. Test data" {
    const file = try std.fs.cwd().openFile("../data/day02/test.txt", .{});
    defer file.close();
    var scanner = scanFile(file, .{});
    try std.testing.expectEqual(8, try solvePart1(std.testing.allocator, &scanner));
}

test "Part 1. Input data" {
    const file = try std.fs.cwd().openFile("../data/day02/input.txt", .{});
    defer file.close();
    var scanner = scanFile(file, .{});
    try std.testing.expectEqual(2486, try solvePart1(std.testing.allocator, &scanner));
}

fn solvePart2(alloc: std.mem.Allocator, scanner: anytype) !u32 {
    var result: u32 = 0;
    var game = Game.init(alloc);
    defer game.deinit();
    while (try game.read(@TypeOf(scanner), scanner)) : (game.reset()) {
        const numbers = game.fewestNumbers();
        result += @as(u32, numbers.red) * numbers.green * numbers.blue;
    }
    return result;
}

test "Part 2. Test data" {
    const file = try std.fs.cwd().openFile("../data/day02/test.txt", .{});
    defer file.close();
    var scanner = scanFile(file, .{});
    try std.testing.expectEqual(2286, try solvePart2(std.testing.allocator, &scanner));
}

test "Part 2. Input data" {
    const file = try std.fs.cwd().openFile("../data/day02/input.txt", .{});
    defer file.close();
    var scanner = scanFile(file, .{});
    try std.testing.expectEqual(87984, try solvePart2(std.testing.allocator, &scanner));
}

const ScanOptions = struct { buffer_size: u8 = 128 };

pub fn Scanner(comptime Context: type, comptime buffer_size: usize) type {
    return struct {
        const Self = @This();

        context: Context,
        readBufferFn: *const fn (context: Context, buffer: []u8) anyerror!usize,

        buffer: [buffer_size]u8 = undefined,
        current: u8 = buffer_size,
        count: usize = buffer_size,
        line: usize = 1,
        column: usize = 1,

        pub fn peek(self: *Self) !u8 {
            if (self.current < self.count) {
                return self.buffer[self.current];
            }
            self.count = try self.readBufferFn(self.context, &self.buffer);
            if (self.count == 0) {
                return 0;
            }
            self.current = 0;
            return self.buffer[self.current];
        }

        pub fn peekNotEnd(self: *Self) !?u8 {
            const c = try self.peek();
            if (c == 0) return null;
            return c;
        }

        pub fn consume(self: *Self) !u8 {
            const b = self.peek();
            switch (try b) {
                '\n', 0 => {
                    self.line += 1;
                    self.column = 1;
                },
                else => {
                    self.column += 1;
                },
            }
            if (try b > 0)
                self.current += 1;

            return b;
        }

        pub fn consumeNotEnd(self: *Self) !?u8 {
            const b = try self.consume();
            if (b == 0) return null;
            return b;
        }

        pub fn skipBytes(self: *Self, count: u8) !void {
            for (0..count) |_| {
                const b = try self.consume();
                if (b == 0) break;
            }
        }

        pub fn consumeNumber(self: *Self, comptime T: type) !u8 {
            var buffer: [64]u8 = undefined;
            var i: u8 = 0;
            while (try self.peekNotEnd()) |b| switch (b) {
                '+', '-', '0'...'9' => {
                    buffer[i] = try self.consume();
                    i += 1;
                },
                else => break,
            };
            if (i == 0) {
                self.printError();
                return error.ParseIntError;
            }
            return std.fmt.parseInt(T, buffer[0..i], 10) catch |err| {
                self.printError();
                return err;
            };
        }

        fn printError(self: *Self) void {
            std.debug.print("\n{d}:{d} [{s}]", .{ self.line, self.column, self.buffer[0..self.current] });
        }
    };
}

pub fn scanFile(file: std.fs.File, comptime opts: ScanOptions) Scanner(std.fs.File, opts.buffer_size) {
    return .{ .context = file, .readBufferFn = std.fs.File.readAll };
}

test scanFile {
    const file = try std.fs.cwd().openFile("build.zig", .{});
    defer file.close();

    var scanner = scanFile(file, .{});
    // var writer = std.io.getStdOut().writer();
    while (try scanner.peekNotEnd()) |c| {
        const b = try scanner.consume();
        try std.testing.expectEqual(c, b);
        // try writer.writeByte(b);
    }
}

const IndexedString = struct {
    idx: usize = 0,
    str: []const u8,
    pub fn scanner(self: *IndexedString, comptime opts: ScanOptions) Scanner(*IndexedString, opts.buffer_size) {
        return .{ .context = self, .readBufferFn = readBufferFromString };
    }
};

pub fn scanString(str: []const u8) IndexedString {
    return .{ .str = str };
}

fn readBufferFromString(istr: *IndexedString, buffer: []u8) anyerror!usize {
    if (istr.idx >= istr.str.len)
        return 0;

    const count: usize = @min(buffer.len, istr.str.len - istr.idx);
    if (count == 0) {
        return 0;
    }
    // exclusive
    @memcpy(buffer[0..count], istr.str[istr.idx..count]);
    istr.idx = count;
    return count;
}

test scanString {
    const str = "Hello world!";
    var buffer: [str.len]u8 = undefined;

    var istr = scanString(str);
    var scanner = istr.scanner(.{});
    var i: u8 = 0;
    while (try scanner.consumeNotEnd()) |c| {
        buffer[i] = c;
        i += 1;
    }
    try std.testing.expectEqualStrings(str, buffer[0..i]);
}

test "Scan valid number" {
    var istr = scanString("10");
    var scanner = istr.scanner(.{});
    try std.testing.expectEqual(10, try scanner.consumeNumber(u8));
}

test "Scan valid number with extra symbols" {
    var istr = scanString("10 ");
    var scanner = istr.scanner(.{});
    const number = try scanner.consumeNumber(u8);
    try std.testing.expectEqual(10, number);
    try std.testing.expectEqual(' ', try scanner.peek());
}
test "Scan valid number with EOF" {
    const str = [_]u8{ '1', '0', 0 };
    var istr = scanString(&str);
    var scanner = istr.scanner(.{});
    const number = try scanner.consumeNumber(u8);
    try std.testing.expectEqual(10, number);
    try std.testing.expectEqual(0, try scanner.peek());
    try std.testing.expectEqual(0, try scanner.consume());
    try std.testing.expectEqual(0, try scanner.consume());
}

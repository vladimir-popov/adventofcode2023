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
const std = @import("std");
const ex = @import("ex.zig");
const ArrayList = std.ArrayList;

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

fn solvePart1(scanner: anytype) !u32 {
    var gpa: std.heap.GeneralPurposeAllocator(.{}) = .{};
    defer std.debug.assert(gpa.deinit() == .ok);
    const allocator = gpa.allocator();

    var result: u32 = 0;
    var game = Game.init(allocator);
    defer game.deinit();
    while (try game.read(@TypeOf(scanner), scanner)) : (game.reset()) {
        game.print();
        if (!game.is_possible())
            continue;
        result += game.id;
    }
    return result;
}

test "Part 1. Test data" {
    const file = try std.fs.cwd().openFile("test.txt", .{});
    defer file.close();
    var scanner = ex.scanFile(file, .{});
    try std.testing.expectEqual(8, try solvePart1(&scanner));
}

test "Part 1. Input data" {
    const file = try std.fs.cwd().openFile("input.txt", .{});
    defer file.close();
    var scanner = ex.scanFile(file, .{});
    try std.testing.expectEqual(2486, try solvePart1(&scanner));
}

pub fn main() !void {
    if (std.os.argv.len != 2) {
        std.debug.print("You have to pass the file name as the single argument", .{});
        std.process.exit(1);
    }
    const file_name = std.mem.span(std.os.argv[1]);
    const file = try std.fs.cwd().openFile(file_name, .{ .mode = .read_only });
    defer file.close();

    var scanner = ex.scanFile(file, .{});
    const result = try solvePart1(&scanner);
    std.debug.print("The result is {any}", .{result});
}

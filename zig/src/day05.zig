const std = @import("std");
const part2 = @import("day05_2.zig");

/// The almanac (your puzzle input) lists all of the seeds that need to be
/// planted. It also lists what type of soil to use with each kind of seed, what
/// type of fertilizer to use with each kind of soil, what type of water to use
/// with each kind of fertilizer, and so on. Every type of seed, soil,
/// fertilizer and so on is identified with a number, but numbers are reused by
/// each category - that is, soil 123 and fertilizer 123 aren't necessarily
/// related to each other.
///
/// For example:
///
/// seeds: 79 14 55 13
///
/// seed-to-soil map:
/// 50 98 2
/// 52 50 48
///
/// soil-to-fertilizer map:
/// 0 15 37
/// 37 52 2
/// 39 0 15
///
/// fertilizer-to-water map:
/// 49 53 8
/// 0 11 42
/// 42 0 7
/// 57 7 4
///
/// water-to-light map:
/// 88 18 7
/// 18 25 70
///
/// light-to-temperature map:
/// 45 77 23
/// 81 45 19
/// 68 64 13
///
/// temperature-to-humidity map:
/// 0 69 1
/// 1 0 69
///
/// humidity-to-location map:
/// 60 56 37
/// 56 93 4
///
/// The almanac starts by listing which seeds need to be planted: seeds 79, 14, 55, and 13.
///
/// The rest of the almanac contains a list of maps which describe how to
/// convert numbers from a source category into numbers in a destination
/// category. That is, the section that starts with seed-to-soil map: describes
/// how to convert a seed number (the source) to a soil number (the
/// destination). This lets the gardener and his team know which soil to use
/// with which seeds, which water to use with which fertilizer, and so on.
///
/// Rather than list every source number and its corresponding destination
/// number one by one, the maps describe entire ranges of numbers that can be
/// converted. Each line within a map contains three numbers: the destination
/// range start, the source range start, and the range length.
///
/// Consider again the example seed-to-soil map:
///
/// 50 98 2
/// 52 50 48
///
/// The first line has a destination range start of 50, a source range start of
/// 98, and a range length of 2. This line means that the source range starts at
/// 98 and contains two values: 98 and 99. The destination range is the same
/// length, but it starts at 50, so its two values are 50 and 51. With this
/// information, you know that seed number 98 corresponds to soil number 50 and
/// that seed number 99 corresponds to soil number 51.
///
/// The second line means that the source range starts at 50 and contains 48
/// values: 50, 51, ..., 96, 97. This corresponds to a destination range
/// starting at 52 and also containing 48 values: 52, 53, ..., 98, 99. So, seed
/// number 53 corresponds to soil number 55.
///
/// Any source numbers that aren't mapped correspond to the same destination
/// number. So, seed number 10 corresponds to soil number 10.
///
/// So, the entire list of seed numbers and their corresponding soil numbers
/// looks like this:
///
/// seed  soil
/// 0     0
/// 1     1
/// ...   ...
/// 48    48
/// 49    49
/// 50    52
/// 51    53
/// ...   ...
/// 96    98
/// 97    99
/// 98    50
/// 99    51
///
/// With this map, you can look up the soil number required for each initial seed number:
///
///     Seed number 79 corresponds to soil number 81.
///     Seed number 14 corresponds to soil number 14.
///     Seed number 55 corresponds to soil number 57.
///     Seed number 13 corresponds to soil number 13.
///
/// The gardener and his team want to get started as soon as possible, so they'd
/// like to know the closest location that needs a seed. Using these maps, find
/// the lowest location number that corresponds to any of the initial seeds. To
/// do this, you'll need to convert each seed number through other categories
/// until you can find its corresponding location number. In this example, the
/// corresponding types are:
///
///     Seed 79, soil 81, fertilizer 81, water 81, light 74, temperature 78, humidity 78, location 82.
///     Seed 14, soil 14, fertilizer 53, water 49, light 42, temperature 42, humidity 43, location 43.
///     Seed 55, soil 57, fertilizer 57, water 53, light 46, temperature 82, humidity 82, location 86.
///     Seed 13, soil 13, fertilizer 52, water 41, light 34, temperature 34, humidity 35, location 35.
///
/// So, the lowest location number in this example is 35.
///
/// What is the lowest location number that corresponds to any of the initial seed numbers?
pub fn solve(alloc: std.mem.Allocator, file: std.fs.File, part: u8) !u64 {
    if (part == 1) {
        return part1_solve(file);
    } else {
        return try part2.solve(alloc, file);
    }
}

fn part1_solve(file: std.fs.File) !u64 {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer std.debug.assert(gpa.deinit() == .ok);
    const alloc = gpa.allocator();

    var almanac = Almanac.init(alloc);
    defer almanac.deinit();
    try almanac.read(file.reader().any());

    var result: u32 = 0xffffffff;
    for (almanac.seeds.items) |seed| {
        const location = almanac.location(seed);
        result = @min(result, location);
    }
    return result;
}

const RangeMap = struct {
    dest: u64 = undefined,
    source: u64 = undefined,
    len: u64 = undefined,

    pub fn contains(self: RangeMap, value: u32) bool {
        return self.source <= value and (self.source + self.len) > value;
    }

    pub fn get(self: *const RangeMap, value: u32) u32 {
        if (self.contains(value))
            return @intCast(self.dest + value - self.source);

        return value;
    }

    pub fn parse(self: *RangeMap, line: []const u8) !void {
        var tokenazer = std.mem.tokenizeScalar(u8, line, ' ');
        self.dest = try std.fmt.parseInt(u64, tokenazer.next().?, 10);
        self.source = try std.fmt.parseInt(u64, tokenazer.next().?, 10);
        self.len = try std.fmt.parseInt(u64, tokenazer.next().?, 10);
    }

    pub fn lessThan(_: void, lr: RangeMap, rr: RangeMap) bool {
        return lr.source < rr.source;
    }

    pub fn compareWithKey(key: u32, range: RangeMap) std.math.Order {
        if (key < range.source) return std.math.Order.lt;
        if (key >= (range.source + range.len)) return std.math.Order.gt;
        return std.math.Order.eq;
    }
};

test "RangeMap.parse" {
    var range = RangeMap{};
    try range.parse("1 2 3");
    try std.testing.expectEqual(1, range.dest);
    try std.testing.expectEqual(2, range.source);
    try std.testing.expectEqual(3, range.len);
}

test "RangeMap.get" {
    var range = RangeMap{};
    try range.parse("2 1 3");
    try std.testing.expectEqual(2, range.get(1));
    try std.testing.expectEqual(4, range.get(3));
    try std.testing.expectEqual(4, range.get(4));
}

const Map = struct {
    ranges: std.ArrayList(RangeMap),

    pub fn init(alloc: std.mem.Allocator) Map {
        return Map{ .ranges = std.ArrayList(RangeMap).init(alloc) };
    }

    pub fn deinit(self: *Map) void {
        self.ranges.deinit();
    }

    pub fn sort(self: *Map) void {
        std.sort.pdq(RangeMap, self.ranges.items, {}, RangeMap.lessThan);
    }

    pub fn get(self: *const Map, key: u32) u32 {
        const idx = std.sort.binarySearch(RangeMap, self.ranges.items, key,RangeMap.compareWithKey);
        if (idx) |i| return self.ranges.items[i].get(key) else return key;
    }
};

const Almanac = struct {
    seeds: std.ArrayList(u32),
    seed_to_soil: Map,
    soil_to_fertilizer: Map,
    fertilizer_to_water: Map,
    water_to_light: Map,
    light_to_temperature: Map,
    temperature_to_humidity: Map,
    humidity_to_location: Map,

    pub fn init(alloc: std.mem.Allocator) Almanac {
        return .{
            .seeds = std.ArrayList(u32).init(alloc),
            .seed_to_soil = Map.init(alloc),
            .soil_to_fertilizer = Map.init(alloc),
            .fertilizer_to_water = Map.init(alloc),
            .water_to_light = Map.init(alloc),
            .light_to_temperature = Map.init(alloc),
            .temperature_to_humidity = Map.init(alloc),
            .humidity_to_location = Map.init(alloc),
        };
    }

    pub fn deinit(self: *Almanac) void {
        self.seeds.deinit();
        self.seed_to_soil.deinit();
        self.soil_to_fertilizer.deinit();
        self.fertilizer_to_water.deinit();
        self.water_to_light.deinit();
        self.light_to_temperature.deinit();
        self.temperature_to_humidity.deinit();
        self.humidity_to_location.deinit();
    }

    pub fn read(self: *Almanac, reader: std.io.AnyReader) !void {
        var buffer: [256]u8 = undefined;
        var map: ?*Map = null;
        while (try reader.readUntilDelimiterOrEof(&buffer, '\n')) |line| {
            if (line.len > 7 and std.mem.eql(u8, line[0..7], "seeds: ")) {
                try self.__parseSeeds(line[7..]);
                continue;
            }
            if (line.len == 0) {
                if (map) |m| m.sort();
                map = null;
                continue;
            }
            if (map) |m| {
                var range = try m.ranges.addOne();
                try range.parse(line);
            } else {
                map = self.__chooseMap(line);
            }
        }
    }

    inline fn __chooseMap(self: *Almanac, line: []const u8) *Map {
        switch (line[0]) {
            's' => if (line[1] == 'e')
                return &self.seed_to_soil
            else
                return &self.soil_to_fertilizer,
            'f' => return &self.fertilizer_to_water,
            'w' => return &self.water_to_light,
            'l' => return &self.light_to_temperature,
            't' => return &self.temperature_to_humidity,
            'h' => return &self.humidity_to_location,
            else => unreachable,
        }
    }

    inline fn __parseSeeds(self: *Almanac, line: []const u8) !void {
        var tokenazier = std.mem.tokenizeScalar(u8, line, ' ');
        while (tokenazier.next()) |number| {
            try self.seeds.append(try std.fmt.parseInt(u32, number, 10));
        }
    }

    pub fn location(self: *const Almanac, seed: u32) u32 {
        const soil = self.seed_to_soil.get(seed);
        const ferilizer = self.soil_to_fertilizer.get(soil);
        const water = self.fertilizer_to_water.get(ferilizer);
        const light = self.water_to_light.get(water);
        const temp = self.light_to_temperature.get(light);
        const loc = self.temperature_to_humidity.get(temp);
        return loc;
    }
};

test "part1: test.txt" {
    const file = try std.fs.cwd().openFile("../data/day05/test.txt", .{ .mode = .read_only });
    defer file.close();

    try std.testing.expectEqual(35, try solve(std.testing.allocator, file, 1));
}

test "part1: input.txt" {
    const file = try std.fs.cwd().openFile("../data/day05/input.txt", .{ .mode = .read_only });
    defer file.close();

    try std.testing.expectEqual(313045984, try solve(std.testing.allocator, file, 1));
}

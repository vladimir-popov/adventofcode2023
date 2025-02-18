const std = @import("std");

/// --- Part Two ---
/// Everyone will starve if you only plant such a small number of seeds.
/// Re-reading the almanac, it looks like the seeds: line actually describes
/// ranges of seed numbers.
///
/// The values on the initial seeds: line come in pairs. Within each pair, the
/// first value is the start of the range and the second value is the length of
/// the range. So, in the first line of the example above:
///
/// seeds: 79 14 55 13
///
/// This line describes two ranges of seed numbers to be planted in the garden.
/// The first range starts with seed number 79 and contains 14 values: 79, 80,
/// ..., 91, 92. The second range starts with seed number 55 and contains 13
/// values: 55, 56, ..., 66, 67.
///
/// Now, rather than considering four seed numbers, you need to consider a total
/// of 27 seed numbers.
///
/// In the above example, the lowest location number can be obtained from seed
/// number 82, which corresponds to soil 84, fertilizer 84, water 84, light 77,
/// temperature 45, humidity 46, and location 46. So, the lowest location number
/// is 46.
pub fn solve(alloc: std.mem.Allocator, file: std.fs.File) !u64 {
    var reader = file.reader().any();
    var buffer: [1024]u8 = undefined;

    var seeds = std.ArrayList(Range).init(alloc);
    defer seeds.deinit();
    try parseSeeds(&seeds, try reader.readUntilDelimiter(&buffer, '\n'));

    var resolved_ranges = std.ArrayList(Range).init(alloc);
    defer resolved_ranges.deinit();

    var unresolved_ranges_ptr = &seeds;
    var resolved_ranges_ptr = &resolved_ranges;

    while (try file.reader().readUntilDelimiterOrEof(&buffer, '\n')) |line| {
        if (line.len == 0) continue;
        var map = Map.init(alloc);
        defer map.deinit();
        try map.read(reader);
        try map.resolve(unresolved_ranges_ptr, resolved_ranges_ptr);
        const tmp = unresolved_ranges_ptr;
        tmp.clearAndFree();
        unresolved_ranges_ptr = resolved_ranges_ptr;
        resolved_ranges_ptr = tmp;
    }
    var result: u32 = 0xffffffff;
    for (unresolved_ranges_ptr.items) |range| {
        result = @min(result, range.start);
        result = @min(result, range.end);
    }
    return result;
}

test "part2: test.txt" {
    const file = try std.fs.cwd().openFile("../data/day05/test.txt", .{ .mode = .read_only });
    defer file.close();

    try std.testing.expectEqual(46, try solve(std.testing.allocator, file));
}

fn parseSeeds(seeds: *std.ArrayList(Range), line: []const u8) !void {
    var tokenazer = std.mem.tokenizeScalar(u8, line[7..], ' ');
    while (tokenazer.next()) |start| {
        if (tokenazer.next()) |len| {
            var range = try seeds.addOne();
            range.start = try std.fmt.parseInt(u32, start, 10);
            range.end = range.start + try std.fmt.parseInt(u32, len, 10);
        }
    }
}

test parseSeeds {
    var seeds = std.ArrayList(Range).init(std.testing.allocator);
    defer seeds.deinit();
    try parseSeeds(&seeds, "seeds: 1 2 3 4");
    const expected = .{ Range{ .start = 1, .end = 3 }, Range{ .start = 3, .end = 7 } };
    try std.testing.expectEqualSlices(Range, &expected, seeds.items);
}

const Map = struct {
    ranges: std.ArrayList(RangeMap),

    fn init(alloc: std.mem.Allocator) Map {
        return Map{ .ranges = std.ArrayList(RangeMap).init(alloc) };
    }

    fn deinit(self: *Map) void {
        self.ranges.deinit();
    }

    fn read(self: *Map, reader: std.io.AnyReader) !void {
        self.ranges.clearAndFree();
        var buffer: [1024]u8 = undefined;
        while (try reader.readUntilDelimiterOrEof(&buffer, '\n')) |line| {
            if (line.len == 0) break;
            if (line[0] > '9') continue;
            try self.ranges.append(try RangeMap.parse(line));
        }
    }

    fn resolve(self: *const Map, unresolved_ranges: *std.ArrayList(Range), resolved_ranges: *std.ArrayList(Range)) !void {
        var from: usize = 0;
        var to: usize = unresolved_ranges.items.len;
        for (self.ranges.items) |range_map| {
            var i = from;
            while (i < to) : (i += 1) {
                const range = unresolved_ranges.items[i];
                // for (unresolved_ranges.items[from..to]) |range| {
                if (range.outerLeft(&range_map.source)) |outer| {
                    try unresolved_ranges.append(outer);
                }
                if (range.outerRight(&range_map.source)) |outer| {
                    try unresolved_ranges.append(outer);
                }
                if (range.intersect(&range_map.source)) |intersection| {
                    var r = try resolved_ranges.addOne();
                    r.start = range_map.get(@intCast(intersection.start));
                    r.end = r.start + intersection.len();
                }
            }
            from = to;
            to = unresolved_ranges.items.len;
        }
        if (from < unresolved_ranges.items.len)
            try resolved_ranges.appendSlice(unresolved_ranges.items[from..]);
    }
};

test "Map.read" {
    const input =
        \\seed-to-soil map:
        \\50 98 2
        \\52 50 48
        \\
        \\soil-to-fertilizer map:
        \\0 15 37
        \\37 52 2
        \\39 0 15
    ;
    var map = Map.init(std.testing.allocator);
    defer map.deinit();
    var bufr = std.io.fixedBufferStream(input);
    try map.read(bufr.reader().any());
    const expected = .{ RangeMap.init(50, 98, 2), RangeMap.init(52, 50, 48) };
    try std.testing.expectEqualSlices(RangeMap, &expected, map.ranges.items);
}

test "Map.resolve soil" {
    var seeds = std.ArrayList(Range).init(std.testing.allocator);
    defer seeds.deinit();
    try parseSeeds(&seeds, "seeds: 79 14 55 13");

    var resolved_ranges = std.ArrayList(Range).init(std.testing.allocator);
    defer resolved_ranges.deinit();

    var map = Map.init(std.testing.allocator);
    defer map.deinit();
    const input: []const u8 =
        \\seed-to-soil map:
        \\50 98 2
        \\52 50 48
    ;
    var bufr = std.io.fixedBufferStream(input);
    try map.read(bufr.reader().any());
    try map.resolve(&seeds, &resolved_ranges);

    const expected = .{ Range{ .start = 81, .end = 95 }, Range{ .start = 57, .end = 70 } };
    try std.testing.expectEqualSlices(Range, &expected, resolved_ranges.items);
}

test "Map.resolve fertilizer" {
    var unresolved_ranges = std.ArrayList(Range).init(std.testing.allocator);
    defer unresolved_ranges.deinit();

    var resolved_ranges = std.ArrayList(Range).init(std.testing.allocator);
    defer resolved_ranges.deinit();

    var expected = .{ Range{ .start = 81, .end = 95 }, Range{ .start = 57, .end = 70 } };
    try unresolved_ranges.appendSlice(&expected);

    var map = Map.init(std.testing.allocator);
    defer map.deinit();
    const input: []const u8 =
        \\soil-to-fertilizer map:
        \\0 15 37
        \\37 52 2
        \\39 0 15
    ;
    var bufr = std.io.fixedBufferStream(input);
    try map.read(bufr.reader().any());
    try map.resolve(&unresolved_ranges, &resolved_ranges);

    try std.testing.expectEqualSlices(Range, &expected, resolved_ranges.items);
}

test "Map.resolve water" {
    var unresolved_ranges = std.ArrayList(Range).init(std.testing.allocator);
    defer unresolved_ranges.deinit();

    var resolved_ranges = std.ArrayList(Range).init(std.testing.allocator);
    defer resolved_ranges.deinit();
    const ranges = .{ Range{ .start = 81, .end = 95 }, Range{ .start = 57, .end = 70 } };
    try unresolved_ranges.appendSlice(&ranges);

    var map = Map.init(std.testing.allocator);
    defer map.deinit();
    const input: []const u8 =
        \\fertilizer-to-water map:
        \\49 53 8
        \\0 11 42
        \\42 0 7
        \\57 7 4
    ;
    var bufr = std.io.fixedBufferStream(input);
    try map.read(bufr.reader().any());
    try map.resolve(&unresolved_ranges, &resolved_ranges);

    var expected = .{ Range{ .start = 53, .end = 57 }, Range{ .start = 81, .end = 95 }, Range{ .start = 61, .end = 70 } };
    try std.testing.expectEqualSlices(Range, &expected, resolved_ranges.items);
}

const RangeMap = struct {
    dest: Range,
    source: Range,

    pub fn init(dest: u64, source: u64, len: u64) RangeMap {
        return .{ .dest = Range{ .start = dest, .end = dest + len }, .source = Range{ .start = source, .end = source + len } };
    }

    pub fn get(self: *const RangeMap, value: u32) u32 {
        if (self.source.contains(value))
            return @intCast(self.dest.start + value - self.source.start);

        return value;
    }

    pub fn parse(line: []const u8) !RangeMap {
        var tokenazer = std.mem.tokenizeScalar(u8, line, ' ');
        const dest = try std.fmt.parseInt(u64, tokenazer.next().?, 10);
        const source = try std.fmt.parseInt(u64, tokenazer.next().?, 10);
        const len = try std.fmt.parseInt(u64, tokenazer.next().?, 10);
        return RangeMap.init(dest, source, len);
    }
};

const Range = struct {
    start: u64,
    end: u64, // exclusive

    pub inline fn len(self: *const Range) u64 {
        return self.end - self.start;
    }

    pub inline fn contains(self: *const Range, value: u64) bool {
        return self.start <= value and self.end > value;
    }

    pub inline fn outerLeft(self: *const Range, other: *const Range) ?Range {
        if (self.end < other.start) return Range{ .start = self.start, .end = self.end };
        if (self.start >= other.start) return null;
        return Range{ .start = self.start, .end = @min(self.end, other.start) };
    }

    pub inline fn outerRight(self: *const Range, other: *const Range) ?Range {
        if (self.start >= other.end) return Range{ .start = self.start, .end = self.end };
        if (self.end <= other.end) return null;
        return Range{ .start = @max(self.start, other.end), .end = self.end };
    }

    pub inline fn intersect(self: *const Range, other: *const Range) ?Range {
        var left: *const Range = undefined;
        var right: *const Range = undefined;
        if (self.start < other.start) {
            left = self;
            right = other;
        } else {
            left = other;
            right = self;
        }

        if (left.contains(right.start))
            return Range{ .start = right.start, .end = @min(left.end, right.end) }
        else
            return null;
    }
};

test "Range.outerLeft without intersection" {
    const range = Range{ .start = 10, .end = 20 };
    const left = Range{ .start = 5, .end = 8 };
    try std.testing.expectEqual(left, left.outerLeft(&range));
}

test "Range.outerLeft with intersection" {
    const range = Range{ .start = 10, .end = 20 };
    const left = Range{ .start = 5, .end = 15 };
    try std.testing.expectEqual(Range{ .start = 5, .end = 10 }, left.outerLeft(&range));
}

test "Range.outerLeft outside" {
    const range = Range{ .start = 10, .end = 20 };
    const left = Range{ .start = 15, .end = 25 };
    try std.testing.expectEqual(null, left.outerLeft(&range));
}

test "Range.outerRight without intersection" {
    const range = Range{ .start = 10, .end = 20 };
    const right = Range{ .start = 25, .end = 30 };
    try std.testing.expectEqual(right, right.outerRight(&range));
}

test "Range.outerRight with intersection" {
    const range = Range{ .start = 10, .end = 20 };
    const right = Range{ .start = 15, .end = 25 };
    try std.testing.expectEqual(Range{ .start = 20, .end = 25 }, right.outerRight(&range));
}

test "Range.outerRight outside" {
    const range = Range{ .start = 10, .end = 20 };
    const right = Range{ .start = 5, .end = 15 };
    try std.testing.expectEqual(null, right.outerRight(&range));
}

test "Range.intersect with left outside" {
    const range = Range{ .start = 10, .end = 20 };
    const left = Range{ .start = 5, .end = 10 };
    try std.testing.expectEqual(null, left.intersect(&range));
}

test "Range.intersect with right outside" {
    const range = Range{ .start = 10, .end = 20 };
    const right = Range{ .start = 20, .end = 30 };
    try std.testing.expectEqual(null, right.intersect(&range));
}

test "Range.intersect with equal" {
    const range = Range{ .start = 10, .end = 20 };
    const inner = Range{ .start = 10, .end = 20 };
    try std.testing.expectEqual(inner, inner.intersect(&range));
}

test "Range.intersect with inner" {
    const range = Range{ .start = 10, .end = 20 };
    const inner = Range{ .start = 12, .end = 18 };
    try std.testing.expectEqual(inner, inner.intersect(&range));
}

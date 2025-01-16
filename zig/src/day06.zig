const std = @import("std");

/// As part of signing up, you get a sheet of paper (your puzzle input) that
/// lists the time allowed for each race and also the best distance ever
/// recorded in that race. To guarantee you win the grand prize, you need to
/// make sure you go farther in each race than the current record holder.
///
/// The organizer brings you over to the area where the boat races are held.
/// The boats are much smaller than you expected - they're actually toy boats,
/// each with a big button on top. Holding down the button charges the boat,
/// and releasing the button allows the boat to move. Boats move faster if
/// their button was held longer, but time spent holding the button counts
/// against the total race time. You can only hold the button at the start of
/// the race, and boats don't move until the button is released.
///
/// For example:
///
/// Time:      7  15   30
/// Distance:  9  40  200
///
/// This document describes three races:
///
///     The first race lasts 7 milliseconds. The record distance in this race is 9 millimeters.
///     The second race lasts 15 milliseconds. The record distance in this race is 40 millimeters.
///     The third race lasts 30 milliseconds. The record distance in this race is 200 millimeters.
///
/// Your toy boat has a starting speed of zero millimeters per millisecond. For
/// each whole millisecond you spend at the beginning of the race holding down
/// the button, the boat's speed increases by one millimeter per millisecond.
///
/// So, because the first race lasts 7 milliseconds, you only have a few options:
///
///     Don't hold the button at all (that is, hold it for 0 milliseconds) at the start of the race. The boat won't move; it will have traveled 0 millimeters by the end of the race.
///     Hold the button for 1 millisecond at the start of the race. Then, the boat will travel at a speed of 1 millimeter per millisecond for 6 milliseconds, reaching a total distance traveled of 6 millimeters.
///     Hold the button for 2 milliseconds, giving the boat a speed of 2 millimeters per millisecond. It will then get 5 milliseconds to move, reaching a total distance of 10 millimeters.
///     Hold the button for 3 milliseconds. After its remaining 4 milliseconds of travel time, the boat will have gone 12 millimeters.
///     Hold the button for 4 milliseconds. After its remaining 3 milliseconds of travel time, the boat will have gone 12 millimeters.
///     Hold the button for 5 milliseconds, causing the boat to travel a total of 10 millimeters.
///     Hold the button for 6 milliseconds, causing the boat to travel a total of 6 millimeters.
///     Hold the button for 7 milliseconds. That's the entire duration of the race. You never let go of the button. The boat can't move until you let go of the button. Please make sure you let go of the button so the boat gets to move. 0 millimeters.
///
/// Since the current record for this race is 9 millimeters, there are actually
/// 4 different ways you could win: you could hold the button for 2, 3, 4, or 5
/// milliseconds at the start of the race.
///
/// In the second race, you could hold the button for at least 4 milliseconds
/// and at most 11 milliseconds and beat the record, a total of 8 different
/// ways to win.
///
/// In the third race, you could hold the button for at least 11 milliseconds
/// and no more than 19 milliseconds and still beat the record, a total of 9
/// ways you could win.
///
/// To see how much margin of error you have, determine the number of ways you
/// can beat the record in each race; in this example, if you multiply these
/// values together, you get 288 (4 * 8 * 9).
pub fn solve(alloc: std.mem.Allocator, file: std.fs.File, part: u8) !u32 {
    _ = part;
    var reader = file.reader().any();
    var buffer: [1024]u8 = undefined;
    const len = try reader.readAll(&buffer);
    var lines = std.mem.splitScalar(u8, buffer[0..len], '\n');
    const times = lines.next().?;
    const distances = lines.next().?;
    var times_itr = std.mem.tokenizeScalar(u8, times[11..], ' ');
    var distances_itr = std.mem.tokenizeScalar(u8, distances[11..], ' ');
    var result: u32 = 1;
    while (times_itr.next()) |s_time| {
        const s_distance = distances_itr.next().?;
        const time = try std.fmt.parseInt(u64, s_time, 10);
        const distance = try std.fmt.parseInt(u64, s_distance, 10);
        const solutions_count = try possibleSolutionsCount(alloc, time, distance);
        std.debug.print(
            "Solutions count is {d} for time {d} and distance {d}\n",
            .{ solutions_count, time, distance },
        );
        result *= solutions_count;
    }
    return result;
}

fn possibleSolutionsCount(alloc: std.mem.Allocator, total_time: u64, record_distance: u64) !u32 {
    if (try binarySearch(alloc, total_time, record_distance, 0, total_time)) |reference_hold_time| {
        // std.debug.print("Reference point {d}\n", .{reference_hold_time});
        var min_time = reference_hold_time;
        while (try binarySearch(alloc, total_time, record_distance, 0, min_time)) |hold_time| {
            if (min_time == hold_time) break;
            min_time = hold_time;
        }
        // std.debug.print("Min time {d}\n", .{min_time});
        var max_time = min_time + 1;
        while (try binarySearch(alloc, total_time, record_distance, max_time, total_time)) |hold_time| {
            if (max_time == hold_time) break;
            max_time = hold_time;
        }
        // std.debug.print("Max time {d}\n", .{max_time});
        return @intCast(max_time - min_time + 1);
    }
    return 0;
}

/// Returns first one available value.
/// The `min_hold_time` and `max_hold_time` are inclusive.
fn binarySearch(
    alloc: std.mem.Allocator,
    total_time: u64,
    record_distance: u64,
    min_hold_time: u64,
    max_hold_time: u64,
) !?u64 {
    var stack = std.ArrayList(struct { u64, u64 }).init(alloc);
    defer stack.deinit();
    try stack.append(.{ min_hold_time, max_hold_time });

    while (stack.popOrNull()) |tuple| {
        const min_hold = tuple[0];
        const max_hold = tuple[1];
        const middle = min_hold + @divTrunc(max_hold - min_hold, 2);
        if (isBetterDistance(total_time, middle, record_distance)) {
            return middle;
        }
        if (min_hold == middle) {
            if (min_hold != max_hold and isBetterDistance(total_time, max_hold, record_distance)) {
                return max_hold;
            } else {
                continue;
            }
        }
        try stack.append(.{ min_hold, middle });
        try stack.append(.{ middle, max_hold });
    }
    return null;
}

inline fn isBetterDistance(total_time: u64, hold_time: u64, record_distance: u64) bool {
    return hold_time * (total_time - hold_time) > record_distance;
}

test "Day 06: binary search [0, 0]" {
    const alloc = std.testing.allocator;
    try std.testing.expectEqual(null, binarySearch(alloc, 5, 0, 0, 0));
}

test "Day 06: binary search [0, 1]" {
    const alloc = std.testing.allocator;
    try std.testing.expectEqual(1, binarySearch(alloc, 5, 0, 0, 1));
}

test "Day 06: binary search [1, 1]" {
    const alloc = std.testing.allocator;
    try std.testing.expectEqual(1, binarySearch(alloc, 5, 0, 1, 1));
}

test "Day 06: test example" {
    // 1     2       5      7
    // |-----|=======|------|
    const result = possibleSolutionsCount(std.testing.allocator, 7, 9);
    try std.testing.expectEqual(4, result);
}

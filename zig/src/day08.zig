const std = @import("std");
const p = @import("parcom");

const log = std.log.scoped(.day08);

/// One of the camel's pouches is labeled "maps" - sure enough, it's full of
/// documents (your puzzle input) about how to navigate the desert. At least,
/// you're pretty sure that's what they are; one of the documents contains a
/// list of left/right instructions, and the rest of the documents seem to
/// describe some kind of network of labeled nodes.
///
/// It seems like you're meant to use the left/right instructions to navigate the
/// network. Perhaps if you have the camel follow the same instructions, you can
/// escape the haunted wasteland!
pub fn solve(alloc: std.mem.Allocator, file: std.fs.File, part: u8) !u64 {
    var buffered = std.io.bufferedReader(file.reader());
    const reader = buffered.reader();
    if (part == 1)
        return try part1(alloc, reader)
    else
        return try part2(alloc, reader);
}

/// After examining the maps for a bit, two nodes stick out: AAA and ZZZ. You feel
/// like AAA is where you are now, and you have to follow the left/right
/// instructions until you reach ZZZ.
///
/// This format defines each node of the network individually. For example:
/// ```
/// LLR
///
/// AAA = (BBB, BBB)
/// BBB = (AAA, ZZZ)
/// ZZZ = (ZZZ, ZZZ)
/// ```
/// Starting with AAA, you need to look up the next element based on the next
/// left/right instruction in your input.
///
/// Of course, you might not find ZZZ right away. If you run out of left/right
/// instructions, repeat the whole sequence of instructions as necessary: LLR
/// really means LLRLLRLLR... and so on. In example above, here is a situation
/// that takes 6 steps to reach ZZZ.
fn part1(alloc: std.mem.Allocator, reader: anytype) !u64 {
    var map = Map.init(alloc);
    defer map.deinit();
    std.debug.assert(try map.parse(alloc, reader));
    var key: [3]u8 = [_]u8{'A'} ** 3;
    var idx: usize = 0;
    var count: u32 = 0;
    while (map.graph.get(key)) |node| {
        if (std.mem.eql(u8, &key, "ZZZ")) return count;
        count += 1;
        const move = map.moves.items[idx];
        key = if (move == 'L') node.left else node.right;
        idx = if (idx < map.moves.items.len - 1) idx + 1 else 0;
    }
    return error.WrongInput;
}

/// The sandstorm is upon you and you aren't any closer to escaping the
/// wasteland. You had the camel follow the instructions, but you've barely
/// left your starting position. It's going to take significantly more steps to
/// escape!
///
/// What if the map isn't for people - what if the map is for ghosts? Are
/// ghosts even bound by the laws of spacetime? Only one way to find out.
///
/// After examining the maps a bit longer, your attention is drawn to a curious
/// fact: the number of nodes with names ending in A is equal to the number ending
/// in Z! If you were a ghost, you'd probably just start at every node that ends
/// with A and follow all of the paths at the same time until they all
/// simultaneously end up at nodes that end with Z.
fn part2(alloc: std.mem.Allocator, reader: anytype) !u64 {
    var map = Map.init(alloc);
    defer map.deinit();
    std.debug.assert(try map.parse(alloc, reader));
    std.debug.assert(map.paths.items.len > 0);

    log.debug("Starting nodes {any}", .{map.paths.items});

    var move_number: u32 = 0;
    var lengths = try alloc.alloc(u32, map.paths.items.len);
    defer alloc.free(lengths);

    var completed = try std.DynamicBitSet.initEmpty(alloc, lengths.len);
    defer completed.deinit();

    while (true) : (move_number += 1) {
        const move = map.moves.items[move_number % map.moves.items.len];
        for (map.paths.items, 0..) |*key_node, j| {
            if (map.graph.get(key_node.*)) |node| {
                key_node.* = if (move == 'L') node.left else node.right;
                if (key_node.*[2] == 'Z' and !completed.isSet(j)) {
                    completed.setValue(j, true);
                    log.debug(
                        "Finished {d} path on {s} node. Completed {d}/{d}",
                        .{ j, key_node, completed.count(), lengths.len },
                    );
                    lengths[j] = move_number + 1;
                }
            } else {
                std.debug.panic("The node {s} was not found", .{key_node});
            }
        }
        if (completed.count() == lengths.len) {
            log.debug("All {d} lengths have been calculated", .{lengths.len});
            break;
        }
    }
    std.mem.sort(u32, lengths, {}, struct {
        fn lessThan(_: void, left: u32, right: u32) bool {
            return left > right;
        }
    }.lessThan);
    log.debug("Found lengths {any}", .{lengths});
    var a: u64 = lengths[0];
    for (lengths[1..]) |b| {
        a = (a / std.math.gcd(a, b)) * b;
    }
    return a;
}

const Map = struct {
    const Key = [3]u8;

    const Node = struct {
        left: Key,
        right: Key,
    };

    paths: std.ArrayList(Key),
    moves: std.ArrayList(u8),
    graph: std.AutoHashMap(Key, Node),

    pub fn init(alloc: std.mem.Allocator) Map {
        return .{
            .paths = std.ArrayList(Key).init(alloc),
            .moves = std.ArrayList(u8).init(alloc),
            .graph = std.AutoHashMap(Key, Node).init(alloc),
        };
    }

    pub fn deinit(self: *Map) void {
        self.moves.deinit();
        self.graph.deinit();
        self.paths.deinit();
    }

    pub fn parse(self: *Map, alloc: std.mem.Allocator, reader: anytype) !bool {
        const key = p.letterOrNumber().repeatToArray(3);
        const moves = p.oneCharOf("LR").repeatTo(&self.moves, .{}, std.ArrayList(u8).append);
        const node_line = p.tuple(.{ p.char('('), key, p.word(", "), key, p.char(')') });
        const node = node_line.transform(Node, {}, struct {
            fn transformNode(_: void, line: @TypeOf(node_line).ResultType) anyerror!Node {
                return .{ .left = line[1], .right = line[3] };
            }
        }.transformNode);
        const graph_line = p.tuple(.{ key, p.word(" = "), node, p.char('\n').optional() });
        const graph_appender = struct {
            fn addNode(map: *Map, line: @TypeOf(graph_line).ResultType) anyerror!void {
                if (line[0][2] == 'A') {
                    try map.paths.append(line[0]);
                }
                try map.graph.put(line[0], line[2]);
            }
        };
        const graph = graph_line.repeatTo(self, .{}, graph_appender.addNode);
        const map_parser = p.tuple(.{ moves, p.word("\n\n"), graph });

        return try map_parser.parseFromReader(alloc, reader.any()) != null;
    }
};

test "Parse test example part 1" {
    const test_data =
        \\LLR
        \\
        \\AAA = (BBB, BBB)
        \\BBB = (AAA, ZZZ)
        \\ZZZ = (ZZZ, ZZZ)
    ;
    var fbs = std.io.fixedBufferStream(test_data);

    var map = Map.init(std.testing.allocator);
    defer map.deinit();

    try std.testing.expect(try map.parse(std.testing.allocator, fbs.reader()));
}

test "check on test data part 1" {
    const test_data =
        \\LLR
        \\
        \\AAA = (BBB, BBB)
        \\BBB = (AAA, ZZZ)
        \\ZZZ = (ZZZ, ZZZ)
    ;
    var fbs = std.io.fixedBufferStream(test_data);
    try std.testing.expectEqual(6, try part1(std.testing.allocator, fbs.reader()));
}

test "Parse test example part 2" {
    const test_data =
        \\LR
        \\
        \\11A = (11B, XXX)
        \\11B = (XXX, 11Z)
        \\11Z = (11B, XXX)
        \\22A = (22B, XXX)
        \\22B = (22C, 22C)
        \\22C = (22Z, 22Z)
        \\22Z = (22B, 22B)
        \\XXX = (XXX, XXX)
    ;
    var fbs = std.io.fixedBufferStream(test_data);

    var map = Map.init(std.testing.allocator);
    defer map.deinit();

    try std.testing.expect(try map.parse(std.testing.allocator, fbs.reader()));
}

test "check on test data part 2" {
    const test_data =
        \\LR
        \\
        \\11A = (11B, XXX)
        \\11B = (XXX, 11Z)
        \\11Z = (11B, XXX)
        \\22A = (22B, XXX)
        \\22B = (22C, 22C)
        \\22C = (22Z, 22Z)
        \\22Z = (22B, 22B)
        \\XXX = (XXX, XXX)
    ;
    var fbs = std.io.fixedBufferStream(test_data);
    try std.testing.expectEqual(6, try part2(std.testing.allocator, fbs.reader()));
}

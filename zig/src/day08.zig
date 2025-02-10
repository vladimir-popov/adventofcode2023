const std = @import("std");
const p = @import("parsec.zig");

/// One of the camel's pouches is labeled "maps" - sure enough, it's full of
/// documents (your puzzle input) about how to navigate the desert. At least,
/// you're pretty sure that's what they are; one of the documents contains a
/// list of left/right instructions, and the rest of the documents seem to
/// describe some kind of network of labeled nodes.
///
/// It seems like you're meant to use the left/right instructions to navigate the
/// network. Perhaps if you have the camel follow the same instructions, you can
/// escape the haunted wasteland!
///
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
pub fn solve(alloc: std.mem.Allocator, file: std.fs.File, _: u8) !u32 {
    var buffered = std.io.bufferedReader(file.reader());
    const reader = buffered.reader();
    return try part1(alloc, reader);
}

fn part1(alloc: std.mem.Allocator, reader: anytype) !u32 {
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

const Map = struct {
    const Key = [3]u8;

    const Node = struct {
        left: Key,
        right: Key,
    };

    moves: std.ArrayList(u8),
    graph: std.AutoHashMap(Key, Node),

    pub fn init(alloc: std.mem.Allocator) Map {
        return .{ .moves = std.ArrayList(u8).init(alloc), .graph = std.AutoHashMap(Key, Node).init(alloc) };
    }

    pub fn deinit(self: *Map) void {
        self.moves.deinit();
        self.graph.deinit();
    }

    pub fn parse(self: *Map, alloc: std.mem.Allocator, reader: anytype) !bool {
        const upper_latter = p.range('A', 'Z');
        const key = p.array(upper_latter, 3);
        const moves = p.arrayList(upper_latter, &self.moves);
        const node_line = p.tuple(.{ p.char('('), key, p.word(", "), key, p.char(')') });
        const node = p.transform(Node, node_line, struct {
            fn transformNode(line: @TypeOf(node_line).Type) anyerror!Node {
                return .{ .left = line[1], .right = line[3] };
            }
        }.transformNode);
        const graph_line = p.tuple(.{ key, p.word(" = "), node, p.opt(p.char('\n')) });
        const graph_appender = struct {
            fn addNode(map: *std.AutoHashMap(Key, Node), line: @TypeOf(graph_line).Type) anyerror!void {
                try map.put(line[0], line[2]);
            }
        };
        const graph = p.collect(std.AutoHashMap(Key, Node), graph_line, &self.graph, graph_appender.addNode);
        const map_parser = p.tuple(.{ moves, p.word("\n\n"), graph });

        return try p.parse(alloc, map_parser, reader) != null;
    }
};

test "Parse test example" {
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

test "check on test data" {
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

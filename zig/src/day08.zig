const std = @import("std");

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
pub fn solve(alloc: std.mem.Allocator, file: std.fs.File, _: u8) !u32 {}

const Map = struct {
    const Key = [3]u8;

    const Node = struct {
        left: u8,
        right: u8,
    };

    moves: std.ArrayList(u8),
    graph: std.AutoHashMap(Key, Node),
};

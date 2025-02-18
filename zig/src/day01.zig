const std = @import("std");

pub fn solve(_: std.mem.Allocator, file: std.fs.File, part: u8) !u64 {
    _ = part;
    var buffered = std.io.bufferedReader(file.reader());
    var reader = buffered.reader();

    var sum: u32 = 0;
    var ns = [_]u8{ 0, 0 };
    var i: u8 = 0;
    while (reader.readByte()) |c| {
        if (std.ascii.isDigit(c)) {
            ns[i] = c;
            i = 1;
        }
        if (c == '\n') {
            ns[1] = if (ns[1] == 0) ns[0] else ns[1];
            sum += try std.fmt.parseInt(u32, &ns, 10);
            ns[1] = 0;
            i = 0;
        }
    } else |err| {
        if (err != error.EndOfStream)
            return err;
    }
    return sum;
}

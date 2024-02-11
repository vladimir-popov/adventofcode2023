const std = @import("std");

pub fn main() !void {
    if (std.os.argv.len != 2) {
        std.debug.print("You have to pass the file name as the single argument", .{});
        std.process.exit(1);
    }
    const file_name: []const u8 = std.mem.span(std.os.argv[1]);
    const file = try std.fs.cwd().openFile(file_name, .{ .mode = .read_only });
    defer file.close();

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
        // ignore end of file (very weird api IMO)
        if (err != error.EndOfStream)
            return err;
    }
    std.debug.print("The result id {}", .{sum});
}

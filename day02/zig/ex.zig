const std = @import("std");

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
    const file = try std.fs.cwd().openFile("ex.zig", .{});
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

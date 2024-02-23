const tasks: [5]*const fn (file: std.fs.File, part: u8) anyerror!u32 = .{
    @import("day01.zig").solve,
    @import("day02.zig").solve,
    @import("day03.zig").solve,
    @import("day04.zig").solve,
    @import("day05.zig").solve,
};

const std = @import("std");

fn showHelp(writer: std.io.AnyWriter) !void {
    _ = try writer.write(
        \\adventofcode <--dayXX> [--partX] <input>
        \\
        \\   input    -  a path to the file with input data for a 
        \\               task.
        \\   --dayXX  -  a number of the task in the form of dayXX,
        \\               where the XX is a number of the day.
        \\   --partX  -  optional; a number of the part of the task 
        \\               in the form of partX, where X is a number 
        \\               of the part. Used if the task has more than
        \\               one part.  
        \\   --help   -  if passed, this help will be shown.
        \\
        \\Example:
        \\  adventofcode --day02 --part1 day02/input.txt
    );
}

const Args = struct {
    day: u8 = 0,
    part: u8 = 1,
    input: []const u8 = undefined,

    fn handleOption(args: *Args, arg: []const u8) !void {
        switch (arg[0]) {
            'd' => {
                args.day = try std.fmt.parseInt(u8, arg[3..], 10);
            },
            'p' => {
                args.part = try std.fmt.parseInt(u8, arg[4..], 10);
            },
            'h' => {
                const sout = std.io.getStdOut();
                defer sout.close();
                try showHelp(sout.writer().any());
            },
            else => {
                std.debug.print("Unknown argument {s}", .{arg});
                std.os.exit(1);
            },
        }
    }

    pub fn parse() !Args {
        var args = Args{};
        for (std.os.argv) |ptr| {
            const arg: []const u8 = std.mem.span(ptr);
            if (arg.len > 2 and arg[0] == '-' and arg[1] == '-')
                handleOption(&args, arg[2..]) catch |err| {
                    std.debug.print("Error on parse argument {s}\n", .{arg});
                    return err;
                }
            else {
                args.input = arg;
            }
        }
        if (args.day == 0) {
            const serr = std.io.getStdErr();
            defer serr.close();
            const writer = serr.writer();
            _ = try writer.write("You have to pass a day. See help below:\n");
            try showHelp(writer.any());
            std.os.exit(1);
        }
        args.input = try resolveInputPath(args.input, args.day);

        return args;
    }
};

fn resolveInputPath(input: []const u8, day: u8) ![]const u8 {
    var buffer: [std.fs.MAX_PATH_BYTES]u8 = undefined;
    return std.fs.realpath(input, &buffer) catch |err1| {
        const dataPath = try std.fmt.bufPrint(&buffer, "../data/day{d:0>2}/{s}", .{ day, input });
        return std.fs.realpath(dataPath, &buffer) catch |err2| {
            std.debug.print("File was not found neither in {s} ({any}) nor in {s} ({any})\n", .{ input, err1, buffer, err2 });
            return err1;
        };
    };
}

pub fn main() !void {
    const args = try Args.parse();
    const file = try std.fs.openFileAbsolute(args.input, .{ .mode = .read_only });
    defer file.close();

    const result = try tasks[args.day - 1](file, args.part);

    std.debug.print("The result for the day {d} part {d} is {d}", .{ args.day, args.part, result });
}

test "all tests" {
    _ = tasks;
}

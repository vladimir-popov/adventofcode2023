const tasks = [_]*const fn (alloc: std.mem.Allocator, file: std.fs.File, part: u8) anyerror!u32{
    @import("day01.zig").solve,
    @import("day02.zig").solve,
    @import("day03.zig").solve,
    @import("day04.zig").solve,
    @import("day05.zig").solve,
    @import("day06.zig").solve,
    @import("day07.zig").solve,
    @import("day08.zig").solve,
};

const std = @import("std");

pub const std_options: std.Options = .{
    .log_level = .info,
    .log_scope_levels = &[_]std.log.ScopeLevel{
        .{ .scope = .parsec, .level = .info },
    },
};

const Path = [std.fs.MAX_PATH_BYTES:0]u8;

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer std.debug.assert(gpa.deinit() == .ok);
    const alloc = gpa.allocator();

    const args = try Args.parse();
    defer args.deinit();
    if (args.part) |p|
        std.log.info("Run task for day {d} part {d} with input from '{s}'", .{ args.day, p, args.input_path })
    else
        std.log.info("Run task for day {d} with input from '{s}'", .{ args.day, args.input_path });

    const result = try tasks[args.day - 1](alloc, args.input_file, args.part orelse 1);

    std.debug.print("The result is {d}", .{result});
}

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
        \\  adventofcode --day01 input.txt
        \\or:
        \\  adventofcode --day02 --part1 test.txt
    );
}

const Args = struct {
    day: u8 = 0,
    part: ?u8 = null,
    input_path: Path = undefined,
    input_file: std.fs.File = undefined,

    pub fn parse() !Args {
        var input: []const u8 = &.{};
        var args = Args{};
        for (std.os.argv[1..]) |ptr| {
            const arg: []const u8 = std.mem.span(ptr);
            if (arg.len > 2 and arg[0] == '-' and arg[1] == '-')
                handleOption(&args, arg[2..]) catch |err| {
                    std.debug.print("Error on parse argument {s}\n", .{arg});
                    return err;
                }
            else {
                input = arg;
            }
        }
        if (args.day == 0) {
            const serr = std.io.getStdErr();
            defer serr.close();
            const writer = serr.writer();
            _ = try writer.write("You have to pass a day. See help below:\n");
            try showHelp(writer.any());
            std.process.exit(1);
        }
        try args.resolveInputPath(std.fs.cwd(), if (input.len > 0) input else "input.txt");

        return args;
    }

    pub fn deinit(self: Args) void {
        self.input_file.close();
    }

    fn handleOption(args: *Args, arg: []const u8) !void {
        switch (arg[0]) {
            'd' => {
                args.day = try std.fmt.parseInt(u8, arg[3..], 10);
            },
            'p' => {
                args.part = try std.fmt.parseInt(u8, arg[4..], 10);
                std.debug.assert(args.part == 1 or args.part == 2);
            },
            'h' => {
                const sout = std.io.getStdOut();
                defer sout.close();
                try showHelp(sout.writer().any());
            },
            else => {
                std.debug.print("Unknown argument {s}", .{arg});
                std.process.exit(1);
            },
        }
    }

    fn resolveInputPath(args: *Args, cwd: std.fs.Dir, input: []const u8) !void {
        std.debug.assert(input.len > 0);
        const flags: std.fs.File.OpenFlags = .{ .mode = .read_only };
        std.log.debug("Input is '{s}'", .{input});
        if (cwd.openFile(input, flags)) |file| {
            std.mem.copyForwards(u8, &args.input_path, input);
            args.input_file = file;
            return;
        } else |err1| switch (err1) {
            error.FileNotFound => {
                var day_path_buffer: Path = undefined;
                const day_path = try std.fmt.bufPrint(
                    &day_path_buffer,
                    "../data/day{d:0>2}/{s}",
                    .{ args.day, input },
                );
                std.log.debug("The path with 'day' part is '{s}'", .{day_path});
                if (cwd.openFile(day_path, flags)) |file| {
                    std.mem.copyForwards(u8, &args.input_path, day_path);
                    args.input_file = file;
                    return;
                } else |err2| switch (err2) {
                    error.FileNotFound => {
                        if (args.part) |p| {
                            var part_path_buffer: Path = undefined;
                            const part_path = try std.fmt.bufPrint(
                                &part_path_buffer,
                                "../data/day{d:0>2}/part{d:0>2}/{s}",
                                .{ args.day, p, input },
                            );
                            std.log.debug("The path with 'part' part is '{s}'", .{part_path});
                            if (cwd.openFile(part_path, flags)) |file| {
                                std.mem.copyForwards(u8, &args.input_path, part_path);
                                args.input_file = file;
                                return;
                            } else |err3| switch (err3) {
                                error.FileNotFound => {
                                    std.log.err(
                                        "File was not found neither in '{s}' ({any}), nor in '{s}' ({any}), nor in '{s}' ({any})\n",
                                        .{ input, err1, &day_path_buffer, err2, part_path, err3 },
                                    );
                                    return err3;
                                },
                                else => return err3,
                            }
                        }
                        std.log.err(
                            "File was not found neither in '{s}' ({any}) nor in '{s}' ({any})\n",
                            .{ input, err1, day_path, err2 },
                        );
                        return err2;
                    },
                    else => return err2,
                }
                return err1;
            },
            else => return err1,
        }
    }
};

test "all tests" {
    _ = tasks;
}

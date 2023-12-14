const std = @import("std");

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();
    
    const input = try open_input_file(allocator);
    defer input.deinit();
    defer {
        for (input.items) |line| {
            allocator.free(line);
        }
    }

    const total = try get_total(input.items, allocator);
    std.debug.print("Total: {d}", .{ total });
}

// Opens file containing input values for the AoC Day 1 Puzzle
// Adds every line as an element in the an ArrayList and returns the array
// Ownership given to caller
fn open_input_file(allocator: std.mem.Allocator) !std.ArrayList([]u8) {
    const file = std.fs.cwd().openFile("aoc-01-input.txt", .{}) catch unreachable; 
    defer file.close();

    var buf_reader = std.io.bufferedReader(file.reader());
    var in_stream = buf_reader.reader();

    var buf: [1024]u8 = undefined;
    var values = std.ArrayList([]u8).init(allocator);

    while (try in_stream.readUntilDelimiterOrEof(&buf, '\n')) |line| {
        const line_copy = try allocator.dupe(u8, line);
        try values.append(line_copy);
    }
    return values;
}

fn get_total(strings: []const []const u8, allocator: std.mem.Allocator) !i32 {
    var total : i32 = 0;
    for (strings) |string| {
        var numbers = std.ArrayList(u8).init(allocator);
        defer numbers.deinit();
        for (string) |char| {
            _ = std.fmt.parseInt(i32, &[_]u8{char}, 10) catch {
                continue;
            };
            try numbers.append(char);
        }
        const first_and_last = get_first_and_last(numbers.items);
        total += std.fmt.parseInt(i32, first_and_last, 10) catch {
            std.debug.print("Invalid String: {s}", .{first_and_last});
            return 0;
        };
    }
    return total;
}

fn get_first_and_last(string: []const u8) []const u8 {
    if (string.len == 0) return "";
    const first = string[0];
    const last = string[string.len - 1];
    return &[_]u8{first, last};
}

test "validates get_total" {
    const allocator = std.testing.allocator;
    const calibarion_values = [_][]const u8{ "1abc2", "pqr3stu8vwx", "a1b2c3d4e5f", "treb7uchet" };

    try std.testing.expectEqual(get_total(&calibarion_values, allocator), 142);
}

test "open input file" {
    const allocator = std.testing.allocator;
    const input = try open_input_file(allocator);
    defer input.deinit();
    defer {
        for (input.items, 0..) |line, idx| {
            std.debug.print("Line {d}: {s}\n", .{idx, line});   
            defer allocator.free(line);    
        }
    }
}
const std = @import("std");
const testing_allocator = std.testing.allocator;

const Numerals = enum(u8) { one = 1, two = 2, three = 3, four = 4, five = 5, six = 6, seven = 7, eight = 8, nine = 9 };
const numerals = [_][]const u8{ "one", "two", "three", "four", "five", "six", "seven", "eight", "nine" };

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

    const total = try get_total(allocator, input.items);
    std.debug.print("Total: {d}", .{total});
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

test "open input file" {
    const allocator = std.testing.allocator;
    const input = try open_input_file(allocator);
    defer input.deinit();
    defer {
        for (input.items) |line| {
            allocator.free(line);
        }
    }
}

fn get_total(allocator: std.mem.Allocator, strings: []const []const u8) !i32 {
    var total: i32 = 0;
    for (strings) |string| {
        const treated_string = try switch_numerals(allocator, string);
        std.debug.print("treated_string: {s}\n", .{treated_string});
        defer allocator.free(treated_string);
        var numbers = std.ArrayList(u8).init(allocator);
        defer numbers.deinit();
        for (treated_string) |char| {
            _ = std.fmt.parseInt(i32, &[_]u8{char}, 10) catch {
                continue;
            };
            try numbers.append(char);
        }
        const first_and_last = get_first_and_last(numbers.items);
        total += std.fmt.parseInt(i32, &first_and_last, 10) catch {
            std.debug.print("Parsing error: {s}", .{first_and_last});
            return 0;
        };
    }
    return total;
}

test "validates get_total" {
    const calibarion_values = [_][]const u8{ "1abc2", "pqr3stu8vwx", "a1b2c3d4e5f", "treb7uchet" };
    const total = try get_total(testing_allocator, &calibarion_values);
    try std.testing.expectEqual(total, 142);
}

test "validates get_total swiching literals" {
    const calibration_values = [_][]const u8{
        "two1nine",
        "eightwothree",
        "abcone2threexyz",
        "xtwone3four",
        "4nineeightseven2",
        "zoneight234",
        "7pqrstsixteen",
    };
    const total = try get_total(testing_allocator, &calibration_values);
    try std.testing.expectEqual(total, 281);
}

fn get_first_and_last(string: []const u8) [2]u8 {
    if (string.len == 0) return [2]u8{ 0, 0 };
    const first = string[0];
    const last = string[string.len - 1];
    return [2]u8{ first, last };
}

test "validates get first and last" {
    const value = "9abcs8";
    try std.testing.expectEqualStrings("98", &get_first_and_last(value));
}

fn switch_numerals(allocator: std.mem.Allocator, string: []const u8) ![]const u8 {
    var result = try allocator.dupe(u8, string);

    // var idx: usize = 0;
    // var return_value = try allocator.alloc(u8, string.len);
    // var return_value_idx: usize = 0;
    // while (idx < string.len) {
    //     field_for: for (numerals, 0..) |numeral, literal_idx| {
    //         if (idx + numeral.len > string.len) {
    //             continue;
    //         }

    //         return_value_idx += 1;
    //         if (std.mem.eql(u8, numeral, string[idx..numeral.len])) {
    //             const number = std.fmt.digitToChar(@truncate(u8, literal_idx + 1), .lower);
    //             return_value[idx] = number;
    //             idx += numeral.len;
    //             break :field_for;
    //         } else {
    //             return_value[idx] = string[idx];
    //             idx += 1;
    //         }
    //     }
    // }
    // std.debug.print("{s}\n", .{return_value});

    inline for (@typeInfo(Numerals).Enum.fields) |field| {
        const numeral = field.name;
        const number = &[_]u8{std.fmt.digitToChar(field.value, .lower)};

        if (std.mem.indexOf(u8, result, numeral)) |index| {
            const prefix = result[0..index];
            const posfix = result[index + numeral.len .. result.len];
            const new_string = try std.mem.concat(allocator, u8, &[_][]const u8{ prefix, number, posfix });
            allocator.free(result);
            result = new_string;
        }
    }
    return result;
}

test "switch numerals with numbers" {
    const string = "one23four";
    const new_string = try switch_numerals(testing_allocator, string);
    defer testing_allocator.free(new_string);
    try std.testing.expectEqualStrings("1234", new_string);
}

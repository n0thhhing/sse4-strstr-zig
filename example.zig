const std = @import("std");
const strstr_anysize = @import("./main.zig").strstr_anysize;

pub fn main() void {
    const str = "12345678901234567"; // if str.len < 16 then it will fall back to std.mem.indexOfAny(u8, str, needle)
    const needle = "90123";
    const index = strstr_anysize(str, needle);

    std.debug.print("Found index: {?}\n", .{index}); // Found index: 8
}

# sse4-strstr-zig

This repo provides a zig implementation for [sse4-strstr](https://github.com/WojciechMula/sse4-strstr/blob/9cdc4b6df817c8a8c67a1cebdc7e18a1da35f407/neon-strstr-v2.cpp#L1)'s neon substring search, zig currently doesnt have any Intrinsics, so this relies solely on the @Vector builtins, which brings some overhead, but overall it functions similarly both time wise and functionality wise.

## Example Usage

```zig
const std = @import("std");
const strstr_anysize = @import("path/to/neon-strstr.zig").strstr_anysize;
pub fn main() void {
    const str = "12345678901234567"; // if str.len < 16 then it will fall back to std.mem.indexOfAny(u8, str, needle)
    const needle = "09123";
    const index = strstr_anysize(str, needle);

    std.debug.print("Found index: {?}\n", .{index}); // Found index:
}
```

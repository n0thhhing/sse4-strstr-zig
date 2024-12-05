const std = @import("std");
const assert = std.debug.assert;
const Allocator = std.mem.Allocator;

const uint8x16 = @Vector(16, u8);
const uint8x8 = @Vector(8, u8);

pub inline fn vget_high_u8(vec: uint8x16) uint8x8 {
    return @shuffle(
        u8,
        vec,
        undefined,
        std.simd.iota(u8, 8) + @as(uint8x8, @splat(8)),
    );
}

pub inline fn vget_low_u8(vec: uint8x16) uint8x8 {
    return @shuffle(
        u8,
        vec,
        undefined,
        std.simd.iota(u8, 8),
    );
}

pub inline fn vld1q_u8(mem: []const u8) uint8x16 {
    if (mem.len < 16) {
        var buffer: [16]u8 = .{0} ** 16;

        const len = @min(mem.len, 16);
        @memcpy(buffer[0..len], mem[0..len]);

        return buffer[0..16].*;
    } else {
        return mem[0..16].*;
    }
}

pub inline fn vceqq_u8(a: uint8x16, b: uint8x16) uint8x16 {
    const cmp = a == b;
    return @select(
        u8,
        cmp,
        @as(uint8x16, @splat(255)),
        @as(uint8x16, @splat(0)),
    );
}

pub inline fn vbsl_u8(mask: uint8x8, a: uint8x8, b: uint8x8) uint8x8 {
    return (mask & a) | (~mask & b);
}

// This implementation is based on code from sse4-strstr.
// Copyright (c) 2008-2016, Wojciech Muła
// Licensed under the BSD-2-Clause license.
// See https://github.com/WojciechMula/sse4-strstr?tab=BSD-2-Clause-1-ov-file#readme for details.
pub fn strstr_anysize(str: []const u8, needle: []const u8) ?usize {
    const str_len = str.len;
    const needle_len = needle.len;

    assert(needle_len > 0);
    assert(str_len > needle_len);

    if (str_len <= 16) {
        return std.mem.indexOfAny(u8, str, needle);
    }

    const first: uint8x16 = @splat(needle[0]);
    const last: uint8x16 = @splat(needle[needle_len - 1]);
    const half: uint8x8 = comptime @splat(0x0f);

    var tmp: [8]u8 = undefined;
    const word: *[2]u32 = @ptrCast(@alignCast(&tmp));

    var i: usize = 0;
    while (i < str_len) : (i += 16) {
        const block_first: uint8x16 = vld1q_u8(str[i..]);
        const block_last: uint8x16 = if (i + needle_len - 1 > str_len) @splat(0) else vld1q_u8(str[i + needle_len - 1 ..]);
        
        const eq_first = vceqq_u8(first, block_first);
        const eq_last = vceqq_u8(last, block_last);
        const pred_16 = eq_first & eq_last;
        const pred_8 = vbsl_u8(half, vget_low_u8(pred_16), vget_high_u8(pred_16));

        tmp = pred_8;

        if ((word.*[0] | word.*[1]) == 0) {
            continue;
        }

        inline for (0..8) |j| {
            if ((tmp[j] & 0x0f) != 0) {
                if (std.mem.eql(
                    u8,
                    str[i + j + 1 ..][0 .. needle_len - 2],
                    needle[1..][0 .. needle_len - 2],
                )) {
                    return i + j;
                }
            }
        }

        inline for (0..8) |j| {
            if ((tmp[j] & 0xf0) != 0) {
                if (std.mem.eql(
                    u8,
                    str[i + j + 1 + 8 ..][0 .. needle_len - 2],
                    needle[1..][0 .. needle_len - 2],
                )) {
                    return i + j + 8;
                }
            }
        }
    }
    return null;
}

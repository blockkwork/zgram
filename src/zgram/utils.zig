const Context = @import("./Context.zig");
const std = @import("std");
const types = @import("../telegram/update_types.zig");

pub fn intToString(int: anytype, buf: []u8) ![]const u8 {
    return try std.fmt.bufPrint(buf, "{}", .{int});
}

// https://github.com/ziglang/zig/issues/15764
pub fn dupe(allocator: std.mem.Allocator, prev: types.Update) !*types.Update {
    const n = try allocator.create(types.Update);
    errdefer allocator.destroy(n);

    n.* = .{
        .message = prev.message,
        .update_id = prev.update_id,
        .callback_query = prev.callback_query,
    };
    if (prev.message != null and prev.message.?.text != null)
        n.message.?.text = try allocator.dupe(u8, prev.message.?.text.?);

    if (prev.callback_query != null) {
        n.callback_query.?.id = try allocator.dupe(u8, prev.callback_query.?.id);
        n.callback_query.?.message.?.text = try allocator.dupe(u8, prev.callback_query.?.message.?.text.?);
        n.callback_query.?.chat_instance = try allocator.dupe(u8, prev.callback_query.?.chat_instance.?);
        n.callback_query.?.data = try allocator.dupe(u8, prev.callback_query.?.data.?);
    }

    return n;
}

pub fn trimTrailingNulls(s: []const u8) []const u8 {
    var end = s.len;
    while (end > 0 and s[end - 1] == 0) {
        end -= 1;
    }
    return s[0..end];
}

const DEBUG = false;

pub inline fn debugln(comptime fmt: []const u8, args: anytype) void {
    if (DEBUG) std.debug.print(fmt ++ "\n", args);
}

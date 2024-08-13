const std = @import("std");
const Context = @import("./Context.zig");
const utils = @import("./utils.zig");
const Client = @import("Client.zig");
const types = @import("types/keyboard.zig");
const requests = @import("../network/requests.zig");

pub fn sendMessage(self: Client, options: struct {
    chat_id: u64,
    payload: []const u8,
}) !void {
    var chat_id_str: [20]u8 = undefined;

    _ = try utils.intToString(options.chat_id, &chat_id_str);

    const res = try std.mem.concat(self.allocator, u8, &.{ self.token_url, "/sendMessage" });
    defer self.allocator.free(res);

    const body = try requests.sendPOST(self, res, options.payload);
    defer self.allocator.free(body);
}

pub fn answerCallbackQuery(self: Client, options: struct {
    payload: []const u8,
}) !void {
    const url = "https://api.telegram.org/bot";

    const res = try std.mem.concat(self.allocator, u8, &.{ url, self.bot_token, "/answerCallbackQuery" });
    defer self.allocator.free(res);

    const body = try requests.sendPOST(self, res, options.payload);
    defer self.allocator.free(body);
}

const std = @import("std");
const keyboard = @import("types/keyboard.zig");
const Client = @import("Client.zig");
const update_types = @import("../telegram/update_types.zig");
const utils = @import("./utils.zig");
pub const Context = @This();
const api = @import("api.zig");

update: *update_types.Update,
allocator: std.mem.Allocator,
client: Client,

const Keyboards = union(enum) {
    inline_keyboard: keyboard.InlineKeyboard,
    keyboard: keyboard.Keyboard,
};

const ReplyOptions = struct {
    message: []const u8,
    reply_keyboard: ?Keyboards = null,
};

const AnswerCbQueryOptions = struct {
    // cb_id: []const u8,
    text: []const u8 = "",
    show_alert: bool = false,
};

pub fn reply(self: Context, options: ReplyOptions) !void {
    var out: [2 << 8]u8 = undefined;

    var fbs = std.io.fixedBufferStream(&out);
    var writer = std.json.writeStream(fbs.writer(), .{});

    var chat_id: u64 = undefined;

    defer writer.deinit();

    try writer.beginObject();
    try writer.objectField("chat_id");
    if (self.update.callback_query != null) {
        chat_id = self.update.callback_query.?.message.?.chat.id;
    }

    if (self.update.message != null) {
        chat_id = self.update.message.?.chat.id;
    }

    try writer.write(chat_id);
    try writer.objectField("text");
    try writer.write(options.message);

    //  TODO: refactor
    if (options.reply_keyboard != null) {
        switch (options.reply_keyboard.?) {
            .inline_keyboard => |k| {
                {
                    try writer.objectField("reply_markup");
                    try writer.beginObject();
                    try writer.objectField("inline_keyboard");
                    try writer.beginArray();

                    for (k.inline_keyboard) |row| {
                        try writer.beginArray();
                        for (row.buttons) |button| {
                            try writer.beginObject();
                            try writer.objectField("text");
                            try writer.write(button.text);
                            try writer.objectField("callback_data");
                            try writer.write(button.callback_data);
                            try writer.endObject();
                        }
                        try writer.endArray();
                    }

                    try writer.endArray();
                    try writer.endObject(); // reply markup end
                    try writer.endObject(); // main object end
                }
            },
            .keyboard => |k| {
                {
                    try writer.objectField("reply_markup");
                    try writer.beginObject();
                    try writer.objectField("one_time_keyboard");
                    try writer.write(k.one_time_keyboard);
                    try writer.objectField("resize_keyboard");
                    try writer.write(k.resize_keyboard);
                    try writer.objectField("keyboard");
                    try writer.beginArray();

                    for (k.keyboard) |row| {
                        try writer.beginArray();
                        for (row.buttons) |button| {
                            try writer.beginObject();
                            try writer.objectField("text");
                            try writer.write(button.text);
                            try writer.endObject();
                        }
                        try writer.endArray();
                    }

                    try writer.endArray();
                    try writer.endObject(); // reply markup end
                    try writer.endObject(); // main object end
                }
            },
        }
    }

    utils.debugln("{s}", .{out[0..fbs.pos]});

    try api.sendMessage(self.client, .{ .chat_id = chat_id, .payload = out[0..fbs.pos] });
}

pub fn answerCbQuery(self: Context, options: AnswerCbQueryOptions) !void {
    // self.update.callback_query.?.id
    if (self.update.callback_query == null) {
        return error.CallbackQueryIsNull;
    }

    const cb_data = struct {
        callback_query_id: []const u8,
        text: []const u8,
        show_alert: bool = false,
    }{
        .callback_query_id = self.update.callback_query.?.id,
        .text = options.text,
        .show_alert = options.show_alert,
    };

    var buf: [500]u8 = undefined;
    var fbs = std.io.fixedBufferStream(&buf);
    try std.json.stringify(cb_data, .{}, fbs.writer());

    try api.answerCallbackQuery(self.client, .{ .payload = &buf });

    // self.update.callback_query.?.id

}

pub fn deinit(self: Context) void {
    self.allocator.destroy(self.update);
}

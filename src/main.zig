const std = @import("std");
const Client = @import("zgram/Client.zig");
const Context = @import("zgram/Context.zig");

const api = @import("zgram/api.zig");

const keyboard = @import("zgram/types/keyboard.zig");

const TOKEN = "";

fn handleKeyboard(ctx: *Context) !void {
    defer ctx.deinit();

    const k = keyboard.Keyboard{
        .resize_keyboard = false,
        .one_time_keyboard = false,
        .keyboard = &[_]keyboard.KeyboardRow{
            .{ .buttons = &[_]keyboard.KeyboardButton{
                .{ .text = "Button 1" },
                .{ .text = "Button 2" },
            } },
        },
    };

    try ctx.reply(.{ .message = "keyboard", .reply_keyboard = .{ .keyboard = k } });
}

fn handleAll(ctx: *Context) !void {
    defer ctx.deinit();

    const k = keyboard.InlineKeyboard{
        .inline_keyboard = &[_]keyboard.InlineKeyboardRow{
            .{ .buttons = &[_]keyboard.InlineKeyboardButton{
                .{ .text = "button 1", .callback_data = "data1" },
                .{ .text = "button 2", .callback_data = "data2" },
            } },
            .{ .buttons = &[_]keyboard.InlineKeyboardButton{
                .{ .text = "button 3", .callback_data = "data3" },
            } },
        },
    };

    ctx.reply(.{ .message = "hi", .reply_keyboard = .{ .inline_keyboard = k } }) catch |err| {
        std.debug.print("{}\n", .{err});
    };
}

pub fn handleQuery(ctx: *Context) !void {
    defer ctx.deinit();

    try ctx.answerCbQuery(.{});

    try ctx.reply(.{ .message = "handle query" });
}

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();

    var tg = try Client.init(allocator, TOKEN, .{});

    try tg.handleAll(handleKeyboard); // handle all messages

    try tg.command("start", handleAll); // handle /start command

    try tg.hears("hello from zgram!", handleAll); // handle message

    try tg.action("data1", handleQuery); // handle callback query

    try tg.startPolling(.{ .drop_pending_updates = true });
}

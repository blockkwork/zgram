const std = @import("std");
const types = @import("../telegram/update_types.zig");
const Context = @import("../zgram/Context.zig");
const utils = @import("../zgram/utils.zig");
const Client = @This();
const requests = @import("../network/requests.zig");

const ClientOptions = struct {
    limit: i32 = 1000,
};

const Handler = struct {
    handler_type: HandlerType,
    trigger: []const u8,
    func: ?*fn (ctx: *Context) anyerror!void,
};

const HandlerType = enum {
    Action, // action
    Text, // hears

    pub const ErrorNameTable = [@typeInfo(HandlerType).Enum.fields.len][:0]const u8{
        "action",
        "text",
    };

    pub fn string(self: HandlerType) [:0]const u8 {
        return ErrorNameTable[@intFromEnum(self)];
    }
};

bot_token: []const u8,
token_url: []const u8, // "https://api.telegram.org/bot"  ++ bot token
allocator: std.mem.Allocator,
handlers: std.StringHashMap(Handler),
client_options: ClientOptions,

pub fn init(allocator: std.mem.Allocator, comptime bot_token: []const u8, options: ClientOptions) !Client {
    const handlers = std.StringHashMap(Handler).init(allocator);
    const token_url = try std.mem.concat(allocator, u8, &.{ "https://api.telegram.org/bot", bot_token });

    return .{
        .token_url = token_url,
        .bot_token = bot_token,
        .allocator = allocator,
        .handlers = handlers,
        .client_options = options,
    };
}

pub fn deinit(self: Client) void {
    self.handlers.deinit();
    self.allocator.destroy(self.workers);
}

pub fn addHandler(self: *Client, comptime handler_type: HandlerType, comptime trigger: []const u8, comptime func: *const fn (ctx: *Context) anyerror!void) !void {
    const new_trigger = try std.mem.concat(self.allocator, u8, &[_][]const u8{ handler_type.string(), " ", trigger });
    utils.debugln("NEW TRIGGER: {s}", .{new_trigger});

    try self.handlers.put(new_trigger, .{ .trigger = trigger, .func = @constCast(func), .handler_type = handler_type });
}

pub fn action(self: *Client, comptime trigger: []const u8, comptime func: *const fn (ctx: *Context) anyerror!void) !void {
    try self.addHandler(HandlerType.Action, trigger, comptime func);
}

pub fn command(self: *Client, comptime trigger: []const u8, comptime func: *const fn (ctx: *Context) anyerror!void) !void {
    comptime {
        if (trigger.len == 0)
            @compileError("Command trigger must not be empty");
        if (trigger[0] == '/')
            @compileError("Command trigger must not start with '/': " ++ trigger);
    }

    try self.addHandler(HandlerType.Text, "/" ++ trigger, comptime func);
}

pub fn handleAll(self: *Client, comptime func: *const fn (ctx: *Context) anyerror!void) !void {
    try self.handlers.put("/", .{ .trigger = "/", .func = @constCast(func), .handler_type = .Text });
}

pub fn hears(self: *Client, comptime trigger: []const u8, comptime func: *const fn (ctx: *Context) anyerror!void) !void {
    try self.addHandler(HandlerType.Text, trigger, comptime func);
}

pub fn startPolling(self: Client, options: struct {
    drop_pending_updates: bool = false,
}) !void {
    _ = options; // autofix

    var index: i32 = 0;
    var offset: i64 = -1;
    var offset_str: [100]u8 = undefined;
    const handle_all_func = self.handlers.get("/"); // get function to handle all updates
    var update_struct = std.mem.zeroes(types.Update);

    var ctx: Context = .{
        .allocator = self.allocator,
        .client = self,
        .update = &update_struct,
    };

    while (true) {
        index += 1;

        _ = try utils.intToString(offset, &offset_str);
        const res = try std.mem.concat(self.allocator, u8, &.{ self.token_url, "/getUpdates?timeout=30&offset=", &offset_str });
        defer self.allocator.free(res);

        const updates = self.polling(res) catch |err| switch (err) {
            error.NotFound => {
                utils.debugln("Not found", .{});
                continue;
            },
            error.BadGateway => {
                utils.debugln("Bad gateway", .{});
                continue;
            },
            error.OtherStatus => {
                utils.debugln("Other status", .{});
                continue;
            },
            else => {
                utils.debugln("Unknown error: {}", .{err});
                return;
            },
        };

        defer updates.deinit();

        for (updates.value.result) |x| {
            defer utils.debugln("END", .{});
            offset = x.update_id + 1;
            var handler_type: HandlerType = undefined;
            var search_data: []const u8 = undefined;

            // if (x.message.?.text == null) continue;
            if (x.callback_query != null) {
                handler_type = .Action;
            } else if (x.message != null) {
                handler_type = .Text;
            }

            if (x.message != null and x.message.?.text != null) {
                search_data = x.message.?.text.?;
            } else if (x.callback_query != null and x.callback_query.?.data != null) {
                search_data = x.callback_query.?.data.?;
            }

            ctx.update = try utils.dupe(self.allocator, x);

            const trigger = try std.mem.concat(self.allocator, u8, &[_][]const u8{ handler_type.string(), " ", search_data });
            defer self.allocator.free(trigger);

            const handler = self.handlers.get(trigger);
            if (handler == null) {
                utils.debugln("Handler not found (trigger: {s})", .{trigger});
                if (handle_all_func != null) {
                    try self.handleUpdate(ctx, handle_all_func.?.func.?);
                }
                continue;
            }

            try self.handleUpdate(ctx, handler.?.func.?);
            utils.debugln("HANDLED", .{});
            // continue;
        }
    }
}

fn polling(self: Client, url: []const u8) !std.json.Parsed(types.Updates) {
    const body = try requests.sendGET(self, url);
    defer self.allocator.free(body);

    const json_parsed = try std.json.parseFromSlice(types.Updates, self.allocator, body, .{ .ignore_unknown_fields = true, .allocate = .alloc_always });

    return json_parsed;
}

pub fn handleUpdate(self: Client, ctx: Context, func: *fn (ctx: *Context) anyerror!void) !void {
    _ = self; // autofix
    var thread = try std.Thread.spawn(.{}, callFunc, .{ ctx, func });
    thread.detach();
}

fn callFunc(ctx: Context, func: *fn (ctx: *Context) anyerror!void) void {
    utils.debugln("CALL FUNCTION", .{});

    func(@constCast(&ctx)) catch |err| {
        utils.debugln("ERROR: {}", .{err});
    };
}

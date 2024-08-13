const Client = @import("../zgram/Client.zig");
const std = @import("std");
const utils = @import("../zgram/utils.zig");

const TgError = error{
    BadGateway, // 502
    NotFound, // 404
    OtherStatus,
    HeaderError,
};

const Error = TgError;

pub fn sendGET(self: Client, url: []const u8) anyerror![]u8 {
    var client = std.http.Client{
        .allocator = self.allocator,
    };
    defer client.deinit();

    const uri = try std.Uri.parse(utils.trimTrailingNulls(url));

    var buf = std.ArrayList(u8).init(client.allocator);

    const res = try client.fetch(
        .{
            .location = .{ .uri = uri },
            .method = .GET,
            .response_storage = .{ .dynamic = &buf },
        },
    );

    switch (res.status) {
        std.http.Status.ok => {}, // ok
        std.http.Status.not_found => return Error.NotFound,
        std.http.Status.bad_gateway => return Error.BadGateway,
        else => return Error.OtherStatus,
    }

    return buf.items;
}

pub fn sendPOST(self: Client, url: []const u8, payload: []const u8) anyerror![]u8 {
    var client = std.http.Client{
        .allocator = self.allocator,
    };
    defer client.deinit();

    const uri = try std.Uri.parse(url);

    const headers = &[_]std.http.Header{
        .{ .name = "Content-Type", .value = "application/json" },
    };

    var buf = std.ArrayList(u8).init(client.allocator);

    const res = try client.fetch(
        .{
            .location = .{ .uri = uri },
            .payload = payload,
            .method = .POST,
            .extra_headers = headers,
            .keep_alive = false,
            .response_storage = .{ .dynamic = &buf },
        },
    );

    utils.debugln("url {s}, status: {}", .{ url, res.status });
    utils.debugln("buffer {s}", .{buf.items});

    switch (res.status) {
        std.http.Status.ok => {}, // ok
        std.http.Status.not_found => return Error.NotFound,
        std.http.Status.bad_gateway => return Error.BadGateway,
        else => return Error.OtherStatus,
    }

    return buf.items;
}

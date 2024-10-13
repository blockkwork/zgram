# zgram

## 💡 Info
In development. use at your own risk

## 🚀 Example
full example: [src/main.zig](https://github.com/blockkwork/zgram/blob/main/src/main.zig)

```zig
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();

    var tg = try Client.init(allocator, TOKEN, .{});
    {
        try tg.handleAll(handleKeyboard); // handle all messages
        try tg.command("start", handleAll); // handle /start command
        try tg.hears("hello from zgram!", handleAll); // handle message
        try tg.action("data1", handleQuery); // handle callback query
    }
    try tg.startPolling(.{ .drop_pending_updates = true });
```

![image](https://github.com/user-attachments/assets/fa302fab-4230-4298-883d-e2f8c77454ce)

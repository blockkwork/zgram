pub const Entity = struct {
    offset: i64,
    length: i64,
    type: []const u8,
    //                 "length": 6,
    //                 "type": "bot_command"
};

pub const Photo = struct {
    file_id: []const u8,
    file_unique_id: []const u8,
    file_size: i64,
    width: i64,
    height: i64,
};

const Chat = struct {
    id: u64,
    first_name: []const u8,
    last_name: ?[]const u8 = null,
    username: ?[]const u8 = null,
    type: []const u8,
};

pub const Update = struct {
    update_id: i64,
    message: ?struct {
        message_id: i64,
        from: struct {
            id: u64,
            is_bot: bool,
            first_name: []const u8,
            last_name: ?[]const u8 = null,
            username: ?[]const u8 = null,
            language_code: []const u8,
        },
        chat: Chat,
        date: u64,
        text: ?[]const u8 = null,
        photo: ?[]Photo = null,
        entities: ?[]Entity = null,
    } = null,
    callback_query: ?struct {
        id: []const u8,
        // from:
        message: ?struct {
            chat: Chat,
            text: ?[]const u8 = null,
            date: i64,
        } = null,
        chat_instance: ?[]const u8 = null,
        data: ?[]const u8 = null,
    } = null,
};

pub const Updates = struct {
    ok: bool,
    result: []Update,
};

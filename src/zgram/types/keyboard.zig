// inline keyboards

pub const InlineKeyboard = struct {
    inline_keyboard: []const InlineKeyboardRow,
};

pub const InlineKeyboardRow = struct {
    buttons: []const InlineKeyboardButton,
};

pub const InlineKeyboardButton = struct {
    text: []const u8,
    callback_data: []const u8,
};

pub const InlineURLButton = struct {
    text: []const u8,
    url: []const u8,
};

// keyboards

pub const Keyboard = struct {
    resize_keyboard: bool = false,
    one_time_keyboard: bool = false,
    keyboard: []const KeyboardRow,
};

pub const KeyboardRow = struct {
    buttons: []const KeyboardButton,
};

pub const KeyboardButton = struct {
    text: []const u8,
};

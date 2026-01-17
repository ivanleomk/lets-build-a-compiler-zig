const std = @import("std");

pub var look: u8 = 0;

pub fn getChar() anyerror!void {
    const stdin = std.io.getStdIn().reader();
    look = stdin.readByte() catch |err| {
        if (err == error.EndOfStream) {
            return;
        }
        return err;
    };
}

pub fn reportError(message: []const u8) void {
    std.debug.print("\nError: {s}.\n", .{message});
}

pub fn abort(message: []const u8) noreturn {
    reportError(message);
    std.process.exit(1);
}

pub fn expected(s: []const u8) noreturn {
    const message = std.fmt.allocPrint(std.heap.page_allocator, "{s} Expected", .{s}) catch unreachable;
    abort(message);
}

pub fn match(x: u8) anyerror!void {
    if (look == x) {
        try getChar();
    } else {
        const expected_char = [1]u8{x};
        expected(&expected_char);
    }
}

pub fn isAlpha(c: u8) bool {
    return std.ascii.isAlphabetic(c);
}

pub fn isDigit(c: u8) bool {
    return std.ascii.isDigit(c);
}

pub fn isAddop(c: u8) bool {
    return c == '+' or c == '-';
}

pub fn getName() anyerror!u8 {
    if (!isAlpha(look)) {
        expected("Name");
    }
    const name = std.ascii.toUpper(look);
    try getChar();
    return name;
}

pub fn getNum() anyerror!u8 {
    if (!isDigit(look)) {
        expected("Integer");
    }
    const num = look;
    try getChar();
    return num;
}

pub fn emit(s: []const u8) void {
    std.debug.print("\t{s}", .{s});
}

pub fn emitLn(s: []const u8) void {
    emit(s);
    std.debug.print("\n", .{});
}

pub fn init() anyerror!void {
    try getChar();
}

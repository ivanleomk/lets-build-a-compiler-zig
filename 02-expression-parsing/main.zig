const cradle = @import("cradle.zig");
const std = @import("std");

fn factor() anyerror!void {
    if (cradle.look == '(') {
        try cradle.match('(');
        try expression();
        try cradle.match(')');
    } else {
        const num = try cradle.getNum();
        const instruction = std.fmt.allocPrint(std.heap.page_allocator, "mov ${c}, %eax", .{num}) catch unreachable;
        cradle.emitLn(instruction);
    }
}

fn multiply() anyerror!void {
    try cradle.match('*');
    try factor();
    cradle.emitLn("pop %ebx");
    cradle.emitLn("imul %ebx, %eax");
}

fn divide() anyerror!void {
    try cradle.match('/');
    try factor();
    cradle.emitLn("pop %ebx");
    cradle.emitLn("xchg %eax, %ebx");
    cradle.emitLn("cdq");
    cradle.emitLn("idiv %ebx");
}

fn term() anyerror!void {
    try factor();
    while (cradle.look == '*' or cradle.look == '/') {
        cradle.emitLn("push %eax");
        switch (cradle.look) {
            '*' => try multiply(),
            '/' => try divide(),
            else => unreachable,
        }
    }
}

fn add() anyerror!void {
    try cradle.match('+');
    try term();
    cradle.emitLn("pop %ebx");
    cradle.emitLn("add %ebx, %eax");
}

fn subtract() anyerror!void {
    try cradle.match('-');
    try term();
    cradle.emitLn("pop %ebx");
    cradle.emitLn("sub %ebx, %eax");
    cradle.emitLn("neg %eax");
}

fn expression() anyerror!void {
    try term();
    while (cradle.isAddop(cradle.look)) {
        cradle.emitLn("push %eax");
        switch (cradle.look) {
            '+' => try add(),
            '-' => try subtract(),
            else => unreachable,
        }
    }
}

pub fn main() anyerror!void {
    try cradle.init();
    try expression();
}

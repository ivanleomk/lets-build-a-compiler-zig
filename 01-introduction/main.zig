const cradle = @import("cradle.zig");
const std = @import("std");

pub fn main() anyerror!void {
    try cradle.init();
    const name = try cradle.getName();
    const num = try cradle.getNum();

    const hello = std.fmt.allocPrint(std.heap.page_allocator, "Hello, {c}{c}", .{name, num}) catch unreachable;
    cradle.emitLn(hello);
}

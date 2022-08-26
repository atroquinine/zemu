const std = @import("std");
const builtin = @import("builtin");
const options = @import("options.zig");
const w = std.os.windows;

pub extern "kernel32" fn AllocConsole() callconv(w.WINAPI) w.BOOL;
pub extern "kernel32" fn FreeConsole() callconv(w.WINAPI) w.BOOL;

var allocated_console = false;
var allocator: std.mem.Allocator = undefined;

pub fn init(alloc: std.mem.Allocator) void {
    allocator = alloc;
    if (!options.enable_console) return;
    if (builtin.os.tag == .windows) {
        allocated_console = AllocConsole() == w.TRUE;
    }
    options.console_ready = true;
}

pub fn deinit() void {
    if (builtin.os.tag == .windows and allocated_console) {
        _ = w.user32.MessageBoxA(null, "a", "b", 0);
        _ = FreeConsole();
    }
    options.console_ready = false;
}

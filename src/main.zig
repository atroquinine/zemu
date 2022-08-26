const std = @import("std");
const builtin = @import("builtin");
const steam_api = @import("steam_api.zig");
const options = @import("options.zig");
const console = @import("console.zig");

const w = std.os.windows;
pub const log = @import("log.zig").log;

const Emu = struct {
    var gpa: std.heap.GeneralPurposeAllocator(.{}) = .{};
    const l = std.log.scoped(.Emu);

    pub fn init() void {
        const allocator = gpa.allocator();
        options.init(allocator);
        console.init(allocator);
        l.info("zemu initialized", .{});
    }

    pub fn deinit() void {
        l.info("Deinitializing zemu", .{});
        _ = gpa.deinit();
        console.deinit();
    }
};

pub fn DllMain(hInstDLL: w.HINSTANCE, fdwReason: w.DWORD, lpReserved: w.LPVOID) w.BOOL {
    _ = hInstDLL;
    _ = lpReserved;

    const DLL_PROCESS_ATTACH = 1;
    const DLL_PROCESS_DETACH = 0;

    switch (fdwReason) {
        DLL_PROCESS_ATTACH => Emu.init(),
        DLL_PROCESS_DETACH => Emu.deinit(),
        else => {}
    }

    return w.TRUE;
}

comptime {
    _ = steam_api;
}

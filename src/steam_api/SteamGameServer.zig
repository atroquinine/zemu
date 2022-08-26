const std = @import("std");
const t = @import("../steam_api.zig");

const l = std.log.scoped(.SteamGameServer);

pub fn GetHSteamUser() callconv(.C) t.HSteamUser {
    l.info("GetHSteamUser", .{});
    return 1;
}

pub fn GetHSteamPipe() callconv(.C) t.HSteamPipe {
    l.info("GetHSteamPipe", .{});
    return 1;
}

pub fn RunCallbacks() callconv(.C) void {
    l.info("RunCallbacks", .{});
}

pub fn Shutdown() callconv(.C) void {
    l.info("Shutdown", .{});
}
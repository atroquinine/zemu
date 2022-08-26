const std = @import("std");
const t = @import("../steam_api.zig");

const l = std.log.scoped(.SteamAPI);
const options = @import("../options.zig");
const manager = options.getManager;

pub fn Init() callconv(.C) bool {
    l.info("Init", .{});
    return true;
}

pub fn ReleaseCurrentThreadMemory() callconv(.C) void {
    l.info("ReleaseCurrentThreadMemory", .{});
}

pub fn RestartAppIfNecessary(unOwnAppID: u32) callconv(.C) bool {
    l.debug("RestartAppIfNecessary", .{});
    if (manager().get(.appid)) |*o| {
        defer o.free();
        const appid = o.as(u32, 0);
        if (unOwnAppID != appid) {
            l.warn("RestartAppIfNecessary: given AppID ({d}) != config AppID ({d})", .{ unOwnAppID, appid });
        }
    }
    return false;
}

pub fn RunCallbacks() callconv(.C) void {
    l.info("RunCallbacks", .{});
}

pub fn SetMiniDumpComment(pchMsg: [*c]const u8) callconv(.C) void {
    l.info("SetMiniDumpComment", .{});
    _ = pchMsg;
}

pub fn Shutdown() callconv(.C) void {
    l.info("Shutdown", .{});
}

pub fn WriteMiniDump(uStructuredExceptionCode: u32, pvExceptionInfo: ?*anyopaque, uBuildID: u32) callconv(.C) void {
    l.info("WriteMiniDump", .{});
    _ = uStructuredExceptionCode;
    _ = pvExceptionInfo;
    _ = uBuildID;
}

pub fn RegisterCallback(pCallback: ?*anyopaque, iCallback: c_int) callconv(.C) void {
    l.info("RegisterCallback", .{});
    _ = pCallback;
    _ = iCallback;
}

pub fn UnregisterCallback(pCallback: ?*anyopaque) callconv(.C) void {
    l.info("UnregisterCallback", .{});
    _ = pCallback;
}

pub fn RegisterCallResult(pCallback: ?*anyopaque, hAPICall: t.SteamAPICall_t) callconv(.C) void {
    l.info("RegisterCallResult", .{});
    _ = pCallback;
    _ = hAPICall;

}

pub fn UnregisterCallResult(pCallback: ?*anyopaque, hAPICall: t.SteamAPICall_t ) callconv(.C) void {
    l.info("UnregisterCallResult", .{});
    _ = pCallback;
    _ = hAPICall;
}

pub fn GetHSteamUser() callconv(.C) t.HSteamUser {
    l.info("GetHSteamUser", .{});
    return 1;
}

pub fn GetHSteamPipe() callconv(.C) t.HSteamPipe {
    l.info("GetHSteamPipe", .{});
    return 1;
}

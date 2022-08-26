const std = @import("std");
const t = @import("../steam_api.zig");
 
const l = std.log.scoped(.SteamInternal);

pub const GameServer = struct {
    const l1 = std.log.scoped(.SteamInternalGameServer);

    pub fn Init(unIP: u32, usLegacySteamPort: u16, usGamePort: u16, usQueryPort: u16, eServerMode: t.EServerMode, pchVersionString: [*c]const u8) callconv(.C) bool {
        l1.info("Init", .{});
        _ = unIP;
        _ = usLegacySteamPort;
        _ = usGamePort;
        _ = usQueryPort;
        _ = eServerMode;
        _ = pchVersionString;
        return true;
    }
};

pub fn ContextInit(pContextInitData: ?*anyopaque) callconv(.C) ?*anyopaque {
    l.info("ContextInit", .{});
    _ = pContextInitData;
    return undefined;
}

pub fn CreateInterface(ver: [*c]const u8) callconv(.C) ?*anyopaque {
    l.info("CreateInterface", .{});
    _ = ver;
    return undefined;
}

pub fn FindOrCreateUserInterface(hSteamUser: t.HSteamUser, pszVersion: [*c]const u8) callconv(.C) ?*anyopaque {
    l.info("FindOrCreateUserInterface", .{});
    _ = hSteamUser;
    _ = pszVersion;
    return undefined;
}

pub fn FindOrCreateGameServerInterface(hSteamUser: t.HSteamUser, pszVersion: [*c]const u8) callconv(.C) ?*anyopaque {
    l.info("FindOrCreateGameServerInterface", .{});
    _ = hSteamUser;
    _ = pszVersion;
    return undefined;
}

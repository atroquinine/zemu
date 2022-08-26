const std = @import("std");
const t = @import("steam_api.zig");

pub const SteamAPI = struct {
    pub const ISteamClient = @import("steam_api/ISteamClient.zig");
};

pub const SteamAPIExtra = @import("steam_api/SteamAPIExtra.zig");
pub const SteamGameServer = @import("steam_api/SteamGameServer.zig");
pub const SteamInternal = @import("steam_api/SteamInternal.zig");

comptime {
    t.exportAll(SteamAPIExtra, [_][]const u8{"SteamAPI"});
    t.exportAll(SteamGameServer, [_][]const u8{"SteamGameServer"});
    t.exportAll(SteamInternal, [_][]const u8{"SteamInternal"});
}

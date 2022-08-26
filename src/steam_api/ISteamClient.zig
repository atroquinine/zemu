const std = @import("std");
const t = @import("../steam_api.zig");

const l = std.log.scoped(.ISteamClient);

pub fn CreateSteamPipe() t.HSteamPipe {
    l.info("Hello from CreateSteamPipe", .{});
    return undefined;
}

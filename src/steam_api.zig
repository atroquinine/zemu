pub const SteamAPI = struct {
    pub usingnamespace @import("generated/callback_structs.zig");
    pub usingnamespace @import("generated/consts.zig");
    pub usingnamespace @import("generated/enums.zig");
    pub usingnamespace @import("generated/interfaces.zig");
    pub usingnamespace @import("generated/structs.zig");
    pub usingnamespace @import("generated/typedefs.zig");
    pub const p = [_][]const u8{ "SteamAPI" };
};

pub usingnamespace SteamAPI;

const impl = @import("impl.zig");

comptime {
    _ = impl;
    _ = SteamAPI;
}

const options = @import("options.zig");

const std = @import("std");
const log = std.log;

/// This function inlines and calls an implementation function from a stub one.
/// Also prints arguments passed to the stub to help debugging and implementing it.
pub inline fn callImplFn(comptime path: []const []const u8, args: anytype, args_names: anytype, comptime FnType: type) (@typeInfo(FnType).Fn.return_type orelse void) {
    const should_log = !options.disable_param_verbose and options.verbose;
    if (should_log) {
        comptime var name = pathToName(path, '.');
        printArgs(name, args, args_names);
    }

    if (comptime getPath(impl, path)) |func| {
        const ret = @call(.{ .modifier = .always_inline }, func, args);
        if (should_log) {
            log.debug("ret = {}\n", .{ ret });
        }
        return ret;
    } else |_| {
        return undefined;
    }
}

/// Exports all functions inside a struct. Roughly follows C++ exports names.
pub fn exportAll(root: anytype, path: anytype) void {
    exportAllSub(root, root, path);
}

fn exportAllSub(root: anytype, current: anytype, path: anytype) void {
    const info = switch (@TypeOf(current)) {
        std.builtin.TypeInfo.Declaration => blk: {
            if (!current.is_pub) return;
            const data = getPath(root, path[1..]) catch unreachable;

            break :blk switch (@typeInfo(@TypeOf(data))) {
                .Fn => {
                    @export(data, .{ .name = pathToName(&path, '_'), .linkage = .Strong });
                    return;
                },
                .Type => @typeInfo(data),
                else => return
            };
        },
        else => @typeInfo(current),
    };

    if (info == .Struct) {
        inline for (info.Struct.decls) |decl| {
            exportAllSub(root, decl, path ++ [_][]const u8{ decl.name });
        }
    }
}

/// Traverses a declaration path and returns the type of the last declaration, or void if it isn't valid.
fn PathType(root: anytype, comptime path: []const []const u8) type {
    if (path.len == 0 or !@hasDecl(root, path[0])) return void;

    const current = @field(root, path[0]);
    if (path.len == 1) return @TypeOf(current);

    return PathType(current, path[1..]);
}

/// Gets the value of the last declaration of a declaration path.
fn getPath(root: anytype, comptime path: []const []const u8) !PathType(root, path) {
    if (path.len == 0) return error.EmptyPath;
    if (!@hasDecl(root, path[0])) return error.InvalidPath;

    const current = @field(root, path[0]);
    if (path.len == 1) {
        return current;
    }
    return try getPath(current, path[1..]);
}

/// Transforms a declaration path into a string.
fn pathToName(comptime path: []const []const u8, comptime sep: u8) []const u8 {
    if (path.len == 0) return "";
    if (path.len == 1) return path[0];
    return path[0] ++ [_]u8{ sep } ++ pathToName(path[1..], sep);
}

inline fn printArgs(name: []const u8, args: anytype, args_names: anytype) void {
    log.debug("CALLED {s}", .{ name });
    comptime var i = 0;
    inline while (i < args.len) : (i += 1) {
        log.debug("\t{s} = {any}", .{ args_names[i], args[i] });
    }
}

pub const size_t = usize;
pub const SteamAPIWarningMessageHook_t = ?*const fn([*c]i32, [*c]const u8) callconv(.C) void;

const GameID_t = packed struct {
    m_nAppID: u24,
    m_nType: u8,
    m_nModID: u32,
};

pub const CGameID = extern union {
    m_ulGameID: u64,
    m_gameID: GameID_t,
};

const SteamIDComponent_t = packed struct {
    m_unAccountID: u32,
    m_unAccountInstance: u20,
    m_EAccountType: u4,
    m_EUniverse: u8,
};

pub const CSteamID = extern union {
    m_unAll64Bits: u64,
    m_comp: SteamIDComponent_t,
};

/////////////////////////////////////////
// TODO implement these types properly //
/////////////////////////////////////////

pub const SteamInputActionEvent_t = extern struct {
    _: u8,
};

pub const SteamDatagramRelayAuthTicket = extern struct {
    _: u8,
};

pub const ISteamNetworkingConnectionSignaling = extern struct {
    _: u8,
};

pub const ISteamNetworkingSignalingRecvContext = extern struct {
    _: u8,
};

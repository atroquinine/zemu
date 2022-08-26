const bo = @import("build_options");
const std = @import("std");

const Allocator = std.mem.Allocator;
const EnumLiteral = @Type(.EnumLiteral);

pub var verbose = bo.force_verbose;

pub const enable_env_options = true;

pub const can_console = !bo.disable_console;
pub var enable_console = bo.force_console;
pub var console_ready = false;

pub const disable_param_verbose = bo.disable_param_verbose;

/// A structure to centralize runtime options management (primarily fetching option values).
/// Initialize the manager with `init`, then get options with `get` or `getErr`.
pub const OptionManager = struct {
    /// The allocator for the manager.
    allocator: Allocator,
    /// The list of directories to search options files in.
    search_dirs: []const []const u8,

    const l = std.log.scoped(.OptionManager);

    /// Creates an `OptionManager` with an allocator and a list of search
    /// directories where option files will be searched for.
    pub fn init(allocator: Allocator, search_dirs: []const []const u8) OptionManager {
        return OptionManager{ .allocator = allocator, .search_dirs = search_dirs };
    }

    /// Returns an `Option`, looking for a corresponding environment variable or file with the option content,
    /// or an `MissingOption` error if the option could not be found.
    pub fn getErr(self: *const OptionManager, comptime option: EnumLiteral) !Option {
        const cwd = std.fs.cwd();
        const file_name = getFileName(option);
        const env_name = getEnvName(option);

        if (enable_env_options) {
            if (std.process.getEnvVarOwned(self.allocator, env_name)) |b| {
                return Option{ .allocator = self.allocator, .val = b };
            } else |_| {}
        }

        var buffer: ?[]u8 = null;
        for (self.search_dirs) |search_dir| {
            const dir = cwd.openDir(search_dir, .{}) catch continue;
            const f = dir.openFile(file_name, .{}) catch continue;
            defer f.close();

            const stat = f.stat() catch continue;
            buffer = self.allocator.alloc(u8, @intCast(usize, stat.size)) catch continue;
            _ = f.readAll(buffer.?) catch {
                self.allocator.free(buffer.?);
                buffer = null;
                continue;
            };

            break;
        }

        if (buffer) |b| {
            return Option{ .allocator = self.allocator, .val = b };
        } else {
            return error.MissingOption;
        }
    }

    /// Returns an optional `Option`. Works exactly like `getErr` but returns null instead of an error.
    pub fn get(self: *const OptionManager, comptime option: EnumLiteral) ?Option {
        return self.getErr(option) catch null;
    }

    /// Transforms an `EnumLiteral` into the corresponding option name.
    fn optionToName(comptime option: EnumLiteral) []const u8 {
        return switch (option) {
            .appid => "steam_appid",
            else => @tagName(option)
        };
    }

    /// Transforms an `EnumLiteral` into the corresponding option file name.
    fn getFileName(comptime option: EnumLiteral) []const u8 {
        comptime var name = optionToName(option);
        comptime var out: [name.len]u8 = undefined;
        return comptime std.ascii.lowerString(out[0..], name) ++ ".txt";
    }

    /// Transforms an `EnumLiteral` into the corresponding option environment variable name.
    fn getEnvName(comptime option: EnumLiteral) []const u8 {
        const prefix = "ZEMU_";
        comptime var name = optionToName(option);
        comptime var out: [name.len]u8 = undefined;
        return prefix ++ comptime std.ascii.upperString(out[0..], name);
    }

    /// A structure that holds the value of an option and what allocator allocated it.
    /// Free it with `free` after you're done with it.
    const Option = struct {
        /// Allocator that was used to allocated `val`.
        allocator: ?Allocator = null,
        /// Actual content of the option.
        val: ?[]const u8,

        /// Free the resources associated with this `Option`.
        pub fn free(self: *const Option) void {
            if (self.val) |v| {
                if (self.allocator) |a| {
                    a.free(v);
                }
            }
        }

        /// Helper function to interpret the content of this option as another type.
        /// Returns an error if an invalid type was given or if the parsing wasn't successful.
        pub fn parseErr(self: *const Option, comptime T: type) !T {
            const v = self.val orelse return error.NullVal;
            if (T == @TypeOf(v)) return v;
            return switch (@typeInfo(T)) {
                .Int => std.fmt.parseInt(T, v, 0),
                .Float => std.fmt.parseFloat(T, v),
                else => error.InvalidType,
            };
        }

        /// Similar to `parseErr`, but returns `default` if `parseErr` would err.
        pub fn parse(self: *const Option, comptime T: type, default: T) T {
            return self.parseErr(T) catch default;
        }

        /// Alias to parse.
        pub const as = parse;
    };
};

/// This is the global option manager. Other modules can call `getManager` to obtain it.
var manager: ?OptionManager = null;

/// Initializes the global option manager. It has a default list of search directories.
pub fn init(allocator: Allocator) void {
    manager = OptionManager.init(allocator, &([_][]const u8{ ".", "zemu_settings", "steam_settings" }));
    if (!enable_console and can_console) {
        if (manager.?.get(.console)) |*o| {
            defer o.free();
            enable_console = o.as(u1, 0) != 0;
        }
    }
    if (!verbose) {
        if (manager.?.get(.verbose)) |*o| {
            defer o.free();
            verbose = o.as(u1, 0) != 0;
        }
    }
}

/// Gets the global option manager.
pub fn getManager() OptionManager {
    if (manager) |m| {
        return m;
    } else {
        @panic("Option manager wasn't initialized");
    }
}

const std = @import("std");
const options = @import("options.zig");
const builtin = @import("builtin");
const c_time = @cImport(@cInclude("time.h"));

const Level = std.log.Level;
const File = std.fs.File;

var log_mutex = std.Thread.Mutex{};

const w = std.os.windows;

pub fn log(comptime level: Level, comptime scope: @Type(.EnumLiteral), comptime format: []const u8, args: anytype) void {
    if (!options.verbose and level == .debug) return;
    log_mutex.lock();
    defer log_mutex.unlock();

    const stderr = std.io.getStdErr();
    const time = Time.get();

    const level_fmt = formatLevel(level);

    if (options.console_ready) {
        changeColor(stderr, level);
    }
    defer if (options.console_ready) resetColor(stderr);

    const err_writer = stderr.writer();
    logToWriter(err_writer, time, level_fmt, scope, format, args);

    if (getFileWriter()) |wr| {
        logToWriter(wr, time, level_fmt, scope, format, args);
    }
}

/// Formats a level enum into its string representation
fn formatLevel(comptime level: Level) []const u8 {
    return switch (level) {
        .debug => "D",
        .info => "I",
        .warn => "W",
        .err => "E",
    };
}

/// Use the old Windows API console attribute API because I still want to target Windows <10
const tty_config: std.debug.TTY.Config = if (builtin.os.tag == .windows) .windows_api else .escape_codes;

/// Changes the terminal color based on the current log level that will be printed.
fn changeColor(stderr: File, comptime level: Level) void {
    const color = switch (level) {
        .debug => .Dim,
        .info => .White,
        // TODO change to yellow if zig ever adds that to std.debug
        .warn => .Cyan,
        .err => .Red,
    };

    tty_config.setColor(stderr, color);
}

/// Resets the terminal color
fn resetColor(stderr: File) void {
    tty_config.setColor(stderr, .Reset);
}

/// Prints the log prelude (date, time, log level and log scope)
fn printPrelude(writer: anytype, time: Time, level: []const u8, comptime scope: @Type(.EnumLiteral)) void {
    writer.print("[{}-{:0>2}-{:0>2} {:0>2}:{:0>2}:{:0>2}.{:0>3}] ", .{
        time.year(),
        time.month(),
        time.day(),
        time.hours(),
        time.minutes(),
        time.seconds(),
        time.milli
    }) catch undefined;
    writer.print("[{s}] [{s}] ", .{ level, @tagName(scope) }) catch undefined;
}

/// Write a log message into a writer, printing the prelude and the actual message.
fn logToWriter(writer: anytype, time: Time, level: []const u8, comptime scope: @Type(.EnumLiteral), comptime format: []const u8, args: anytype) void {
    printPrelude(writer, time, level, scope);
    writer.print(format ++ "\n", args) catch undefined;
}

/// A helper struct to get current time and get its components as unsigned integers.
/// (for some reason, zig prefixes signed integers on format with plus signs)
const Time = struct {
    /// C tm struct, holds information about number of seconds in current minute, etc.
    tm: c_time.tm,
    /// Number of milliseconds ellapsed in current second.
    milli: u16,

    /// Gets the current time.
    pub fn get() Time {
        var ret: Time = undefined;

        const total_milliseconds = std.time.milliTimestamp();

        const secs = @divFloor(total_milliseconds, 1000);
        ret.milli = @intCast(u16, @mod(total_milliseconds, 1000));

        // Windows' localtime_s arguments are reversed in relation to standard C
        if (builtin.os.tag == .windows) {
            _ = c_time.localtime_s(&ret.tm, &@truncate(c_time.time_t, secs));
        } else {
            _ = c_time.localtime_r(&@truncate(c_time.time_t, secs), &ret.tm);
        }

        return ret;
    }

    pub inline fn seconds(self: *const Time) u8 {
        return @intCast(u8, self.tm.tm_sec);
    }

    pub inline fn minutes(self: *const Time) u8 {
        return @intCast(u8, self.tm.tm_min);
    }

    pub inline fn hours(self: *const Time) u8 {
        return @intCast(u8, self.tm.tm_hour);
    }

    pub inline fn day(self: *const Time) u8 {
        return @intCast(u8, self.tm.tm_mday);
    }

    pub inline fn month(self: *const Time) u8 {
        return @intCast(u8, self.tm.tm_mon+1);
    }

    pub inline fn year(self: *const Time) u32 {
        return @intCast(u32, self.tm.tm_year+1900);
    }
};

fn getFileWriter() ?std.fs.File.Writer {
    const S = struct {
        var file: std.fs.File = undefined;
        var init_file = false;
    };

    if (!S.init_file) {
        var free = false;
        var manager = options.getManager();
        var log_file_name = blk: {
            if (manager.get(.log_file)) |o| {
                free = true;
                break :blk o.val.?;
            } else if (manager.get(.should_log)) |o| {
                o.free();
                break :blk "zemu_log.txt"[0..];
            } else {
                break :blk null;
            }
        };
        defer if (free) manager.allocator.free(log_file_name.?);

        if (log_file_name) |name| {
            S.file = std.fs.cwd().createFile(name, .{ .truncate = false }) catch return null;
            S.file.seekFromEnd(0) catch undefined;
            S.init_file = true;
        }
    }

    return if (S.init_file) S.file.writer() else null;
}

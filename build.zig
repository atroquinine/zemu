const std = @import("std");

pub fn build(b: *std.build.Builder) void {
    // Standard release options allow the person running `zig build` to select
    // between Debug, ReleaseSafe, ReleaseFast, and ReleaseSmall.
    const mode = b.standardReleaseOptions();
    const target = b.standardTargetOptions(.{});

    const generate_bindings = b.option(bool, "generate-bindings", "Force the (re)generation of the Steam API bindings") orelse false;
    const force_verbose = b.option(bool, "force-verbose", "Force debug logging") orelse false;
    const disable_param_verbose = b.option(bool, "disable-param-verbose", "Disable logging of SteamAPI calls") orelse false;
    const force_console = b.option(bool, "force-console", "Force enabling access to the console") orelse false;
    const disable_console = b.option(bool, "disable-console", "Fully disable access to the console") orelse false;

    if (force_console and disable_console) {
        std.debug.panic("force-console and disable-console options are mutually exclusive\n", .{});
    }

    const options = b.addOptions();
    options.addOption(bool, "force_verbose", force_verbose);
    options.addOption(bool, "disable_param_verbose", disable_param_verbose);
    options.addOption(bool, "force_console", force_console);
    options.addOption(bool, "disable_console", disable_console);

    const lib = b.addSharedLibrary("zemu", "src/main.zig", .unversioned);
    lib.linkLibC();
    lib.setBuildMode(mode);
    lib.setTarget(target);
    lib.addOptions("build_options", options);
    lib.install();

    if (generate_bindings) {
        const generate_step = b.step("generate", "Generate steam_api bindings");
        const generator = b.addExecutable("generator", "src/generator/main.zig");
        var run = generator.run();
        run.addArgs(&.{ "src/generator/steam_api.json", "src/generated", "force" });
        generate_step.dependOn(&run.step);
        lib.step.dependOn(generate_step);
    }

    const main_tests = b.addTest("src/main.zig");
    main_tests.setBuildMode(mode);

    const test_step = b.step("test", "Run library tests");
    test_step.dependOn(&main_tests.step);
}

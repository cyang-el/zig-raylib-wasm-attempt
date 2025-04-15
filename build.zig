const std = @import("std");
const rlz = @import("raylib_zig");

pub fn build(b: *std.Build) !void {
    // Standard target options
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    // Get the target
    const is_wasm = target.result.cpu.arch.isWasm();

    // Native build (non-WebAssembly)
    if (!is_wasm) {
        // Add executable
        const exe = b.addExecutable(.{
            .name = "impossible-day",
            .root_source_file = b.path("src/main.zig"),
            .target = target,
            .optimize = optimize,
        });

        // Add raylib as a dependency
        const raylib_dep = b.dependency("raylib_zig", .{
            .target = target,
            .optimize = optimize,
        });
        const raylib = raylib_dep.module("raylib");
        const raylib_artifact = raylib_dep.artifact("raylib");

        // Link with raylib
        exe.root_module.addImport("raylib", raylib);
        exe.linkLibrary(raylib_artifact);

        // Install the executable
        b.installArtifact(exe);

        // Setup run command
        const run_cmd = b.addRunArtifact(exe);
        run_cmd.step.dependOn(b.getInstallStep());

        // Add run step
        const run_step = b.step("run", "Run the game");
        run_step.dependOn(&run_cmd.step);
    }
    // WebAssembly build
    else {
        // Create the WebAssembly build step
        const wasm_step = b.step(
            "wasm",
            "Build for WebAssembly",
        );

        // Add library for wasm
        const exe_lib = b.addStaticLibrary(.{
            .name = "impossible-day",
            .root_source_file = b.path("src/main.zig"),
            .target = target,
            .optimize = optimize,
        });

        // Add raylib as a dependency with wasm options
        const raylib_dep = b.dependency("raylib_zig", .{
            .target = target,
            .optimize = optimize,
        });
        const raylib = raylib_dep.module("raylib");
        const raylib_artifact = raylib_dep.artifact("raylib");

        // Add raylib to our application
        exe_lib.root_module.addImport("raylib", raylib);
        exe_lib.linkLibrary(raylib_artifact);

        // Link everything with emscripten
        const link_step = try rlz.emcc.linkWithEmscripten(
            b,
            &[_]*std.Build.Step.Compile{ exe_lib, raylib_artifact },
        );

        // Add emscripten flags with more verbose debug options
        link_step.addArg("-sASYNCIFY");
        link_step.addArg("-sUSE_GLFW=3");
        link_step.addArg("-sSINGLE_FILE=1");
        link_step.addArg("-sINITIAL_MEMORY=67108864"); // 64MB
        link_step.addArg("-sALLOW_MEMORY_GROWTH=1");
        link_step.addArg("-sEXPORTED_RUNTIME_METHODS=ccall,cwrap");
        link_step.addArg("-sFORCE_FILESYSTEM=1");
        link_step.addArg("-o"); // Output file name
        link_step.addArg("impossible-day.html"); // Set the HTML file name

        // Make sure to use our custom shell file
        link_step.addArg("--shell-file=shell.html");

        wasm_step.dependOn(&link_step.step);
    }
}

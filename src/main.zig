const std = @import("std");
const rl = @import("raylib");

pub fn main() !void {
    // Initialize window
    const screenWidth = 1000;
    const screenHeight = 750;
    rl.initWindow(screenWidth, screenHeight, "impossible-day");
    defer rl.closeWindow();

    // Set target FPS
    rl.setTargetFPS(60);

    // Ball position
    var ballPosition = rl.Vector2{
        .x = @as(f32, @floatFromInt(screenWidth)) / 2.0,
        .y = @as(f32, @floatFromInt(screenHeight)) / 2.0,
    };

    // Main game loop
    while (!rl.windowShouldClose()) {
        // Update
        if (rl.isMouseButtonDown(.left)) {
            const mousePosition = rl.getMousePosition();
            ballPosition = mousePosition;
        }

        // Draw
        rl.beginDrawing();
        defer rl.endDrawing();

        rl.clearBackground(.ray_white);
        rl.drawCircleV(ballPosition, 50, .maroon);

        // Check if running in WebAssembly (using CPU architecture)
        if (@import("builtin").cpu.arch.isWasm()) {
            rl.drawText("in wasm!", 10, screenHeight - 30, 20, .green);
        } else {
            rl.drawText("native build", 10, screenHeight - 30, 20, .blue);
        }
    }
}

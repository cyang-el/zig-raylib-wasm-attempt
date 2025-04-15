#!/bin/bash

# Create output directory if it doesn't exist
mkdir -p zig-out/htmlout

# Build for WASM
zig build wasm -Dtarget=wasm32-emscripten --sysroot "/home/cy/emsdk/upstream/emscripten"

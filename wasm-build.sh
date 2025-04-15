#!/bin/bash

# Make sure we're in the project root directory
cd "$(dirname "$0")"

# Create a container-based shell.html template for emscripten
cat > shell.html << 'EOL'
<!DOCTYPE html>
<html>
<head>
    <meta charset="utf-8">
    <style>
        #app-container {
            width: 800px;
            height: 600px;
            position: relative;
            margin: 0 auto;
            overflow: hidden;
            background-color: black;
        }
        #canvas {
            position: absolute;
            top: 0;
            left: 0;
            width: 100%;
            height: 100%;
            image-rendering: pixelated;
            image-rendering: crisp-edges;
        }
    </style>
</head>
<body>
    <div id="app-container">
        <canvas id="canvas" oncontextmenu="event.preventDefault()"></canvas>
    </div>
    <script>
        var Module = {
            canvas: document.getElementById('canvas'),
            onRuntimeInitialized: function() {
                document.getElementById('canvas').focus();
            }
        };
    </script>
    {{{ SCRIPT }}}
</body>
</html>
EOL

# Make sure shell.html exists and is readable
if [ ! -f "shell.html" ]; then
    echo "Error: shell.html was not created properly."
    exit 1
fi

chmod 644 shell.html
echo "Shell file created at: $(pwd)/shell.html"

# Make sure emscripten is in the PATH and configured
source "/home/cy/emsdk/emsdk_env.sh" > /dev/null 2>&1 || true

# Clean any previous builds
rm -f zig-out/htmlout/*.html zig-out/htmlout/*.js zig-out/htmlout/*.wasm

# Create output directory if it doesn't exist
mkdir -p zig-out/htmlout

# Build for WASM with absolute path to shell.html
SHELL_PATH="$(pwd)/shell.html"
echo "Using shell file at: $SHELL_PATH"

zig build wasm -Dtarget=wasm32-emscripten --sysroot "/home/cy/emsdk/upstream/emscripten" -- "--shell-file=$SHELL_PATH"

# Clean up and move to output directory
mv *.html zig-out/htmlout/index.html 2>/dev/null || true
mv *.js zig-out/htmlout/ 2>/dev/null || true
mv *.wasm zig-out/htmlout/ 2>/dev/null || true

echo "Build complete. Files moved to zig-out/htmlout/"
echo "The app is now in a container div that can be embedded in other HTML pages."

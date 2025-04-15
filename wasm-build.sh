#!/bin/bash

# Make sure we're in the project root directory
cd "$(dirname "$0")"

# Create a standard shell.html for the build process
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

# Move generated files to output directory
# mv *.html zig-out/htmlout/index.html 2>/dev/null || true
# mv *.js zig-out/htmlout/ 2>/dev/null || true
# mv *.wasm zig-out/htmlout/ 2>/dev/null || true

# Create an org-mode compatible HTML snippet
cat > org-embed.html << 'EOL'
<!-- Begin Embedded WASM App -->
<style>
.wasm-app-container {
    width: 800px;
    height: 600px;
    position: relative;
    margin: 0 auto;
    overflow: hidden;
    background-color: black;
    border: 1px solid #333;
}
.wasm-app-canvas {
    position: absolute;
    top: 0;
    left: 0;
    width: 100%;
    height: 100%;
    image-rendering: pixelated;
    image-rendering: crisp-edges;
}
</style>

<div class="wasm-app-container">
    <canvas class="wasm-app-canvas" id="impossibleDayCanvas" oncontextmenu="event.preventDefault()"></canvas>
</div>

<script>
    // Only initialize if not already initialized
    if (typeof window.impossibleDayInitialized === 'undefined') {
        window.impossibleDayInitialized = true;

        // Load the JavaScript module for the app
        var script = document.createElement('script');
        script.src = "impossible-day.js";
        script.onload = function() {
            var Module = {
                canvas: document.getElementById('impossibleDayCanvas'),
                onRuntimeInitialized: function() {
                    document.getElementById('impossibleDayCanvas').focus();
                }
            };
        };
        document.body.appendChild(script);
    }
</script>
<!-- End Embedded WASM App -->
EOL

echo "Created org-mode compatible HTML snippet"
echo "To use in org-mode, copy the contents of org-embed.html into a #+BEGIN_EXPORT html ... #+END_EXPORT block"
echo "Make sure to also copy the impossible-day.js and *.wasm files to your website's assets directory"

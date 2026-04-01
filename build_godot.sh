#!/bin/bash

# Detect platform
case "$(uname -s)" in
    Linux*)  PLATFORM="linuxbsd" ;;
    Darwin*) PLATFORM="macos" ;;
    *)       echo "Unsupported OS: $(uname -s)"; exit 1 ;;
esac

echo "Detected platform: $PLATFORM"
echo ""
echo "What would you like to build?"
echo "  1) Editor only"
echo "  2) Export templates only"
echo "  3) Both"
echo ""
read -rp "Choice [1/2/3]: " CHOICE

# Add any custom flags here (modules, arch, etc.)
EXTRA_FLAGS=""

build_editor() {
    echo "=== Building Editor ==="
    scons platform="$PLATFORM" target=editor $EXTRA_FLAGS -j"$(nproc 2>/dev/null || sysctl -n hw.ncpu)"
}

build_templates() {
    echo "=== Building Debug Export Template ==="
    scons platform="$PLATFORM" target=template_debug $EXTRA_FLAGS -j"$(nproc 2>/dev/null || sysctl -n hw.ncpu)"

    echo "=== Building Release Export Template ==="
    scons platform="$PLATFORM" target=template_release production=yes $EXTRA_FLAGS -j"$(nproc 2>/dev/null || sysctl -n hw.ncpu)"
}

case "$CHOICE" in
    1) build_editor ;;
    2) build_templates ;;
    3) build_editor && build_templates ;;
    *) echo "Invalid choice."; exit 1 ;;
esac

echo ""
echo "Done! Binaries are in bin/"

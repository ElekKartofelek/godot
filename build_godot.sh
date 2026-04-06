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

# Add any custom flags here (modules, etc.)
EXTRA_FLAGS=""

JOBS="-j$(nproc 2>/dev/null || sysctl -n hw.ncpu)"

build_editor() {
    echo "=== Building Editor ==="
    if [ "$PLATFORM" = "macos" ]; then
        scons platform=macos target=editor arch=x86_64 $EXTRA_FLAGS $JOBS
        scons platform=macos target=editor arch=arm64 generate_bundle=yes $EXTRA_FLAGS $JOBS
        lipo -create \
            bin/godot.macos.editor.x86_64 \
            bin/godot.macos.editor.arm64 \
            -output bin/godot.macos.editor.universal
    else
        scons platform="$PLATFORM" target=editor $EXTRA_FLAGS $JOBS
    fi
}

build_templates() {
    echo ""
    echo "Which templates?"
    echo "  1) Debug only (fastest, good for testing)"
    echo "  2) Debug + Release"
    echo "  3) Debug + Release (production=yes, slow but optimized)"
    echo ""
    read -rp "Choice [1/2/3]: " TMPL_CHOICE

    if [ "$PLATFORM" = "macos" ]; then
        echo "=== Building Debug Export Template ==="
        scons platform=macos target=template_debug arch=x86_64 $EXTRA_FLAGS $JOBS
        scons platform=macos target=template_debug arch=arm64 $EXTRA_FLAGS $JOBS
        lipo -create \
            bin/godot.macos.template_debug.x86_64 \
            bin/godot.macos.template_debug.arm64 \
            -output bin/godot.macos.template_debug.universal

        if [ "$TMPL_CHOICE" = "2" ]; then
            echo "=== Building Release Export Template ==="
            scons platform=macos target=template_release arch=x86_64 $EXTRA_FLAGS $JOBS
            scons platform=macos target=template_release arch=arm64 $EXTRA_FLAGS $JOBS
            lipo -create \
                bin/godot.macos.template_release.x86_64 \
                bin/godot.macos.template_release.arm64 \
                -output bin/godot.macos.template_release.universal
        elif [ "$TMPL_CHOICE" = "3" ]; then
            echo "=== Building Release Export Template (production) ==="
            scons platform=macos target=template_release arch=x86_64 production=yes $EXTRA_FLAGS $JOBS
            scons platform=macos target=template_release arch=arm64 production=yes $EXTRA_FLAGS $JOBS
            lipo -create \
                bin/godot.macos.template_release.x86_64 \
                bin/godot.macos.template_release.arm64 \
                -output bin/godot.macos.template_release.universal
        fi
    else
        echo "=== Building Debug Export Template ==="
        scons platform="$PLATFORM" target=template_debug $EXTRA_FLAGS $JOBS

        if [ "$TMPL_CHOICE" = "2" ]; then
            echo "=== Building Release Export Template ==="
            scons platform="$PLATFORM" target=template_release $EXTRA_FLAGS $JOBS
        elif [ "$TMPL_CHOICE" = "3" ]; then
            echo "=== Building Release Export Template (production) ==="
            scons platform="$PLATFORM" target=template_release production=yes $EXTRA_FLAGS $JOBS
        fi
    fi
}

case "$CHOICE" in
    1) build_editor ;;
    2) build_templates ;;
    3) build_editor && build_templates ;;
    *) echo "Invalid choice."; exit 1 ;;
esac

echo ""
echo "Done! Binaries are in bin/"
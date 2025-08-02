#!/bin/bash

# Secure Rust build script with cross-compilation support
# Usage: secure-build.sh <binary-name> <target> <cargo-args> [output-dir]

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Source validation functions
# shellcheck source=validate-inputs.sh
source "$SCRIPT_DIR/validate-inputs.sh"

# Parse arguments
BINARY_NAME="${1:-}"
TARGET="${2:-}"
CARGO_ARGS="${3:---release}"
OUTPUT_DIR="${4:-release}"

# Validate required arguments
if [[ -z "$BINARY_NAME" || -z "$TARGET" ]]; then
    echo "Usage: $0 <binary-name> <target> [cargo-args] [output-dir]"
    echo ""
    echo "Arguments:"
    echo "  binary-name  Name of the binary to build"
    echo "  target       Rust target triple (e.g., x86_64-unknown-linux-gnu)"
    echo "  cargo-args   Additional cargo build arguments (default: --release)"
    echo "  output-dir   Output directory for built binaries (default: release)"
    echo ""
    echo "Examples:"
    echo "  $0 my-app x86_64-unknown-linux-gnu"
    echo "  $0 my-cli aarch64-apple-darwin '--release --locked'"
    exit 1
fi

# Validate inputs
echo "Validating build parameters..."
validate_binary_name "$BINARY_NAME" || exit 1
validate_cargo_args "$CARGO_ARGS" || exit 1

# Validate target format
if [[ ! "$TARGET" =~ ^[a-zA-Z0-9_-]+$ ]]; then
    echo "Error: Invalid target format: $TARGET"
    echo "Target must contain only alphanumeric characters, dashes and underscores"
    exit 1
fi

# Validate and create output directory
if ! validate_file_path "$OUTPUT_DIR"; then
    exit 1
fi

mkdir -p "$OUTPUT_DIR"

echo "Building $BINARY_NAME for target $TARGET..."

# Determine platform characteristics
BINARY_EXT=""
PLATFORM=""
ARCHIVE_EXT="tar.gz"

case "$TARGET" in
    *"windows"*)
        BINARY_EXT=".exe"
        ARCHIVE_EXT="zip"
        if [[ "$TARGET" == *"x86_64"* ]]; then
            PLATFORM="windows-x86_64"
        elif [[ "$TARGET" == *"aarch64"* ]]; then
            PLATFORM="windows-arm64"
        elif [[ "$TARGET" == *"i686"* ]]; then
            PLATFORM="windows-i686"
        else
            PLATFORM="windows-unknown"
        fi
        ;;
    *"apple"*)
        if [[ "$TARGET" == *"x86_64"* ]]; then
            PLATFORM="mac-x86_64"
        elif [[ "$TARGET" == *"aarch64"* ]]; then
            PLATFORM="mac-arm64"
        else
            PLATFORM="mac-unknown"
        fi
        ;;
    *"linux"*)
        if [[ "$TARGET" == *"x86_64"* ]]; then
            if [[ "$TARGET" == *"musl"* ]]; then
                PLATFORM="linux-x86_64-musl"
            else
                PLATFORM="linux-x86_64"
            fi
        elif [[ "$TARGET" == *"aarch64"* ]]; then
            if [[ "$TARGET" == *"musl"* ]]; then
                PLATFORM="linux-arm64-musl"
            else
                PLATFORM="linux-arm64"
            fi
        elif [[ "$TARGET" == *"armv7"* ]]; then
            PLATFORM="linux-armv7"
        elif [[ "$TARGET" == *"i686"* ]]; then
            PLATFORM="linux-i686"
        else
            PLATFORM="linux-unknown"
        fi
        ;;
    *)
        PLATFORM="unknown"
        ;;
esac

echo "Detected platform: $PLATFORM"

# Setup cross-compilation environment
setup_cross_compilation() {
    local target="$1"
    
    echo "Setting up cross-compilation for $target..."
    
    case "$target" in
        "aarch64-unknown-linux-gnu")
            if command -v apt-get >/dev/null 2>&1; then
                echo "Installing cross-compilation tools for ARM64 Linux..."
                sudo apt-get update
                sudo apt-get install -y gcc-aarch64-linux-gnu
                export CARGO_TARGET_AARCH64_UNKNOWN_LINUX_GNU_LINKER=aarch64-linux-gnu-gcc
                export CC_aarch64_unknown_linux_gnu=aarch64-linux-gnu-gcc
                export AR_aarch64_unknown_linux_gnu=aarch64-linux-gnu-ar
            fi
            ;;
        "armv7-unknown-linux-gnueabihf")
            if command -v apt-get >/dev/null 2>&1; then
                echo "Installing cross-compilation tools for ARMv7 Linux..."
                sudo apt-get update
                sudo apt-get install -y gcc-arm-linux-gnueabihf
                export CARGO_TARGET_ARMV7_UNKNOWN_LINUX_GNUEABIHF_LINKER=arm-linux-gnueabihf-gcc
                export CC_armv7_unknown_linux_gnueabihf=arm-linux-gnueabihf-gcc
                export AR_armv7_unknown_linux_gnueabihf=arm-linux-gnueabihf-ar
            fi
            ;;
        "aarch64-unknown-linux-musl")
            if command -v apt-get >/dev/null 2>&1; then
                echo "Installing musl cross-compilation tools for ARM64..."
                sudo apt-get update
                sudo apt-get install -y musl-tools gcc-aarch64-linux-gnu
                export CARGO_TARGET_AARCH64_UNKNOWN_LINUX_MUSL_LINKER=aarch64-linux-gnu-gcc
                export CC_aarch64_unknown_linux_musl=aarch64-linux-gnu-gcc
                export AR_aarch64_unknown_linux_musl=aarch64-linux-gnu-ar
            fi
            ;;
        "x86_64-unknown-linux-musl")
            if command -v apt-get >/dev/null 2>&1; then
                echo "Installing musl tools for x86_64..."
                sudo apt-get update
                sudo apt-get install -y musl-tools
            fi
            ;;
        "i686-unknown-linux-gnu")
            if command -v apt-get >/dev/null 2>&1; then
                echo "Installing cross-compilation tools for i686 Linux..."
                sudo apt-get update
                sudo apt-get install -y gcc-multilib
            fi
            ;;
        "x86_64-pc-windows-gnu")
            if command -v apt-get >/dev/null 2>&1; then
                echo "Installing MinGW for Windows cross-compilation..."
                sudo apt-get update
                sudo apt-get install -y gcc-mingw-w64-x86-64
                export CARGO_TARGET_X86_64_PC_WINDOWS_GNU_LINKER=x86_64-w64-mingw32-gcc
                export CC_x86_64_pc_windows_gnu=x86_64-w64-mingw32-gcc
                export AR_x86_64_pc_windows_gnu=x86_64-w64-mingw32-ar
            fi
            ;;
    esac
}

# Add target if not already installed
echo "Adding Rust target: $TARGET"
rustup target add "$TARGET" || {
    echo "Error: Failed to add target $TARGET"
    echo "Available targets:"
    rustup target list --installed
    exit 1
}

# Setup cross-compilation if needed
setup_cross_compilation "$TARGET"

# Build the binary
echo "Building binary with cargo..."
echo "Command: cargo build --bin $(escape_for_shell "$BINARY_NAME") --target $(escape_for_shell "$TARGET") $CARGO_ARGS"

# Use eval with properly escaped arguments to handle complex cargo args safely
if ! eval "cargo build --bin $(escape_for_shell "$BINARY_NAME") --target $(escape_for_shell "$TARGET") $CARGO_ARGS"; then
    echo "Error: Build failed"
    echo "Build command: cargo build --bin $BINARY_NAME --target $TARGET $CARGO_ARGS"
    exit 1
fi

# Locate the built binary
SOURCE_BINARY="target/$TARGET/release/${BINARY_NAME}${BINARY_EXT}"
if [[ ! -f "$SOURCE_BINARY" ]]; then
    # Try debug build location if release build not found
    SOURCE_BINARY="target/$TARGET/debug/${BINARY_NAME}${BINARY_EXT}"
    if [[ ! -f "$SOURCE_BINARY" ]]; then
        echo "Error: Built binary not found"
        echo "Expected locations:"
        echo "  target/$TARGET/release/${BINARY_NAME}${BINARY_EXT}"
        echo "  target/$TARGET/debug/${BINARY_NAME}${BINARY_EXT}"
        
        echo ""
        echo "Contents of target/$TARGET/:"
        find "target/$TARGET" -name "*$BINARY_NAME*" 2>/dev/null || echo "  No files found"
        exit 1
    fi
fi

# Copy binary to output directory with platform suffix
OUTPUT_BINARY="${BINARY_NAME}-${PLATFORM}${BINARY_EXT}"
OUTPUT_PATH="$OUTPUT_DIR/$OUTPUT_BINARY"

echo "Copying binary: $SOURCE_BINARY -> $OUTPUT_PATH"
cp "$SOURCE_BINARY" "$OUTPUT_PATH"

# Set executable permissions for non-Windows platforms
if [[ "$TARGET" != *"windows"* ]]; then
    chmod +x "$OUTPUT_PATH"
fi

# Verify the binary was created successfully
if [[ ! -f "$OUTPUT_PATH" ]]; then
    echo "Error: Failed to create output binary: $OUTPUT_PATH"
    exit 1
fi

# Get binary size and basic info
BINARY_SIZE=$(stat -f%z "$OUTPUT_PATH" 2>/dev/null || stat -c%s "$OUTPUT_PATH" 2>/dev/null || echo "unknown")
echo "Built binary: $OUTPUT_PATH"
echo "Binary size: $BINARY_SIZE bytes"

# Try to get binary info (if possible)
if command -v file >/dev/null 2>&1; then
    echo "Binary info: $(file "$OUTPUT_PATH")"
fi

# Verify binary is executable (for non-Windows)
if [[ "$TARGET" != *"windows"* ]]; then
    if [[ ! -x "$OUTPUT_PATH" ]]; then
        echo "Warning: Binary is not executable"
    fi
fi

# Create metadata file
METADATA_FILE="$OUTPUT_DIR/${OUTPUT_BINARY}.meta"
cat > "$METADATA_FILE" << EOF
{
  "binary_name": "$BINARY_NAME",
  "target": "$TARGET",
  "platform": "$PLATFORM",
  "output_path": "$OUTPUT_PATH",
  "binary_size": $BINARY_SIZE,
  "cargo_args": "$CARGO_ARGS",
  "binary_ext": "$BINARY_EXT",
  "archive_ext": "$ARCHIVE_EXT",
  "build_timestamp": "$(date -u +"%Y-%m-%dT%H:%M:%SZ")",
  "rust_version": "$(rustc --version 2>/dev/null || echo 'unknown')"
}
EOF

echo "Build completed successfully!"
echo "Output binary: $OUTPUT_PATH"
echo "Metadata: $METADATA_FILE"
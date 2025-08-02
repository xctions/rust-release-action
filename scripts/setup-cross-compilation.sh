#!/bin/bash

# Setup cross-compilation environment for Rust
# Usage: setup-cross-compilation.sh <target>

set -euo pipefail

TARGET="$1"

echo "Setting up cross-compilation for target: $TARGET"

case "$TARGET" in
    "aarch64-unknown-linux-gnu")
        echo "Setting up Linux ARM64 cross-compilation"
        if [[ "$RUNNER_OS" == "Linux" ]]; then
            sudo apt-get update
            sudo apt-get install -y gcc-aarch64-linux-gnu
            echo "CARGO_TARGET_AARCH64_UNKNOWN_LINUX_GNU_LINKER=aarch64-linux-gnu-gcc" >> "$GITHUB_ENV"
        fi
        ;;
    "x86_64-unknown-linux-gnu")
        echo "Setting up Linux x86_64 cross-compilation"
        # Native compilation on Linux x86_64 runner
        ;;
    "aarch64-apple-darwin")
        echo "Setting up macOS ARM64 cross-compilation"
        # Native compilation on macOS ARM64 runner
        ;;
    "x86_64-pc-windows-msvc")
        echo "Setting up Windows x86_64 cross-compilation"
        # Native compilation on Windows x86_64 runner
        ;;
    "aarch64-pc-windows-msvc")
        echo "Setting up Windows ARM64 cross-compilation"
        # Cross-compilation on Windows runner
        ;;
    *)
        echo "Warning: Unknown target $TARGET, proceeding without special setup"
        ;;
esac

# Install the target
rustup target add "$TARGET"

echo "Cross-compilation setup completed for $TARGET"
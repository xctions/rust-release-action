#!/bin/bash

# Secure build matrix generator
# Usage: generate-matrix.sh [--include=JSON] [--exclude=platforms]

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Source validation functions
# shellcheck source=validate-inputs.sh
source "$SCRIPT_DIR/validate-inputs.sh"

# Default supported platforms matrix - simplified to 3 platforms
DEFAULT_MATRIX='[
  {
    "target": "x86_64-unknown-linux-gnu",
    "os": "ubuntu-latest",
    "platform": "linux-x86_64",
    "archive_ext": "tar.gz",
    "binary_ext": ""
  },
  {
    "target": "aarch64-unknown-linux-gnu",
    "os": "ubuntu-latest",
    "platform": "linux-arm64",
    "archive_ext": "tar.gz",
    "binary_ext": ""
  },
  {
    "target": "aarch64-apple-darwin",
    "os": "macos-latest",
    "platform": "mac-arm64",
    "archive_ext": "tar.gz",
    "binary_ext": ""
  }
]'

# Additional supported platforms (can be enabled via include)
EXTENDED_MATRIX='[
  {
    "target": "i686-unknown-linux-gnu",
    "os": "ubuntu-latest",
    "platform": "linux-i686",
    "archive_ext": "tar.gz",
    "binary_ext": ""
  },
  {
    "target": "armv7-unknown-linux-gnueabihf",
    "os": "ubuntu-latest",
    "platform": "linux-armv7",
    "archive_ext": "tar.gz",
    "binary_ext": ""
  },
  {
    "target": "x86_64-unknown-linux-musl",
    "os": "ubuntu-latest",
    "platform": "linux-x86_64-musl",
    "archive_ext": "tar.gz",
    "binary_ext": ""
  },
  {
    "target": "aarch64-unknown-linux-musl",
    "os": "ubuntu-latest",
    "platform": "linux-arm64-musl",
    "archive_ext": "tar.gz",
    "binary_ext": ""
  },
  {
    "target": "x86_64-pc-windows-gnu",
    "os": "ubuntu-latest",
    "platform": "windows-x86_64-gnu",
    "archive_ext": "zip",
    "binary_ext": ".exe"
  },
  {
    "target": "i686-pc-windows-msvc",
    "os": "windows-latest",
    "platform": "windows-i686",
    "archive_ext": "zip",
    "binary_ext": ".exe"
  }
]'

# Parse command line arguments
INCLUDE_JSON=""
EXCLUDE_PLATFORMS=""

while [[ $# -gt 0 ]]; do
    case $1 in
        --include=*)
            INCLUDE_JSON="${1#*=}"
            shift
            ;;
        --exclude=*)
            EXCLUDE_PLATFORMS="${1#*=}"
            shift
            ;;
        --help|-h)
            echo "Usage: $0 [--include=JSON] [--exclude=platforms]"
            echo ""
            echo "Options:"
            echo "  --include=JSON       Custom JSON matrix to use instead of defaults"
            echo "  --exclude=platforms  Comma-separated list of platforms to exclude"
            echo "  --help, -h          Show this help message"
            echo ""
            echo "Default platforms: linux-x86_64, linux-arm64, mac-arm64"
            echo ""
            echo "Example:"
            echo "  $0 --exclude=windows-arm64,linux-arm64"
            echo "  $0 --include='[{\"target\":\"x86_64-unknown-linux-gnu\",\"os\":\"ubuntu-latest\",\"platform\":\"linux-x86_64\"}]'"
            exit 0
            ;;
        *)
            echo "Error: Unknown option $1"
            echo "Use --help for usage information"
            exit 1
            ;;
    esac
done

# Validate and process include parameter
if [[ -n "$INCLUDE_JSON" ]]; then
    echo "Using custom include matrix"
    
    # Validate JSON format
    if ! echo "$INCLUDE_JSON" | jq empty 2>/dev/null; then
        echo "Error: Invalid JSON format in include parameter"
        exit 1
    fi
    
    # Validate required fields in each matrix entry
    MATRIX_ENTRIES=$(echo "$INCLUDE_JSON" | jq length)
    for ((i=0; i<MATRIX_ENTRIES; i++)); do
        ENTRY=$(echo "$INCLUDE_JSON" | jq ".[$i]")
        
        # Check required fields
        TARGET=$(echo "$ENTRY" | jq -r '.target // empty')
        OS=$(echo "$ENTRY" | jq -r '.os // empty')
        PLATFORM=$(echo "$ENTRY" | jq -r '.platform // empty')
        
        if [[ -z "$TARGET" || -z "$OS" || -z "$PLATFORM" ]]; then
            echo "Error: Matrix entry $i missing required fields (target, os, platform)"
            echo "Entry: $ENTRY"
            exit 1
        fi
        
        # Validate platform name
        if ! validate_platform_name "$PLATFORM"; then
            exit 1
        fi
        
        # Validate target format
        if [[ ! "$TARGET" =~ ^[a-zA-Z0-9_-]+$ ]]; then
            echo "Error: Invalid target format: $TARGET"
            exit 1
        fi
        
        # Validate OS
        case "$OS" in
            ubuntu-latest|ubuntu-20.04|ubuntu-22.04|ubuntu-24.04|macos-latest|macos-13|macos-12|windows-latest|windows-2022|windows-2019)
                # Valid OS
                ;;
            *)
                echo "Error: Unsupported OS: $OS"
                echo "Supported: ubuntu-latest, ubuntu-20.04, ubuntu-22.04, ubuntu-24.04, macos-latest, macos-13, macos-12, windows-latest, windows-2022, windows-2019"
                exit 1
                ;;
        esac
    done
    
    MATRIX="$INCLUDE_JSON"
else
    echo "Using default matrix"
    MATRIX="$DEFAULT_MATRIX"
fi

# Process exclude parameter
if [[ -n "$EXCLUDE_PLATFORMS" ]]; then
    echo "Applying exclude filter: $EXCLUDE_PLATFORMS"
    
    IFS=',' read -ra EXCLUDE_ARRAY <<< "$EXCLUDE_PLATFORMS"
    for exclude_platform in "${EXCLUDE_ARRAY[@]}"; do
        # Trim whitespace
        exclude_platform=$(echo "$exclude_platform" | xargs)
        
        # Validate exclude platform name
        if ! validate_platform_name "$exclude_platform"; then
            exit 1
        fi
        
        # Remove from matrix
        ORIGINAL_COUNT=$(echo "$MATRIX" | jq length)
        MATRIX=$(echo "$MATRIX" | jq --arg platform "$exclude_platform" 'map(select(.platform != $platform))')
        NEW_COUNT=$(echo "$MATRIX" | jq length)
        
        if [[ "$NEW_COUNT" -eq "$ORIGINAL_COUNT" ]]; then
            echo "Warning: Platform '$exclude_platform' not found in matrix"
        else
            echo "Excluded platform: $exclude_platform"
        fi
    done
fi

# Validate final matrix is not empty
FINAL_COUNT=$(echo "$MATRIX" | jq length)
if [[ "$FINAL_COUNT" -eq 0 ]]; then
    echo "Error: No platforms remaining in matrix after filtering"
    exit 1
fi

# Add computed fields to matrix entries
ENHANCED_MATRIX="[]"
MATRIX_LENGTH=$(echo "$MATRIX" | jq length)

for ((i=0; i<MATRIX_LENGTH; i++)); do
    ENTRY=$(echo "$MATRIX" | jq ".[$i]")
    
    # Get values
    TARGET=$(echo "$ENTRY" | jq -r '.target')
    PLATFORM=$(echo "$ENTRY" | jq -r '.platform')
    
    # Add binary extension if not present
    if ! echo "$ENTRY" | jq -e '.binary_ext' >/dev/null; then
        if [[ "$TARGET" == *"windows"* ]]; then
            ENTRY=$(echo "$ENTRY" | jq '. + {"binary_ext": ".exe"}')
        else
            ENTRY=$(echo "$ENTRY" | jq '. + {"binary_ext": ""}')
        fi
    fi
    
    # Add archive extension if not present
    if ! echo "$ENTRY" | jq -e '.archive_ext' >/dev/null; then
        if [[ "$TARGET" == *"windows"* ]]; then
            ENTRY=$(echo "$ENTRY" | jq '. + {"archive_ext": "zip"}')
        else
            ENTRY=$(echo "$ENTRY" | jq '. + {"archive_ext": "tar.gz"}')
        fi
    fi
    
    # Add cross-compilation flags if needed
    CROSS_COMPILE_FLAGS=""
    case "$TARGET" in
        "aarch64-unknown-linux-gnu")
            CROSS_COMPILE_FLAGS="CC=aarch64-linux-gnu-gcc"
            ;;
    esac
    
    if [[ -n "$CROSS_COMPILE_FLAGS" ]]; then
        ENTRY=$(echo "$ENTRY" | jq --arg flags "$CROSS_COMPILE_FLAGS" '. + {"cross_compile_env": $flags}')
    fi
    
    # Add to enhanced matrix
    ENHANCED_MATRIX=$(echo "$ENHANCED_MATRIX" | jq ". + [$ENTRY]")
done

# Output the final matrix
echo "Generated build matrix:"
echo "$ENHANCED_MATRIX" | jq .

# Also output as GitHub Actions matrix format
echo ""
echo "GitHub Actions matrix format:"
echo "{\"include\": $(echo "$ENHANCED_MATRIX" | jq -c .)}"

# Save to file if requested
if [[ "${SAVE_TO_FILE:-}" == "true" ]]; then
    OUTPUT_FILE="${MATRIX_FILE:-build-matrix.json}"
    echo "$ENHANCED_MATRIX" > "$OUTPUT_FILE"
    echo "Matrix saved to: $OUTPUT_FILE"
fi

# Set GitHub Actions output if running in CI
if [[ -n "${GITHUB_OUTPUT:-}" ]]; then
    echo "matrix=$(echo "$ENHANCED_MATRIX" | jq -c .)" >> "$GITHUB_OUTPUT"
    echo "Matrix set as GitHub Actions output"
fi
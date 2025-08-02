#!/bin/bash

# Generate installation script for a specific platform
# Usage: generate-install-script.sh <binary-name> <platform> <version> <repo>

set -euo pipefail

BINARY_NAME="$1"
PLATFORM="$2"
VERSION="$3"
REPO="$4"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TEMPLATE_DIR="$SCRIPT_DIR/../templates"

# Determine script extension based on platform
if [[ "$PLATFORM" == *"windows"* ]]; then
    SCRIPT_EXT=".ps1"
    TEMPLATE_FILE="$TEMPLATE_DIR/install-windows.ps1.template"
else
    SCRIPT_EXT=".sh"
    TEMPLATE_FILE="$TEMPLATE_DIR/install-unix.sh.template"
fi

OUTPUT_FILE="release/install-${PLATFORM}${SCRIPT_EXT}"

# Create release directory if it doesn't exist
mkdir -p release

# Check if template exists
if [[ ! -f "$TEMPLATE_FILE" ]]; then
    echo "Error: Template file not found: $TEMPLATE_FILE"
    exit 1
fi

# Determine binary extension
BINARY_EXT=""
if [[ "$PLATFORM" == *"windows"* ]]; then
    BINARY_EXT=".exe"
fi

# Generate the installation script from template
sed -e "s/{{BINARY_NAME}}/$BINARY_NAME/g" \
    -e "s/{{PLATFORM}}/$PLATFORM/g" \
    -e "s/{{VERSION}}/$VERSION/g" \
    -e "s|{{REPO}}|$REPO|g" \
    -e "s/{{BINARY_EXT}}/$BINARY_EXT/g" \
    "$TEMPLATE_FILE" > "$OUTPUT_FILE"

# Make Unix scripts executable
if [[ "$SCRIPT_EXT" == ".sh" ]]; then
    chmod +x "$OUTPUT_FILE"
fi

echo "Generated installation script: $OUTPUT_FILE"
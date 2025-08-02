#!/bin/bash

# Secure asset packaging script - Create zoxide-style archives
# Usage: package-assets.sh <binary-name> <version> <platform> <assets-dir> [options]

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Source validation functions
# shellcheck source=validate-inputs.sh
source "$SCRIPT_DIR/validate-inputs.sh"

# Default options
CREATE_STANDALONE=true
CREATE_ARCHIVE=true
INCLUDE_README=true
INCLUDE_LICENSE=true
ASSETS_DIR="release"

# Parse arguments
BINARY_NAME="${1:-}"
VERSION="${2:-}"
PLATFORM="${3:-}"
ASSETS_DIR="${4:-release}"

# Parse additional options
shift 4 2>/dev/null || true
while [[ $# -gt 0 ]]; do
    case $1 in
        --no-standalone)
            CREATE_STANDALONE=false
            shift
            ;;
        --no-archive)
            CREATE_ARCHIVE=false
            shift
            ;;
        --no-readme)
            INCLUDE_README=false
            shift
            ;;
        --no-license)
            INCLUDE_LICENSE=false
            shift
            ;;
        --help|-h)
            echo "Usage: $0 <binary-name> <version> <platform> <assets-dir> [options]"
            echo ""
            echo "Arguments:"
            echo "  binary-name  Name of the binary"
            echo "  version      Version tag (e.g., v1.0.0)"
            echo "  platform     Platform identifier (e.g., linux-x86_64)"
            echo "  assets-dir   Directory containing built assets"
            echo ""
            echo "Options:"
            echo "  --no-standalone  Don't create standalone binary copies"
            echo "  --no-archive     Don't create tar.gz/zip archives"
            echo "  --no-readme      Don't include README in archives"
            echo "  --no-license     Don't include LICENSE in archives"
            echo "  --help, -h       Show this help message"
            echo ""
            echo "Examples:"
            echo "  $0 my-app v1.0.0 linux-x86_64 release/"
            echo "  $0 my-cli v2.1.0 windows-x86_64 release/ --no-standalone"
            exit 0
            ;;
        *)
            echo "Error: Unknown option $1"
            echo "Use --help for usage information"
            exit 1
            ;;
    esac
done

# Validate required arguments
if [[ -z "$BINARY_NAME" || -z "$VERSION" || -z "$PLATFORM" ]]; then
    echo "Error: Missing required arguments"
    echo "Usage: $0 <binary-name> <version> <platform> <assets-dir> [options]"
    exit 1
fi

# Validate inputs
echo "Validating packaging parameters..."
validate_binary_name "$BINARY_NAME" || exit 1
validate_version_tag "$VERSION" || exit 1
validate_platform_name "$PLATFORM" || exit 1
validate_file_path "$ASSETS_DIR" || exit 1

# Check if assets directory exists
if [[ ! -d "$ASSETS_DIR" ]]; then
    echo "Error: Assets directory does not exist: $ASSETS_DIR"
    exit 1
fi

echo "Packaging $BINARY_NAME $VERSION for $PLATFORM..."

# Determine file extensions
BINARY_EXT=""
ARCHIVE_EXT="tar.gz"
if [[ "$PLATFORM" == *"windows"* ]]; then
    BINARY_EXT=".exe"
    ARCHIVE_EXT="zip"
fi

# Find the built binary
BINARY_FILE="${BINARY_NAME}-${PLATFORM}${BINARY_EXT}"
BINARY_PATH="$ASSETS_DIR/$BINARY_FILE"

if [[ ! -f "$BINARY_PATH" ]]; then
    echo "Error: Built binary not found: $BINARY_PATH"
    echo "Available files in $ASSETS_DIR:"
    ls -la "$ASSETS_DIR/" || echo "  Directory is empty or inaccessible"
    exit 1
fi

echo "Found binary: $BINARY_PATH"

# Get binary size and metadata
BINARY_SIZE=$(stat -f%z "$BINARY_PATH" 2>/dev/null || stat -c%s "$BINARY_PATH" 2>/dev/null || echo "unknown")
echo "Binary size: $BINARY_SIZE bytes"

# Create package directory
PACKAGE_NAME="${BINARY_NAME}-${VERSION}-${PLATFORM}"
PACKAGE_DIR="$ASSETS_DIR/$PACKAGE_NAME"

echo "Creating package directory: $PACKAGE_DIR"
mkdir -p "$PACKAGE_DIR"

# Copy binary to package directory
PACKAGE_BINARY="$PACKAGE_DIR/${BINARY_NAME}${BINARY_EXT}"
cp "$BINARY_PATH" "$PACKAGE_BINARY"

# Set executable permissions for non-Windows
if [[ "$PLATFORM" != *"windows"* ]]; then
    chmod +x "$PACKAGE_BINARY"
fi

echo "Copied binary to package: $PACKAGE_BINARY"

# Create README for the package
if [[ "$INCLUDE_README" == "true" ]]; then
    README_FILE="$PACKAGE_DIR/README.md"
    cat > "$README_FILE" << EOF
# $BINARY_NAME $VERSION

This package contains the $BINARY_NAME binary for $PLATFORM.

## Quick Installation

### Automated Install (Unix/Linux/macOS)
\`\`\`bash
curl -fsSL https://github.com/\${GITHUB_REPOSITORY}/releases/download/$VERSION/install-$PLATFORM.sh | bash
\`\`\`

### Manual Installation

1. Extract this archive to a temporary directory
2. Copy the binary to a directory in your PATH:

#### Unix/Linux/macOS:
\`\`\`bash
sudo cp ${BINARY_NAME}${BINARY_EXT} /usr/local/bin/${BINARY_NAME}
sudo chmod +x /usr/local/bin/${BINARY_NAME}
\`\`\`

#### Windows:
- Copy \`${BINARY_NAME}${BINARY_EXT}\` to a directory in your PATH
- Or add the current directory to your PATH environment variable

## Usage

Run \`${BINARY_NAME} --help\` for usage information.

## Package Information

- **Binary**: ${BINARY_NAME}${BINARY_EXT}
- **Version**: $VERSION
- **Platform**: $PLATFORM
- **Size**: $BINARY_SIZE bytes
- **Built**: $(date -u +"%Y-%m-%d %H:%M:%S UTC")

## Verification

This package is part of an official release. You can verify the integrity using checksums:

\`\`\`bash
# Download checksums file
curl -fsSL https://github.com/\${GITHUB_REPOSITORY}/releases/download/$VERSION/checksums.txt

# Verify this archive
sha256sum -c checksums.txt --ignore-missing
\`\`\`

---

*Generated by rust-release GitHub Action*
EOF
    echo "Created README: $README_FILE"
fi

# Find and copy LICENSE file
if [[ "$INCLUDE_LICENSE" == "true" ]]; then
    LICENSE_FOUND=false
    
    # Look for license files in common locations
    for license_path in "../LICENSE" "../LICENSE.md" "../LICENSE.txt" "../../LICENSE" "../../LICENSE.md" "../../LICENSE.txt" "LICENSE" "LICENSE.md" "LICENSE.txt"; do
        if [[ -f "$license_path" ]]; then
            cp "$license_path" "$PACKAGE_DIR/"
            echo "Copied license: $license_path -> $PACKAGE_DIR/$(basename "$license_path")"
            LICENSE_FOUND=true
            break
        fi
    done
    
    if [[ "$LICENSE_FOUND" == "false" ]]; then
        echo "Warning: No LICENSE file found - skipping license inclusion"
    fi
fi

# Create archive if requested
ARCHIVE_PATH=""
if [[ "$CREATE_ARCHIVE" == "true" ]]; then
    ARCHIVE_NAME="${PACKAGE_NAME}.${ARCHIVE_EXT}"
    ARCHIVE_PATH="$ASSETS_DIR/$ARCHIVE_NAME"
    
    echo "Creating archive: $ARCHIVE_PATH"
    
    cd "$ASSETS_DIR"
    
    if [[ "$ARCHIVE_EXT" == "zip" ]]; then
        # Create ZIP for Windows
        if command -v zip >/dev/null 2>&1; then
            zip -r "$ARCHIVE_NAME" "$(basename "$PACKAGE_DIR")" >/dev/null
        else
            echo "Error: zip command not found"
            exit 1
        fi
    else
        # Create tar.gz for Unix-like systems
        if command -v tar >/dev/null 2>&1; then
            tar -czf "$ARCHIVE_NAME" "$(basename "$PACKAGE_DIR")"
        else
            echo "Error: tar command not found"
            exit 1
        fi
    fi
    
    cd - >/dev/null
    
    if [[ -f "$ARCHIVE_PATH" ]]; then
        ARCHIVE_SIZE=$(stat -f%z "$ARCHIVE_PATH" 2>/dev/null || stat -c%s "$ARCHIVE_PATH" 2>/dev/null || echo "unknown")
        echo "Created archive: $ARCHIVE_PATH ($ARCHIVE_SIZE bytes)"
        
        # Verify archive integrity
        if [[ "$ARCHIVE_EXT" == "zip" ]]; then
            if command -v unzip >/dev/null 2>&1; then
                if unzip -t "$ARCHIVE_PATH" >/dev/null 2>&1; then
                    echo "Archive integrity verified (ZIP)"
                else
                    echo "Warning: Archive integrity check failed"
                fi
            fi
        else
            if tar -tzf "$ARCHIVE_PATH" >/dev/null 2>&1; then
                echo "Archive integrity verified (tar.gz)"
            else
                echo "Warning: Archive integrity check failed"
            fi
        fi
    else
        echo "Error: Failed to create archive"
        exit 1
    fi
fi

# Create standalone binary copy if requested
STANDALONE_PATH=""
if [[ "$CREATE_STANDALONE" == "true" ]]; then
    STANDALONE_NAME="${BINARY_NAME}-${VERSION}-${PLATFORM}${BINARY_EXT}"
    STANDALONE_PATH="$ASSETS_DIR/$STANDALONE_NAME"
    
    echo "Creating standalone binary: $STANDALONE_PATH"
    cp "$BINARY_PATH" "$STANDALONE_PATH"
    
    # Set executable permissions for non-Windows
    if [[ "$PLATFORM" != *"windows"* ]]; then
        chmod +x "$STANDALONE_PATH"
    fi
    
    echo "Created standalone binary: $STANDALONE_PATH"
fi

# Clean up temporary package directory
echo "Cleaning up package directory: $PACKAGE_DIR"
rm -rf "$PACKAGE_DIR"

# Create package manifest
MANIFEST_FILE="$ASSETS_DIR/${PACKAGE_NAME}.manifest.json"
cat > "$MANIFEST_FILE" << EOF
{
  "binary_name": "$BINARY_NAME",
  "version": "$VERSION",
  "platform": "$PLATFORM",
  "binary_size": $BINARY_SIZE,
  "binary_file": "$BINARY_FILE",
  "package_name": "$PACKAGE_NAME",
  "archive_path": $(if [[ -n "$ARCHIVE_PATH" ]]; then echo "\"$(basename "$ARCHIVE_PATH")\""; else echo "null"; fi),
  "standalone_path": $(if [[ -n "$STANDALONE_PATH" ]]; then echo "\"$(basename "$STANDALONE_PATH")\""; else echo "null"; fi),
  "archive_ext": "$ARCHIVE_EXT",
  "binary_ext": "$BINARY_EXT",
  "created_at": "$(date -u +"%Y-%m-%dT%H:%M:%SZ")",
  "options": {
    "create_standalone": $CREATE_STANDALONE,
    "create_archive": $CREATE_ARCHIVE,
    "include_readme": $INCLUDE_README,
    "include_license": $INCLUDE_LICENSE
  }
}
EOF

echo "Created manifest: $MANIFEST_FILE"

# Summary
echo ""
echo "Packaging completed successfully!"
echo "Binary: $BINARY_PATH"
if [[ -n "$ARCHIVE_PATH" ]]; then
    echo "Archive: $ARCHIVE_PATH"
fi
if [[ -n "$STANDALONE_PATH" ]]; then
    echo "Standalone: $STANDALONE_PATH"
fi
echo "Manifest: $MANIFEST_FILE"

# List all created files
echo ""
echo "Created files:"
if [[ -n "$ARCHIVE_PATH" && -f "$ARCHIVE_PATH" ]]; then
    echo "  $(basename "$ARCHIVE_PATH")"
fi
if [[ -n "$STANDALONE_PATH" && -f "$STANDALONE_PATH" ]]; then
    echo "  $(basename "$STANDALONE_PATH")"
fi
echo "  $(basename "$MANIFEST_FILE")"
#!/bin/bash

# Generate SHA256 checksums for release assets
# Usage: create-checksums.sh <assets-directory> [output-file]

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Source validation functions
# shellcheck source=validate-inputs.sh
source "$SCRIPT_DIR/validate-inputs.sh"

# Parse arguments
ASSETS_DIR="${1:-}"
OUTPUT_FILE="${2:-checksums.txt}"

# Validate required arguments
if [[ -z "$ASSETS_DIR" ]]; then
    echo "Usage: $0 <assets-directory> [output-file]"
    echo ""
    echo "Arguments:"
    echo "  assets-directory  Directory containing release assets"
    echo "  output-file      Output checksums file (default: checksums.txt)"
    echo ""
    echo "Examples:"
    echo "  $0 release/"
    echo "  $0 release/ sha256sums.txt"
    exit 1
fi

# Validate inputs
if ! validate_file_path "$ASSETS_DIR"; then
    exit 1
fi

if ! validate_file_path "$OUTPUT_FILE"; then
    exit 1
fi

# Check if assets directory exists
if [[ ! -d "$ASSETS_DIR" ]]; then
    echo "Error: Assets directory does not exist: $ASSETS_DIR"
    exit 1
fi

# Find SHA256 utility
SHA256_CMD=""
if command -v sha256sum >/dev/null 2>&1; then
    SHA256_CMD="sha256sum"
elif command -v shasum >/dev/null 2>&1; then
    SHA256_CMD="shasum -a 256"
elif command -v openssl >/dev/null 2>&1; then
    SHA256_CMD="openssl dgst -sha256"
else
    echo "Error: No SHA256 utility found"
    echo "Please install one of: sha256sum, shasum, or openssl"
    exit 1
fi

echo "Using SHA256 utility: $SHA256_CMD"
echo "Processing assets in: $ASSETS_DIR"

# Find all regular files in assets directory (excluding subdirectories and hidden files)
ASSET_FILES=()
while IFS= read -r -d '' file; do
    # Skip directories
    if [[ -d "$file" ]]; then
        continue
    fi
    
    # Skip hidden files and specific files we don't want to checksum
    filename=$(basename "$file")
    case "$filename" in
        .*|checksums.txt|*.meta|*.log)
            echo "Skipping: $filename"
            continue
            ;;
    esac
    
    ASSET_FILES+=("$file")
done < <(find "$ASSETS_DIR" -maxdepth 1 -type f -print0 | sort -z)

# Check if we found any files
if [[ ${#ASSET_FILES[@]} -eq 0 ]]; then
    echo "Warning: No asset files found in $ASSETS_DIR"
    echo "Creating empty checksums file"
    cat > "$OUTPUT_FILE" << EOF
# SHA256 Checksums
# Generated on $(date -u +"%Y-%m-%d %H:%M:%S UTC")
# No assets found in $ASSETS_DIR
EOF
    exit 0
fi

echo "Found ${#ASSET_FILES[@]} asset files to checksum"

# Create temporary file for checksums
TEMP_CHECKSUMS=$(mktemp)
trap 'rm -f "$TEMP_CHECKSUMS"' EXIT

# Generate checksums
{
    echo "# SHA256 Checksums"
    echo "# Generated on $(date -u +"%Y-%m-%d %H:%M:%S UTC")"
    echo "# Directory: $ASSETS_DIR"
    echo "# Utility: $SHA256_CMD"
    echo ""
} > "$TEMP_CHECKSUMS"

# Process each file
PROCESSED_COUNT=0
FAILED_COUNT=0

for file in "${ASSET_FILES[@]}"; do
    filename=$(basename "$file")
    echo "Processing: $filename"
    
    # Generate checksum
    if [[ "$SHA256_CMD" == "openssl dgst -sha256" ]]; then
        # OpenSSL format: SHA256(filename)= hash
        if CHECKSUM_OUTPUT=$($SHA256_CMD "$file" 2>/dev/null); then
            # Extract hash from OpenSSL output
            HASH=$(echo "$CHECKSUM_OUTPUT" | sed 's/.*= //')
            echo "$HASH  $filename" >> "$TEMP_CHECKSUMS"
            echo "  → $HASH"
            ((PROCESSED_COUNT++))
        else
            echo "  → ERROR: Failed to generate checksum"
            echo "# ERROR: Failed to generate checksum for $filename" >> "$TEMP_CHECKSUMS"
            ((FAILED_COUNT++))
        fi
    else
        # sha256sum/shasum format: hash filename
        if CHECKSUM_OUTPUT=$($SHA256_CMD "$file" 2>/dev/null); then
            # Replace full path with just filename in output
            echo "$CHECKSUM_OUTPUT" | sed "s|$file|$filename|" >> "$TEMP_CHECKSUMS"
            HASH=$(echo "$CHECKSUM_OUTPUT" | cut -d' ' -f1)
            echo "  → $HASH"
            ((PROCESSED_COUNT++))
        else
            echo "  → ERROR: Failed to generate checksum"
            echo "# ERROR: Failed to generate checksum for $filename" >> "$TEMP_CHECKSUMS"
            ((FAILED_COUNT++))
        fi
    fi
done

# Add summary to checksums file
{
    echo ""
    echo "# Summary:"
    echo "# Files processed: $PROCESSED_COUNT"
    if [[ $FAILED_COUNT -gt 0 ]]; then
        echo "# Files failed: $FAILED_COUNT"
    fi
    echo "# Total size: $(du -sh "$ASSETS_DIR" 2>/dev/null | cut -f1 || echo "unknown")"
} >> "$TEMP_CHECKSUMS"

# Move temp file to final location
mv "$TEMP_CHECKSUMS" "$OUTPUT_FILE"

echo ""
echo "Checksums generated successfully!"
echo "Output file: $OUTPUT_FILE"
echo "Files processed: $PROCESSED_COUNT"

if [[ $FAILED_COUNT -gt 0 ]]; then
    echo "Files failed: $FAILED_COUNT"
    echo "WARNING: Some checksums could not be generated"
fi

# Display the checksums file
echo ""
echo "Contents of $OUTPUT_FILE:"
echo "----------------------------------------"
cat "$OUTPUT_FILE"
echo "----------------------------------------"

# Verify checksums file is readable and contains expected content
if [[ ! -s "$OUTPUT_FILE" ]]; then
    echo "Error: Checksums file is empty"
    exit 1
fi

# Count non-comment lines (actual checksums)
CHECKSUM_LINES=$(grep -c '^[^#]' "$OUTPUT_FILE" || true)
if [[ $CHECKSUM_LINES -eq 0 ]] && [[ $PROCESSED_COUNT -gt 0 ]]; then
    echo "Error: No checksums found in output file"
    exit 1
fi

echo ""
echo "Verification complete. Checksums file contains $CHECKSUM_LINES checksums."

# Optional: Create verification script
VERIFY_SCRIPT="${OUTPUT_FILE%.txt}-verify.sh"
cat > "$VERIFY_SCRIPT" << 'EOF'
#!/bin/bash

# Verify checksums
# Usage: ./checksums-verify.sh [checksums-file]

set -euo pipefail

CHECKSUMS_FILE="${1:-checksums.txt}"

if [[ ! -f "$CHECKSUMS_FILE" ]]; then
    echo "Error: Checksums file not found: $CHECKSUMS_FILE"
    exit 1
fi

echo "Verifying checksums from: $CHECKSUMS_FILE"

# Find SHA256 utility
if command -v sha256sum >/dev/null 2>&1; then
    sha256sum -c "$CHECKSUMS_FILE"
elif command -v shasum >/dev/null 2>&1; then
    shasum -a 256 -c "$CHECKSUMS_FILE"
else
    echo "Error: No SHA256 utility found for verification"
    echo "Please install sha256sum or shasum"
    exit 1
fi

echo "All checksums verified successfully!"
EOF

chmod +x "$VERIFY_SCRIPT"
echo "Verification script created: $VERIFY_SCRIPT"
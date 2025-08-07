#!/bin/bash

# Secure input validation and sanitization functions
# Usage: source validate-inputs.sh

set -euo pipefail

# Validate binary name format
validate_binary_name() {
    local binary_name="$1"
    
    # Check for empty input
    if [[ -z "$binary_name" ]]; then
        echo "Error: Binary name cannot be empty"
        return 1
    fi
    
    # Check length (reasonable limit)
    if [[ ${#binary_name} -gt 50 ]]; then
        echo "Error: Binary name too long (max 50 characters): $binary_name"
        return 1
    fi
    
    # Check for valid characters only (alphanumeric, dash, underscore)
    if [[ ! "$binary_name" =~ ^[a-zA-Z0-9_-]+$ ]]; then
        echo "Error: Invalid binary name: $binary_name"
        echo "Binary names must contain only alphanumeric characters, dashes and underscores"
        return 1
    fi
    
    # Check for reserved names
    case "$binary_name" in
        "con"|"prn"|"aux"|"nul"|"com1"|"com2"|"com3"|"com4"|"com5"|"com6"|"com7"|"com8"|"com9"|"lpt1"|"lpt2"|"lpt3"|"lpt4"|"lpt5"|"lpt6"|"lpt7"|"lpt8"|"lpt9")
            echo "Error: Reserved name cannot be used as binary name: $binary_name"
            return 1
            ;;
    esac
    
    return 0
}

# Validate platform name
validate_platform_name() {
    local platform="$1"
    
    # Check for empty input
    if [[ -z "$platform" ]]; then
        echo "Error: Platform name cannot be empty"
        return 1
    fi
    
    # Check length
    if [[ ${#platform} -gt 30 ]]; then
        echo "Error: Platform name too long (max 30 characters): $platform"
        return 1
    fi
    
    # Check for valid characters only
    if [[ ! "$platform" =~ ^[a-zA-Z0-9_-]+$ ]]; then
        echo "Error: Invalid platform name: $platform"
        echo "Platform names must contain only alphanumeric characters, dashes and underscores"
        return 1
    fi
    
    return 0
}

# Validate repository format
validate_repository() {
    local repo="$1"
    
    # Check for empty input
    if [[ -z "$repo" ]]; then
        echo "Error: Repository cannot be empty"
        return 1
    fi
    
    # Check length
    if [[ ${#repo} -gt 100 ]]; then
        echo "Error: Repository name too long (max 100 characters): $repo"
        return 1
    fi
    
    # Check for valid GitHub repo format (owner/repo)
    if [[ ! "$repo" =~ ^[a-zA-Z0-9_.-]+/[a-zA-Z0-9_.-]+$ ]]; then
        echo "Error: Invalid repository format: $repo"
        echo "Repository must be in format: owner/repo"
        return 1
    fi
    
    # Check for path traversal attempts
    if [[ "$repo" == *".."* ]] || [[ "$repo" == *"/"* ]] && [[ $(echo "$repo" | tr -cd '/' | wc -c) -ne 1 ]]; then
        echo "Error: Invalid repository format (path traversal detected): $repo"
        return 1
    fi
    
    return 0
}

# Validate version tag format
validate_version_tag() {
    local version="$1"
    
    # Check for empty input
    if [[ -z "$version" ]]; then
        echo "Error: Version tag cannot be empty"
        return 1
    fi
    
    # Check length
    if [[ ${#version} -gt 50 ]]; then
        echo "Error: Version tag too long (max 50 characters): $version"
        return 1
    fi
    
    # Check for valid semantic version or tag format
    # Simple but effective version validation - allows most common version formats
    if [[ ! "$version" =~ ^v?[0-9] ]]; then
        echo "Error: Invalid version tag format: $version"
        echo "Version must start with a number or 'v' followed by a number"
        return 1
    fi
    
    # Check for invalid characters (only allow alphanumeric, dots, dashes, plus)
    if [[ "$version" =~ [^a-zA-Z0-9v.+-] ]]; then
        echo "Error: Invalid characters in version tag: $version"
        echo "Version tags can only contain letters, numbers, dots, dashes, and plus signs"
        return 1
    fi
    
    # Check for invalid patterns
    if [[ "$version" =~ \.\. ]]; then
        echo "Error: Invalid version format - double dots not allowed: $version"
        return 1
    fi
    
    if [[ "$version" =~ -- ]]; then
        echo "Error: Invalid version format - double dashes not allowed: $version"
        return 1
    fi
    
    if [[ "$version" =~ -$ ]]; then
        echo "Error: Invalid version format - cannot end with dash: $version"
        return 1
    fi
    
    if [[ "$version" =~ \+$ ]]; then
        echo "Error: Invalid version format - cannot end with plus: $version"
        return 1
    fi
    
    return 0
}

# Validate cargo arguments
validate_cargo_args() {
    local cargo_args="$1"
    
    # Allow empty cargo args
    if [[ -z "$cargo_args" ]]; then
        return 0
    fi
    
    # Check length
    if [[ ${#cargo_args} -gt 200 ]]; then
        echo "Error: Cargo args too long (max 200 characters): $cargo_args"
        return 1
    fi
    
    # Check for dangerous characters that could lead to command injection
    if [[ "$cargo_args" =~ [\;\|\&\$\`\(\)\>\<] ]]; then
        echo "Error: Invalid characters in cargo-args: $cargo_args"
        echo "Cargo args cannot contain: ; | & \$ \` ( ) > <"
        return 1
    fi
    
    # Check for dangerous patterns
    local dangerous_patterns=(
        "rm -rf"
        "curl.*\|"
        "wget.*\|"
        "nc -"
        "bash -"
        "sh -"
        "/bin/"
        "/usr/bin/"
        "python -c"
        "perl -e"
        "ruby -e"
    )
    
    for pattern in "${dangerous_patterns[@]}"; do
        if [[ "$cargo_args" =~ $pattern ]]; then
            echo "Error: Potentially dangerous pattern in cargo-args: $pattern"
            return 1
        fi
    done
    
    return 0
}

# Validate Rust version
validate_rust_version() {
    local rust_version="$1"
    
    # Check for empty input
    if [[ -z "$rust_version" ]]; then
        echo "Error: Rust version cannot be empty"
        return 1
    fi
    
    # Check length
    if [[ ${#rust_version} -gt 20 ]]; then
        echo "Error: Rust version too long (max 20 characters): $rust_version"
        return 1
    fi
    
    # Check for valid rust version format
    if [[ ! "$rust_version" =~ ^(stable|beta|nightly|[0-9]+\.[0-9]+(\.[0-9]+)?)$ ]]; then
        echo "Error: Invalid rust version format: $rust_version"
        echo "Rust version must be: stable, beta, nightly, or a version number (e.g., 1.75.0)"
        return 1
    fi
    
    return 0
}

# Escape string for use in sed command
escape_for_sed() {
    local input="$1"
    # Escape special sed characters: / \ & newline
    printf '%s\n' "$input" | sed 's/[[\.*^$()+?{|]/\\&/g; s|/|\\/|g'
}

# Escape string for shell usage
escape_for_shell() {
    local input="$1"
    # Use printf with %q to properly shell-escape the string
    printf '%q' "$input"
}

# Validate file path to prevent directory traversal
validate_file_path() {
    local file_path="$1"
    local base_dir="${2:-$(pwd)}"
    
    # Check for empty input
    if [[ -z "$file_path" ]]; then
        echo "Error: File path cannot be empty"
        return 1
    fi
    
    # Check for path traversal attempts
    if [[ "$file_path" == *".."* ]]; then
        echo "Error: Path traversal detected in file path: $file_path"
        return 1
    fi
    
    # Check for absolute paths outside of allowed base directory
    case "$file_path" in
        /*)
            echo "Error: Absolute paths not allowed: $file_path"
            return 1
            ;;
    esac
    
    # Resolve path and check if it's within base directory
    local resolved_path
    resolved_path=$(realpath -m "$base_dir/$file_path" 2>/dev/null || echo "$base_dir/$file_path")
    local canonical_base
    canonical_base=$(realpath -m "$base_dir" 2>/dev/null || echo "$base_dir")
    
    if [[ "$resolved_path" != "$canonical_base"* ]]; then
        echo "Error: File path outside of allowed directory: $file_path"
        return 1
    fi
    
    return 0
}

# Main validation function for common inputs
validate_common_inputs() {
    local binary_name="$1"
    local platform="$2"
    local version="$3"
    local repo="$4"
    local cargo_args="${5:-}"
    local rust_version="${6:-stable}"
    
    echo "Validating inputs..."
    
    validate_binary_name "$binary_name" || return 1
    validate_platform_name "$platform" || return 1
    validate_version_tag "$version" || return 1
    validate_repository "$repo" || return 1
    validate_cargo_args "$cargo_args" || return 1
    validate_rust_version "$rust_version" || return 1
    
    echo "All inputs validated successfully"
    return 0
}

# Export functions for use in other scripts
export -f validate_binary_name
export -f validate_platform_name
export -f validate_repository
export -f validate_version_tag
export -f validate_cargo_args
export -f validate_rust_version
export -f escape_for_sed
export -f escape_for_shell
export -f validate_file_path
export -f validate_common_inputs
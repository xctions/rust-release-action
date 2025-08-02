# Secure Rust Release Builder

A production-ready reusable GitHub workflow that builds Rust binaries for multiple platforms and creates secure releases with checksums, archives, and installation scripts - similar to zoxide's release structure.

## 🔒 Security First

This reusable workflow addresses critical security vulnerabilities found in similar actions:
- ✅ **No command injection** - All inputs are properly validated and sanitized
- ✅ **Input validation** - Strict validation prevents malicious inputs
- ✅ **Checksum verification** - SHA256 checksums for all assets
- ✅ **Safe template rendering** - No shell interpretation in templates
- ✅ **Path traversal protection** - All file operations are validated

## ✨ Features

- 🚀 **Matrix-based parallel builds** - Fast cross-platform compilation
- 📦 **Multiple release formats** - Standalone binaries + tar.gz/zip archives
- 🔍 **Checksum generation** - SHA256 checksums for integrity verification
- 📋 **Multiple binaries** - Build several binaries from one repository
- 🎯 **Flexible platform targeting** - Include/exclude specific platforms
- 📥 **Secure install scripts** - Hardened installation with integrity checks
- 🏗️ **Professional structure** - Follows zoxide's release asset patterns

## 🚀 Quick Start

```yaml
name: Release
on:
  push:
    tags: ['v*']

jobs:
  release:
    uses: xctions/rust-release/.github/workflows/reusable-rust-release.yml@v2
    with:
      binaries: 'my-app'
      release-tag: ${{ github.ref_name }}
    secrets:
      GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}
```

## 📋 Inputs

| Input | Description | Required | Default |
|-------|-------------|----------|---------|
| `binaries` | Comma-separated list of binary names | Yes | |
| `release-tag` | Release tag to create | Yes | |
| `include` | JSON array of custom platforms | No | Default matrix |
| `exclude` | Comma-separated platforms to exclude | No | |
| `rust-version` | Rust version to use | No | `stable` |
| `cargo-args` | Additional cargo build arguments | No | `--release` |
| `generate-checksums` | Generate SHA256 checksums | No | `true` |
| `create-archives` | Create tar.gz/zip archives | No | `true` |

## 🎯 Supported Platforms

**Default Matrix:**
- `linux-x86_64` - Linux x86_64 (GNU)
- `linux-arm64` - Linux ARM64 (GNU)
- `mac-x86_64` - macOS Intel
- `mac-arm64` - macOS Apple Silicon
- `windows-x86_64` - Windows x86_64 (MSVC)
- `windows-arm64` - Windows ARM64 (MSVC)

**Extended Support** (via custom `include`):
- `linux-i686` - 32-bit Linux
- `linux-armv7` - ARMv7 Linux
- `linux-x86_64-musl` - Linux x86_64 (musl)
- `linux-arm64-musl` - Linux ARM64 (musl)
- `windows-x86_64-gnu` - Windows x86_64 (MinGW)
- `windows-i686` - 32-bit Windows

## 📚 Examples

### Multiple Binaries
```yaml
jobs:
  release:
    uses: xctions/rust-release/.github/workflows/reusable-rust-release.yml@v2
    with:
      binaries: 'my-app,my-cli,my-daemon'
      release-tag: ${{ github.ref_name }}
    secrets:
      GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}
```

### Exclude Platforms
```yaml
jobs:
  release:
    uses: xctions/rust-release/.github/workflows/reusable-rust-release.yml@v2
    with:
      binaries: 'my-app'
      exclude: 'windows-arm64,linux-arm64'
      release-tag: ${{ github.ref_name }}
    secrets:
      GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}
```

### Custom Platform Matrix
```yaml
jobs:
  release:
    uses: xctions/rust-release/.github/workflows/reusable-rust-release.yml@v2
    with:
      binaries: 'my-app'
      include: |
        [
          {"target": "x86_64-unknown-linux-gnu", "os": "ubuntu-latest", "platform": "linux-x86_64"},
          {"target": "x86_64-unknown-linux-musl", "os": "ubuntu-latest", "platform": "linux-x86_64-musl"},
          {"target": "aarch64-apple-darwin", "os": "macos-latest", "platform": "mac-arm64"}
        ]
      release-tag: ${{ github.ref_name }}
    secrets:
      GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}
```

### Advanced Configuration
```yaml
jobs:
  release:
    uses: xctions/rust-release/.github/workflows/reusable-rust-release.yml@v2
    with:
      binaries: 'my-app'
      release-tag: ${{ github.ref_name }}
      rust-version: '1.75.0'
      cargo-args: '--release --locked --no-default-features --features production'
      generate-checksums: true
      create-archives: true
    secrets:
      GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}
```

## 📦 Release Assets

For each binary and platform, the workflow creates:

### Standalone Binaries
- `my-app-linux-x86_64`
- `my-app-mac-arm64` 
- `my-app-windows-x86_64.exe`

### Archives (zoxide-style)
- `my-app-v1.0.0-linux-x86_64.tar.gz`
- `my-app-v1.0.0-mac-arm64.tar.gz`
- `my-app-v1.0.0-windows-x86_64.zip`

### Security Assets
- `checksums.txt` - SHA256 checksums for all assets
- `checksums-verify.sh` - Verification script

## 🔐 Secure Installation

### Unix/Linux/macOS
```bash
curl -fsSL https://github.com/owner/repo/releases/download/v1.0.0/install-linux-x86_64.sh | bash
```

### Windows (PowerShell)
```powershell
iwr https://github.com/owner/repo/releases/download/v1.0.0/install-windows-x86_64.ps1 | iex
```

### Manual Installation with Verification
```bash
# Download and verify
curl -fsSL -O https://github.com/owner/repo/releases/download/v1.0.0/my-app-v1.0.0-linux-x86_64.tar.gz
curl -fsSL -O https://github.com/owner/repo/releases/download/v1.0.0/checksums.txt
sha256sum -c checksums.txt --ignore-missing

# Extract and install
tar -xzf my-app-v1.0.0-linux-x86_64.tar.gz
sudo cp my-app-v1.0.0-linux-x86_64/my-app /usr/local/bin/
```

## 🔧 Development

See [examples/](examples/) directory for complete workflow examples:
- [workflow-usage.yml](examples/workflow-usage.yml) - Basic usage
- [advanced-usage.yml](examples/advanced-usage.yml) - Multiple binaries with platform exclusion
- [custom-platforms.yml](examples/custom-platforms.yml) - Custom platform matrix

## 🛠️ Scripts

The workflow uses several secure scripts in the `scripts/` directory:
- `validate-inputs.sh` - Input validation and sanitization
- `generate-matrix.sh` - Build matrix generation
- `secure-build.sh` - Cross-compilation with security
- `create-checksums.sh` - SHA256 checksum generation
- `package-assets.sh` - Asset packaging

## 🆚 Migration from v1

The new v2 reusable workflow replaces the composite action with enhanced security:

**v1 (Composite Action):**
```yaml
- uses: xctions/rust-release@v1
  with:
    binary-name: 'my-app'
    platforms: 'linux-x86_64,mac-arm64'
```

**v2 (Reusable Workflow):**
```yaml
uses: xctions/rust-release/.github/workflows/reusable-rust-release.yml@v2
with:
  binaries: 'my-app'
  exclude: 'linux-arm64,windows-x86_64,windows-arm64'
```

## 🔒 Security

This workflow has been designed with security as a priority:
- All inputs are validated and sanitized
- No command injection vulnerabilities
- Secure template rendering
- Checksum verification for all assets
- Path traversal protection

For security issues, please see [SECURITY_IMPROVEMENTS.md](SECURITY_IMPROVEMENTS.md).

## 📄 License

MIT

## 🤝 Contributing

Contributions are welcome! Please see [CONTRIBUTING.md](CONTRIBUTING.md) for guidelines.

## 🆘 Support

For issues and questions:
1. Check the [examples](examples/) directory
2. Review the security documentation
3. Open an issue on GitHub
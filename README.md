# 🚀 Rust Build & Release

A unified GitHub workflow for building Rust binaries across multiple platforms and optionally publishing to npm - designed for simplicity and security.

## ✨ Features

- 🚀 **Unified Workflow** - Rust builds + npm publishing in one workflow
- 🔒 **Security First** - Minimal validation, letting cargo handle errors naturally
- 📦 **Cross-Platform Builds** - 8 platforms by default (Linux, macOS, Windows)
- 📋 **Single Binary Focus** - Optimized for 90%+ of Rust projects (single binary)
- 🎯 **Smart Defaults** - Auto-detects repository name as binary name
- 📥 **npm Integration** - Optional npm publishing with platform detection
- 🏗️ **Simple Interface** - Exclude platforms instead of complex include logic
- 🧪 **Local Testing** - Full test suite with `act` support for workflow validation

## 🚀 Quick Start

### Basic Rust Release

```yaml
name: Release
on:
  push:
    tags: ['v*']

jobs:
  release:
    uses: xctions/rust-release/.github/workflows/rust-release.yml@v3
    secrets:
      GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}
```

### With npm Publishing

```yaml
name: Release with npm
on:
  push:
    tags: ['v*']

jobs:
  release:
    uses: xctions/rust-release/.github/workflows/rust-release.yml@v3
    with:
      enable-npm: true
      npm-package-name: 'my-cli'
      # npm-dist-tag auto-detected from release tag
    secrets:
      GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}
      NPM_TOKEN: ${{ secrets.NPM_TOKEN }}
```

## 📋 Input Parameters

| Parameter | Description | Required | Default |
|-----------|-------------|----------|---------|
| `binary-name` | Binary name | No | Repository name |
| `platforms` | Platforms to include | No | `mac-arm64,linux-x86_64,linux-arm64` |
| `rust-version` | Rust version | No | `stable` |
| `cargo-args` | Cargo build arguments | No | `--release` |
| `generate-checksums` | Generate SHA256 checksums | No | `true` |
| `create-archives` | Create platform archives | No | `true` |
| **npm Options** | | | |
| `enable-npm` | Enable npm publishing | No | `false` |
| `npm-package-name` | npm package name | No* | |
| `npm-dist-tag` | npm dist-tag | No | Auto-detected from release tag |
| `npm-description` | Package description | No | Auto-generated |

\* Required when `enable-npm: true`

## 🎯 Supported Platforms

**Default Matrix (3 platforms):**
- `linux-x86_64` - Linux x86_64 (GNU)
- `linux-arm64` - Linux ARM64 (GNU)  
- `mac-arm64` - macOS Apple Silicon

**Platform Selection:**
```yaml
platforms: 'linux-x86_64,mac-arm64'  # Build only x86_64 and macOS ARM64
```

## 📚 Usage Examples

### 1. Basic Release (Auto-detected binary name)
```yaml
# Uses repository name as binary name
uses: xctions/rust-release/.github/workflows/rust-release.yml@v3
secrets:
  GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}
```

### 2. Custom Binary Name
```yaml
uses: xctions/rust-release/.github/workflows/rust-release.yml@v3
with:
  binary-name: 'my-custom-tool'
secrets:
  GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}
```

### 3. Selective Platforms
```yaml
uses: xctions/rust-release/.github/workflows/rust-release.yml@v3
with:
  platforms: 'linux-x86_64'  # Build only Linux x86_64
secrets:
  GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}
```

### 4. Production npm Publishing
```yaml
uses: xctions/rust-release/.github/workflows/rust-release.yml@v3
with:
  binary-name: 'my-cli'
  platforms: 'linux-x86_64,mac-arm64'  # Faster builds
  
  # npm publishing
  enable-npm: true
  npm-package-name: '@myorg/my-cli'
  # npm-dist-tag auto-detected: v1.0.0 → latest, v1.0.0-beta.1 → beta
  npm-description: 'My awesome CLI tool'
secrets:
  GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}
  NPM_TOKEN: ${{ secrets.NPM_TOKEN }}
```

### 5. Override Auto-Detected Tag
```yaml
uses: xctions/rust-release/.github/workflows/rust-release.yml@v3
with:
  enable-npm: true
  npm-package-name: 'my-cli'
  # Override auto-detection with custom logic
  npm-dist-tag: ${{ contains(github.ref_name, 'experimental') && 'experimental' || '' }}
```

## 📦 Release Assets

For each build, the workflow creates:

### Standalone Binaries
- `my-app-linux-x86_64`
- `my-app-linux-arm64`
- `my-app-mac-arm64`

### Archives
- `my-app-v1.0.0-linux-x86_64.tar.gz`
- `my-app-v1.0.0-linux-arm64.tar.gz`
- `my-app-v1.0.0-mac-arm64.tar.gz`

### Security
- `checksums.txt` - SHA256 checksums for all assets

### npm Package (when enabled)
- Cross-platform npm package with automatic platform detection
- Binary wrapper that downloads the correct platform binary
- Works with `npm install -g my-cli`

## 🔐 npm Publishing Strategy

### Dist-Tag Options

| Tag | Use Case | Risk Level |
|-----|----------|------------|
| `latest` | Production releases | ❌ High (default install) |
| `beta` | Testing releases | ⚠️ Medium |
| `alpha` | Early testing | ⚠️ Medium |
| `rc` | Release candidates | ⚠️ Medium |
| `dev` | Development builds | ✅ Low |

### Safe Deployment Pattern

```yaml
# 1. Create beta release (auto-detected)
git tag v1.0.0-beta.1  # → npm-dist-tag: beta

# 2. Test with: npm install -g my-cli@beta

# 3. Create stable release (auto-detected)
git tag v1.0.0  # → npm-dist-tag: latest
```

### Auto-Detection Rules

| Release Tag Pattern | npm dist-tag |
|---------------------|--------------|
| `v1.0.0` | `latest` |
| `v1.0.0-beta.1` | `beta` |
| `v1.0.0-alpha.1` | `alpha` |
| `v1.0.0-rc.1` | `rc` |
| `v1.0.0-dev.1` | `dev` |

### npm Installation

```bash
# Install from specific tag
npm install -g my-cli@beta

# Install latest (production)
npm install -g my-cli

# Use without installing
npx my-cli --help
```

## 🔧 Complete Example

See [examples/](examples/) directory:
- **[basic-usage.yml](examples/basic-usage.yml)** - Simple Rust release
- **[with-npm.yml](examples/with-npm.yml)** - Rust + npm publishing
- **[advanced.yml](examples/advanced.yml)** - Full configuration with smart tagging

## 🆚 Migration from v2

### Before (v2 - Separate Workflows)
```yaml
jobs:
  rust-release:
    uses: ./.github/workflows/rust-release.yml@v2
    with:
      binary-name: 'my-app'
      release-tag: ${{ github.ref_name }}
  
  npm-publish:
    needs: rust-release  
    uses: ./.github/workflows/npm-publish.yml@v2
    with:
      source_tag: ${{ github.ref_name }}
      npm_package_name: 'my-app'
      npm_dist_tag: 'beta'
```

### After (v3 - Unified Workflow)
```yaml
jobs:
  release:
    uses: xctions/rust-release/.github/workflows/rust-release.yml@v3
    with:
      binary-name: 'my-app'  # Optional - auto-detects from repo
      enable-npm: true
      npm-package-name: 'my-app'
      # release-tag: auto-detects github.ref_name
      # npm-dist-tag: auto-detects from release tag
```

**Key Changes:**
- ✅ **Unified**: Single workflow instead of two
- ✅ **Simplified**: 50% fewer lines of code  
- ✅ **Auto-detection**: No manual release-tag or npm-dist-tag needed
- ✅ **Faster**: Minimal validation overhead
- ✅ **Easier**: Simpler parameter interface

## 🔧 Development Setup

### Prerequisites
- **Rust** (stable toolchain recommended)
- **Git** for version control
- **Docker** (optional, for local testing with act)

### Local Testing
```bash
# Install act for local GitHub Actions testing
brew install act  # macOS
# or download from: https://github.com/nektos/act/releases

# Test workflow locally
act -l  # List available workflows
act workflow_dispatch  # Run with manual trigger
```

### Development Dependencies
For detailed information about all external dependencies and tools used in this workflow, see **[docs/DEPENDENCIES.md](docs/DEPENDENCIES.md)**.

## 📁 Project Structure

```
rust-release/
├── .github/workflows/
│   └── rust-release.yml          # Main production workflow
├── scripts/                      # Build and validation scripts
├── templates/                    # Install script templates
├── examples/                     # Usage examples
├── test/                        # Testing infrastructure
│   ├── workflows/               # Test workflows (act-compatible)
│   ├── test-*.sh               # Test scripts
│   ├── test-project/           # Sample Rust project
│   └── results/                # Test output (gitignored)
└── docs/                       # Documentation
    ├── DEPENDENCIES.md         # Dependency reference
    ├── NPM_PUBLISHING.md       # npm publishing guide
    ├── TESTING.md              # Testing documentation
    └── *.md                    # Other docs
```

## 🧪 Testing

```bash
# Run all tests
./test/run-tests.sh

# Run specific test suites
./test/test-workflow.sh    # Workflow testing with act
./test/test-scripts.sh     # Script unit tests
./test/test-security.sh    # Security validation tests

# Local workflow testing
act -W test/workflows/rust-release-simple.yml

# NOTE: Main rust-release.yml not compatible with act due to dynamic matrix
```

## 📄 Documentation

- **[docs/DEPENDENCIES.md](docs/DEPENDENCIES.md)** - Complete dependency reference
- **[docs/NPM_PUBLISHING.md](docs/NPM_PUBLISHING.md)** - Complete npm publishing guide  
- **[docs/TESTING.md](docs/TESTING.md)** - Testing guide and troubleshooting
- **[docs/SECURITY_IMPROVEMENTS.md](docs/SECURITY_IMPROVEMENTS.md)** - Security enhancements

## 🛡️ Security Features

- **Minimal Validation** - Trusts cargo/npm for error handling
- **Input Sanitization** - Core security validations only
- **Safe npm Publishing** - Prevents accidental @latest deploys
- **Checksum Verification** - SHA256 for all release assets

## ⚡ Performance

- **862 → 430 lines** - 50% code reduction
- **Faster builds** - Removed validation overhead  
- **Single workflow** - Unified execution
- **Smart caching** - Optimized cargo cache strategy

## 📄 License

MIT

## 🤝 Contributing

1. Check [examples/](examples/) for usage patterns
2. Test with different platforms and configurations  
3. Update documentation for any interface changes
4. Follow the unified workflow pattern

## ⚠️ Known Limitations

### act (Local Testing) Compatibility
- **Main workflow** (`rust-release.yml`): ❌ Not compatible with act
  - Uses dynamic matrix with `${{ fromJson(needs.prepare.outputs.matrix) }}`
  - act cannot parse complex job output dependencies at compile time
- **Simple workflow** (`test/workflows/rust-release-simple.yml`): ✅ Fully compatible
  - Static matrix configuration
  - Use this for all local testing with act

### Workaround
```bash
# ❌ This will fail
act -W .github/workflows/rust-release.yml

# ✅ Use this instead  
act -W test/workflows/rust-release-simple.yml
```

## 🆘 Support

- **Examples**: Check [examples/](examples/) directory
- **Issues**: GitHub Issues for bugs and feature requests
- **Security**: See [docs/SECURITY_IMPROVEMENTS.md](docs/SECURITY_IMPROVEMENTS.md)
- **Testing Issues**: See [docs/TESTING.md](docs/TESTING.md) for troubleshooting
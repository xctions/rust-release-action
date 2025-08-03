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
    with:
      release-tag: ${{ github.ref_name }}
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
      release-tag: ${{ github.ref_name }}
      enable-npm: true
      npm-package-name: 'my-cli'
      npm-dist-tag: 'beta'
    secrets:
      GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}
      NPM_TOKEN: ${{ secrets.NPM_TOKEN }}
```

## 📋 Input Parameters

| Parameter | Description | Required | Default |
|-----------|-------------|----------|---------|
| `binary-name` | Binary name | No | Repository name |
| `release-tag` | Release tag to create | Yes | |
| `exclude` | Platforms to exclude | No | |
| `rust-version` | Rust version | No | `stable` |
| `cargo-args` | Cargo build arguments | No | `--release` |
| `generate-checksums` | Generate SHA256 checksums | No | `true` |
| `create-archives` | Create platform archives | No | `true` |
| **npm Options** | | | |
| `enable-npm` | Enable npm publishing | No | `false` |
| `npm-package-name` | npm package name | No* | |
| `npm-dist-tag` | npm dist-tag | No | `latest` |
| `npm-description` | Package description | No | Auto-generated |

\* Required when `enable-npm: true`

## 🎯 Supported Platforms

**Default Matrix (8 platforms):**
- `linux-x86_64` - Linux x86_64 (GNU)
- `linux-arm64` - Linux ARM64 (GNU)  
- `linux-x86_64-musl` - Linux x86_64 (musl)
- `linux-arm64-musl` - Linux ARM64 (musl)
- `mac-x86_64` - macOS Intel
- `mac-arm64` - macOS Apple Silicon
- `windows-x86_64` - Windows x86_64
- `windows-arm64` - Windows ARM64

**Platform Exclusion:**
```yaml
exclude: 'linux-arm64,windows-arm64'  # Build only x86_64 + mac-arm64
```

## 📚 Usage Examples

### 1. Basic Release (Auto-detected binary name)
```yaml
# Uses repository name as binary name
uses: xctions/rust-release/.github/workflows/rust-release.yml@v3
with:
  release-tag: ${{ github.ref_name }}
secrets:
  GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}
```

### 2. Custom Binary Name
```yaml
uses: xctions/rust-release/.github/workflows/rust-release.yml@v3
with:
  binary-name: 'my-custom-tool'
  release-tag: ${{ github.ref_name }}
secrets:
  GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}
```

### 3. Selective Platforms
```yaml
uses: xctions/rust-release/.github/workflows/rust-release.yml@v3
with:
  exclude: 'linux-arm64,windows-arm64,linux-arm64-musl'  # x86_64 only
  release-tag: ${{ github.ref_name }}
secrets:
  GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}
```

### 4. Production npm Publishing
```yaml
uses: xctions/rust-release/.github/workflows/rust-release.yml@v3
with:
  binary-name: 'my-cli'
  release-tag: ${{ github.ref_name }}
  exclude: 'linux-arm64,windows-arm64'  # Faster builds
  
  # npm publishing
  enable-npm: true
  npm-package-name: '@myorg/my-cli'
  npm-dist-tag: 'latest'
  npm-description: 'My awesome CLI tool'
secrets:
  GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}
  NPM_TOKEN: ${{ secrets.NPM_TOKEN }}
```

### 5. Smart npm Tagging
```yaml
uses: xctions/rust-release/.github/workflows/rust-release.yml@v3
with:
  enable-npm: true
  npm-package-name: 'my-cli'
  # Smart tag based on release type
  npm-dist-tag: ${{ contains(github.ref_name, 'rc') && 'rc' || contains(github.ref_name, 'beta') && 'beta' || 'latest' }}
```

## 📦 Release Assets

For each build, the workflow creates:

### Standalone Binaries
- `my-app-linux-x86_64`
- `my-app-mac-arm64`
- `my-app-windows-x86_64.exe`

### Archives
- `my-app-v1.0.0-linux-x86_64.tar.gz`
- `my-app-v1.0.0-mac-arm64.tar.gz`
- `my-app-v1.0.0-windows-x86_64.zip`

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
# 1. Deploy to beta first
npm-dist-tag: 'beta'

# 2. Test with: npm install -g my-cli@beta

# 3. Promote to latest when ready:
# npm dist-tag add my-cli@1.0.0 latest
```

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
  
  npm-publish:
    needs: rust-release  
    uses: ./.github/workflows/npm-publish.yml@v2
    with:
      source_tag: ${{ github.ref_name }}
      npm_package_name: 'my-app'
```

### After (v3 - Unified Workflow)
```yaml
jobs:
  release:
    uses: xctions/rust-release/.github/workflows/rust-release.yml@v3
    with:
      binary-name: 'my-app'
      enable-npm: true
      npm-package-name: 'my-app'
```

**Key Changes:**
- ✅ **Unified**: Single workflow instead of two
- ✅ **Simplified**: 50% fewer lines of code  
- ✅ **Faster**: Minimal validation overhead
- ✅ **Easier**: Simpler parameter interface

## 📄 Documentation

- **[NPM_PUBLISHING.md](NPM_PUBLISHING.md)** - Complete npm publishing guide
- **[SECURITY_IMPROVEMENTS.md](SECURITY_IMPROVEMENTS.md)** - Security enhancements

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

## 🆘 Support

- **Examples**: Check [examples/](examples/) directory
- **Issues**: GitHub Issues for bugs and feature requests
- **Security**: See [SECURITY_IMPROVEMENTS.md](SECURITY_IMPROVEMENTS.md)
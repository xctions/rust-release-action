# 📦 Dependencies & External Tools

This document provides a comprehensive overview of all external dependencies, tools, and libraries used in the Rust Build & Release workflow.

## 🎯 Core GitHub Actions

### Official GitHub Actions

| Action | Version | Purpose | License |
|--------|---------|---------|---------|
| [`actions/checkout`](https://github.com/actions/checkout) | `v4` | Repository code checkout | MIT |
| [`actions/cache`](https://github.com/actions/cache) | `v4` | Cargo registry and build cache | MIT |
| [`actions/upload-artifact`](https://github.com/actions/upload-artifact) | `v4` | Upload build artifacts between jobs | MIT |
| [`actions/download-artifact`](https://github.com/actions/download-artifact) | `v4` | Download artifacts for release | MIT |
| [`actions/setup-node`](https://github.com/actions/setup-node) | `v4` | Node.js environment for npm publishing | MIT |

### Third-Party Actions

| Action | Version | Purpose | License | Maintainer |
|--------|---------|---------|---------|------------|
| [`dtolnay/rust-toolchain`](https://github.com/dtolnay/rust-toolchain) | `stable` | Rust toolchain installation | Apache-2.0/MIT | David Tolnay |
| [`softprops/action-gh-release`](https://github.com/softprops/action-gh-release) | `v1` | GitHub release creation | MIT | softprops |

## 🛠️ System Dependencies

### Rust Ecosystem

| Tool | Version | Purpose | Platforms |
|------|---------|---------|-----------|
| **Rust Toolchain** | `stable` (configurable) | Core Rust compiler and tools | All |
| **Cargo** | Bundled with Rust | Build system and package manager | All |
| **rustc** | Bundled with Rust | Rust compiler | All |

### Cross-Compilation Tools

#### Linux Dependencies
| Tool | Target | Purpose | Installation |
|------|--------|---------|-------------|
| `gcc-aarch64-linux-gnu` | `aarch64-unknown-linux-gnu` | ARM64 cross-compiler | `apt-get install gcc-aarch64-linux-gnu` |
| `musl-tools` | `*-musl` targets | Static linking with musl | `apt-get install musl-tools` |

#### Target Triples Supported
```
x86_64-unknown-linux-gnu     # Linux x86_64 (GNU libc)
aarch64-unknown-linux-gnu    # Linux ARM64 (GNU libc)
x86_64-unknown-linux-musl    # Linux x86_64 (musl - static)
aarch64-unknown-linux-musl   # Linux ARM64 (musl - static)
x86_64-apple-darwin          # macOS Intel
aarch64-apple-darwin         # macOS Apple Silicon
x86_64-pc-windows-msvc       # Windows x86_64
aarch64-pc-windows-msvc      # Windows ARM64
```

## 🌐 npm Publishing Dependencies

### Node.js Ecosystem

| Tool | Version | Purpose | Notes |
|------|---------|---------|-------|
| **Node.js** | `18` | JavaScript runtime | LTS version for stability |
| **npm** | Bundled with Node.js | Package manager | For publishing to npm registry |

### Runtime Dependencies (npm package)
| Module | Purpose | Built-in |
|--------|---------|----------|
| `child_process` | Binary execution | ✅ Node.js built-in |
| `path` | Path manipulation | ✅ Node.js built-in |
| `os` | Platform detection | ✅ Node.js built-in |

## 🔧 System Utilities

### Archive & Compression
| Tool | Purpose | Platforms | Availability |
|------|---------|-----------|--------------|
| `tar` | Create .tar.gz archives | Linux, macOS | ✅ System default |
| `zip` | Create .zip archives | Windows | ✅ System default |
| `gzip` | Compression | Linux, macOS | ✅ System default |

### Security & Verification
| Tool | Purpose | Platforms | Alternatives |
|------|---------|-----------|-------------|
| `sha256sum` | Checksum generation | Linux | `shasum -a 256` (macOS) |
| `shasum` | Checksum generation | macOS | `sha256sum` (Linux) |

### Shell & Scripting
| Tool | Purpose | Availability |
|------|---------|-------------|
| `bash` | Shell scripting | ✅ All GitHub runners |
| `jq` | JSON processing | ✅ Pre-installed on runners |

## 🏗️ GitHub Runner Environments

### Runner OS Matrix
| OS | Version | Use Case |
|----|---------|----------|
| `ubuntu-latest` | Ubuntu 22.04 | Linux builds, release management |
| `macos-12` | macOS 12 Monterey | macOS Intel builds |
| `macos-latest` | macOS 14 Sonoma | macOS Apple Silicon builds |
| `windows-latest` | Windows Server 2022 | Windows builds |

### Pre-installed Tools
All GitHub runners come with:
- Git
- curl
- jq
- tar, gzip, zip
- Basic development tools (gcc, make, etc.)

## 🔒 Security Dependencies

### Secrets Management
| Secret | Purpose | Required | Scope |
|--------|---------|----------|-------|
| `GITHUB_TOKEN` | GitHub API access | ✅ Always | Release creation |
| `NPM_TOKEN` | npm registry access | ⚠️ If npm enabled | Package publishing |

### Security Tools
- **SHA256 checksums** - Integrity verification for all release assets
- **GitHub Releases** - Secure asset hosting and distribution
- **npm registry** - Package distribution with token authentication

## 📦 Cache Strategy

### Cargo Cache
```yaml
~/.cargo/registry    # Crate registry cache
~/.cargo/git         # Git dependencies cache  
target/              # Build artifacts cache
```

**Cache Key Strategy:**
- Primary: `${{ runner.os }}-${{ matrix.target }}-cargo-${{ hashFiles('**/Cargo.lock') }}`
- Fallback: `${{ runner.os }}-${{ matrix.target }}-cargo-`

## 🚀 Development Tools (Optional)

### Local Testing
| Tool | Purpose | Installation |
|------|---------|-------------|
| [**act**](https://github.com/nektos/act) | Local GitHub Actions testing | `brew install act` |
| **Docker** | Container runtime for act | [Docker Desktop](https://docker.com) |

### Code Quality
| Tool | Purpose | Usage |
|------|---------|-------|
| `cargo fmt` | Code formatting | `cargo fmt --check` |
| `cargo clippy` | Linting | `cargo clippy -- -D warnings` |
| `cargo test` | Testing | `cargo test` |

## 🔄 Update Policy

### Automatic Updates
- **GitHub Actions**: Dependabot enabled for action updates
- **Rust Toolchain**: Uses `stable` channel for automatic updates

### Manual Updates Required
- **Target platforms**: Review quarterly for new platform support
- **Node.js version**: Update annually or when LTS changes
- **Cross-compilation tools**: Update with OS package managers

## ⚠️ Version Compatibility

### Known Constraints
- **Node.js 18+**: Required for npm publishing (uses modern modules)
- **Rust stable**: Minimum version depends on used language features
- **GitHub Actions v4**: Uses latest runner capabilities

### Breaking Changes to Watch
- **GitHub runner OS updates**: May affect pre-installed tools
- **Rust edition changes**: May require toolchain updates
- **npm API changes**: May affect publishing workflow

## 🆘 Troubleshooting Dependencies

### Common Issues

#### Missing Cross-Compilation Tools
```bash
# Error: linking with gcc failed
sudo apt-get update && sudo apt-get install gcc-aarch64-linux-gnu
```

#### Cache Issues
```bash
# Clear cargo cache
cargo clean
rm -rf ~/.cargo/registry/cache
```

#### npm Publishing Failures
```bash
# Check npm token permissions
npm whoami --registry https://registry.npmjs.org
```

### Dependency Health Checks
```bash
# Verify Rust installation
rustc --version
cargo --version

# Verify target support
rustup target list --installed

# Check npm configuration
npm config list
```

## 📋 Maintenance Checklist

### Monthly
- [ ] Check for GitHub Actions updates
- [ ] Review Rust stable channel updates
- [ ] Verify npm package dependencies

### Quarterly  
- [ ] Review target platform matrix
- [ ] Update documentation for new platforms
- [ ] Test with latest runner images

### Annually
- [ ] Review Node.js LTS version
- [ ] Evaluate new GitHub Actions
- [ ] Update security best practices

---

*Last updated: 2025-08-03*  
*Workflow version: v3*
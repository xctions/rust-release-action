# 🔄 Migration Guide: v2 → v3

Complete migration guide from separate workflows (v2) to unified workflow (v3).

## 📊 What's Changed

### Code Reduction
- **862 → 430 lines** (50% reduction)
- **2 workflows → 1 workflow** (unified)
- **Complex validation → Minimal validation**
- **JSON matrix manipulation → Simple hardcoded matrix**

### Interface Simplification
- **Unified parameters** - All options in one workflow
- **Auto-detection** - Repository name as default binary name
- **Simple exclusion** - Comma-separated platform exclusion
- **Optional npm** - Enable/disable with single flag

## 🚀 Migration Steps

### Step 1: Update Workflow Reference

**Before (v2):**
```yaml
# .github/workflows/release.yml
jobs:
  rust-release:
    uses: xctions/rust-release/.github/workflows/rust-release.yml@v2
    with:
      binary-name: 'my-app'
      release-tag: ${{ github.ref_name }}
  
  npm-publish:
    needs: rust-release
    uses: xctions/rust-release/.github/workflows/npm-publish.yml@v2
    with:
      source_tag: ${{ github.ref_name }}
      npm_package_name: 'my-app'
      npm_dist_tag: 'beta'
    secrets:
      NPM_TOKEN: ${{ secrets.NPM_TOKEN }}
```

**After (v3):**
```yaml
# .github/workflows/release.yml  
jobs:
  release:
    uses: xctions/rust-release/.github/workflows/rust-release.yml@v3
    with:
      binary-name: 'my-app'  # Optional - auto-detects from repo name
      release-tag: ${{ github.ref_name }}
      enable-npm: true
      npm-package-name: 'my-app'
      npm-dist-tag: 'beta'
    secrets:
      GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}
      NPM_TOKEN: ${{ secrets.NPM_TOKEN }}
```

### Step 2: Parameter Mapping

| v2 Parameter | v3 Parameter | Notes |
|--------------|--------------|-------|
| `binary-name` | `binary-name` | ✅ Same |
| `release-tag` | `release-tag` | ✅ Same |
| `exclude` | `exclude` | ✅ Same |
| `rust-version` | `rust-version` | ✅ Same |
| `cargo-args` | `cargo-args` | ✅ Same |
| `generate-checksums` | `generate-checksums` | ✅ Same |
| `create-archives` | `create-archives` | ✅ Same |
| **npm Parameters** | | |
| `source_tag` | ❌ Removed | Auto-uses `release-tag` |
| `npm_package_name` | `npm-package-name` | ✅ Renamed (dash-case) |
| `npm_dist_tag` | `npm-dist-tag` | ✅ Renamed (dash-case) |
| `package_description` | `npm-description` | ✅ Renamed |
| ❌ N/A | `enable-npm` | ✅ New (required for npm) |

### Step 3: Remove Separate npm Workflow

**Delete these files:**
- `.github/workflows/npm-publish.yml` (if you copied it)
- Any custom npm publishing workflows

The unified workflow handles both Rust builds and npm publishing.

## 📋 Migration Examples

### Example 1: Basic Rust Release

**v2:**
```yaml
jobs:
  release:
    uses: xctions/rust-release/.github/workflows/rust-release.yml@v2
    with:
      binary-name: 'my-tool'
      release-tag: ${{ github.ref_name }}
```

**v3:**
```yaml
jobs:
  release:
    uses: xctions/rust-release/.github/workflows/rust-release.yml@v3
    with:
      # binary-name is now optional - uses repo name by default
      release-tag: ${{ github.ref_name }}
```

### Example 2: With npm Publishing

**v2:**
```yaml
jobs:
  rust-release:
    uses: xctions/rust-release/.github/workflows/rust-release.yml@v2
    with:
      binary-name: 'my-cli'
      release-tag: ${{ github.ref_name }}
    secrets:
      GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}
  
  npm-publish:
    needs: rust-release
    uses: xctions/rust-release/.github/workflows/npm-publish.yml@v2
    with:
      source_tag: ${{ github.ref_name }}
      npm_package_name: 'my-cli'
      npm_dist_tag: 'beta'
    secrets:
      NPM_TOKEN: ${{ secrets.NPM_TOKEN }}
```

**v3:**
```yaml
jobs:
  release:
    uses: xctions/rust-release/.github/workflows/rust-release.yml@v3
    with:
      binary-name: 'my-cli'
      release-tag: ${{ github.ref_name }}
      enable-npm: true
      npm-package-name: 'my-cli'
      npm-dist-tag: 'beta'
    secrets:
      GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}
      NPM_TOKEN: ${{ secrets.NPM_TOKEN }}
```

### Example 3: Platform Exclusion

**v2:**
```yaml
uses: xctions/rust-release/.github/workflows/rust-release.yml@v2
with:
  exclude: 'linux-arm64,windows-arm64'
```

**v3:**
```yaml
uses: xctions/rust-release/.github/workflows/rust-release.yml@v3
with:
  exclude: 'linux-arm64,windows-arm64'  # Same syntax
```

### Example 4: Advanced Configuration

**v2:**
```yaml
jobs:
  rust-release:
    uses: xctions/rust-release/.github/workflows/rust-release.yml@v2
    with:
      binary-name: 'advanced-tool'
      release-tag: ${{ github.ref_name }}
      rust-version: '1.75.0'
      cargo-args: '--release --locked --features production'
      exclude: 'linux-arm64,windows-arm64'
  
  npm-publish:
    needs: rust-release
    uses: xctions/rust-release/.github/workflows/npm-publish.yml@v2
    with:
      source_tag: ${{ github.ref_name }}
      npm_package_name: '@myorg/advanced-tool'
      npm_dist_tag: ${{ contains(github.ref_name, 'beta') && 'beta' || 'latest' }}
      package_description: 'Advanced development tool'
```

**v3:**
```yaml
jobs:
  release:
    uses: xctions/rust-release/.github/workflows/rust-release.yml@v3
    with:
      binary-name: 'advanced-tool'
      release-tag: ${{ github.ref_name }}
      rust-version: '1.75.0'
      cargo-args: '--release --locked --features production'
      exclude: 'linux-arm64,windows-arm64'
      
      enable-npm: true
      npm-package-name: '@myorg/advanced-tool'
      npm-dist-tag: ${{ contains(github.ref_name, 'beta') && 'beta' || 'latest' }}
      npm-description: 'Advanced development tool'
```

## 🔍 Validation Changes

### What's Removed (Less Validation)

**Binary Name Validation:**
- ❌ Regex pattern matching
- ❌ Length restrictions
- ✅ Let cargo handle invalid names naturally

**Cargo Args Validation:**
- ❌ Character restrictions (`;`, `|`, `&`, etc.)
- ❌ Flag format validation
- ✅ Let cargo handle invalid arguments naturally

**Rust Version Validation:**
- ❌ Version pattern matching  
- ❌ Standard version warnings
- ✅ Let rustup handle invalid versions naturally

**Platform Validation:**
- ❌ Platform name regex validation
- ❌ Length restrictions
- ✅ Simple string matching with jq

### What's Kept (Essential Validation)

- ✅ npm token presence (when npm enabled)
- ✅ npm package name requirement (when npm enabled)
- ✅ Basic empty string checks
- ✅ File existence verification

## ⚡ Performance Improvements

### Build Time Reduction
- **Faster validation** - 80% less validation code
- **Simpler matrix generation** - No complex JSON manipulation
- **Unified execution** - No workflow dependencies
- **Better caching** - Optimized cargo cache strategy

### Code Maintainability  
- **Single workflow** - Easier to understand and debug
- **Fewer parameters** - Reduced configuration complexity
- **Clear defaults** - Smart auto-detection
- **Consistent naming** - dash-case parameters throughout

## 🚨 Breaking Changes

### Removed Features
1. **Multi-binary support** - Now focuses on single binary (90%+ use case)
2. **Complex include matrix** - Only exclude-based filtering
3. **Separate npm workflow** - Integrated into main workflow
4. **Extensive validation** - Minimal validation approach

### Parameter Changes
- `npm_package_name` → `npm-package-name` (dash-case)
- `npm_dist_tag` → `npm-dist-tag` (dash-case)  
- `package_description` → `npm-description` (prefix added)
- `source_tag` → removed (auto-uses `release-tag`)

### Workflow Structure
- Job names changed: `rust-release` + `npm-publish` → `release`
- Single unified workflow instead of two separate workflows

## ✅ Migration Checklist

- [ ] Update workflow reference to `@v3`
- [ ] Combine rust-release and npm-publish jobs into single `release` job
- [ ] Add `enable-npm: true` for npm publishing
- [ ] Update parameter names (underscores → dashes)
- [ ] Remove `source_tag` (auto-uses `release-tag`)
- [ ] Test with a development release first
- [ ] Update any documentation references

## 🔄 Rollback Plan

If you need to rollback to v2:

```yaml
# Rollback to v2
uses: xctions/rust-release/.github/workflows/rust-release.yml@v2
```

However, note that v2 will not receive further updates. Consider fixing issues in v3 instead.

## 🆘 Troubleshooting

### Common Migration Issues

**Issue: npm publishing not working**
```yaml
# Solution: Add enable-npm flag
enable-npm: true
npm-package-name: 'my-package'
```

**Issue: Parameter name errors**
```yaml
# Wrong (v2 style)
npm_package_name: 'my-package'

# Correct (v3 style)  
npm-package-name: 'my-package'
```

**Issue: Missing binary name**
```yaml
# v3 auto-detects from repository name
# Only specify if you need a different name
binary-name: 'custom-name'
```

**Issue: Platform filtering not working**
```yaml
# Use comma-separated exclude list
exclude: 'linux-arm64,windows-arm64,linux-arm64-musl'
```

## 📞 Support

- **Examples**: Check [examples/](examples/) directory for v3 patterns
- **Issues**: GitHub Issues for migration problems
- **Documentation**: See updated [README.md](README.md) for v3 usage
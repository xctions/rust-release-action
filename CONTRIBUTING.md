# Contributing to Rust Release Action

Thank you for considering contributing to the Rust Release Action! This guide will help you get started.

## Development Setup

1. **Fork and Clone**
   ```bash
   git clone https://github.com/your-username/rust-release.git
   cd rust-release
   ```

2. **Test Your Changes**
   Create a test repository with a simple Rust project to test the action.

## Project Structure

```
rust-release/
├── action.yml              # Main action definition
├── scripts/                # Build and utility scripts
│   ├── generate-install-script.sh
│   ├── package-release.sh
│   └── setup-cross-compilation.sh
├── templates/              # Installation script templates
│   ├── install-unix.sh.template
│   └── install-windows.ps1.template
├── examples/               # Usage examples
│   ├── simple-usage.yml
│   ├── workflow-usage.yml
│   └── selective-platforms.yml
└── README.md
```

## Making Changes

### Adding New Platforms

To add support for a new platform:

1. **Update `action.yml`**: Add the platform to the parsing logic in the `parse-platforms` step
2. **Update templates**: Ensure installation scripts work for the new platform
3. **Update documentation**: Add the platform to README.md and examples
4. **Test thoroughly**: Create a test case for the new platform

### Modifying Installation Scripts

1. **Edit templates**: Modify files in `templates/` directory
2. **Test on target platforms**: Ensure scripts work correctly
3. **Update generation script**: Modify `scripts/generate-install-script.sh` if needed

### Updating Build Process

1. **Modify `action.yml`**: Update the build steps
2. **Update scripts**: Modify files in `scripts/` directory
3. **Test cross-compilation**: Ensure all platforms build correctly

## Testing

### Local Testing

1. **Create a test repository** with a simple Rust project
2. **Use the action** in a workflow file
3. **Test on all platforms** you're modifying

### Test Checklist

- [ ] All supported platforms build successfully
- [ ] Installation scripts work on target platforms
- [ ] Generated releases contain all expected assets
- [ ] Cross-compilation works correctly
- [ ] Documentation is up to date

## Submitting Changes

1. **Create a descriptive commit message**
   ```
   feat: add support for FreeBSD x86_64
   
   - Add FreeBSD target to platform matrix
   - Update installation script templates
   - Add FreeBSD-specific build configuration
   ```

2. **Test your changes** thoroughly

3. **Update documentation** if needed

4. **Submit a pull request** with:
   - Clear description of changes
   - Test results
   - Any breaking changes noted

## Code Style

- **Shell scripts**: Use `set -euo pipefail` and proper error handling
- **YAML**: Use 2-space indentation
- **PowerShell**: Follow PowerShell best practices
- **Documentation**: Use clear, concise language

## Platform-Specific Considerations

### Linux
- Use `apt-get` for package installation
- Consider both x86_64 and ARM64 architectures
- Test on Ubuntu (GitHub Actions runner)

### macOS
- Support both Intel and Apple Silicon
- Use native compilation when possible
- Test installation script with homebrew paths

### Windows
- Support both x86_64 and ARM64
- Use PowerShell for installation scripts
- Handle Windows-specific paths and permissions

## Release Process

1. **Version bump**: Update version in documentation
2. **Tag release**: Create a new tag following semantic versioning
3. **Test release**: Verify the tagged version works correctly
4. **Update major version tag**: Update `v1` tag to point to latest `v1.x.x`

## Getting Help

- **GitHub Issues**: For bugs and feature requests
- **Discussions**: For questions and general discussion
- **Documentation**: Check README.md and examples first

## Code of Conduct

Please be respectful and inclusive in all interactions. We welcome contributions from everyone regardless of background or experience level.

## License

By contributing, you agree that your contributions will be licensed under the same license as the project (MIT License).
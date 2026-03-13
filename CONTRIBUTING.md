# Contributing to spaceheater

Thanks for your interest in contributing to `spaceheater`! This document provides guidelines for contributing to the project.

## How to Contribute

### Reporting Issues

If you find a bug or have a suggestion:

1. Check if the issue already exists in the [issue tracker](https://github.com/dbernard/spaceheater/issues)
2. If not, create a new issue with:
   - A clear, descriptive title
   - Steps to reproduce (for bugs)
   - Expected behavior
   - Actual behavior
   - Your environment (OS, bash version, gh CLI version)

### Submitting Changes

1. **Fork the repository**
   ```bash
   # Click "Fork" on GitHub, then clone your fork
   git clone https://github.com/YOUR-USERNAME/spaceheater.git
   cd spaceheater
   ```

2. **Create a feature branch**
   ```bash
   git checkout -b feature/your-feature-name
   # or
   git checkout -b fix/your-bug-fix
   ```

3. **Make your changes**
   - Follow the existing code style
   - Keep changes focused and atomic
   - Test your changes manually

4. **Commit your changes**
   ```bash
   git add .
   git commit -m "Brief description of your changes"
   ```

5. **Push to your fork**
   ```bash
   git push origin feature/your-feature-name
   ```

6. **Create a Pull Request**
   - Go to the original repository on GitHub
   - Click "New Pull Request"
   - Select your fork and branch
   - Provide a clear description of your changes

## Code Guidelines

### Shell Script Style

- Use bash best practices (`set -euo pipefail`)
- Quote variables to prevent word splitting
- Use meaningful variable names
- Add comments for complex logic
- Follow the existing indentation (2 spaces)

### Example:
```bash
# Good
local codespace_name="${1:-}"
if [ -z "$codespace_name" ]; then
  error "Codespace name required"
fi

# Avoid
local name=$1
if [ -z $name ]; then
  echo "Error: name required"
  exit 1
fi
```

### Testing Your Changes

Before submitting, test your changes:

```bash
# Run automated tests
make test

# Check syntax
make lint

# Check prerequisites
make check

# Test basic commands
./spaceheater version
./spaceheater help
./spaceheater config

# Test with different configurations
SPACEHEATER_REPO=owner/repo ./spaceheater config
SPACEHEATER_MACHINE=basicLinux ./spaceheater config
```

### Testing Installation

To test the installation process:

```bash
# Test installation
./install.sh

# Verify it works
spaceheater version
spaceheater help

# Test uninstallation
./uninstall.sh
```

## Feature Requests

Have an idea for a new feature? Great! Please:

1. Check if it's already been requested in [issues](https://github.com/dbernard/spaceheater/issues)
2. Open a new issue with:
   - **Why**: Explain the use case
   - **What**: Describe the proposed feature
   - **How**: Suggest implementation approach (optional)

## Questions?

Feel free to open an issue with the `question` label if you have questions about:
- How to use the tool
- How to contribute
- Technical decisions

## Code of Conduct

- Be respectful and constructive
- Focus on the problem, not the person
- Help make this a welcoming community

## License

By contributing, you agree that your contributions will be licensed under the MIT License.

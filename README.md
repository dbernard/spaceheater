# spaceheater 🔥

> Personal pre-warming for GitHub Codespaces - your setup, instant startup

[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)
[![Version](https://img.shields.io/badge/version-1.0.0-green.svg)](https://github.com/dbernard/spaceheater/releases)

Tired of waiting 5-10 minutes for Codespaces to build? `spaceheater` creates pre-warmed codespaces in the background that start in ~30 seconds when you need them.

## Why spaceheater?

- 🚀 **Instant startup** - Pre-built codespaces start in ~30 seconds instead of 5-10 minutes
- 🤖 **Background building** - Let codespaces build while you work on something else
- 💰 **Cost-efficient** - Stopped codespaces cost nothing (only minimal storage)
- 🎯 **Smart workflows** - Interactive menus, fuzzy name matching, and auto-selection
- 🧹 **Easy management** - List, start, stop, and clean up codespaces effortlessly

## Quick Start

```bash
# Install
git clone https://github.com/dbernard/spaceheater.git
cd spaceheater
./install.sh

# Create 3 pre-warmed codespaces
spaceheater create 3

# List your codespaces with status
spaceheater list

# Auto-select and start a clean codespace (opens in browser, vs code, or ssh)
spaceheater autostart

# Or interactively choose which one to start
spaceheater start
```

## Installation

### Automated Installer (Recommended)

```bash
git clone https://github.com/dbernard/spaceheater.git
cd spaceheater
./install.sh
```

The installer will check prerequisites, install to `~/.local/bin` or `/usr/local/bin`, and set up shell completions.

### Prerequisites

- [GitHub CLI (`gh`)](https://cli.github.com/) - installed and authenticated
- [`jq`](https://jqlang.github.io/jq/) - for JSON processing
- Python 3, Git, and Bash 4.0+

```bash
# macOS
brew install gh jq

# Authenticate with GitHub
gh auth login
```

For detailed installation instructions, see [Full Documentation](docs/GUIDE.md#-installation).

## Basic Commands

```bash
# Create codespaces (max 3 per invocation)
spaceheater create <count>

# List all codespaces with status
spaceheater list

# Start a codespace (interactive or by name)
spaceheater start [name]

# Auto-select and start a clean codespace
spaceheater autostart

# Stop a running codespace
spaceheater stop [name]

# Delete a specific codespace
spaceheater delete <name>

# Clean up old codespaces
spaceheater clean [days]

# Show help
spaceheater help
```

## Common Workflows

### Morning Routine
Pre-warm codespaces while you grab coffee:

```bash
spaceheater create 3  # Start building (~5-10 minutes)
# Go grab coffee - they'll auto-stop when ready
spaceheater autostart  # Later, start one instantly
```

### Feature Branch Development

```bash
SPACEHEATER_BRANCH=my-feature spaceheater create 2
spaceheater autostart
```

### Weekly Cleanup

```bash
spaceheater list
spaceheater clean 7  # Delete codespaces older than 7 days
```

## Configuration

Configure via environment variables (all optional). Spaceheater auto-detects sensible defaults from your repository and GitHub's API.

| Variable | Default | Description |
|----------|---------|-------------|
| `SPACEHEATER_REPO` | Auto-detect | Repository (owner/repo) |
| `SPACEHEATER_BRANCH` | Auto-detect | Branch to create from |
| `SPACEHEATER_CONNECT` | browser | Connection method (browser, ssh, code) |
| `SPACEHEATER_MACHINE` | Auto-detect | Machine type |

**Example:**
```bash
# Override machine type
SPACEHEATER_MACHINE=premiumLinux spaceheater create 2

# Persist settings in your shell
export SPACEHEATER_CONNECT=ssh
export SPACEHEATER_MACHINE=standardLinux
```

### Configuration Files (Optional)

Spaceheater supports optional configuration files for persistent settings without modifying your shell environment.

**File hierarchy (highest priority first):**
1. Environment variables (always take precedence)
2. `.spaceheater.conf` - Repo-specific config (in your git repo root)
3. `~/.config/spaceheater/config` - User-wide config
4. Auto-detected defaults

**Example config file:**
```bash
# ~/.config/spaceheater/config or .spaceheater.conf
REPO=myorg/myrepo
CONNECT=ssh
MACHINE=premiumLinux
BRANCH=develop
```

Note: Config files use `KEY=value` format without the `SPACEHEATER_` prefix.

**Config management commands:**
```bash
# Create a new config file interactively
spaceheater config init

# Edit your config file
spaceheater config edit

# Validate config file syntax
spaceheater config validate

# Use a specific config file for one command
spaceheater create 2 --config /path/to/custom.conf
```

For all configuration options and advanced usage, see [Full Documentation](docs/GUIDE.md#%EF%B8%8F-configuration).

## Documentation

- **[Full Guide](docs/GUIDE.md)** - Complete documentation with all features, examples, and troubleshooting
- **[Installation](docs/GUIDE.md#-installation)** - Detailed installation instructions
- **[Configuration](docs/GUIDE.md#%EF%B8%8F-configuration)** - All configuration options
- **[Troubleshooting](docs/GUIDE.md#-troubleshooting)** - Common issues and solutions
- **[Contributing](CONTRIBUTING.md)** - How to contribute to spaceheater

## Testing

```bash
# Run the full test suite (lint + unit tests)
make test

# Check syntax
make lint
```

Tests require [Bats](https://github.com/bats-core/bats-core). See [Full Documentation](docs/GUIDE.md#-testing) for details.

## Contributing

Contributions are welcome! Please see [CONTRIBUTING.md](CONTRIBUTING.md) for guidelines.

```bash
# Quick development setup
git clone https://github.com/dbernard/spaceheater.git
cd spaceheater
make test
```

## License

MIT License - see [LICENSE](LICENSE) file for details.

---

**Note:** This project is not officially affiliated with GitHub.

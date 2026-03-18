# spaceheater 🔥

> Personal pre-warming for GitHub Codespaces - your setup, instant startup

[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)
[![Version](https://img.shields.io/badge/version-1.0.0-green.svg)](https://github.com/dbernard/spaceheater/releases)

Tired of waiting 5-10 minutes for Codespaces to build? `spaceheater` creates pre-warmed codespaces in the background that start in ~30 seconds when you need them.

## ✨ Features

- 🚀 **Instant startup** - Pre-built codespaces start in ~30 seconds instead of 5-10 minutes
- 🤖 **Background building** - Let codespaces build while you work on something else
- 💰 **Cost-efficient** - Stopped codespaces cost nothing (only minimal storage)
- 🎯 **Smart selection** - Interactive menu or auto-select clean codespaces
- 🌐 **Universal access** - Connect via browser, SSH, or VS Code desktop
- 🧹 **Easy cleanup** - Bulk delete old codespaces by age
- ⚙️ **Configurable** - Respects devcontainer settings and GitHub defaults
- 🎨 **Git-aware** - Shows uncommitted changes and sync status at a glance

## 🚀 Quick Start

```bash
# Install
git clone https://github.com/dbernard/spaceheater.git
cd spaceheater
./install.sh

# Create 3 pre-warmed codespaces
spaceheater create 3

# List your codespaces with status
spaceheater list

# Auto-select and start a clean codespace (opens in browser)
spaceheater autostart

# Or interactively choose which one to start
spaceheater start
```

## 📦 Installation

### Recommended: Automated Installer

```bash
git clone https://github.com/dbernard/spaceheater.git
cd spaceheater
./install.sh
```

The installer will:
- ✅ Check prerequisites (`gh`, `python3`, `git`) and GitHub authentication
- 📁 Install to `~/.local/bin` or `/usr/local/bin`
- 🔧 Set up shell completions (bash/zsh)
- ✓ Verify the installation

**Note:** Ensure `jq` is installed before running the installer (it's required by spaceheater but not checked during installation).

**Alternative with Make:**
```bash
make install
```

### Manual Installation

If you prefer manual installation:

```bash
# Clone and add to PATH
git clone https://github.com/dbernard/spaceheater.git
echo 'export PATH="$HOME/spaceheater:$PATH"' >> ~/.zshrc
source ~/.zshrc

# Or create a symlink
sudo ln -s "$PWD/spaceheater/spaceheater" /usr/local/bin/spaceheater
```

### Prerequisites

- [GitHub CLI (`gh`)](https://cli.github.com/) - installed and authenticated
- [`jq`](https://jqlang.github.io/jq/) - for JSON processing
- Python 3 - for date calculations
- Git - for repository detection
- Bash 4.0+ - for the script itself
- GitHub Codespaces access on your repository

**Setup GitHub CLI and jq:**
```bash
# Install (macOS)
brew install gh jq

# Install (Linux)
sudo apt-get install gh jq  # Debian/Ubuntu
# See https://github.com/cli/cli/blob/trunk/docs/install_linux.md for other distros

# Authenticate with GitHub
gh auth login
```

### Verify Installation

```bash
spaceheater version
spaceheater help
```

### Uninstall

```bash
cd /path/to/spaceheater
./uninstall.sh
```

Or:
```bash
make uninstall
```

## 📖 Usage

### Commands

```
spaceheater create <count>    Create codespaces (max 3 per invocation)
spaceheater list|ls           List all codespaces with status
spaceheater start [name]      Start a codespace (interactive selection if no name)
spaceheater autostart         Auto-select and start a clean codespace
spaceheater stop [name]       Stop a running codespace
spaceheater clean [days]      Delete codespaces older than N days (default: 7)
spaceheater delete|rm <name>  Delete a specific codespace
spaceheater config            Show current configuration
spaceheater version           Show version information
spaceheater help              Show help message
```

### JSON Output Support

All spaceheater commands support JSON output for programmatic consumption and LLM integration:

```bash
# Add --json flag to any command
spaceheater list --json
spaceheater start my-codespace --json
spaceheater config --json

# Short form also supported
spaceheater list -j

# Alternative syntax
spaceheater list --output=json
```

JSON output includes:
- **Complete metadata**: All fields from GitHub API
- **Temperature classification**: hot/warm/cold/transitioning states
- **Git status**: Clean/dirty status with commit ahead/behind counts
- **Timestamps**: ISO 8601 formatted dates
- **Success/error status**: Consistent error handling

Perfect for:
- CI/CD pipelines and GitHub Actions
- LLM tool integration (Claude, GitHub Copilot)
- Scripting and automation
- Monitoring dashboards
- Bulk operations

### Create Codespaces

```bash
# Create 3 codespaces (the maximum per invocation)
spaceheater create 3

# They build in the background (~5-10 minutes)
# Then auto-stop and cost nothing until you start them
```

### List Codespaces

```bash
spaceheater list
```

The list command groups codespaces by **temperature**, showing their readiness for immediate use:

**Temperature categories:**
- 🔥 **HOT** - Running codespaces (immediately available)
- ♨️ **WARM** - Shutdown but clean & recent (≤3 days old) - quick to restart
- 🧊 **COLD** - Old or dirty codespaces - need maintenance first

**Example output:**
```
✓ Available  ✔  fuzzy-umbrella      main         [clean]            (0h ago)
○ Shutdown   ●  organic-sniffle     my-feature   [uncommitted, 2↑]  (1h ago)
○ Shutdown   ⤓  sturdy-capybara     main         [3↓]               (2h ago)
```

**Status indicators:**
- ✓ Available = Running or building (often HOT)
- ○ Shutdown = Built and ready for instant start (WARM or COLD)

**Git indicators:**
- ✔ Clean = No uncommitted changes
- ● Has changes = Uncommitted or unpushed changes
- ⤓ Behind remote = Needs pull

### Start a Codespace

```bash
# Auto-select a clean codespace and start it (opens in browser by default)
spaceheater autostart

# Interactive selection - choose from a menu
spaceheater start

# Start by exact name (no quotes needed)
spaceheater start fuzzy-umbrella-9wjgq56x74hxpp7

# Start by partial name with fuzzy matching
spaceheater start fuzzy umbrella    # matches 'fuzzy-umbrella-9wjgq56x74hxpp7'
spaceheater start organic sniffle   # matches 'organic-sniffle-...'
```

**Fuzzy Matching:**
The start command supports flexible name matching that works with partial names and spaces. No quotes needed—just type part of the codespace name. If multiple codespaces match your search, you'll see an interactive menu to select which one to start.

**Connection Methods:**

By default, codespaces open in your browser (github.dev) for universal access. You can change the connection method:

```bash
# Open in browser (default)
spaceheater autostart

# Connect via SSH for terminal access
SPACEHEATER_CONNECT=ssh spaceheater start

# Open in VS Code desktop (requires VS Code installed)
SPACEHEATER_CONNECT=code spaceheater autostart

# Set your preferred method permanently
export SPACEHEATER_CONNECT=ssh
spaceheater autostart  # Now uses SSH by default
```

**Interactive vs Auto-select:**

- `spaceheater start` - Shows a numbered menu of all codespaces for you to choose
- `spaceheater autostart` - Automatically picks a clean codespace (no uncommitted changes), fails if none available

### Stop a Codespace

```bash
# Stop the most recently used codespace
spaceheater stop

# Stop by exact name (no quotes needed)
spaceheater stop fuzzy-umbrella-9wjgq56x74hxpp7

# Stop by partial name with fuzzy matching
spaceheater stop fuzzy umbrella    # matches 'fuzzy-umbrella-9wjgq56x74hxpp7'
spaceheater stop stunning lamp     # matches 'stunning-lamp-...'
```

**Fuzzy Matching:**
Like the start command, stop supports flexible name matching with partial names and spaces. No quotes needed. If multiple codespaces match your search, you'll see an interactive menu to select which one to stop.

### Delete a Codespace

```bash
# Delete by exact name (with confirmation prompt)
spaceheater delete fuzzy-umbrella-9wjgq56x74hxpp7

# Delete by partial name with fuzzy matching
spaceheater delete fuzzy umbrella    # matches 'fuzzy-umbrella-9wjgq56x74hxpp7'
spaceheater delete organic           # matches 'organic-sniffle-...'
```

**Fuzzy Matching:**
The delete command supports the same flexible name matching as start and stop. If multiple codespaces match your search, you'll see an interactive menu to select which one to delete. A confirmation prompt will then ask you to confirm before deleting.

**Safety:**
Unlike the `clean` command which can delete multiple codespaces at once, `delete` targets a single codespace and always asks for confirmation before proceeding.

### Clean Up Old Codespaces

```bash
# Delete codespaces older than 7 days
spaceheater clean

# Delete codespaces older than 14 days
spaceheater clean 14
```

### View Configuration

```bash
spaceheater config
```

Shows current settings, detected repository, and devcontainer configuration.

## ⚙️ Configuration

Spaceheater offers flexible configuration through environment variables and optional configuration files.

### Configuration Variables

All configuration is optional - spaceheater auto-detects sensible defaults:

| Variable | Default | Description |
|----------|---------|-------------|
| `SPACEHEATER_REPO` | Auto-detect from git | Repository (owner/repo format) |
| `SPACEHEATER_BRANCH` | Auto-detect from repo | Branch to create from |
| `SPACEHEATER_CONNECT` | browser | Connection method (browser, ssh, or code) |
| `SPACEHEATER_MACHINE` | Auto-detect from API | Machine type (basicLinux, basicLinux32gb, standardLinux, standardLinux32gb, premiumLinux, premiumLinux32gb, largePremiumLinux) |
| `SPACEHEATER_RETENTION` | GitHub default | How long before auto-deletion (e.g., 168h, 720h) |
| `SPACEHEATER_IDLE_TIMEOUT` | GitHub/org default | Idle timeout before auto-stop (e.g., 30m, 1h) |
| `SPACEHEATER_DEVCONTAINER_PATH` | Auto-detect | Path to devcontainer.json |
| `SPACEHEATER_LOCATION` | Auto-detect | Azure region (EastUs, WestEurope, SoutheastAsia) |
| `SPACEHEATER_DISPLAY_NAME` | GitHub-generated | Custom display name prefix |
| `SPACEHEATER_DEBUG` | false | Enable debug output |
| `NO_COLOR` | (not set) | Disable colored output when set to any value |
| `SPACEHEATER_UI_STYLE` | Auto-detect | Force UI mode: plain or simple for limited terminals |

### Configuration Files (Optional)

Configuration files provide persistent settings without cluttering your shell environment. **Files are completely optional** - environment variables and auto-detection still work as before.

#### File Locations and Precedence

Spaceheater checks for configuration files in this order (highest priority first):

1. **Environment variables** - Always take precedence over config files
2. **`.spaceheater.conf`** - Repo-specific config in your git repository root
3. **`~/.config/spaceheater/config`** - User-wide config for all projects
4. **Auto-detected defaults** - From git, GitHub API, and devcontainer.json

#### Config File Format

Config files use simple `KEY=value` format without the `SPACEHEATER_` prefix:

```bash
# ~/.config/spaceheater/config or .spaceheater.conf

# Repository settings
REPO=myorg/myrepo
BRANCH=develop

# Connection preferences
CONNECT=ssh
MACHINE=premiumLinux

# Advanced options
RETENTION=168h
IDLE_TIMEOUT=30m
LOCATION=WestEurope
DEVCONTAINER_PATH=.devcontainer/python/devcontainer.json
DISPLAY_NAME=my-codespace

# Debug mode
DEBUG=false
```

**Important notes:**
- Lines starting with `#` are comments
- Blank lines are ignored
- No quotes needed around values
- Keys are case-insensitive (REPO, repo, and Repo all work)
- Use `KEY=value` format, not `SPACEHEATER_KEY=value`

#### Example: Complete Config File

```bash
# Complete configuration example with all available options
# Save as ~/.config/spaceheater/config or .spaceheater.conf

# ==============================================================================
# Repository Configuration
# ==============================================================================

# Target repository (format: owner/repo)
# Example: REPO=facebook/react
REPO=myorg/myrepo

# Default branch to create codespaces from
# Example: BRANCH=main, develop, staging
BRANCH=develop

# ==============================================================================
# Connection Settings
# ==============================================================================

# How to connect when starting codespaces
# Options: browser, ssh, code
# - browser: Opens in github.dev (default, works everywhere)
# - ssh: Opens SSH connection in terminal (good for CLI workflows)
# - code: Opens in VS Code desktop (requires VS Code installed)
CONNECT=ssh

# ==============================================================================
# Machine Resources
# ==============================================================================

# Machine type for codespaces
# Options: basicLinux, basicLinux32gb, standardLinux, standardLinux32gb,
#          premiumLinux, premiumLinux32gb, largePremiumLinux
# Tip: Use basicLinux for light work, premiumLinux for heavy builds
MACHINE=premiumLinux

# ==============================================================================
# Lifecycle Settings
# ==============================================================================

# Retention period before auto-deletion
# Format: hours (e.g., 168h = 7 days, 720h = 30 days)
# Default: GitHub organization setting
RETENTION=168h

# Idle timeout before auto-stop
# Format: minutes or hours (e.g., 30m, 1h, 2h)
# Default: GitHub organization setting
IDLE_TIMEOUT=30m

# ==============================================================================
# Advanced Options
# ==============================================================================

# Azure region for codespace hosting
# Options: EastUs, WestEurope, SoutheastAsia
# Choose region closest to you for lower latency
LOCATION=WestEurope

# Path to devcontainer.json (for monorepos)
# Example: DEVCONTAINER_PATH=.devcontainer/backend/devcontainer.json
# DEVCONTAINER_PATH=.devcontainer.json

# Custom display name prefix for created codespaces
# Example: DISPLAY_NAME=feature-work
# DISPLAY_NAME=

# ==============================================================================
# Debug Settings
# ==============================================================================

# Enable debug output for troubleshooting
# Options: true, false
DEBUG=false
```

#### Config Management Commands

```bash
# Create a new config file interactively
spaceheater config init

# Edit your config file (uses $EDITOR or falls back to vi)
spaceheater config edit

# Validate config file syntax
spaceheater config validate

# Show current effective configuration (merged from all sources)
spaceheater config
```

#### Per-Command Config Override

Use the `--config` flag to use a different config file for a single command:

```bash
# Use custom config for this command only
spaceheater create 2 --config /path/to/custom.conf

# Different configs for different projects
spaceheater create 1 --config ~/configs/work-project.conf
spaceheater create 1 --config ~/configs/side-project.conf

# Test a new config without committing it
spaceheater list --config /tmp/test.conf
```

Environment variables still override config file settings when using `--config`.

#### How Config Files Interact with Environment Variables

Environment variables always take precedence over config files. This lets you:

1. Set defaults in config files
2. Override for specific commands with env vars

**Example:**

```bash
# Config file sets: MACHINE=standardLinux, CONNECT=browser

# Use config file defaults
spaceheater create 2

# Override machine type for this command only
SPACEHEATER_MACHINE=premiumLinux spaceheater create 1

# Override connection method for this session
export SPACEHEATER_CONNECT=ssh
spaceheater start  # Uses SSH, but machine type still from config
```

#### Repo-Specific vs User-Wide Config

**Use `.spaceheater.conf` in repo root for:**
- Project-specific settings (machine type, devcontainer path)
- Team-shared defaults (commit to git for consistency)
- Overriding user defaults for specific projects

**Use `~/.config/spaceheater/config` for:**
- Personal preferences (connection method, location)
- Defaults across all projects
- Settings you don't want to commit to git

**Example workflow:**

```bash
# User config: ~/.config/spaceheater/config
CONNECT=ssh
LOCATION=WestEurope

# Project config: /path/to/project/.spaceheater.conf
REPO=myorg/backend
MACHINE=premiumLinux
BRANCH=develop

# Result: Uses SSH and WestEurope from user config,
#         but premiumLinux and develop branch from project config
```

### Configuration Philosophy

Spaceheater automatically detects sensible defaults from your repository and GitHub's API, while allowing overrides when needed.

**Machine Type Auto-Detection:**
- **No `SPACEHEATER_MACHINE` set** → Queries GitHub API for available machine types and uses the first one (respects devcontainer `hostRequirements`)
- **`SPACEHEATER_MACHINE` set** → Overrides with your specified value
- **Detection fails** → Shows clear error message with instructions to set manually

This ensures codespaces are created with appropriate resources without requiring manual configuration, while preventing unexpected costs from expensive machine types.

### Example Configurations

**Using environment variables:**

```bash
# Use repository defaults (recommended)
spaceheater create 3

# Override machine type for heavier workload
SPACEHEATER_MACHINE=premiumLinux spaceheater create 2

# Create on a feature branch
SPACEHEATER_BRANCH=my-feature spaceheater create 2

# Use specific devcontainer in a monorepo
SPACEHEATER_DEVCONTAINER_PATH=.devcontainer/python/devcontainer.json spaceheater create 1

# Create in specific region for lower latency
SPACEHEATER_LOCATION=WestEurope spaceheater create 1

# Multiple overrides
SPACEHEATER_MACHINE=standardLinux SPACEHEATER_RETENTION=168h spaceheater create 1
```

**Persist settings in your shell:**

```bash
# Add to ~/.zshrc or ~/.bashrc
export SPACEHEATER_REPO=myorg/myrepo
export SPACEHEATER_CONNECT=ssh  # Use SSH by default
export SPACEHEATER_MACHINE=premiumLinux
```

**Using config files:**

```bash
# Create user-wide config
spaceheater config init
# Choose: 1) User-wide config (~/.config/spaceheater/config)

# Create repo-specific config
cd /path/to/project
spaceheater config init
# Choose: 2) Repo-specific config (.spaceheater.conf)

# Now commands use config automatically
spaceheater create 2  # Uses settings from config file

# Override config for one command
SPACEHEATER_MACHINE=basicLinux spaceheater create 1
```

### Troubleshooting Config Issues

**Check which config file is being used:**

```bash
spaceheater config
# Shows: Config file: ~/.config/spaceheater/config
```

**Validate config syntax:**

```bash
spaceheater config validate
# Reports any syntax errors or invalid values
```

**Config not being loaded:**

1. Verify file location:
   ```bash
   ls -la ~/.config/spaceheater/config
   ls -la .spaceheater.conf
   ```

2. Check file format (no `SPACEHEATER_` prefix in config files):
   ```bash
   # Wrong:
   SPACEHEATER_REPO=owner/repo

   # Correct:
   REPO=owner/repo
   ```

3. Look for syntax errors:
   ```bash
   # Wrong:
   REPO = owner/repo  # No spaces around =
   REPO="owner/repo"  # No quotes needed

   # Correct:
   REPO=owner/repo
   ```

**Environment variable not overriding config:**

Make sure you're using the full `SPACEHEATER_` prefix with environment variables:

```bash
# Wrong:
REPO=other/repo spaceheater create 1

# Correct:
SPACEHEATER_REPO=other/repo spaceheater create 1
```

**Debug config loading:**

```bash
# Enable debug mode to see config resolution
SPACEHEATER_DEBUG=true spaceheater config
```

## 💡 Examples & Workflows

### Morning Routine

Pre-warm codespaces while you grab coffee:

```bash
# Create 3 codespaces
spaceheater create 3

# Go grab coffee (~5-10 minutes)
# They'll auto-stop when ready

# Later, start one instantly in your browser
spaceheater autostart  # ~30 seconds, fully built

# Or SSH directly into one
SPACEHEATER_CONNECT=ssh spaceheater autostart
```

### Feature Branch Development

```bash
# Create codespaces on your feature branch
SPACEHEATER_BRANCH=my-feature spaceheater create 2

# Start one when ready
spaceheater autostart
```

### Weekly Maintenance

```bash
# List all codespaces
spaceheater list

# Clean up old ones
spaceheater clean 7
```

### Multi-Repository Workflow

```bash
# Check config for current repo
cd ~/projects/repo1
spaceheater config

# Create for a different repo
SPACEHEATER_REPO=myorg/repo2 spaceheater create 2

# Or set default repo
export SPACEHEATER_REPO=myorg/repo2
spaceheater create 2
```

## 💰 Cost Optimization

- **Stopped codespaces are free** - Only pay for minimal storage
- **Codespaces auto-stop** - After idle timeout (default: GitHub/org setting)
- **Initial build costs compute** - ~5-10 minutes of VM time
- **After auto-stop, they're free** - Until you start them again
- **Set retention periods** - Use `SPACEHEATER_RETENTION` to avoid accumulation
- **Regular cleanup** - Use `spaceheater clean` to remove old codespaces

**Cost comparison:**
- Traditional: 5-10 min build time every session = $$$ per start
- Spaceheater: 5-10 min build once, instant starts = $ initial + free thereafter

## 🔧 Troubleshooting

### "Not authenticated with GitHub"
```bash
gh auth login
```

### "Unable to detect repository"
```bash
# Option 1: Run from within your git repository
cd /path/to/your/repo
spaceheater create 1

# Option 2: Set repository explicitly
export SPACEHEATER_REPO=owner/repo
spaceheater create 1
```

### "GitHub CLI (gh) is required"
```bash
# macOS
brew install gh

# Linux - see https://github.com/cli/cli/blob/trunk/docs/install_linux.md
```

### "Python 3 is required"
```bash
# macOS (usually pre-installed)
python3 --version

# Linux
sudo apt-get install python3  # Debian/Ubuntu
sudo yum install python3       # RHEL/CentOS
```

### "jq is required"
```bash
# macOS
brew install jq

# Linux
sudo apt-get install jq  # Debian/Ubuntu
sudo yum install jq      # RHEL/CentOS
```

### "No clean codespaces available"
This means all your codespaces have uncommitted changes. Options:
```bash
# Use interactive selection to choose any codespace
spaceheater start

# Create new clean codespaces
spaceheater create 1
```

### "No codespaces found"
```bash
# Create some first
spaceheater create 1
```

### Codespace stuck in "Starting" state
Wait 30-60 seconds - it's being provisioned. Check status:
```bash
spaceheater list
```

### See all available commands
```bash
spaceheater help
```

## 🧪 Testing

Spaceheater uses the [Bats](https://github.com/bats-core/bats-core) testing framework for its test suite. Tests ensure core functionality remains stable during development.

### Running Tests

```bash
# Run the full test suite (lint + unit tests)
make test

# Just check syntax
make lint

# Clean test artifacts
make clean
```

### Installing Bats (Optional)

The test suite will fall back to basic smoke tests if Bats is not installed, but for full testing capabilities:

```bash
# macOS
brew install bats-core

# Ubuntu/Debian
apt-get install bats

# npm (cross-platform)
npm install -g bats

# From source
git clone https://github.com/bats-core/bats-core.git
cd bats-core
./install.sh /usr/local
```

### Test Coverage

The test suite covers:
- ✅ All command functionality (create, list, start, stop, etc.)
- ✅ Configuration and environment variable handling
- ✅ Input validation and error handling
- ✅ Mock GitHub API interactions
- ✅ Git repository detection

## 🤝 Contributing

Contributions are welcome! Please see [CONTRIBUTING.md](CONTRIBUTING.md) for guidelines.

**Quick development setup:**

```bash
git clone https://github.com/dbernard/spaceheater.git
cd spaceheater

# Check prerequisites
make check

# Run tests (requires Bats for full suite)
make test

# Check syntax
make lint
```

**Before submitting a PR:**
1. Run `make test` to ensure all tests pass
2. Add tests for any new functionality
3. Update documentation as needed

## 📄 License

MIT License - see [LICENSE](LICENSE) file for details.

## 🙏 Acknowledgments

Built with:
- [GitHub CLI](https://cli.github.com/) - Official GitHub command-line tool
- [GitHub Codespaces](https://github.com/features/codespaces) - Cloud-hosted development environments

---

**Note:** This project is not officially affiliated with GitHub.

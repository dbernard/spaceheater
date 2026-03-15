# Spaceheater - GitHub Codespaces Management Tool

## Project Overview
Spaceheater is a Bash CLI tool for managing GitHub Codespaces efficiently. It provides commands to create, list, start, stop, and clean up codespaces with an intuitive temperature-based visualization system (HOT/WARM/COLD) to help users identify and manage their codespace resources.

## Core Architecture

### Language & Runtime
- **Primary Language**: Pure Bash 4.0+ (967 lines)
- **Secondary**: Python 3 (for ISO 8601 date calculations)
- **Execution**: Direct script execution, no compilation needed
- **Platform**: macOS and Linux compatible

### Dependencies
**Required:**
- `gh` (GitHub CLI) - Main interface to GitHub Codespaces API
- `python3` - Date/time calculations
- `bash` 4.0+ - Script runtime
- `git` - Repository detection

**Optional:**
- `jq` - Enhanced JSON processing (fallback to python if unavailable)

### Project Structure
```
spaceheater/
├── spaceheater           # Main executable (967 lines)
├── install.sh           # Installation script
├── uninstall.sh         # Uninstallation script
├── Makefile            # Build automation
├── completions/        # Shell completions
│   ├── _spaceheater    # Zsh completions
│   └── spaceheater.bash # Bash completions
├── test/              # Test suite
│   ├── spaceheater.bats # Bats tests
│   ├── test_helper.bash # Test utilities & mocks
│   └── fixtures/       # Test data
└── docs/              # Documentation
    ├── INSTALL.md     # Installation guide
    └── WISHLIST.md    # Feature wishlist
```

## Command Reference

### Core Commands
- `create <N>` - Create N codespaces (max 5 per batch)
- `list` - List all codespaces with temperature visualization
- `start [name]` - Start a codespace (interactive if no name)
- `autostart` - Auto-select and start the best available codespace
- `stop` - Stop the running codespace
- `clean [days]` - Delete codespaces older than N days (default: 7)
- `delete <name>` - Delete a specific codespace
- `config` - Display current configuration
- `version` - Show version information
- `help` - Display help message

### Temperature System
Codespaces are categorized by idle time:
- **🔥 HOT** - Active within last 5 minutes
- **♨️ WARM** - Idle 5-30 minutes
- **❄️ COLD** - Idle over 30 minutes

## Development Workflow

### Making Changes
1. Edit the `spaceheater` script
2. Check syntax: `make lint` or `bash -n spaceheater`
3. Run tests: `make test`
4. Manual verification: `./spaceheater help`
5. Commit with descriptive message

### Testing Strategy
- **Framework**: Bats (Bash Automated Testing System)
- **Test File**: `test/spaceheater.bats`
- **Mocks**: `test/test_helper.bash` provides mocks for `gh`, `git`, `jq`
- **Coverage**: All commands, error handling, input validation

### Configuration
Environment variables (with defaults):
- `SPACEHEATER_REPO` - Target repository (auto-detected from git)
- `SPACEHEATER_BRANCH` - Branch to use (auto-detected)
- `SPACEHEATER_MACHINE` - Machine type (basicLinux32gb)
- `SPACEHEATER_CONNECT` - Connection method (browser/ssh/code)
- `SPACEHEATER_RETENTION` - Auto-deletion days (30)
- `SPACEHEATER_IDLE_TIMEOUT` - Idle timeout minutes (30)
- `SPACEHEATER_DEVCONTAINER_PATH` - Path to devcontainer.json
- `SPACEHEATER_LOCATION` - Azure region (WestUs2)
- `SPACEHEATER_DISPLAY_NAME` - Custom name prefix
- `SPACEHEATER_DEBUG` - Enable debug output (1 to enable)
- `NO_COLOR` - Disable colored output
- `SPACEHEATER_UI_STYLE` - Force UI mode (plain/simple)

## Key Implementation Details

### Error Handling
- Strict mode: `set -euo pipefail`
- Graceful degradation for missing optional tools
- User-friendly error messages with context
- Exit codes: 0 (success), 1 (error), 2 (usage error)

### UI Features
- Unicode support with ASCII fallback
- Color output with NO_COLOR support
- Interactive fuzzy matching for codespace selection
- Progress indicators for long operations
- Temperature-based visualization

### Git Integration
- Auto-detects repository from current directory
- Extracts owner/repo from remote URL
- Handles both HTTPS and SSH remote formats
- Caches repository ID for performance

### GitHub API Usage
- All operations via `gh` CLI (no direct API calls)
- Handles pagination for large codespace lists
- Robust error handling for API failures
- Rate limiting awareness

## Code Patterns

### Function Structure
```bash
cmd_name() {
  local var1="$1"
  local var2="${2:-default}"

  # Validation
  [[ -z "$var1" ]] && error "Missing required argument"

  # Implementation
  result=$(command)

  # Output
  echo "$result"
}
```

### Error Handling Pattern
```bash
if ! command; then
  error "Failed to execute command"
  return 1
fi
```

### Mock-friendly Design
External commands are wrapped in functions for easy mocking:
- Use `gh` commands that can be mocked in tests
- Avoid direct file system operations where possible
- Keep side effects isolated

## Important Notes

1. **Version**: Currently at 1.0.0 (stable release)
2. **License**: MIT License
3. **Compatibility**: Bash 4.0+ required (associative arrays)
4. **Safety**: No destructive operations without confirmation
5. **Testing**: Comprehensive test coverage with Bats
6. **Documentation**: Extensive inline comments and help text

## Common Tasks

### Adding a New Command
1. Add function `cmd_newname()` in main script
2. Add to help text in `cmd_help()`
3. Add case in main dispatcher
4. Add tests in `test/spaceheater.bats`
5. Update completions if needed
6. Document in README.md

### Debugging
- Set `SPACEHEATER_DEBUG=1` for verbose output
- Check `~/.spaceheater/cache/` for cached data
- Use `bash -x spaceheater` for trace mode
- Review test output with `make test`

### Release Process
1. Update version in `spaceheater` script
2. Run full test suite
3. Update README.md and docs
4. Create git tag with version
5. Update installation documentation
# Spaceheater

## What

A pure Bash CLI tool for pre-warming GitHub Codespaces. Instead of waiting 5-10 minutes for a codespace to build, spaceheater pre-creates them in the background so they start in ~30 seconds.

Stopped codespaces cost nothing (only storage), making this a cost-efficient way to eliminate build wait times.

## Quick Reference

```bash
make check         # Verify prerequisites (gh, python3, bash 4.0+, git)
make lint          # Syntax check + ShellCheck
make test          # Lint + Bats test suite
./spaceheater help # CLI usage
```

## Dependencies

| Dependency | Required | Purpose |
|-----------|----------|---------|
| `gh` (GitHub CLI) | Yes | All Codespaces API access (no direct API calls) |
| `python3` | Yes | Date calculations, JSON fallback |
| `bash` 4.0+ | Yes | Runtime (needs associative arrays) |
| `git` | Yes | Repository detection |
| `jq` | No | JSON processing (falls back to python3) |

Testing additionally requires [bats-core](https://github.com/bats-core/bats-core).

## Repo Map

```
spaceheater              # Main executable (~2500 lines, single-file CLI)
install.sh               # Installer with prerequisite checks
uninstall.sh             # Uninstaller
Makefile                 # check, lint, test, install, uninstall, clean

completions/
  spaceheater.bash       # Bash completions
  _spaceheater           # Zsh completions

test/
  spaceheater.bats       # Bats test suite (comprehensive)
  test_helper.bash       # Mocks for gh, git, jq + test utilities
  fixtures/              # Test fixture data (codespaces.json)

docs/
  GUIDE.md               # Full user guide (advanced features, workflows)
  INSTALL.md             # Installation guide
  agent/                 # Deep-dive docs for coding agents & contributors
    ARCHITECTURE.md      # Code organization, adding commands, API access
    STYLE.md             # Bash coding standards, patterns, conventions
    TESTING.md           # Testing strategy, writing tests, debugging

.spaceheater.conf.example  # Example configuration file
```

**Deeper documentation** for contributors:
- [docs/agent/ARCHITECTURE.md](docs/agent/ARCHITECTURE.md) - Architecture, code organization, adding commands
- [docs/agent/STYLE.md](docs/agent/STYLE.md) - Bash coding standards, patterns, conventions
- [docs/agent/TESTING.md](docs/agent/TESTING.md) - Testing strategy, writing tests, debugging failures

## Architecture

The entire CLI is a single Bash script (`spaceheater`). Code is organized in sections:

1. **Strict mode & config loading** - `set -euo pipefail`, config file hierarchy
2. **Terminal & UI setup** - Colors, unicode detection, `NO_COLOR` support
3. **Repository config** - Git remote parsing, repo ID caching (`~/.spaceheater/cache/`)
4. **JSON output utilities** - All commands support `--json` for programmatic use
5. **Helper functions** - Logging (`error`, `info`, `warn`, `debug`), input validation
6. **Command functions** - Each command is `cmd_<name>()` (e.g., `cmd_create`, `cmd_list`)
7. **Main dispatcher** - Routes subcommands to `cmd_*` functions

### Commands

| Command | Purpose |
|---------|---------|
| `create <N>` | Create N pre-warmed codespaces (max 3 per batch) |
| `list` / `ls` | List codespaces with temperature status |
| `start [name]` | Start a codespace (interactive selection if no name) |
| `autostart` | Auto-select and start the best available codespace |
| `stop [name]` | Stop a codespace (`stop all` supported) |
| `clean [days]` | Delete codespaces older than N days (default: 7) |
| `delete` / `rm` | Delete a specific codespace |
| `config [init\|edit\|validate]` | Manage configuration |
| `schedule [set\|list\|remove\|status]` | Schedule automatic codespace pre-warming (macOS launchd) |

### Temperature System

Codespaces are classified by state and age:
- **HOT** - Available/Running, immediately usable
- **WARM** - Shutdown, clean, <3 days old (quick restart)
- **COLD** - Shutdown, old or dirty (needs maintenance)
- **TRANSITIONING** - Starting or stopping

### Configuration Precedence (highest first)

1. Environment variables (`SPACEHEATER_REPO`, `SPACEHEATER_BRANCH`, etc.)
2. Repo config (`.spaceheater.conf` in git root)
3. User config (`~/.config/spaceheater/config`)
4. System config (`/etc/spaceheater/config`)
5. Auto-detected defaults

See `.spaceheater.conf.example` for all available options.

## Development Workflow

### Making Changes

1. Edit the `spaceheater` script
2. Run `make lint` (syntax + ShellCheck)
3. Run `make test` (full Bats suite)
4. Manual smoke test: `./spaceheater help`, `./spaceheater version`

### Adding a New Command

1. Add `cmd_newname()` function in the main script
2. Add case to the main dispatcher
3. Update `cmd_help()` output
4. Add tests in `test/spaceheater.bats`
5. Update shell completions in `completions/`

### Testing

Tests use **Bats** with mocked external commands. The test helper (`test/test_helper.bash`) provides mock functions for `gh`, `git`, and `jq` so tests run without network access or real codespaces.

```bash
# Run full suite
make test

# Run specific test
bats test/spaceheater.bats --filter "test name pattern"

# Debug
SPACEHEATER_DEBUG=1 make test
bash -x ./spaceheater <command>
```

### Commits

Use conventional commit types: `feat:`, `fix:`, `docs:`, `test:`, `refactor:`, `style:`, `chore:`.

## Keeping Docs in Sync

When making changes, update the corresponding documentation:

- **Adding/removing/renaming a command** → update the Commands table above, `cmd_help()`, shell completions, and `docs/agent/ARCHITECTURE.md`
- **Changing a `cmd_*` function signature or behavior** → update `docs/agent/ARCHITECTURE.md`
- **Adding/changing config options or env vars** → update the Configuration Precedence section above and `.spaceheater.conf.example`
- **Changing test patterns or mock infrastructure** → update `docs/agent/TESTING.md`
- **Changing code conventions** → update `docs/agent/STYLE.md`

If you're unsure whether a doc needs updating, check the repo map above — if the area you changed has a corresponding doc, review it.

## Key Patterns

- **Strict mode**: `set -euo pipefail` everywhere
- **All variables quoted**: `"$var"` not `$var`
- **Local declarations**: All function variables use `local`
- **Graceful degradation**: `jq` optional, falls back to python3
- **Mock-friendly**: External commands wrapped for testability
- **2-space indentation**, no tabs

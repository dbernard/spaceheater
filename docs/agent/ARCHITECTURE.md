# Spaceheater - Architecture & Development Reference

> This is a deep-dive companion to the root [CLAUDE.md](../../CLAUDE.md). Start there for an overview.

## Code Organization

The main `spaceheater` script (~2500 lines) is organized into these sections, in order:

### 1. Configuration File System
- `find_config_file()` - Searches config hierarchy (repo > user > system)
- `load_config_file()` - Parses KEY=value format, applies to env vars
- `validate_config_file()` - Syntax validation for config files

### 2. Core Configuration
- `VERSION` constant and cache directory (`~/.spaceheater/cache/`)
- Environment variable defaults with `${VAR:-default}` pattern

### 3. Terminal & UI
- Unicode/ASCII detection with fallback
- Color support respecting `NO_COLOR` and `SPACEHEATER_UI_STYLE`
- Output functions: `error()`, `info()`, `success()`, `warn()`, `debug()`
- Progress indicators and spinners

### 4. Repository Integration
- `detect_repo()` - Extracts owner/repo from git remote (HTTPS & SSH)
- `get_repo_id()` - Fetches and caches GitHub repo ID
- Git status detection (clean/dirty, ahead/behind)

### 5. JSON Output
- `json_output()` - Structured JSON for `--json` flag
- All commands produce consistent JSON schema with metadata, timestamps

### 6. Command Functions
Each command follows the pattern `cmd_<name>()`:

| Function | Notes |
|----------|-------|
| `cmd_create` | Background creation via `gh codespace create`, max 3 per batch |
| `cmd_list` | Temperature classification, git status, tabular + JSON output |
| `cmd_start` | Interactive fuzzy-match selection or direct name |
| `cmd_autostart` | Prioritizes HOT > WARM, selects best candidate |
| `cmd_stop` | Supports `stop all` for batch operations |
| `cmd_clean` | Age-based cleanup with confirmation |
| `cmd_delete` | Single codespace deletion with confirmation |
| `cmd_config` | Subcommands: show, init, edit, validate |
| `cmd_version` | Version display |
| `cmd_help` | Usage text |

### 7. Main Dispatcher
A `case` statement routing the first argument to `cmd_*` functions. Aliases: `ls` -> `list`, `rm` -> `delete`.

## Adding a New Command

1. **Write the function** - Add `cmd_newname()` following existing patterns:
   - Validate inputs first
   - Use `local` for all variables
   - Support `--json` output if the command returns data
   - Use `error()`/`info()`/`success()` for output

2. **Wire it up** - Add a case in the main dispatcher at the bottom of the script

3. **Update help** - Add to `cmd_help()` output

4. **Add tests** - Write Bats tests covering:
   - Happy path
   - Error cases (missing args, invalid input)
   - Edge cases
   - JSON output mode

5. **Update completions** - Add to both `completions/spaceheater.bash` and `completions/_spaceheater`

## GitHub API Access

All GitHub operations go through the `gh` CLI - there are no direct API calls. Key commands used:

```bash
gh codespace create    # Create a codespace
gh codespace list      # List codespaces (JSON output)
gh codespace stop      # Stop a codespace
gh codespace delete    # Delete a codespace
gh codespace ssh       # SSH into a codespace
gh codespace code      # Open in VS Code
gh api repos/{owner}/{repo}  # Get repo metadata (cached)
```

## Caching

- **Repo ID**: Cached in `~/.spaceheater/cache/` to avoid repeated API calls
- Cache is keyed by owner/repo string
- No TTL - cache is simple and persistent

## Exit Codes

- `0` - Success
- `1` - Error (API failure, invalid state, etc.)
- `2` - Usage error (bad arguments, missing required input)

## Debugging

```bash
SPACEHEATER_DEBUG=1 ./spaceheater list   # Verbose debug output
bash -x ./spaceheater list               # Bash trace mode
```
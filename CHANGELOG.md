# Changelog

All notable changes to spaceheater will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.2.0] - 2026-03-31

### Added
- New `schedule` command for automatic codespace pre-warming via macOS launchd
  - `schedule set <count>` with `--preset` (weekday-morning, daily) or custom `--hour`/`--minute`/`--weekday`
  - `schedule list` to view active schedules
  - `schedule remove` to delete schedules
  - `schedule status` to check schedule health
  - `schedule run` for manual trigger of scheduled pre-warming
- Comprehensive `--json` output support for all commands
  - Supports `--json`, `-j`, and `--output=json` flags
  - Structured JSON output with consistent schema across commands

### Changed
- Reorganized documentation with dedicated agent docs (`docs/agent/`)
- Migrated wishlist tracking from WISHLIST.md to GitHub Issues

### Fixed
- Improved error handling for previously masked return values across the codebase
- Fixed installer to support Homebrew completion paths and removed unnecessary sudo usage
- Resolved all ShellCheck warnings across shell scripts

## [1.1.0] - 2026-03-17

### Added
- Configuration file support for persistent settings without shell environment modifications
  - System-wide config: `/etc/spaceheater/config`
  - User-wide config: `~/.config/spaceheater/config`
  - Repository-specific config: `.spaceheater.conf`
  - Command-line override: `--config=<file>`
- New `config` subcommands for configuration management:
  - `spaceheater config` - Show current configuration
  - `spaceheater config init` - Create a config file template interactively
  - `spaceheater config edit` - Edit your config file
  - `spaceheater config validate` - Validate config file syntax
- `stop all` command to stop all running codespaces at once
- Example configuration file `.spaceheater.conf.example` with comprehensive documentation

### Changed
- Improved codespace state handling with clearer status indicators
- Enhanced autostart command to prioritize HOT codespaces over WARM when available
- Reorganized documentation for better clarity
- Updated tagline to "Personal pre-warming for GitHub Codespaces - your setup, instant startup"

### Fixed
- Fixed codespace creation and command consistency issues
- Fixed empty config array handling when running with `set -u` (nounset mode)
- Fixed autostart prioritization logic to prefer actively running codespaces

### Documentation
- Comprehensive documentation overhaul in docs/GUIDE.md
- Added CONTRIBUTING.md with contribution guidelines
- Enhanced README.md with configuration file documentation
- Added testing documentation

## [1.0.0] - 2025-03-13

### Added
- Initial release of spaceheater
- Core commands: create, list, start, stop, delete, clean
- Auto-selection with `autostart` command
- Temperature-based codespace visualization (HOT, WARM, COLD)
- Interactive fuzzy name matching for commands
- Environment variable configuration (SPACEHEATER_REPO, SPACEHEATER_BRANCH, etc.)
- Shell completion support for bash and zsh
- Comprehensive Bats test suite
- Automated installer and uninstaller scripts
- Full documentation in docs/GUIDE.md

[1.2.0]: https://github.com/dbernard/spaceheater/compare/v1.1.0...v1.2.0
[1.1.0]: https://github.com/dbernard/spaceheater/compare/v1.0.0...v1.1.0
[1.0.0]: https://github.com/dbernard/spaceheater/releases/tag/v1.0.0

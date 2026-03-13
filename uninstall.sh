#!/usr/bin/env bash
#
# spaceheater uninstaller
# Removes spaceheater from standard installation locations

set -euo pipefail

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

info() {
  echo -e "${BLUE}==>${NC} $*"
}

success() {
  echo -e "${GREEN}✓${NC} $*"
}

error() {
  echo -e "${RED}Error:${NC} $*" >&2
  exit 1
}

warn() {
  echo -e "${YELLOW}Warning:${NC} $*"
}

# Find installed spaceheater
find_installation() {
  local spaceheater_path=$(command -v spaceheater 2>/dev/null || echo "")

  if [ -z "$spaceheater_path" ]; then
    # Not in PATH, check common locations
    if [ -f "$HOME/.local/bin/spaceheater" ]; then
      echo "$HOME/.local/bin/spaceheater"
    elif [ -f "/usr/local/bin/spaceheater" ]; then
      echo "/usr/local/bin/spaceheater"
    else
      echo ""
    fi
  else
    echo "$spaceheater_path"
  fi
}

# Remove spaceheater
remove_installation() {
  local install_path="$1"
  local install_dir=$(dirname "$install_path")

  info "Removing: $install_path"

  if [ -w "$install_dir" ]; then
    rm -f "$install_path"
  else
    sudo rm -f "$install_path"
  fi

  success "Removed $install_path"
}

# Remove completions
remove_completions() {
  local removed=0

  # Bash completions
  if [ -f "$HOME/.local/share/bash-completion/completions/spaceheater" ]; then
    rm -f "$HOME/.local/share/bash-completion/completions/spaceheater"
    success "Removed bash completions"
    removed=1
  fi

  if [ -f "/usr/local/etc/bash_completion.d/spaceheater" ]; then
    if [ -w "/usr/local/etc/bash_completion.d" ]; then
      rm -f "/usr/local/etc/bash_completion.d/spaceheater"
    else
      sudo rm -f "/usr/local/etc/bash_completion.d/spaceheater"
    fi
    success "Removed bash completions"
    removed=1
  fi

  if [ $removed -eq 0 ]; then
    info "No completions found to remove"
  fi
}

# Main uninstallation
main() {
  echo
  info "spaceheater uninstaller"
  echo

  # Find installation
  local install_path=$(find_installation)

  if [ -z "$install_path" ]; then
    warn "spaceheater is not installed (not found in PATH or common locations)"
    echo
    info "Common installation locations checked:"
    echo "  - ~/.local/bin/spaceheater"
    echo "  - /usr/local/bin/spaceheater"
    exit 0
  fi

  info "Found spaceheater at: $install_path"
  echo

  # Confirm uninstallation
  read -p "Uninstall spaceheater? [y/N] " -n 1 -r
  echo

  if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    info "Uninstallation cancelled"
    exit 0
  fi

  # Remove the binary
  remove_installation "$install_path"

  # Remove completions
  remove_completions

  echo
  success "spaceheater has been uninstalled"
  echo
  info "Note: If you added spaceheater to your shell config (PATH/alias),"
  info "you may want to remove those lines manually from:"
  echo "  - ~/.zshrc"
  echo "  - ~/.bashrc"
}

main "$@"

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

  if rm -f "$install_path" 2>/dev/null; then
    success "Removed $install_path"
  else
    error "Cannot remove $install_path (permission denied). Please remove manually or run with appropriate permissions."
  fi
}

# Remove completions
remove_completions() {
  local removed=0
  local failed=0

  # Bash completions
  if [ -f "$HOME/.local/share/bash-completion/completions/spaceheater" ]; then
    if rm -f "$HOME/.local/share/bash-completion/completions/spaceheater" 2>/dev/null; then
      success "Removed bash completions from ~/.local/share/bash-completion/completions"
      removed=1
    else
      warn "Failed to remove bash completions from ~/.local/share/bash-completion/completions"
      failed=1
    fi
  fi

  if [ -f "/usr/local/etc/bash_completion.d/spaceheater" ]; then
    if rm -f "/usr/local/etc/bash_completion.d/spaceheater" 2>/dev/null; then
      success "Removed bash completions from /usr/local/etc/bash_completion.d"
      removed=1
    else
      warn "Failed to remove bash completions from /usr/local/etc/bash_completion.d (permission denied)"
      failed=1
    fi
  fi

  # Homebrew bash completions
  if command -v brew &>/dev/null; then
    local brew_bash_completion="$(brew --prefix)/etc/bash_completion.d/spaceheater"
    if [ -f "$brew_bash_completion" ]; then
      if rm -f "$brew_bash_completion" 2>/dev/null; then
        success "Removed bash completions from $(brew --prefix)/etc/bash_completion.d"
        removed=1
      else
        warn "Failed to remove bash completions from $(brew --prefix)/etc/bash_completion.d (permission denied)"
        failed=1
      fi
    fi
  fi

  # Zsh completions
  if [ -f "$HOME/.local/share/zsh/site-functions/_spaceheater" ]; then
    if rm -f "$HOME/.local/share/zsh/site-functions/_spaceheater" 2>/dev/null; then
      success "Removed zsh completions from ~/.local/share/zsh/site-functions"
      removed=1
    else
      warn "Failed to remove zsh completions from ~/.local/share/zsh/site-functions"
      failed=1
    fi
  fi

  if [ -f "/usr/local/share/zsh/site-functions/_spaceheater" ]; then
    if rm -f "/usr/local/share/zsh/site-functions/_spaceheater" 2>/dev/null; then
      success "Removed zsh completions from /usr/local/share/zsh/site-functions"
      removed=1
    else
      warn "Failed to remove zsh completions from /usr/local/share/zsh/site-functions (permission denied)"
      failed=1
    fi
  fi

  # Homebrew zsh completions
  if command -v brew &>/dev/null; then
    local brew_zsh_completion="$(brew --prefix)/share/zsh/site-functions/_spaceheater"
    if [ -f "$brew_zsh_completion" ]; then
      if rm -f "$brew_zsh_completion" 2>/dev/null; then
        success "Removed zsh completions from $(brew --prefix)/share/zsh/site-functions"
        removed=1
      else
        warn "Failed to remove zsh completions from $(brew --prefix)/share/zsh/site-functions (permission denied)"
        failed=1
      fi
    fi
  fi

  if [ $removed -eq 0 ] && [ $failed -eq 0 ]; then
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

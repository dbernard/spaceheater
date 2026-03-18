#!/usr/bin/env bash
#
# spaceheater installer
# Installs spaceheater to a standard location in your PATH

set -euo pipefail

VERSION="1.0.0"

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

# Check prerequisites
check_prerequisites() {
  info "Checking prerequisites..."

  # Check for bash
  if ! command -v bash &>/dev/null; then
    error "Bash is required but not found"
  fi

  # Check for gh CLI
  if ! command -v gh &>/dev/null; then
    error "GitHub CLI (gh) is required. Install from: https://cli.github.com"
  fi

  # Check for python3
  if ! command -v python3 &>/dev/null; then
    error "Python 3 is required. Install from: https://python.org"
  fi

  # Check for git
  if ! command -v git &>/dev/null; then
    error "Git is required"
  fi

  # Check GitHub authentication
  if ! gh auth status &>/dev/null; then
    warn "Not authenticated with GitHub. Run 'gh auth login' after installation"
  fi

  success "All prerequisites satisfied"
}

# Determine installation directory
determine_install_dir() {
  local install_dir=""

  # Prefer ~/.local/bin if it exists or can be created
  if [ -d "$HOME/.local/bin" ]; then
    install_dir="$HOME/.local/bin"
  elif [ -w "$HOME/.local" ] || [ ! -e "$HOME/.local" ]; then
    mkdir -p "$HOME/.local/bin"
    install_dir="$HOME/.local/bin"
  # Fall back to /usr/local/bin if writable
  elif [ -w "/usr/local/bin" ]; then
    install_dir="/usr/local/bin"
  # Try /usr/local/bin with sudo
  elif [ -d "/usr/local/bin" ]; then
    warn "/usr/local/bin requires sudo access"
    if sudo -v &>/dev/null; then
      install_dir="/usr/local/bin"
    else
      error "Cannot install: neither ~/.local/bin nor /usr/local/bin are accessible"
    fi
  else
    error "No suitable installation directory found"
  fi

  echo "$install_dir"
}

# Install the script
install_script() {
  local install_dir="$1"
  local script_path="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/spaceheater"

  if [ ! -f "$script_path" ]; then
    error "Cannot find spaceheater script at: $script_path"
  fi

  info "Installing to: $install_dir/spaceheater"

  # Copy the script
  if [ -w "$install_dir" ]; then
    cp "$script_path" "$install_dir/spaceheater"
    chmod +x "$install_dir/spaceheater"
  else
    sudo cp "$script_path" "$install_dir/spaceheater"
    sudo chmod +x "$install_dir/spaceheater"
  fi

  success "Installed spaceheater to $install_dir/spaceheater"
}

# Check if install_dir is in PATH
check_path() {
  local install_dir="$1"

  if [[ ":$PATH:" == *":$install_dir:"* ]]; then
    success "$install_dir is already in your PATH"
    return 0
  else
    warn "$install_dir is not in your PATH"

    # Detect shell
    local shell_config=""
    if [ -n "${ZSH_VERSION:-}" ] || [ "$SHELL" = "$(which zsh 2>/dev/null)" ]; then
      shell_config="$HOME/.zshrc"
    elif [ -n "${BASH_VERSION:-}" ] || [ "$SHELL" = "$(which bash 2>/dev/null)" ]; then
      shell_config="$HOME/.bashrc"
    fi

    if [ -n "$shell_config" ]; then
      echo
      echo "Add this to your $shell_config:"
      echo "  export PATH=\"$install_dir:\$PATH\""
      echo
      echo "Then reload your shell:"
      echo "  source $shell_config"
    fi
    return 1
  fi
}

# Install shell completions (optional)
install_completions() {
  local script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

  info "Installing shell completions..."

  # Bash completions
  local bash_completions_dir=""
  if [ -d "$HOME/.local/share/bash-completion/completions" ]; then
    bash_completions_dir="$HOME/.local/share/bash-completion/completions"
  elif [ -d "/usr/local/etc/bash_completion.d" ]; then
    bash_completions_dir="/usr/local/etc/bash_completion.d"
  fi

  if [ -n "$bash_completions_dir" ] && [ -w "$bash_completions_dir" ]; then
    if [ -f "$script_dir/completions/spaceheater.bash" ]; then
      cp "$script_dir/completions/spaceheater.bash" "$bash_completions_dir/spaceheater"
      success "Installed bash completions to $bash_completions_dir"
    fi
  fi

  # Zsh completions
  local zsh_completions_dir=""
  if [ -d "$HOME/.local/share/zsh/site-functions" ]; then
    zsh_completions_dir="$HOME/.local/share/zsh/site-functions"
  elif [ -d "/usr/local/share/zsh/site-functions" ]; then
    zsh_completions_dir="/usr/local/share/zsh/site-functions"
  fi

  if [ -n "$zsh_completions_dir" ] && [ -w "$zsh_completions_dir" ]; then
    if [ -f "$script_dir/completions/_spaceheater" ]; then
      cp "$script_dir/completions/_spaceheater" "$zsh_completions_dir/_spaceheater"
      success "Installed zsh completions to $zsh_completions_dir"
    fi
  fi

  if [ -z "$bash_completions_dir" ] && [ -z "$zsh_completions_dir" ]; then
    info "No standard completion directories found (completions not installed)"
  fi
}

# Create config directory
create_config_dir() {
  local config_dir="$HOME/.config/spaceheater"

  if [ ! -d "$config_dir" ]; then
    info "Creating config directory: $config_dir"
    mkdir -p "$config_dir"
    success "Config directory created"
  else
    info "Config directory already exists: $config_dir"
  fi

  echo "  Note: Config files are optional. Run 'spaceheater config init' to create one."
}

# Main installation
main() {
  echo
  info "spaceheater v${VERSION} installer"
  echo

  # Check prerequisites
  check_prerequisites
  echo

  # Determine where to install
  local install_dir=$(determine_install_dir)

  # Install the script
  install_script "$install_dir"
  echo

  # Check PATH
  check_path "$install_dir"
  echo

  # Try to install completions
  install_completions "$install_dir"
  echo

  # Create config directory
  create_config_dir
  echo

  # Verify installation
  info "Verifying installation..."
  if command -v spaceheater &>/dev/null; then
    success "spaceheater is now available!"
    echo
    echo "Run 'spaceheater help' to get started"
    echo "Optional: Run 'spaceheater config init' to create a config file"
  else
    warn "Installation complete, but spaceheater is not yet in your PATH"
    echo "You may need to:"
    echo "  1. Add $install_dir to your PATH"
    echo "  2. Reload your shell"
  fi
}

main "$@"

# Advanced Installation Guide

> **Note:** For standard installation, see the [main README](../README.md#-installation). This guide provides additional installation methods and advanced configuration options.

## Prerequisites

Before installing `spaceheater`, ensure you have:

1. **GitHub CLI (`gh`)** - Required for Codespaces operations
   ```bash
   # macOS
   brew install gh

   # Linux
   # See https://github.com/cli/cli/blob/trunk/docs/install_linux.md

   # Authenticate after installation
   gh auth login
   ```

2. **Python 3** - Required for date calculations (usually pre-installed on macOS/Linux)
   ```bash
   python3 --version
   ```

3. **Bash 4.0+** - Usually pre-installed on modern systems
   ```bash
   bash --version
   ```

4. **GitHub Codespaces access** - Your repository must have Codespaces enabled

## Quick Install (Recommended)

The easiest way to install spaceheater:

```bash
# Clone the repository
git clone https://github.com/dbernard/spaceheater.git
cd spaceheater

# Run the installer
./install.sh
```

The installer will:
- Check all prerequisites (gh, python3, git)
- Install to `~/.local/bin` or `/usr/local/bin`
- Set up shell completions if available
- Verify the installation

**Alternative:** Use the Makefile:
```bash
make install
```

## Manual Installation Methods

If you prefer manual installation, choose one of these options:

### Option 1: Add to PATH

Clone the repository and add it to your PATH:

```bash
# Clone the repository
cd ~/projects  # or wherever you keep your projects
git clone https://github.com/dbernard/spaceheater.git

# Add to PATH in your shell config
echo 'export PATH="$HOME/projects/spaceheater:$PATH"' >> ~/.zshrc  # or ~/.bashrc

# Reload your shell
source ~/.zshrc  # or source ~/.bashrc

# Verify installation
spaceheater help
```

### Option 2: Symlink to /usr/local/bin

Create a symlink to make `spaceheater` available globally:

```bash
# Clone the repository
cd ~/projects
git clone https://github.com/dbernard/spaceheater.git

# Create symlink
ln -s ~/projects/spaceheater/spaceheater /usr/local/bin/spaceheater

# Verify installation
spaceheater help
```

### Option 3: Direct Download

Download the script directly to a location in your PATH:

```bash
# Download to /usr/local/bin
curl -L https://raw.githubusercontent.com/dbernard/spaceheater/main/spaceheater \
  -o /usr/local/bin/spaceheater

# Make executable
chmod +x /usr/local/bin/spaceheater

# Verify installation
spaceheater help
```

### Option 4: Shell Alias

If you prefer to keep the script in a custom location:

```bash
# Clone the repository
git clone https://github.com/dbernard/spaceheater.git ~/spaceheater

# Add alias to your shell config
echo 'alias spaceheater="~/spaceheater/spaceheater"' >> ~/.zshrc  # or ~/.bashrc

# Reload your shell
source ~/.zshrc  # or source ~/.bashrc

# Verify installation
spaceheater help
```

## Verification

After installation, verify everything works:

```bash
# Check that gh CLI is authenticated
gh auth status

# Check that spaceheater is available
spaceheater help

# Try to list codespaces (from within a git repository)
cd /path/to/your/repo
spaceheater list
```

## Configuration

### Repository Detection

`spaceheater` will automatically detect your repository if you run it from within a git repository. If you want to use it with a specific repository regardless of your current directory:

```bash
# Option 1: Set environment variable temporarily
SPACEHEATER_REPO=owner/repo spaceheater create 3

# Option 2: Set environment variable permanently
echo 'export SPACEHEATER_REPO=owner/repo' >> ~/.zshrc
source ~/.zshrc
```

### Recommended Shell Configuration

Add these to your `~/.zshrc` or `~/.bashrc` for convenience:

```bash
# Add spaceheater to PATH
export PATH="$HOME/projects/spaceheater:$PATH"

# Optional: Set default repository if you primarily use one
export SPACEHEATER_REPO=myorg/myrepo

# Optional: Set preferred machine type
export SPACEHEATER_MACHINE=premiumLinux  # or largePremiumLinux

# Optional: Shorter alias
alias sh='spaceheater'
```

Then reload your shell:
```bash
source ~/.zshrc  # or source ~/.bashrc
```

## Updating

To update to the latest version:

```bash
cd ~/projects/spaceheater  # or wherever you cloned it
git pull
```

## Uninstallation

### Using the uninstaller (Recommended):
```bash
cd /path/to/spaceheater
./uninstall.sh
```

Or with the Makefile:
```bash
make uninstall
```

### Manual uninstallation:

#### If installed via PATH or alias:
```bash
# Remove from shell config
# Edit ~/.zshrc or ~/.bashrc and remove the PATH/alias line

# Remove the cloned directory
rm -rf ~/projects/spaceheater
```

### If installed via symlink:
```bash
# Remove symlink
rm /usr/local/bin/spaceheater

# Remove cloned directory
rm -rf ~/projects/spaceheater
```

### If installed via direct download:
```bash
rm /usr/local/bin/spaceheater
```

## Troubleshooting Installation

### "command not found: spaceheater"
- Ensure the script is executable: `chmod +x /path/to/spaceheater`
- Ensure the directory is in your PATH: `echo $PATH`
- Try opening a new terminal window after modifying shell config

### "Permission denied"
- The script needs execute permissions: `chmod +x /path/to/spaceheater`
- If symlinking to `/usr/local/bin`, you may need: `sudo ln -s ...`

### "Unable to detect repository"
- Run `spaceheater` from within your git repository, OR
- Set `SPACEHEATER_REPO=owner/repo` environment variable

### "Not authenticated with GitHub"
```bash
gh auth login
```

## Next Steps

After installation, see the [README.md](README.md) for usage examples and workflows.

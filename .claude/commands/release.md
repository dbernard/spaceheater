Prepare a new release of the spaceheater project.

## Release preparation checklist:

### 1. **Version update**
- [ ] Update VERSION in `spaceheater` script (line ~30)
- [ ] Follow semantic versioning (MAJOR.MINOR.PATCH):
  - MAJOR: Breaking changes
  - MINOR: New features (backwards compatible)
  - PATCH: Bug fixes

### 2. **Testing**
- [ ] Run full test suite: `make test`
- [ ] Perform manual testing of all commands
- [ ] Test installation process: `./install.sh`
- [ ] Test uninstallation: `./uninstall.sh`
- [ ] Verify shell completions work

### 3. **Documentation updates**
- [ ] Update README.md:
  - New features documentation
  - Updated examples
  - Version badge/reference
  - Installation instructions current
- [ ] Update CHANGELOG.md (create if doesn't exist):
  ```markdown
  ## [Version] - YYYY-MM-DD
  ### Added
  - New features

  ### Changed
  - Modified functionality

  ### Fixed
  - Bug fixes

  ### Deprecated
  - Features to be removed

  ### Removed
  - Deleted features

  ### Security
  - Security fixes
  ```
- [ ] Update docs/INSTALL.md if installation changed
- [ ] Review and update docs/WISHLIST.md

### 4. **Code quality**
- [ ] No TODO comments in code
- [ ] No debug code left (check for SPACEHEATER_DEBUG usage)
- [ ] All functions documented
- [ ] Error messages are helpful

### 5. **Final checks**
```bash
# Verify everything works
make clean
make check
make lint
make test

# Check git status is clean
git status

# Review recent commits
git log --oneline -10
```

### 6. **Create release commit**
```bash
# Stage all changes
git add -A

# Commit with version
git commit -m "Release version X.Y.Z

- List major changes
- Include breaking changes warning if applicable"
```

### 7. **Tag the release**
```bash
# Create annotated tag
git tag -a "vX.Y.Z" -m "Release version X.Y.Z

Summary of changes:
- Feature 1
- Feature 2
- Bug fixes"

# Push commit and tag
git push origin main
git push origin vX.Y.Z
```

### 8. **Create GitHub release**
```bash
# Using GitHub CLI
gh release create vX.Y.Z \
  --title "Release vX.Y.Z" \
  --notes "## What's Changed

### Features
- Description of new features

### Bug Fixes
- Fixed issues

### Breaking Changes
- Any breaking changes

## Installation
\`\`\`bash
# Quick install
curl -fsSL https://raw.githubusercontent.com/owner/spaceheater/main/install.sh | bash
\`\`\`

## Full Changelog
See [CHANGELOG.md](CHANGELOG.md) for details."
```

### 9. **Post-release tasks**
- [ ] Verify release appears on GitHub
- [ ] Test installation from release
- [ ] Update any external documentation
- [ ] Announce release if appropriate
- [ ] Start new development cycle (bump to next dev version)

## Release naming convention:
- Production: vX.Y.Z (e.g., v1.0.0)
- Pre-release: vX.Y.Z-beta.N (e.g., v1.0.0-beta.1)
- Development: vX.Y.Z-dev (e.g., v1.1.0-dev)
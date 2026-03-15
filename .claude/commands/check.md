Run a comprehensive check of the project environment and status.

## Execute these checks in order:

### 1. **Environment verification**
```bash
# Check all prerequisites
make check
```

### 2. **Dependency status**
```bash
# Check required tools
echo "=== Checking dependencies ==="
command -v bash && bash --version | head -1
command -v gh && gh --version | head -1
command -v python3 && python3 --version
command -v git && git --version
command -v jq && jq --version || echo "jq: optional, not installed"
command -v bats && bats --version || echo "bats: optional, not installed"
command -v shellcheck && shellcheck --version | head -2 || echo "shellcheck: optional, not installed"
```

### 3. **GitHub authentication**
```bash
echo "=== GitHub CLI authentication ==="
gh auth status
```

### 4. **Git repository status**
```bash
echo "=== Repository status ==="
git status --short
git branch --show-current
git remote -v
git log --oneline -5
```

### 5. **Project structure validation**
```bash
echo "=== Project files check ==="
for file in spaceheater install.sh uninstall.sh Makefile README.md; do
  if [[ -f "$file" ]]; then
    echo "✓ $file exists"
  else
    echo "✗ $file missing"
  fi
done
```

### 6. **Configuration check**
```bash
echo "=== Current configuration ==="
./spaceheater config
```

### 7. **Quick syntax validation**
```bash
echo "=== Syntax check ==="
make lint
```

### 8. **Test readiness**
```bash
echo "=== Test environment ==="
if [[ -f test/spaceheater.bats ]]; then
  echo "✓ Test suite found"
  # Count tests
  grep -c "^@test" test/spaceheater.bats | xargs echo "  Total tests:"
else
  echo "✗ Test suite missing"
fi
```

### 9. **Cache status** (if applicable)
```bash
echo "=== Cache status ==="
if [[ -d ~/.spaceheater/cache ]]; then
  ls -la ~/.spaceheater/cache/
else
  echo "No cache directory found"
fi
```

### 10. **Summary report**
Provide a summary indicating:
- ✅ What's working correctly
- ⚠️ What might need attention
- ❌ What needs to be fixed
- 💡 Suggestions for improvements

## Success criteria:
- All required dependencies installed
- GitHub CLI authenticated
- Git repository properly configured
- All core files present
- Syntax check passes
- Test suite available
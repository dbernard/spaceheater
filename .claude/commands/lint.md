Check shell script syntax and code quality for all project files.

## Steps to execute:

1. **Basic syntax check** - Run `make lint` to validate Bash syntax for:
   - `spaceheater` (main script)
   - `install.sh`
   - `uninstall.sh`

2. **Enhanced linting with ShellCheck** (if available):
   ```bash
   # Check if shellcheck is installed
   if command -v shellcheck &>/dev/null; then
     # Run shellcheck with appropriate warning level
     shellcheck -S warning spaceheater install.sh uninstall.sh

     # Also check test files
     shellcheck -S warning test/test_helper.bash
   else
     echo "Note: ShellCheck not installed. Consider installing for enhanced linting:"
     echo "  brew install shellcheck  # macOS"
     echo "  apt-get install shellcheck  # Ubuntu/Debian"
   fi
   ```

3. **Check for common issues**:
   - Unquoted variables
   - Missing error handling
   - Deprecated syntax
   - Potential word splitting issues
   - Command injection vulnerabilities

4. **Style compliance check**:
   - Verify 2-space indentation
   - Check for consistent function formatting
   - Ensure proper quoting of variables
   - Validate use of `[[ ]]` over `[ ]`

5. **Report findings**:
   - List any syntax errors (must fix)
   - List any warnings (should fix)
   - Suggest improvements for code quality
   - Confirm if all checks pass

## Success criteria:
- No syntax errors from `make lint`
- No critical warnings from ShellCheck
- Code follows project style guide
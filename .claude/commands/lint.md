Check shell script syntax and code quality for all project files.

## Steps to execute:

1. **Run the lint target** which performs both syntax checking and ShellCheck analysis:
   ```bash
   make lint
   ```

   This will:
   - Run `bash -n` syntax validation on `spaceheater`, `install.sh`, and `uninstall.sh`
   - Run `shellcheck -S warning` on all shell scripts and test helpers (if shellcheck is installed)

2. **Check for common issues**:
   - Unquoted variables
   - Missing error handling
   - Deprecated syntax
   - Potential word splitting issues
   - Command injection vulnerabilities

3. **Style compliance check**:
   - Verify 2-space indentation
   - Check for consistent function formatting
   - Ensure proper quoting of variables
   - Validate use of `[[ ]]` over `[ ]`

4. **Report findings**:
   - List any syntax errors (must fix)
   - List any warnings (should fix)
   - Suggest improvements for code quality
   - Confirm if all checks pass

## Success criteria:
- No syntax errors from `bash -n`
- No critical warnings from ShellCheck
- Code follows project style guide
# Spaceheater Code Style Guide

## Bash Script Standards

### File Structure
1. **Shebang**: Always use `#!/usr/bin/env bash`
2. **Set Options**: Include `set -euo pipefail` immediately after shebang
3. **Version**: Define VERSION variable near top of file
4. **Organization**: Group related functions together with clear section comments

### Safety & Best Practices
```bash
# Always use these at the start of scripts
set -euo pipefail  # Exit on error, undefined vars, pipe failures
IFS=$'\n\t'       # Set safe Internal Field Separator
```

### Variable Conventions
- **Naming**: Use lowercase with underscores for local vars: `local_var`
- **Constants**: Use uppercase for globals/constants: `SPACEHEATER_REPO`
- **Declaration**: Always declare locals: `local var_name="value"`
- **Quoting**: Always quote variables: `"$var"` not `$var`
- **Defaults**: Use parameter expansion: `${VAR:-default}`
- **Arrays**: Properly quote array expansions: `"${array[@]}"`

### Function Guidelines
```bash
# Function format with clear documentation
function_name() {
  local param1="${1:-}"
  local param2="${2:-default}"

  # Validate inputs
  [[ -z "$param1" ]] && {
    error "Missing required parameter"
    return 1
  }

  # Main logic
  local result
  result=$(some_command)

  # Return/output
  echo "$result"
}
```

### Conditionals
- Use `[[ ]]` for string/file tests (more reliable than `[ ]`)
- Use `(( ))` for arithmetic comparisons
- Always quote variables in conditionals
```bash
# Good
if [[ -n "$var" ]]; then
if [[ "$var" == "value" ]]; then
if (( count > 0 )); then

# Avoid
if [ -n $var ]; then  # Unquoted, single brackets
```

### Error Handling
```bash
# Use the error() function for consistent error output
error() {
  echo "Error: $*" >&2
}

# Check command success
if ! command; then
  error "Command failed"
  return 1
fi

# Or use || for simple cases
command || error "Command failed"
```

### Command Substitution
- Use `$(command)` syntax, not backticks
- Quote command substitutions: `"$(command)"`
- Capture in variable first if used multiple times

### Formatting Rules
- **Indentation**: 2 spaces (NO TABS)
- **Line Length**: Prefer under 100 characters
- **Line Continuations**: Indent continued lines by 2 spaces
- **Pipes**: Place `|` at end of line for multi-line pipes
```bash
# Multi-line pipe example
long_command |
  grep pattern |
  sort -u
```

### Comments
- Use `#` for single-line comments
- Add space after `#`: `# This is a comment`
- Document complex logic and non-obvious behavior
- Place function documentation above the function
```bash
# Create N codespaces with configured settings
# Args: $1 - number of codespaces to create (max 5)
# Returns: 0 on success, 1 on error
cmd_create() {
  # Implementation
}
```

## Testing Requirements

### For All Changes
1. **Syntax Check**: Run `make lint` (or `bash -n spaceheater`)
2. **Test Suite**: Run `make test` - all tests must pass
3. **Manual Test**: Verify with `./spaceheater help`

### When Adding Features
1. Add corresponding tests to `test/spaceheater.bats`
2. Test both success and failure cases
3. Use mocks for external commands
4. Update help text and documentation

### When Fixing Bugs
1. Add a test that reproduces the bug first
2. Fix the bug
3. Verify test now passes
4. Check for similar issues elsewhere

## Git Commit Standards

### Commit Messages
```
<type>: <description>

[optional body]

[optional footer]
```

Types:
- `feat:` New feature
- `fix:` Bug fix
- `docs:` Documentation only
- `test:` Test additions/changes
- `refactor:` Code restructuring
- `style:` Formatting changes
- `chore:` Maintenance tasks

Examples:
```
feat: add autostart command for quick codespace startup

fix: handle spaces in repository names correctly

docs: update README with new configuration options

test: add coverage for clean command edge cases
```

## Code Quality Checklist

Before committing:
- [ ] Code follows 2-space indentation
- [ ] All variables are quoted
- [ ] Functions have local declarations
- [ ] Error handling is in place
- [ ] No TODO comments left uncommented
- [ ] Tests pass (`make test`)
- [ ] Syntax check passes (`make lint`)
- [ ] Help text is updated if needed
- [ ] README is updated for new features

## Common Patterns

### Input Validation
```bash
# Validate required arguments
[[ $# -eq 0 ]] && {
  error "Missing required argument"
  show_usage
  return 2
}

# Validate numeric input
if ! [[ "$1" =~ ^[0-9]+$ ]]; then
  error "Invalid number: $1"
  return 1
fi
```

### Safe Array Handling
```bash
# Declare array
local items=()

# Add to array
items+=("item1")
items+=("item2")

# Iterate safely
for item in "${items[@]}"; do
  echo "$item"
done

# Check if array is empty
if [[ ${#items[@]} -eq 0 ]]; then
  echo "No items found"
fi
```

### JSON Processing
```bash
# Prefer jq when available
if command -v jq &>/dev/null; then
  result=$(echo "$json" | jq -r '.field')
else
  # Fallback to Python
  result=$(python3 -c "import json; print(json.loads('$json')['field'])")
fi
```

## UI/Output Guidelines

### Color Output
- Check for NO_COLOR environment variable
- Provide fallback for non-terminal output
- Use consistent color scheme

### Progress Indicators
- Use spinner for long operations
- Show item counts: "Processing 3/10..."
- Clear line with `\r` for updates

### Error Messages
- Be specific about what went wrong
- Suggest how to fix the issue
- Include relevant context

Example:
```bash
error "Failed to create codespace: API rate limit exceeded"
echo "Try again in a few minutes or check 'gh api rate_limit'" >&2
```

## Performance Considerations

1. **Cache expensive operations**: Store repo ID lookups
2. **Minimize external calls**: Batch operations when possible
3. **Use built-in bash features**: Avoid spawning subshells unnecessarily
4. **Lazy evaluation**: Don't compute values until needed

## Security Notes

1. **Never echo sensitive data** (tokens, passwords)
2. **Validate all user input** before using in commands
3. **Use `--` to separate options from arguments** in commands
4. **Avoid eval** unless absolutely necessary
5. **Quote everything** to prevent injection attacks
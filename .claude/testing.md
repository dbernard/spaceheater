# Testing and Quality Assurance Guide

## Prerequisites Check

Before making any changes, verify your environment:

```bash
# Check all prerequisites
make check

# Verify GitHub CLI authentication
gh auth status

# Ensure you're in a git repository
git status
```

## Testing Workflow

### Quick Testing Cycle
```bash
# 1. Syntax check (fast)
make lint

# 2. Run test suite (comprehensive)
make test

# 3. Manual smoke test
./spaceheater help
./spaceheater version
./spaceheater config
```

### Before Committing
```bash
# Run the full validation suite
make lint && make test && ./spaceheater help
```

## Bats Testing Framework

### Test File Location
- Main test file: `test/spaceheater.bats`
- Test helpers: `test/test_helper.bash`
- Test fixtures: `test/fixtures/`

### Writing Tests

#### Basic Test Structure
```bash
@test "description of what is being tested" {
  # Arrange - Set up test environment
  export SPACEHEATER_REPO="owner/repo"
  setup_test_fixture

  # Act - Run the command
  run ./spaceheater command args

  # Assert - Check the results
  [ "$status" -eq 0 ]
  [[ "$output" =~ "expected text" ]]
}
```

#### Testing Success Cases
```bash
@test "create command creates specified number of codespaces" {
  export SPACEHEATER_REPO="owner/repo"
  mock_gh "codespace create" "Successfully created codespace"

  run ./spaceheater create 3

  [ "$status" -eq 0 ]
  [[ "$output" =~ "Creating 3 codespaces" ]]
  [[ "$output" =~ "Successfully created" ]]
}
```

#### Testing Error Cases
```bash
@test "create command fails with invalid number" {
  run ./spaceheater create abc

  [ "$status" -eq 1 ]
  [[ "$output" =~ "Error" ]]
  [[ "$output" =~ "Invalid number" ]]
}
```

#### Testing with Mocks
```bash
@test "list command displays codespaces" {
  # Use mock_gh to simulate GitHub CLI responses
  mock_gh "codespace list" "$(cat test/fixtures/codespaces.json)"

  run ./spaceheater list

  [ "$status" -eq 0 ]
  [[ "$output" =~ "HOT" ]]
  [[ "$output" =~ "WARM" ]]
  [[ "$output" =~ "COLD" ]]
}
```

### Test Helper Functions

Available in `test/test_helper.bash`:

```bash
# Mock GitHub CLI commands
mock_gh() {
  local subcommand="$1"
  local response="$2"
  # Sets up gh command to return mock response
}

# Mock git commands
mock_git() {
  local subcommand="$1"
  local response="$2"
  # Sets up git command to return mock response
}

# Generate test fixtures with relative dates
generate_test_fixture() {
  # Creates codespaces.json with current timestamps
}

# Set up test environment
setup() {
  # Creates temporary test directory
  # Sets up PATH for mocked commands
}

# Clean up test environment
teardown() {
  # Removes temporary files
  # Restores original environment
}
```

## Test Coverage Areas

### Command Testing
- [ ] `create` - Test with 1-5 codespaces, validate limits
- [ ] `list` - Test empty list, single item, multiple items
- [ ] `start` - Test interactive mode, direct name, fuzzy matching
- [ ] `autostart` - Test selection logic, no available spaces
- [ ] `stop` - Test stopping running space, no running space
- [ ] `clean` - Test age filtering, dry run, actual deletion
- [ ] `delete` - Test specific deletion, non-existent space
- [ ] `config` - Test output format, environment variable reading
- [ ] `version` - Test version output format
- [ ] `help` - Test help text completeness

### Error Handling
- [ ] Missing required arguments
- [ ] Invalid argument formats
- [ ] GitHub CLI not authenticated
- [ ] Not in a git repository
- [ ] API failures and rate limiting
- [ ] Network connectivity issues

### Edge Cases
- [ ] Repository names with spaces or special characters
- [ ] Codespace names with unicode characters
- [ ] Empty responses from GitHub API
- [ ] Concurrent operations
- [ ] Interrupted operations

### Environment Variables
- [ ] Test all SPACEHEATER_* variables
- [ ] Test defaults when variables not set
- [ ] Test invalid values for variables
- [ ] Test NO_COLOR mode
- [ ] Test SPACEHEATER_DEBUG mode

## Testing Checklist

### For New Features
1. [ ] Write tests BEFORE implementing the feature (TDD)
2. [ ] Test the happy path (normal usage)
3. [ ] Test error conditions
4. [ ] Test edge cases
5. [ ] Test with different configurations
6. [ ] Update existing tests if behavior changes
7. [ ] Add integration test if feature spans multiple functions

### For Bug Fixes
1. [ ] Write a test that reproduces the bug
2. [ ] Verify test fails with current code
3. [ ] Fix the bug
4. [ ] Verify test now passes
5. [ ] Check for similar issues in other commands
6. [ ] Add regression test to prevent reoccurrence

### For Refactoring
1. [ ] Ensure all existing tests pass before changes
2. [ ] Make refactoring changes
3. [ ] Verify all tests still pass
4. [ ] Add new tests if new patterns are introduced
5. [ ] Update test helpers if needed

## Manual Testing Guide

### Installation Testing
```bash
# Test installation
./install.sh
which spaceheater
spaceheater version

# Test uninstallation
./uninstall.sh
which spaceheater  # Should return error
```

### Command Testing Sequence
```bash
# 1. Configuration check
./spaceheater config

# 2. Create codespaces
./spaceheater create 2

# 3. List codespaces
./spaceheater list

# 4. Start a codespace
./spaceheater start

# 5. Check running status
./spaceheater list

# 6. Stop codespace
./spaceheater stop

# 7. Clean old codespaces
./spaceheater clean 7

# 8. Delete specific codespace
./spaceheater delete codespace-name
```

### UI/UX Testing
- [ ] Test with terminal that supports Unicode
- [ ] Test with terminal that doesn't support Unicode
- [ ] Test with NO_COLOR=1
- [ ] Test with different terminal widths
- [ ] Test interactive prompts
- [ ] Test Ctrl+C handling

## Performance Testing

### Check for Performance Issues
```bash
# Time command execution
time ./spaceheater list

# Check cache effectiveness
ls -la ~/.spaceheater/cache/

# Monitor API calls (debug mode)
SPACEHEATER_DEBUG=1 ./spaceheater list
```

### Performance Targets
- `list` command: < 2 seconds
- `create` command: < 5 seconds per codespace
- `start` command: < 3 seconds to prompt
- Cache hits should prevent API calls

## Debugging Failed Tests

### Run Single Test
```bash
# Run specific test by name
bats test/spaceheater.bats --filter "test name pattern"
```

### Verbose Test Output
```bash
# Show all test output
bats test/spaceheater.bats --verbose --show-output-of-passing-tests
```

### Debug Mode
```bash
# Enable debug output in tests
SPACEHEATER_DEBUG=1 make test

# Trace mode for script
bash -x ./spaceheater command
```

### Common Test Failures

1. **"gh: command not found"**
   - Install GitHub CLI: `brew install gh`
   - Authenticate: `gh auth login`

2. **"not in a git repository"**
   - Run tests from repository root
   - Ensure `.git` directory exists

3. **"python3: command not found"**
   - Install Python 3: `brew install python3`

4. **Timing-related failures**
   - Check if fixtures have stale dates
   - Regenerate fixtures: `generate_test_fixture`

## Continuous Integration

While no CI is currently configured, here's the recommended CI pipeline:

```yaml
# Suggested GitHub Actions workflow
test:
  - make check      # Verify prerequisites
  - make lint       # Syntax check + ShellCheck
  - make test       # Run full test suite
```

## Quality Gates

### Minimum Requirements for Code Changes
1. ✅ All existing tests pass
2. ✅ New tests added for new functionality
3. ✅ Syntax check passes (`make lint`)
4. ✅ Manual smoke test successful
5. ✅ Documentation updated if needed

### Recommended Additional Checks
1. 📊 Code coverage remains above 80%
2. 🔍 ShellCheck warnings addressed
3. 📝 CHANGELOG updated
4. 🏷️ Version bumped if needed
5. 👥 Peer review completed

## Test Maintenance

### Regular Maintenance Tasks
- Update test fixtures when GitHub API changes
- Add tests for reported bugs
- Refactor test helpers for reusability
- Remove obsolete tests
- Update mocks to match current `gh` CLI behavior

### Test Documentation
- Keep test descriptions clear and specific
- Comment complex test logic
- Document test dependencies
- Maintain test fixture documentation
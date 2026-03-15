Run the full test suite for the spaceheater project and verify all tests pass.

## Steps to execute:

1. **Check prerequisites** - Run `make check` to ensure all dependencies are available
2. **Syntax validation** - Run `make lint` to check shell script syntax
3. **Execute test suite** - Run `make test` to execute all Bats tests
4. **Analyze results** - If any tests fail:
   - Identify the failing test(s)
   - Read the error messages carefully
   - Check the test file at `test/spaceheater.bats` for the failing test
   - Investigate the root cause
   - Fix the issue
   - Re-run tests until all pass

5. **Report results** - Provide a summary of:
   - Total tests run
   - Tests passed/failed
   - Any issues found and fixed
   - Confirmation that all tests are passing

## Expected output when successful:
```
✓ No syntax errors
✓ All tests passed
```

## Common issues to check:
- GitHub CLI not authenticated (`gh auth status`)
- Missing dependencies (python3, git, gh)
- Not in a git repository
- Stale test fixtures needing regeneration
Create a pull request with proper testing and documentation.

## Pre-flight checks:

1. **Testing** - Run the full test suite:
   ```bash
   make lint && make test
   ```
   Stop if any tests fail - fix issues first!

2. **Review changes**:
   ```bash
   git status
   git diff
   ```

## Pull request creation:

1. **Create feature branch** (if not already on one):
   ```bash
   git checkout -b feature/description-of-change
   ```

2. **Stage and commit changes**:
   - Review all changes carefully
   - Stage appropriate files
   - Write clear, descriptive commit message following format:
     ```
     <type>: <description>

     - Detail of what changed
     - Why it was changed
     - Any breaking changes
     ```

3. **Push to remote**:
   ```bash
   git push -u origin feature/branch-name
   ```

4. **Create pull request** using GitHub CLI:
   ```bash
   gh pr create --title "Clear description of change" \
                --body "## Summary
   - What: Brief description of changes
   - Why: Reason for the changes
   - How: Implementation approach

   ## Changes
   - List specific changes made
   - Highlight any breaking changes

   ## Testing
   - ✅ All tests pass (`make test`)
   - ✅ Syntax check passes (`make lint`)
   - ✅ Manual testing completed
   - Describe any additional testing performed

   ## Checklist
   - [ ] Tests added/updated
   - [ ] Documentation updated
   - [ ] Code follows style guide
   - [ ] No debugging code left
   - [ ] Version bumped if needed"
   ```

5. **Post-creation tasks**:
   - Link any related issues
   - Request reviewers if needed
   - Add appropriate labels
   - Ensure CI checks pass (if configured)

## Required before merge:
- All tests passing
- Documentation updated
- Code reviewed
- No merge conflicts
- Follows semantic versioning if applicable
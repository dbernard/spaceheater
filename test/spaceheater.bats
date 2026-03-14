#!/usr/bin/env bats
# Core test suite for spaceheater CLI
# Tests critical functionality to prevent regressions

load test_helper

# =============================================================================
# Basic Command Tests
# =============================================================================

@test "spaceheater script exists and is executable" {
    [ -f "$SPACEHEATER" ]
    [ -x "$SPACEHEATER" ]
}

@test "version command works" {
    run "$SPACEHEATER" version
    [ "$status" -eq 0 ]
    [[ "$output" =~ spaceheater ]]
}

@test "help command shows usage information" {
    run "$SPACEHEATER" help
    [ "$status" -eq 0 ]
    [[ "$output" =~ COMMANDS ]]
    [[ "$output" =~ create ]]
    [[ "$output" =~ list ]]
    [[ "$output" =~ SPACEHEATER ]]
}

@test "invalid command returns error" {
    run "$SPACEHEATER" invalid-command-xyz
    [ "$status" -ne 0 ]
    [[ "$output" =~ [Ee]rror ]]
}

# =============================================================================
# Configuration Tests
# =============================================================================

@test "config command with mocked dependencies" {
    create_mock_gh
    create_mock_git
    create_mock_jq

    run "$SPACEHEATER" config
    [ "$status" -eq 0 ]
    [[ "$output" =~ "Repository:" ]]
    [[ "$output" =~ "testorg/testrepo" ]]
}

@test "respects SPACEHEATER_REPO environment variable" {
    create_mock_gh
    create_mock_jq

    export SPACEHEATER_REPO="customorg/customrepo"
    run "$SPACEHEATER" config
    [ "$status" -eq 0 ]
    [[ "$output" =~ "customorg/customrepo" ]]
}

# =============================================================================
# List Command Tests
# =============================================================================

@test "list command shows codespaces with temperature categories" {
    create_mock_gh
    create_mock_jq

    run "$SPACEHEATER" list
    [ "$status" -eq 0 ]

    # Check for temperature categories
    [[ "$output" =~ HOT ]]
    [[ "$output" =~ WARM ]]
    [[ "$output" =~ COLD ]]

    # Check for codespace display names (what users actually see)
    [[ "$output" =~ "Running Test Codespace" ]]
    [[ "$output" =~ "Clean Stopped Codespace" ]]
    [[ "$output" =~ "Old Dirty Codespace" ]]
}

@test "list command handles empty codespace list" {
    # Create a custom mock that returns empty list instead of modifying fixtures
    cat > "${MOCK_BIN_DIR}/gh" << 'EOF'
#!/usr/bin/env bash
case "$1 $2" in
    "auth status")
        echo "✓ Logged in to github.com as testuser (oauth_token)"
        exit 0
        ;;
    "api repos/testorg/testrepo")
        echo '{"id": 12345678, "default_branch": "main", "full_name": "testorg/testrepo"}'
        exit 0
        ;;
    "api /user/codespaces?repository_id=12345678")
        echo '{"codespaces": []}'
        exit 0
        ;;
    *)
        echo "Error: Mock gh - unhandled command: $*" >&2
        exit 1
        ;;
esac
EOF
    chmod +x "${MOCK_BIN_DIR}/gh"

    create_mock_jq

    run "$SPACEHEATER" list
    [ "$status" -eq 0 ]
    [[ "$output" =~ "No hot codespaces" ]] || [[ "$output" =~ "No codespaces" ]]
}

# =============================================================================
# Create Command Tests
# =============================================================================

@test "create command with valid count" {
    create_mock_gh
    create_mock_jq

    run "$SPACEHEATER" create 1
    [ "$status" -eq 0 ]
    [[ "$output" =~ [Cc]reat ]]

    # Verify gh codespace create was called
    assert_gh_called_with "codespace create"
}

@test "create command validates count is a number" {
    create_mock_gh

    run "$SPACEHEATER" create abc
    [ "$status" -ne 0 ]
    [[ "$output" =~ [Ee]rror ]]
}

@test "create command enforces maximum of 3" {
    create_mock_gh
    create_mock_jq

    run "$SPACEHEATER" create 5

    # Should either error or cap at 3
    # Count actual gh calls
    local call_count=$(grep -c "codespace create" "${TEST_TEMP_DIR}/gh-calls.log" 2>/dev/null || echo 0)
    [ "$call_count" -le 3 ]
}

# =============================================================================
# Start/Stop Command Tests
# =============================================================================

@test "start command accepts codespace name" {
    create_mock_gh
    create_mock_jq

    run "$SPACEHEATER" start hot-space-001
    [ "$status" -eq 0 ]

    # Should call gh codespace code/ssh
    assert_gh_called_with "codespace"
}

@test "stop command accepts codespace name" {
    create_mock_gh
    create_mock_jq

    run "$SPACEHEATER" stop hot-space-001
    [ "$status" -eq 0 ]
    [[ "$output" =~ [Ss]top ]]

    assert_gh_called_with "codespace stop"
}

@test "autostart selects appropriate codespace" {
    create_mock_gh
    create_mock_jq

    run "$SPACEHEATER" autostart
    [ "$status" -eq 0 ]

    # Should select and start a codespace
    # With our fixture, should prefer warm-space-002 (shutdown but clean)
    [[ "$output" =~ "warm-space-002" ]] || [[ "$output" =~ "Starting" ]]
}

# =============================================================================
# Clean Command Tests
# =============================================================================

@test "clean command with valid days parameter" {
    create_mock_gh
    create_mock_jq

    # Need to handle the confirmation prompt
    run bash -c "echo 'n' | '$SPACEHEATER' clean 7"

    # Should at least parse the command correctly
    # Status might be non-zero if no codespaces to clean or user cancels
    [[ "$output" =~ [Cc]lean ]] || [[ "$output" =~ [Cc]ancel ]] || [[ "$output" =~ "No codespaces" ]]
}

@test "clean command validates days parameter" {
    create_mock_gh

    run "$SPACEHEATER" clean abc
    [ "$status" -ne 0 ]
    [[ "$output" =~ [Ee]rror ]]
}

# =============================================================================
# Delete Command Tests
# =============================================================================

@test "delete command accepts codespace name" {
    create_mock_gh
    create_mock_jq

    run "$SPACEHEATER" delete cold-space-003
    [ "$status" -eq 0 ]
    [[ "$output" =~ [Dd]elet ]]

    assert_gh_called_with "codespace delete"
}

# =============================================================================
# Dependency Check Tests
# =============================================================================

@test "checks for required dependencies when gh is missing" {
    # Create empty bin directory for this test only
    local empty_path="${TEST_TEMP_DIR}/empty-bin"
    mkdir -p "$empty_path"

    # Set PATH to include basic system binaries but not gh
    # This allows bash/env to work but gh won't be found
    export PATH="/usr/bin:/bin:$empty_path"

    run "$SPACEHEATER" list
    [ "$status" -ne 0 ]
    [[ "$output" =~ "gh" ]] || [[ "$output" =~ "GitHub CLI" ]]
}

# =============================================================================
# Error Handling Tests
# =============================================================================

@test "handles API errors gracefully" {
    # Create a mock gh that returns errors
    cat > "${MOCK_BIN_DIR}/gh" << 'EOF'
#!/usr/bin/env bash
echo "Error: API rate limit exceeded" >&2
exit 1
EOF
    chmod +x "${MOCK_BIN_DIR}/gh"

    run "$SPACEHEATER" list
    [ "$status" -ne 0 ]
    [[ "$output" =~ [Ee]rror ]]
}
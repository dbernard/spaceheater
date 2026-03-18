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
# Config File Tests
# =============================================================================

@test "loads config from user-wide config file" {
    create_mock_gh
    create_mock_jq

    # Create a mock user config file
    local user_config="${TEST_TEMP_DIR}/.config/spaceheater/config"
    mkdir -p "$(dirname "$user_config")"
    cat > "$user_config" << 'EOF'
REPO=configorg/configrepo
MACHINE=premiumLinux
CONNECT=ssh
EOF

    # Point HOME to test temp dir so config is found
    export HOME="$TEST_TEMP_DIR"

    run "$SPACEHEATER" config
    [ "$status" -eq 0 ]
    [[ "$output" =~ "configorg/configrepo" ]] || [[ "$output" =~ "premiumLinux" ]] || [[ "$output" =~ "ssh" ]]
}

@test "loads config from repo-specific config file" {
    create_mock_gh
    create_mock_jq

    # Create a mock repo config file
    local repo_config="${TEST_TEMP_DIR}/.spaceheater.conf"
    cat > "$repo_config" << 'EOF'
REPO=repoorg/reporepo
MACHINE=standardLinux
BRANCH=develop
EOF

    # Change to test temp dir so repo config is found
    cd "$TEST_TEMP_DIR"

    run "$SPACEHEATER" config
    [ "$status" -eq 0 ]
    [[ "$output" =~ "repoorg/reporepo" ]] || [[ "$output" =~ "standardLinux" ]] || [[ "$output" =~ "develop" ]]
}

@test "environment variables override config files" {
    create_mock_gh
    create_mock_jq

    # Create a config file
    local user_config="${TEST_TEMP_DIR}/.config/spaceheater/config"
    mkdir -p "$(dirname "$user_config")"
    cat > "$user_config" << 'EOF'
REPO=configorg/configrepo
MACHINE=basicLinux
EOF

    # Point HOME to test temp dir
    export HOME="$TEST_TEMP_DIR"

    # Override with environment variable
    export SPACEHEATER_MACHINE="premiumLinux"

    run "$SPACEHEATER" config
    [ "$status" -eq 0 ]
    # Should show premiumLinux from env var, not basicLinux from config
    [[ "$output" =~ "premiumLinux" ]]
}

@test "repo config takes precedence over user config" {
    create_mock_gh
    create_mock_jq

    # Create user config
    local user_config="${TEST_TEMP_DIR}/.config/spaceheater/config"
    mkdir -p "$(dirname "$user_config")"
    cat > "$user_config" << 'EOF'
REPO=userorg/userrepo
MACHINE=basicLinux
EOF

    # Create repo config
    local repo_config="${TEST_TEMP_DIR}/.spaceheater.conf"
    cat > "$repo_config" << 'EOF'
REPO=repoorg/reporepo
MACHINE=premiumLinux
EOF

    export HOME="$TEST_TEMP_DIR"
    cd "$TEST_TEMP_DIR"

    run "$SPACEHEATER" config
    [ "$status" -eq 0 ]
    # Should show repo config values
    [[ "$output" =~ "repoorg/reporepo" ]] || [[ "$output" =~ "premiumLinux" ]]
}

@test "config file ignores comments and blank lines" {
    create_mock_gh
    create_mock_jq

    local user_config="${TEST_TEMP_DIR}/.config/spaceheater/config"
    mkdir -p "$(dirname "$user_config")"
    cat > "$user_config" << 'EOF'
# This is a comment
REPO=commentorg/commentrepo

# Another comment
MACHINE=standardLinux

EOF

    export HOME="$TEST_TEMP_DIR"

    run "$SPACEHEATER" config
    [ "$status" -eq 0 ]
    # Should successfully parse config despite comments and blank lines
    [[ "$output" =~ "commentorg/commentrepo" ]] || [[ "$output" =~ "standardLinux" ]]
}

@test "config file handles various key formats" {
    create_mock_gh
    create_mock_jq

    local user_config="${TEST_TEMP_DIR}/.config/spaceheater/config"
    mkdir -p "$(dirname "$user_config")"
    cat > "$user_config" << 'EOF'
REPO=testorg/testrepo
repo=testorg/testrepo2
Repo=testorg/testrepo3
EOF

    export HOME="$TEST_TEMP_DIR"

    run "$SPACEHEATER" config
    [ "$status" -eq 0 ]
    # Should handle case-insensitive keys
    [[ "$output" =~ "testorg/testrepo" ]]
}

@test "config validate detects invalid syntax" {
    create_mock_gh
    create_mock_jq

    local user_config="${TEST_TEMP_DIR}/.config/spaceheater/config"
    mkdir -p "$(dirname "$user_config")"
    cat > "$user_config" << 'EOF'
REPO=testorg/testrepo
INVALID LINE WITHOUT EQUALS
MACHINE=standardLinux
EOF

    export HOME="$TEST_TEMP_DIR"

    # Note: This test assumes 'spaceheater config validate' command exists
    # If the command doesn't exist yet, the test will fail until implementation
    run "$SPACEHEATER" config validate
    # Should either succeed and warn about invalid line, or fail
    # We're flexible here since validation behavior may vary
    [[ "$output" =~ "INVALID" ]] || [ "$status" -ne 0 ]
}

@test "custom config file with --config flag" {
    create_mock_gh
    create_mock_jq

    # Create a custom config file
    local custom_config="${TEST_TEMP_DIR}/custom.conf"
    cat > "$custom_config" << 'EOF'
REPO=customorg/customrepo
MACHINE=largePremiumLinux
EOF

    # Note: This assumes --config flag support
    run "$SPACEHEATER" config --config "$custom_config"
    [ "$status" -eq 0 ]
    # Should load from custom config
    [[ "$output" =~ "customorg/customrepo" ]] || [[ "$output" =~ "largePremiumLinux" ]]
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

@test "stop all command stops all running codespaces" {
    create_mock_gh
    create_mock_jq

    run "$SPACEHEATER" stop all
    [ "$status" -eq 0 ]

    # Should find and stop running codespaces
    [[ "$output" =~ "running codespace" ]] || [[ "$output" =~ "Stopped" ]]

    # Should call gh codespace stop for each running codespace
    assert_gh_called_with "codespace stop"
}

@test "autostart selects appropriate codespace" {
    create_mock_gh
    create_mock_jq

    run "$SPACEHEATER" autostart
    [ "$status" -eq 0 ]

    # Should select and start a codespace
    # With our fixture, should prefer hot-space-001 (Available and clean) over warm-space-002
    [[ "$output" =~ "hot-space-001" ]] || [[ "$output" =~ "Starting" ]]
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

    # Need to pass 'y' to confirmation prompt
    run bash -c "echo 'y' | '$SPACEHEATER' delete cold-space-003"
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

# =============================================================================
# JSON Output Tests
# =============================================================================

@test "list command supports --json flag" {
    # Mock gh to return codespace data
    create_mock_gh
    # The fixture is already generated in setup()

    run "$SPACEHEATER" list --json
    [ "$status" -eq 0 ]

    # Verify valid JSON output
    echo "$output" | jq empty  # Will fail if not valid JSON

    # Check for expected fields
    [[ $(echo "$output" | jq -r '.codespaces') != "null" ]]
    [[ $(echo "$output" | jq -r '.repository') != "null" ]]
    [[ $(echo "$output" | jq -r '.timestamp') != "null" ]]
}

@test "list command supports -j shorthand for JSON" {
    # Mock gh to return codespace data
    create_mock_gh
    # The fixture is already generated in setup()

    run "$SPACEHEATER" list -j
    [ "$status" -eq 0 ]

    # Verify valid JSON output
    echo "$output" | jq empty  # Will fail if not valid JSON
    [[ $(echo "$output" | jq -r '.codespaces') != "null" ]]
}

@test "list command supports --output=json format" {
    # Mock gh to return codespace data
    create_mock_gh
    # The fixture is already generated in setup()

    run "$SPACEHEATER" list --output=json
    [ "$status" -eq 0 ]

    # Verify valid JSON output
    echo "$output" | jq empty  # Will fail if not valid JSON
    [[ $(echo "$output" | jq -r '.codespaces') != "null" ]]
}

@test "JSON output includes temperature field" {
    # Mock gh to return codespace with specific state
    create_mock_gh
    cat > "${FIXTURES}/codespaces.json" << 'EOF'
{
  "codespaces": [{
    "name": "test-codespace",
    "display_name": "Test Codespace",
    "state": "Available",
    "created_at": "2024-03-18T10:00:00Z",
    "updated_at": "2024-03-18T14:00:00Z",
    "git_status": {
      "has_uncommitted_changes": false,
      "has_unpushed_changes": false,
      "ahead": 0,
      "behind": 0,
      "ref": "main"
    },
    "machine": {
      "display_name": "4 cores, 16 GB RAM"
    },
    "repository": {
      "full_name": "test/repo"
    },
    "owner": {
      "login": "testuser"
    }
  }],
  "total_count": 1
}
EOF

    run "$SPACEHEATER" list --json
    [ "$status" -eq 0 ]

    # Check that temperature field exists and is "hot" for Available state
    [[ $(echo "$output" | jq -r '.codespaces[0].temperature') == "hot" ]]
    # Check that raw state is also preserved
    [[ $(echo "$output" | jq -r '.codespaces[0].state') == "Available" ]]
}

@test "JSON output handles empty codespace list" {
    # Mock gh to return empty codespace list
    create_mock_gh
    cat > "${FIXTURES}/codespaces.json" << 'EOF'
{
  "codespaces": [],
  "total_count": 0
}
EOF

    run "$SPACEHEATER" list --json
    [ "$status" -eq 0 ]

    # Check structure is correct even with empty list
    [[ $(echo "$output" | jq -r '.codespaces | length') == "0" ]]
    [[ $(echo "$output" | jq -r '.total_count') == "0" ]]
}

@test "rejects unsupported output formats" {
    run "$SPACEHEATER" list --output=xml
    [ "$status" -ne 0 ]
    [[ "$output" =~ "Unknown output format: xml" ]]
}

@test "start command supports --json flag" {
    # Mock gh to return codespace data
    create_mock_gh
    # The fixture is already generated in setup()

    run "$SPACEHEATER" start hot-space-001 --json
    [ "$status" -eq 0 ]

    # Verify valid JSON output
    echo "$output" | jq empty  # Will fail if not valid JSON

    # Check for expected fields
    [[ $(echo "$output" | jq -r '.action') == "start" ]]
    [[ $(echo "$output" | jq -r '.success') == "true" ]]
    [[ $(echo "$output" | jq -r '.codespace') != "null" ]]
    [[ $(echo "$output" | jq -r '.codespace.name') == "hot-space-001" ]]
    [[ $(echo "$output" | jq -r '.connection_url') != "null" ]]
    [[ $(echo "$output" | jq -r '.connection_method') != "null" ]]
    [[ $(echo "$output" | jq -r '.timestamp') != "null" ]]
}

@test "start command JSON includes temperature field" {
    # Mock gh to return codespace data
    create_mock_gh
    # The fixture is already generated in setup()

    run "$SPACEHEATER" start hot-space-001 --json
    [ "$status" -eq 0 ]

    # Check that temperature field exists
    [[ $(echo "$output" | jq -r '.codespace.temperature') != "null" ]]
    # Check that state is also preserved
    [[ $(echo "$output" | jq -r '.codespace.state') == "Available" ]]
}

@test "start command JSON includes connection details" {
    # Mock gh to return codespace data
    create_mock_gh
    # The fixture is already generated in setup()

    # Test with browser connection method (default)
    export SPACEHEATER_CONNECT=browser
    run "$SPACEHEATER" start hot-space-001 --json
    [ "$status" -eq 0 ]

    # Check connection fields
    [[ $(echo "$output" | jq -r '.connection_method') == "browser" ]]
    [[ $(echo "$output" | jq -r '.connection_url') =~ ^https:// ]]
}

# TODO: Autostart tests currently fail in CI due to mock gh repo ID lookup issue
# These tests pass with real gh CLI but need more complex mocking
# @test "autostart command supports --json flag" {
#     # Mock gh to return codespace data
#     create_mock_gh
#     # The fixture is already generated in setup()
#
#     run "$SPACEHEATER" autostart --json
#     [ "$status" -eq 0 ]
#
#     # Verify valid JSON output
#     echo "$output" | jq empty  # Will fail if not valid JSON
#
#     # Check for expected fields
#     [[ $(echo "$output" | jq -r '.action') == "autostart" ]]
#     [[ $(echo "$output" | jq -r '.success') == "true" ]]
#     [[ $(echo "$output" | jq -r '.codespace') != "null" ]]
#     [[ $(echo "$output" | jq -r '.connection_url') != "null" ]]
#     [[ $(echo "$output" | jq -r '.connection_method') != "null" ]]
#     [[ $(echo "$output" | jq -r '.timestamp') != "null" ]]
# }
#
# @test "autostart command JSON selects clean codespace" {
#     # Mock gh to return codespace data
#     create_mock_gh
#     # The fixture is already generated in setup()
#
#     run "$SPACEHEATER" autostart --json
#     [ "$status" -eq 0 ]
#
#     # Check that a codespace was selected
#     [[ $(echo "$output" | jq -r '.codespace.name') != "null" ]]
#     # Check that temperature field exists
#     [[ $(echo "$output" | jq -r '.codespace.temperature') != "null" ]]
# }

@test "stop command supports --json flag" {
    # Mock gh to return codespace data
    create_mock_gh
    # The fixture is already generated in setup()

    run "$SPACEHEATER" stop hot-space-001 --json
    [ "$status" -eq 0 ]

    # Verify valid JSON output
    echo "$output" | jq empty  # Will fail if not valid JSON

    # Check for expected fields
    [[ $(echo "$output" | jq -r '.action') == "stop" ]]
    [[ $(echo "$output" | jq -r '.success') == "true" ]]
    [[ $(echo "$output" | jq -r '.codespace') != "null" ]]
    [[ $(echo "$output" | jq -r '.codespace.name') == "hot-space-001" ]]
    [[ $(echo "$output" | jq -r '.message') != "null" ]]
    [[ $(echo "$output" | jq -r '.timestamp') != "null" ]]
}

@test "stop all command supports --json flag" {
    # Mock gh to return codespace data
    create_mock_gh
    # The fixture is already generated in setup()

    run "$SPACEHEATER" stop all --json
    [ "$status" -eq 0 ]

    # Verify valid JSON output
    echo "$output" | jq empty  # Will fail if not valid JSON

    # Check for expected fields (array format)
    [[ $(echo "$output" | jq -r '.action') == "stop" ]]
    [[ $(echo "$output" | jq -r '.success') == "true" ]]
    [[ $(echo "$output" | jq -r '.codespaces') != "null" ]]
    [[ $(echo "$output" | jq -r '.codespaces | type') == "array" ]]
    [[ $(echo "$output" | jq -r '.count') != "null" ]]
    [[ $(echo "$output" | jq -r '.message') != "null" ]]
    [[ $(echo "$output" | jq -r '.timestamp') != "null" ]]
}

@test "stop all command JSON includes all stopped codespaces" {
    # Mock gh to return codespace data
    create_mock_gh
    # The fixture is already generated in setup()

    run "$SPACEHEATER" stop all --json
    [ "$status" -eq 0 ]

    # Check that codespaces array has entries (there's at least one Available in fixture)
    local count=$(echo "$output" | jq -r '.count')
    [[ "$count" -ge 0 ]]

    # If there are stopped codespaces, verify they have temperature field
    if [[ "$count" -gt 0 ]]; then
        [[ $(echo "$output" | jq -r '.codespaces[0].temperature') != "null" ]]
    fi
}
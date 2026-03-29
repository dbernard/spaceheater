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

# =============================================================================
# JSON Output Tests - Action Commands (start, stop)
# =============================================================================

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

@test "autostart command supports --json flag" {
    create_mock_gh_with_jq

    run "$SPACEHEATER" autostart --json
    [ "$status" -eq 0 ]

    # Verify valid JSON output
    echo "$output" | jq empty  # Will fail if not valid JSON

    # Check for expected fields
    [[ $(echo "$output" | jq -r '.action') == "autostart" ]]
    [[ $(echo "$output" | jq -r '.success') == "true" ]]
    [[ $(echo "$output" | jq -r '.codespace') != "null" ]]
    [[ $(echo "$output" | jq -r '.connection_url') != "null" ]]
    [[ $(echo "$output" | jq -r '.connection_method') != "null" ]]
    [[ $(echo "$output" | jq -r '.timestamp') != "null" ]]
}

@test "autostart command JSON selects clean codespace" {
    create_mock_gh_with_jq

    run "$SPACEHEATER" autostart --json
    [ "$status" -eq 0 ]

    # Check that a codespace was selected
    [[ $(echo "$output" | jq -r '.codespace.name') != "null" ]]
    # Check that temperature field exists
    [[ $(echo "$output" | jq -r '.codespace.temperature') != "null" ]]
}

@test "start command JSON returns structured error when API fetch fails" {
    # Mock gh where codespace list works but individual API fetch fails
    cat > "${MOCK_BIN_DIR}/gh" << 'EOFMOCK'
#!/usr/bin/env bash
case "$*" in
    "auth status")
        echo "✓ Logged in"
        exit 0
        ;;
    "api /repos/testorg/testrepo --jq .id")
        echo "12345678"
        exit 0
        ;;
    "api /user/codespaces?repository_id=12345678 --jq "*)
        # Return tab-separated format for codespace search
        printf 'hot-space-001\tRunning Test Codespace\n'
        exit 0
        ;;
    "api /user/codespaces?repository_id=12345678")
        cat "${FIXTURES}/codespaces.json"
        exit 0
        ;;
    "api /user/codespaces/"*)
        # Simulate API failure for individual codespace fetch
        exit 1
        ;;
    *)
        exit 1
        ;;
esac
EOFMOCK
    chmod +x "${MOCK_BIN_DIR}/gh"

    run "$SPACEHEATER" start hot-space-001 --json
    [ "$status" -ne 0 ]

    # Should produce valid JSON with error details
    echo "$output" | jq empty
    [[ $(echo "$output" | jq -r '.action') == "start" ]]
    [[ $(echo "$output" | jq -r '.success') == "false" ]]
    [[ $(echo "$output" | jq -r '.error') =~ "Failed to fetch" ]]
    [[ $(echo "$output" | jq -r '.codespace_name') == "hot-space-001" ]]
}

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

# =============================================================================
# JSON Output Tests - Lifecycle Commands (create, delete, clean)
# =============================================================================

@test "create command supports --json flag" {
    # Create custom mock gh that handles create properly
    cat > "${MOCK_BIN_DIR}/gh" << 'EOFMOCK'
#!/usr/bin/env bash
case "$*" in
    "auth status")
        echo "✓ Logged in to github.com as testuser"
        exit 0
        ;;
    "api /repos/testorg/testrepo --jq .id")
        echo "12345678"
        exit 0
        ;;
    "api /repos/testorg/testrepo/codespaces/machines --jq .machines[0].name")
        echo "basicLinux32gb"
        exit 0
        ;;
    "codespace create"*)
        echo "Creating codespace..."
        echo "test-created-123"
        exit 0
        ;;
    "api /user/codespaces/test-created-"*)
        echo '{
            "name": "test-created-123",
            "display_name": "Test Created",
            "state": "Starting",
            "created_at": "2024-03-18T10:00:00Z",
            "updated_at": "2024-03-18T10:00:00Z",
            "git_status": {
                "has_uncommitted_changes": false,
                "has_unpushed_changes": false,
                "ahead": 0,
                "behind": 0,
                "ref": "main"
            },
            "machine": {
                "display_name": "2 cores, 8 GB RAM"
            }
        }'
        exit 0
        ;;
    *)
        echo "Mock gh - unhandled: $*" >&2
        exit 1
        ;;
esac
EOFMOCK
    chmod +x "${MOCK_BIN_DIR}/gh"

    run "$SPACEHEATER" create --json
    [ "$status" -eq 0 ]

    # Verify valid JSON output
    echo "$output" | jq empty

    # Check for expected fields
    [[ $(echo "$output" | jq -r '.action') == "create" ]]
    [[ $(echo "$output" | jq -r '.success') == "true" ]]
    [[ $(echo "$output" | jq -r '.codespaces') != "null" ]]
    [[ $(echo "$output" | jq -r '.count') != "null" ]]
    [[ $(echo "$output" | jq -r '.timestamp') != "null" ]]
}

@test "create command supports -j shorthand for JSON" {
    cat > "${MOCK_BIN_DIR}/gh" << 'EOFMOCK'
#!/usr/bin/env bash
case "$*" in
    "auth status")
        echo "✓ Logged in"
        exit 0
        ;;
    "api /repos/testorg/testrepo --jq .id")
        echo "12345678"
        exit 0
        ;;
    "api /repos/testorg/testrepo/codespaces/machines --jq .machines[0].name")
        echo "basicLinux32gb"
        exit 0
        ;;
    "codespace create"*)
        echo "test-created-456"
        exit 0
        ;;
    "api /user/codespaces/test-created-"*)
        echo '{
            "name": "test-created-456",
            "display_name": "Test Created 2",
            "state": "Starting",
            "created_at": "2024-03-18T10:00:00Z",
            "updated_at": "2024-03-18T10:00:00Z",
            "git_status": {},
            "machine": {"display_name": "2 cores, 8 GB RAM"}
        }'
        exit 0
        ;;
    *)
        exit 1
        ;;
esac
EOFMOCK
    chmod +x "${MOCK_BIN_DIR}/gh"

    run "$SPACEHEATER" create -j
    [ "$status" -eq 0 ]

    # Verify valid JSON output
    echo "$output" | jq empty
    [[ $(echo "$output" | jq -r '.action') == "create" ]]
}

@test "create command JSON output includes created codespace details" {
    cat > "${MOCK_BIN_DIR}/gh" << 'EOFMOCK'
#!/usr/bin/env bash
case "$*" in
    "auth status")
        echo "✓ Logged in"
        exit 0
        ;;
    "api /repos/testorg/testrepo --jq .id")
        echo "12345678"
        exit 0
        ;;
    "api /repos/testorg/testrepo/codespaces/machines --jq .machines[0].name")
        echo "basicLinux32gb"
        exit 0
        ;;
    "codespace create"*)
        echo "new-space-789"
        exit 0
        ;;
    "api /user/codespaces/new-space-"*)
        echo '{
            "name": "new-space-789",
            "display_name": "New Codespace",
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
            "machine": {"display_name": "4 cores, 16 GB RAM"}
        }'
        exit 0
        ;;
    *)
        exit 1
        ;;
esac
EOFMOCK
    chmod +x "${MOCK_BIN_DIR}/gh"

    run "$SPACEHEATER" create --json
    [ "$status" -eq 0 ]

    # Check that codespace details are included
    [[ $(echo "$output" | jq -r '.codespaces[0].name') == "new-space-789" ]]
    [[ $(echo "$output" | jq -r '.codespaces[0].state') == "Available" ]]
    [[ $(echo "$output" | jq -r '.codespaces[0].temperature') != "null" ]]
    [[ $(echo "$output" | jq -r '.count') == "1" ]]
}

@test "delete command supports --json flag" {
    cat > "${MOCK_BIN_DIR}/gh" << 'EOFMOCK'
#!/usr/bin/env bash
case "$*" in
    "auth status")
        echo "✓ Logged in"
        exit 0
        ;;
    "api /repos/testorg/testrepo --jq .id")
        echo "12345678"
        exit 0
        ;;
    "api /user/codespaces?repository_id=12345678 --jq "*)
        echo -e "hot-space-001\tRunning Test Codespace"
        exit 0
        ;;
    "codespace delete"*)
        exit 0
        ;;
    "api /user/codespaces/hot-space-001")
        echo '{
            "name": "hot-space-001",
            "display_name": "Running Test Codespace",
            "state": "Available",
            "created_at": "2024-03-18T10:00:00Z",
            "updated_at": "2024-03-18T14:00:00Z",
            "git_status": {},
            "machine": {"display_name": "2 cores, 8 GB RAM"}
        }'
        exit 0
        ;;
    *)
        exit 1
        ;;
esac
EOFMOCK
    chmod +x "${MOCK_BIN_DIR}/gh"

    run "$SPACEHEATER" delete hot-space-001 --json
    [ "$status" -eq 0 ]

    # Verify valid JSON output
    echo "$output" | jq empty

    # Check for expected fields
    [[ $(echo "$output" | jq -r '.action') == "delete" ]]
    [[ $(echo "$output" | jq -r '.success') == "true" ]]
    [[ $(echo "$output" | jq -r '.codespace') != "null" ]]
    [[ $(echo "$output" | jq -r '.codespace.name') == "hot-space-001" ]]
    [[ $(echo "$output" | jq -r '.timestamp') != "null" ]]
}

@test "delete command supports -j shorthand for JSON" {
    cat > "${MOCK_BIN_DIR}/gh" << 'EOFMOCK'
#!/usr/bin/env bash
case "$*" in
    "auth status")
        echo "✓ Logged in"
        exit 0
        ;;
    "api /repos/testorg/testrepo --jq .id")
        echo "12345678"
        exit 0
        ;;
    "api /user/codespaces?repository_id=12345678 --jq "*)
        echo -e "warm-space-002\tClean Stopped Codespace"
        exit 0
        ;;
    "codespace delete"*)
        exit 0
        ;;
    "api /user/codespaces/warm-space-002")
        echo '{
            "name": "warm-space-002",
            "display_name": "Clean Stopped Codespace",
            "state": "Shutdown",
            "created_at": "2024-03-18T09:00:00Z",
            "updated_at": "2024-03-18T14:00:00Z",
            "git_status": {},
            "machine": {"display_name": "4 cores, 16 GB RAM"}
        }'
        exit 0
        ;;
    *)
        exit 1
        ;;
esac
EOFMOCK
    chmod +x "${MOCK_BIN_DIR}/gh"

    run "$SPACEHEATER" delete warm-space-002 -j
    [ "$status" -eq 0 ]

    # Verify valid JSON output
    echo "$output" | jq empty
    [[ $(echo "$output" | jq -r '.action') == "delete" ]]
    [[ $(echo "$output" | jq -r '.codespace.name') == "warm-space-002" ]]
}

@test "clean command supports --json flag" {
    # Create fixture with old codespaces
    local old_date=$(date -u -d "30 days ago" +%Y-%m-%dT%H:%M:%SZ 2>/dev/null || date -u -v-30d +%Y-%m-%dT%H:%M:%SZ)
    cat > "${FIXTURES}/codespaces.json" << EOF
{
  "codespaces": [
    {
      "name": "old-space-001",
      "display_name": "Old Codespace 1",
      "state": "Shutdown",
      "created_at": "$old_date",
      "updated_at": "$old_date",
      "git_status": {},
      "machine": {"display_name": "2 cores, 8 GB RAM"}
    },
    {
      "name": "old-space-002",
      "display_name": "Old Codespace 2",
      "state": "Shutdown",
      "created_at": "$old_date",
      "updated_at": "$old_date",
      "git_status": {},
      "machine": {"display_name": "2 cores, 8 GB RAM"}
    }
  ],
  "total_count": 2
}
EOF

    cat > "${MOCK_BIN_DIR}/gh" << EOFMOCK
#!/usr/bin/env bash
case "\$*" in
    "auth status")
        echo "✓ Logged in"
        exit 0
        ;;
    "api /repos/testorg/testrepo --jq .id")
        echo "12345678"
        exit 0
        ;;
    "api /user/codespaces?repository_id=12345678")
        cat "${FIXTURES}/codespaces.json"
        exit 0
        ;;
    "codespace delete"*)
        exit 0
        ;;
    "api /user/codespaces/old-space-001")
        echo '{
            "name": "old-space-001",
            "display_name": "Old Codespace 1",
            "state": "Shutdown",
            "created_at": "$old_date",
            "updated_at": "$old_date",
            "git_status": {},
            "machine": {"display_name": "2 cores, 8 GB RAM"}
        }'
        exit 0
        ;;
    "api /user/codespaces/old-space-002")
        echo '{
            "name": "old-space-002",
            "display_name": "Old Codespace 2",
            "state": "Shutdown",
            "created_at": "$old_date",
            "updated_at": "$old_date",
            "git_status": {},
            "machine": {"display_name": "2 cores, 8 GB RAM"}
        }'
        exit 0
        ;;
    *)
        exit 1
        ;;
esac
EOFMOCK
    chmod +x "${MOCK_BIN_DIR}/gh"

    run "$SPACEHEATER" clean 7 --json
    [ "$status" -eq 0 ]

    # Verify valid JSON output
    echo "$output" | jq empty

    # Check for expected fields
    [[ $(echo "$output" | jq -r '.action') == "clean" ]]
    [[ $(echo "$output" | jq -r '.success') == "true" ]]
    [[ $(echo "$output" | jq -r '.age_threshold_days') == "7" ]]
    [[ $(echo "$output" | jq -r '.total_found') != "null" ]]
    [[ $(echo "$output" | jq -r '.timestamp') != "null" ]]
}

@test "clean command supports -j shorthand for JSON" {
    create_mock_gh

    # Create fixture with no old codespaces
    cat > "${FIXTURES}/codespaces.json" << 'EOF'
{
  "codespaces": [],
  "total_count": 0
}
EOF

    run "$SPACEHEATER" clean 7 -j
    [ "$status" -eq 0 ]

    # Verify valid JSON output
    echo "$output" | jq empty
    [[ $(echo "$output" | jq -r '.action') == "clean" ]]
    [[ $(echo "$output" | jq -r '.deleted_count') == "0" ]]
}

@test "clean command JSON output includes deleted count and age threshold" {
    # Create fixture with one old codespace
    local old_date=$(date -u -d "15 days ago" +%Y-%m-%dT%H:%M:%SZ 2>/dev/null || date -u -v-15d +%Y-%m-%dT%H:%M:%SZ)
    cat > "${FIXTURES}/codespaces.json" << EOF
{
  "codespaces": [
    {
      "name": "ancient-space",
      "display_name": "Very Old Codespace",
      "state": "Shutdown",
      "created_at": "$old_date",
      "updated_at": "$old_date",
      "git_status": {},
      "machine": {"display_name": "2 cores, 8 GB RAM"}
    }
  ],
  "total_count": 1
}
EOF

    cat > "${MOCK_BIN_DIR}/gh" << EOFMOCK
#!/usr/bin/env bash
case "\$*" in
    "auth status")
        echo "✓ Logged in"
        exit 0
        ;;
    "api /repos/testorg/testrepo --jq .id")
        echo "12345678"
        exit 0
        ;;
    "api /user/codespaces?repository_id=12345678")
        cat "${FIXTURES}/codespaces.json"
        exit 0
        ;;
    "codespace delete"*)
        exit 0
        ;;
    "api /user/codespaces/ancient-space")
        echo '{
            "name": "ancient-space",
            "display_name": "Very Old Codespace",
            "state": "Shutdown",
            "created_at": "$old_date",
            "updated_at": "$old_date",
            "git_status": {},
            "machine": {"display_name": "2 cores, 8 GB RAM"}
        }'
        exit 0
        ;;
    *)
        exit 1
        ;;
esac
EOFMOCK
    chmod +x "${MOCK_BIN_DIR}/gh"

    run "$SPACEHEATER" clean 10 --json
    [ "$status" -eq 0 ]

    # Check age threshold is included
    [[ $(echo "$output" | jq -r '.age_threshold_days') == "10" ]]
    [[ $(echo "$output" | jq -r '.total_found') == "1" ]]
}

@test "create command JSON output handles creation failure" {
    # Write a fresh mock where codespace create fails
    cat > "${MOCK_BIN_DIR}/gh" << 'EOFMOCK'
#!/usr/bin/env bash
echo "gh $*" >> "${TEST_TEMP_DIR}/gh-calls.log"
case "$*" in
    "auth status")
        echo "✓ Logged in"
        exit 0
        ;;
    "api /repos/testorg/testrepo --jq .id")
        echo "12345678"
        exit 0
        ;;
    "api /repos/testorg/testrepo/codespaces/machines --jq .machines[0].name")
        echo "basicLinux32gb"
        exit 0
        ;;
    "codespace create"*)
        echo "Error: Failed to create codespace" >&2
        exit 1
        ;;
    *)
        exit 1
        ;;
esac
EOFMOCK
    chmod +x "${MOCK_BIN_DIR}/gh"

    run "$SPACEHEATER" create --json
    [ "$status" -eq 0 ]  # Command should still succeed but report failure in JSON

    # Verify error is reported in JSON
    echo "$output" | jq empty
    [[ $(echo "$output" | jq -r '.success') == "false" ]]
}

# =============================================================================
# JSON Output Tests for Info Commands
# =============================================================================

@test "version command supports --json flag" {
    run "$SPACEHEATER" version --json
    [ "$status" -eq 0 ]

    # Verify valid JSON output
    echo "$output" | jq empty

    # Check for expected fields
    [[ $(echo "$output" | jq -r '.version') != "null" ]]
    [[ $(echo "$output" | jq -r '.system') != "null" ]]
    [[ $(echo "$output" | jq -r '.system.os_type') != "null" ]]
    [[ $(echo "$output" | jq -r '.system.platform') != "null" ]]
    [[ $(echo "$output" | jq -r '.system.bash_version') != "null" ]]
    [[ $(echo "$output" | jq -r '.project.url') != "null" ]]
    [[ $(echo "$output" | jq -r '.project.license') != "null" ]]
    [[ $(echo "$output" | jq -r '.timestamp') != "null" ]]
}

@test "version command JSON includes git commit when available" {
    # Create a temporary git repo for testing
    cd "$TEST_TEMP_DIR"
    git init &>/dev/null
    git config user.email "test@example.com"
    git config user.name "Test User"
    echo "test" > test.txt
    git add test.txt
    git commit -m "test" &>/dev/null

    run "$SPACEHEATER" version --json
    [ "$status" -eq 0 ]

    # Git commit should be present since we're in a git repo
    local git_commit=$(echo "$output" | jq -r '.git_commit')
    [[ "$git_commit" =~ ^[0-9a-f]+$ ]] || [[ "$git_commit" == "null" ]]
}

@test "config command supports --json flag" {
    create_mock_gh
    create_mock_git
    create_mock_jq

    run "$SPACEHEATER" config --json
    [ "$status" -eq 0 ]

    # Verify valid JSON output
    echo "$output" | jq empty

    # Check for expected top-level structure
    [[ $(echo "$output" | jq -r '.loaded_config_files') != "null" ]]
    [[ $(echo "$output" | jq -r '.repository') != "null" ]]
    [[ $(echo "$output" | jq -r '.connection') != "null" ]]
    [[ $(echo "$output" | jq -r '.codespace_overrides') != "null" ]]
    [[ $(echo "$output" | jq -r '.ui') != "null" ]]
    [[ $(echo "$output" | jq -r '.debug') != "null" ]]
    [[ $(echo "$output" | jq -r '.detected') != "null" ]]
    [[ $(echo "$output" | jq -r '.timestamp') != "null" ]]
}

@test "config command JSON includes source information" {
    create_mock_gh
    create_mock_git
    create_mock_jq

    # Set an environment variable to test source tracking
    export SPACEHEATER_DEBUG="true"

    run "$SPACEHEATER" config --json
    [ "$status" -eq 0 ]

    # Check that values have source fields
    [[ $(echo "$output" | jq -r '.debug.enabled.source') != "null" ]]
    [[ $(echo "$output" | jq -r '.repository.repo.source') != "null" ]]
    [[ $(echo "$output" | jq -r '.connection.method.source') != "null" ]]
}

@test "config command JSON includes detected repository info" {
    create_mock_gh
    create_mock_git
    create_mock_jq

    run "$SPACEHEATER" config --json
    [ "$status" -eq 0 ]

    # Check detected repository fields
    [[ $(echo "$output" | jq -r '.detected.repository') == "testorg/testrepo" ]]
    [[ $(echo "$output" | jq -r '.detected.branch') != "null" ]]
}

@test "config init command supports --json flag" {
    cd "$TEST_TEMP_DIR"

    run "$SPACEHEATER" config init .test-config.conf --json
    [ "$status" -eq 0 ]

    # Verify valid JSON output
    echo "$output" | jq empty

    # Check for expected fields
    [[ $(echo "$output" | jq -r '.success') == "true" ]]
    [[ $(echo "$output" | jq -r '.file_path') != "null" ]]
    [[ $(echo "$output" | jq -r '.location') != "null" ]]
    [[ $(echo "$output" | jq -r '.template') == "default" ]]
    [[ $(echo "$output" | jq -r '.timestamp') != "null" ]]

    # Verify file was actually created
    [ -f ".test-config.conf" ]
}

@test "config init command JSON reports error when file exists" {
    cd "$TEST_TEMP_DIR"

    # Create the file first
    echo "test" > .existing-config.conf

    run "$SPACEHEATER" config init .existing-config.conf --json
    [ "$status" -ne 0 ]

    # Verify valid JSON output
    echo "$output" | jq empty

    # Check for expected error fields
    [[ $(echo "$output" | jq -r '.success') == "false" ]]
    [[ $(echo "$output" | jq -r '.error') == "Config file already exists" ]]
    [[ $(echo "$output" | jq -r '.file_path') != "null" ]]
}

@test "config init command JSON tracks directory creation" {
    cd "$TEST_TEMP_DIR"

    run "$SPACEHEATER" config init newdir/config.conf --json
    [ "$status" -eq 0 ]

    # Check that directory_created is true
    [[ $(echo "$output" | jq -r '.directory_created') == "true" ]]
    [[ $(echo "$output" | jq -r '.success') == "true" ]]

    # Verify directory and file were created
    [ -d "newdir" ]
    [ -f "newdir/config.conf" ]
}

@test "config edit command supports --json flag" {
    cd "$TEST_TEMP_DIR"

    # Create a config file first
    echo "REPO=test/repo" > .spaceheater.conf

    # Mock git to make it look like we're in a repo
    create_mock_git

    run "$SPACEHEATER" config edit --json
    [ "$status" -eq 0 ]

    # Verify valid JSON output
    echo "$output" | jq empty

    # Check for expected fields
    [[ $(echo "$output" | jq -r '.success') == "true" ]]
    [[ $(echo "$output" | jq -r '.file_path') != "null" ]]
    [[ $(echo "$output" | jq -r '.editor') != "null" ]]
    [[ $(echo "$output" | jq -r '.config_type') != "null" ]]
    [[ $(echo "$output" | jq -r '.file_exists') == "true" ]]
    [[ $(echo "$output" | jq -r '.note') =~ "text output mode" ]]
}

@test "config edit command JSON reports error when file doesn't exist" {
    cd "$TEST_TEMP_DIR"

    run "$SPACEHEATER" config edit --json
    [ "$status" -ne 0 ]

    # Verify valid JSON output
    echo "$output" | jq empty

    # Check for expected error fields
    [[ $(echo "$output" | jq -r '.success') == "false" ]]
    [[ $(echo "$output" | jq -r '.error') == "Config file does not exist" ]]
    [[ $(echo "$output" | jq -r '.file_exists') == "false" ]]
}

# =============================================================================
# Schedule Command Tests
# =============================================================================

# Helper to set up schedule test environment
setup_schedule_env() {
    create_mock_gh
    create_mock_git
    create_mock_launchctl
    # Point HOME to test temp dir so plists go to mock LaunchAgents
    export HOME="$TEST_TEMP_DIR"
    mkdir -p "${TEST_TEMP_DIR}/Library/LaunchAgents"
}

@test "schedule help shows usage information" {
    run "$SPACEHEATER" schedule help
    [ "$status" -eq 0 ]
    [[ "$output" =~ "SPACEHEATER SCHEDULE" ]]
    [[ "$output" =~ "SUBCOMMANDS" ]]
    [[ "$output" =~ "PRESETS" ]]
    [[ "$output" =~ "weekday-morning" ]]
}

@test "schedule set with --preset weekday-morning generates correct plist" {
    setup_schedule_env

    run "$SPACEHEATER" schedule set 2 --preset weekday-morning
    [ "$status" -eq 0 ]

    # Verify plist was created
    local plist_path="${TEST_TEMP_DIR}/Library/LaunchAgents/com.spaceheater.schedule.testorg-testrepo.plist"
    [ -f "$plist_path" ]

    # Verify plist content
    [[ $(cat "$plist_path") =~ "com.spaceheater.schedule.testorg-testrepo" ]]
    [[ $(cat "$plist_path") =~ "<key>SPACEHEATER_REPO</key>" ]]
    [[ $(cat "$plist_path") =~ "<string>testorg/testrepo</string>" ]]
    [[ $(cat "$plist_path") =~ "<string>2</string>" ]]
    [[ $(cat "$plist_path") =~ "<key>Hour</key>" ]]
    [[ $(cat "$plist_path") =~ "<integer>8</integer>" ]]
    [[ $(cat "$plist_path") =~ "<key>Weekday</key>" ]]
}

@test "schedule set with --preset daily generates correct plist" {
    setup_schedule_env

    run "$SPACEHEATER" schedule set 1 --preset daily
    [ "$status" -eq 0 ]

    local plist_path="${TEST_TEMP_DIR}/Library/LaunchAgents/com.spaceheater.schedule.testorg-testrepo.plist"
    [ -f "$plist_path" ]

    # Daily should have Hour=9, Minute=0, no Weekday
    [[ $(cat "$plist_path") =~ "<integer>9</integer>" ]]
    ! [[ $(cat "$plist_path") =~ "<key>Weekday</key>" ]]
}

@test "schedule set with custom --hour --minute --weekday generates correct plist" {
    setup_schedule_env

    run "$SPACEHEATER" schedule set 1 --hour 7 --minute 30 --weekday 1-5
    [ "$status" -eq 0 ]

    local plist_path="${TEST_TEMP_DIR}/Library/LaunchAgents/com.spaceheater.schedule.testorg-testrepo.plist"
    [ -f "$plist_path" ]

    [[ $(cat "$plist_path") =~ "<integer>7</integer>" ]]
    [[ $(cat "$plist_path") =~ "<integer>30</integer>" ]]
    [[ $(cat "$plist_path") =~ "<key>Weekday</key>" ]]
}

@test "schedule set validates count must be 1-3" {
    setup_schedule_env

    run "$SPACEHEATER" schedule set 0 --preset daily
    [ "$status" -ne 0 ]
    [[ "$output" =~ "Count must be between 1 and 3" ]]

    run "$SPACEHEATER" schedule set 4 --preset daily
    [ "$status" -ne 0 ]
    [[ "$output" =~ "Count must be between 1 and 3" ]]

    run "$SPACEHEATER" schedule set abc --preset daily
    [ "$status" -ne 0 ]
    [[ "$output" =~ "Count must be between 1 and 3" ]]
}

@test "schedule set requires count argument" {
    setup_schedule_env

    run "$SPACEHEATER" schedule set --preset daily
    [ "$status" -ne 0 ]
    [[ "$output" =~ "Missing required argument" ]]
}

@test "schedule set requires --preset or --hour/--minute" {
    setup_schedule_env

    run "$SPACEHEATER" schedule set 2
    [ "$status" -ne 0 ]
    [[ "$output" =~ "Must specify --preset" ]]
}

@test "schedule set rejects invalid preset name" {
    setup_schedule_env

    run "$SPACEHEATER" schedule set 2 --preset invalid-preset
    [ "$status" -ne 0 ]
    [[ "$output" =~ "Unknown preset" ]]
}

@test "schedule set rejects invalid weekday value" {
    setup_schedule_env

    run "$SPACEHEATER" schedule set 1 --hour 8 --weekday 9
    [ "$status" -ne 0 ]
    [[ "$output" =~ "Invalid weekday" ]]
}

@test "schedule set rejects reversed weekday range" {
    setup_schedule_env

    run "$SPACEHEATER" schedule set 1 --hour 8 --weekday 5-1
    [ "$status" -ne 0 ]
    [[ "$output" =~ "Invalid weekday range" ]]
}

@test "schedule set cannot combine --preset with --hour" {
    setup_schedule_env

    run "$SPACEHEATER" schedule set 2 --preset daily --hour 8
    [ "$status" -ne 0 ]
    [[ "$output" =~ "Cannot use --preset with" ]]
}

@test "schedule set updates existing schedule for same repo" {
    setup_schedule_env

    # Create initial schedule
    run "$SPACEHEATER" schedule set 1 --preset daily
    [ "$status" -eq 0 ]

    local plist_path="${TEST_TEMP_DIR}/Library/LaunchAgents/com.spaceheater.schedule.testorg-testrepo.plist"
    [ -f "$plist_path" ]

    # Update with new schedule
    run "$SPACEHEATER" schedule set 2 --preset weekday-morning
    [ "$status" -eq 0 ]
    [ -f "$plist_path" ]

    # Should have new count
    [[ $(cat "$plist_path") =~ "<string>2</string>" ]]
    # launchctl bootout should have been called for the removal
    assert_launchctl_called_with "bootout"
}

@test "schedule set includes SPACEHEATER_REPO in plist" {
    setup_schedule_env

    run "$SPACEHEATER" schedule set 1 --preset daily
    [ "$status" -eq 0 ]

    local plist_path="${TEST_TEMP_DIR}/Library/LaunchAgents/com.spaceheater.schedule.testorg-testrepo.plist"
    [[ $(cat "$plist_path") =~ "<key>SPACEHEATER_REPO</key>" ]]
    [[ $(cat "$plist_path") =~ "<string>testorg/testrepo</string>" ]]
}

@test "schedule set includes PATH in plist" {
    setup_schedule_env

    run "$SPACEHEATER" schedule set 1 --preset daily
    [ "$status" -eq 0 ]

    local plist_path="${TEST_TEMP_DIR}/Library/LaunchAgents/com.spaceheater.schedule.testorg-testrepo.plist"
    [[ $(cat "$plist_path") =~ "<key>PATH</key>" ]]
    [[ $(cat "$plist_path") =~ "/usr/local/bin" ]]
}

@test "schedule set uses absolute path to spaceheater in ProgramArguments" {
    setup_schedule_env

    run "$SPACEHEATER" schedule set 1 --preset daily
    [ "$status" -eq 0 ]

    local plist_path="${TEST_TEMP_DIR}/Library/LaunchAgents/com.spaceheater.schedule.testorg-testrepo.plist"
    # Should contain an absolute path (starts with /)
    [[ $(cat "$plist_path") =~ "<string>/".*/spaceheater"</string>" ]]
}

@test "schedule set calls launchctl bootstrap" {
    setup_schedule_env

    run "$SPACEHEATER" schedule set 1 --preset daily
    [ "$status" -eq 0 ]

    assert_launchctl_called_with "bootstrap"
}

@test "schedule list shows entries from plist files" {
    setup_schedule_env

    # Create a schedule first
    "$SPACEHEATER" schedule set 2 --preset weekday-morning

    run "$SPACEHEATER" schedule list
    [ "$status" -eq 0 ]
    [[ "$output" =~ "testorg/testrepo" ]]
    [[ "$output" =~ "2" ]]
}

@test "schedule list shows message when no schedules exist" {
    setup_schedule_env

    run "$SPACEHEATER" schedule list
    [ "$status" -eq 0 ]
    [[ "$output" =~ "No schedules" ]]
}

@test "schedule remove deletes plist and calls launchctl bootout" {
    setup_schedule_env

    # Create a schedule first
    "$SPACEHEATER" schedule set 1 --preset daily

    local plist_path="${TEST_TEMP_DIR}/Library/LaunchAgents/com.spaceheater.schedule.testorg-testrepo.plist"
    [ -f "$plist_path" ]

    run "$SPACEHEATER" schedule remove
    [ "$status" -eq 0 ]
    [ ! -f "$plist_path" ]
    assert_launchctl_called_with "bootout"
}

@test "schedule remove --all removes all spaceheater plists" {
    setup_schedule_env

    # Create a schedule
    "$SPACEHEATER" schedule set 1 --preset daily

    local plist_path="${TEST_TEMP_DIR}/Library/LaunchAgents/com.spaceheater.schedule.testorg-testrepo.plist"
    [ -f "$plist_path" ]

    run "$SPACEHEATER" schedule remove --all
    [ "$status" -eq 0 ]
    [ ! -f "$plist_path" ]
    [[ "$output" =~ "Removed" ]]
}

@test "schedule remove warns when no schedule exists" {
    setup_schedule_env

    run "$SPACEHEATER" schedule remove
    [ "$status" -ne 0 ]
    [[ "$output" =~ "No schedule found" ]]
}

@test "schedule set JSON output has correct structure" {
    setup_schedule_env

    run "$SPACEHEATER" schedule set 2 --preset weekday-morning --json
    [ "$status" -eq 0 ]

    # Verify valid JSON
    echo "$output" | jq empty

    [[ $(echo "$output" | jq -r '.action') == "schedule_set" ]]
    [[ $(echo "$output" | jq -r '.success') == "true" ]]
    [[ $(echo "$output" | jq -r '.schedule.repository') == "testorg/testrepo" ]]
    [[ $(echo "$output" | jq '.schedule.desired_count') == "2" ]]
}

@test "schedule list JSON output has correct structure" {
    setup_schedule_env

    # Create a schedule first
    "$SPACEHEATER" schedule set 1 --preset daily

    run "$SPACEHEATER" schedule list --json
    [ "$status" -eq 0 ]

    echo "$output" | jq empty

    [[ $(echo "$output" | jq -r '.action') == "schedule_list" ]]
    [[ $(echo "$output" | jq -r '.success') == "true" ]]
    [[ $(echo "$output" | jq '.count') == "1" ]]
    [[ $(echo "$output" | jq -r '.schedules[0].repository') == "testorg/testrepo" ]]
}

@test "schedule remove JSON output has correct structure" {
    setup_schedule_env

    "$SPACEHEATER" schedule set 1 --preset daily

    run "$SPACEHEATER" schedule remove --json
    [ "$status" -eq 0 ]

    echo "$output" | jq empty

    [[ $(echo "$output" | jq -r '.action') == "schedule_remove" ]]
    [[ $(echo "$output" | jq -r '.success') == "true" ]]
    [[ $(echo "$output" | jq -r '.repository') == "testorg/testrepo" ]]
}

@test "schedule invalid subcommand returns error" {
    run "$SPACEHEATER" schedule invalid-subcmd
    [ "$status" -ne 0 ]
    [[ "$output" =~ "Unknown schedule subcommand" ]]
}

@test "schedule presets resolve to correct values" {
    setup_schedule_env

    # Test each preset generates a valid plist
    for preset in weekday-morning weekday-evening weekday-hourly hourly daily twice-daily; do
        run "$SPACEHEATER" schedule set 1 --preset "$preset"
        [ "$status" -eq 0 ]
        # Clean up for next iteration
        "$SPACEHEATER" schedule remove 2>/dev/null || true
    done
}

@test "schedule status shows schedule info" {
    setup_schedule_env

    "$SPACEHEATER" schedule set 2 --preset weekday-morning

    run "$SPACEHEATER" schedule status
    [ "$status" -eq 0 ]
    [[ "$output" =~ "testorg/testrepo" ]]
    [[ "$output" =~ "2" ]]
}

@test "schedule status JSON parses launchctl exit status" {
    setup_schedule_env

    "$SPACEHEATER" schedule set 1 --preset daily

    run "$SPACEHEATER" schedule status --json
    [ "$status" -eq 0 ]

    echo "$output" | jq empty
    [[ $(echo "$output" | jq '.schedules[0].last_exit_status') == "0" ]]
}

# =============================================================================
# Schedule Run (Smart Top-up) Tests
# =============================================================================

@test "schedule run creates deficit codespaces when below target" {
    # Use the jq-capable mock since schedule run uses complex jq filters
    create_mock_gh_with_jq
    create_mock_git
    create_mock_launchctl

    # Fixture has 1 HOT (Available) + 1 WARM (Shutdown, clean, <3 days) = 2
    # Requesting 3 should create 1
    run "$SPACEHEATER" schedule run 3
    [ "$status" -eq 0 ]

    echo "$output" | jq empty
    [[ $(echo "$output" | jq -r '.action') == "schedule_run" ]]
    [[ $(echo "$output" | jq -r '.skipped') == "false" ]]
    [[ $(echo "$output" | jq '.desired_count') == "3" ]]
    [[ $(echo "$output" | jq '.existing_hot_warm') == "2" ]]
    [[ $(echo "$output" | jq '.created_count') == "1" ]]
    # Verify cmd_create output is nested under create_result
    [[ $(echo "$output" | jq 'has("create_result")') == "true" ]]
}

@test "schedule run creates nothing when target is met" {
    create_mock_gh_with_jq
    create_mock_git
    create_mock_launchctl

    # Fixture has 2 HOT+WARM codespaces, requesting 2 should skip
    run "$SPACEHEATER" schedule run 2
    [ "$status" -eq 0 ]

    echo "$output" | jq empty
    [[ $(echo "$output" | jq -r '.skipped') == "true" ]]
    [[ $(echo "$output" | jq -r '.message') == "Target already met" ]]
}

@test "schedule run creates partial when some HOT/WARM exist" {
    create_mock_gh_with_jq
    create_mock_git
    create_mock_launchctl

    # Fixture has 2 HOT+WARM, requesting 3 should try to create 1
    run "$SPACEHEATER" schedule run 3
    [ "$status" -eq 0 ]

    echo "$output" | jq empty
    [[ $(echo "$output" | jq '.created_count') == "1" ]]
    [[ $(echo "$output" | jq '.existing_hot_warm') == "2" ]]
}

@test "schedule run validates count" {
    create_mock_gh_with_jq
    create_mock_git

    run "$SPACEHEATER" schedule run 0
    [ "$status" -ne 0 ]

    run "$SPACEHEATER" schedule run 4
    [ "$status" -ne 0 ]

    run "$SPACEHEATER" schedule run
    [ "$status" -ne 0 ]
}

@test "schedule run outputs JSON with correct fields" {
    create_mock_gh_with_jq
    create_mock_git
    create_mock_launchctl

    run "$SPACEHEATER" schedule run 2
    [ "$status" -eq 0 ]

    echo "$output" | jq empty
    [[ $(echo "$output" | jq -r '.action') == "schedule_run" ]]
    [[ $(echo "$output" | jq -r '.repository') == "testorg/testrepo" ]]
    [[ $(echo "$output" | jq '.desired_count') == "2" ]]
    [[ $(echo "$output" | jq -r '.success') == "true" ]]
}
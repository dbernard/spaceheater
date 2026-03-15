#!/usr/bin/env bash
# Test helper for spaceheater Bats tests
# Provides common setup, teardown, and mock utilities

# Export paths
export PROJECT_ROOT="${BATS_TEST_DIRNAME}/.."
export SPACEHEATER="${PROJECT_ROOT}/spaceheater"
export FIXTURES="${BATS_TEST_DIRNAME}/fixtures"

# Generate codespaces fixture with relative dates
# This ensures test dates remain realistic over time
generate_codespaces_fixture() {
    local target_file="$1"

    # Generate relative timestamps (cross-platform compatible)
    local now=$(date -u +%Y-%m-%dT%H:%M:%SZ)

    # Calculate relative dates based on epoch seconds for cross-platform compatibility
    local now_epoch=$(date +%s)
    local two_hours_ago_epoch=$((now_epoch - 7200))
    local yesterday_epoch=$((now_epoch - 86400))
    local two_weeks_ago_epoch=$((now_epoch - 1209600))

    # Convert back to ISO 8601 format
    local two_hours_ago=$(date -u -r $two_hours_ago_epoch +%Y-%m-%dT%H:%M:%SZ 2>/dev/null || date -u -d "@$two_hours_ago_epoch" +%Y-%m-%dT%H:%M:%SZ 2>/dev/null || echo "$now")
    local yesterday_created=$(date -u -r $yesterday_epoch +%Y-%m-%dT%H:%M:%SZ 2>/dev/null || date -u -d "@$yesterday_epoch" +%Y-%m-%dT%H:%M:%SZ 2>/dev/null || echo "$now")
    local yesterday_updated=$(date -u -r $((yesterday_epoch + 28800)) +%Y-%m-%dT%H:%M:%SZ 2>/dev/null || date -u -d "@$((yesterday_epoch + 28800))" +%Y-%m-%dT%H:%M:%SZ 2>/dev/null || echo "$now")
    local two_weeks_ago_created=$(date -u -r $two_weeks_ago_epoch +%Y-%m-%dT%H:%M:%SZ 2>/dev/null || date -u -d "@$two_weeks_ago_epoch" +%Y-%m-%dT%H:%M:%SZ 2>/dev/null || echo "$now")
    local two_weeks_ago_updated=$(date -u -r $((two_weeks_ago_epoch + 28800)) +%Y-%m-%dT%H:%M:%SZ 2>/dev/null || date -u -d "@$((two_weeks_ago_epoch + 28800))" +%Y-%m-%dT%H:%M:%SZ 2>/dev/null || echo "$now")

    # Generate fixture with relative dates
    cat > "$target_file" << EOF
{
  "codespaces": [
    {
      "name": "hot-space-001",
      "display_name": "Running Test Codespace",
      "state": "Available",
      "created_at": "$two_hours_ago",
      "updated_at": "$now",
      "git_status": {
        "ahead": 0,
        "behind": 0,
        "has_uncommitted_changes": false,
        "has_unpushed_changes": false
      },
      "machine": {
        "display_name": "2 cores, 8 GB RAM"
      }
    },
    {
      "name": "warm-space-002",
      "display_name": "Clean Stopped Codespace",
      "state": "Shutdown",
      "created_at": "$yesterday_created",
      "updated_at": "$yesterday_updated",
      "git_status": {
        "ahead": 0,
        "behind": 0,
        "has_uncommitted_changes": false,
        "has_unpushed_changes": false
      },
      "machine": {
        "display_name": "4 cores, 16 GB RAM"
      }
    },
    {
      "name": "cold-space-003",
      "display_name": "Old Dirty Codespace",
      "state": "Shutdown",
      "created_at": "$two_weeks_ago_created",
      "updated_at": "$two_weeks_ago_updated",
      "git_status": {
        "ahead": 2,
        "behind": 1,
        "has_uncommitted_changes": true,
        "has_unpushed_changes": true
      },
      "machine": {
        "display_name": "2 cores, 8 GB RAM"
      }
    }
  ]
}
EOF
}

# Setup function - runs before each test
setup() {
    # Create temp directory for test isolation
    export TEST_TEMP_DIR="$(mktemp -d -t spaceheater-test.XXXXXX)"
    export MOCK_BIN_DIR="${TEST_TEMP_DIR}/bin"
    mkdir -p "$MOCK_BIN_DIR"

    # Create fixtures directory if it doesn't exist
    mkdir -p "$FIXTURES"

    # Generate dynamic fixture with current relative dates
    generate_codespaces_fixture "${FIXTURES}/codespaces.json"

    # Add mock bin to PATH (before real commands)
    export ORIGINAL_PATH="$PATH"
    export PATH="${MOCK_BIN_DIR}:${PATH}"

    # Set test environment variables
    export SPACEHEATER_REPO="testorg/testrepo"
    export SPACEHEATER_BRANCH="main"
    export NO_COLOR=1
    export SPACEHEATER_DEBUG=false

    # Clear any cached repo ID
    unset CACHED_REPO_ID
}

# Teardown function - runs after each test
teardown() {
    # Restore original PATH
    export PATH="$ORIGINAL_PATH"

    # Clean up temp directory with safety check
    # Only delete if it's a spaceheater test directory to prevent accidental deletions
    if [[ -d "$TEST_TEMP_DIR" && "$TEST_TEMP_DIR" == */spaceheater-test.* ]]; then
        rm -rf "$TEST_TEMP_DIR"
    fi
}

# Create a basic mock gh command
#
# IMPORTANT: Mock-Script Coupling
# ===============================
# This mock is tightly coupled to the exact jq query patterns used in the main
# spaceheater script. If you change jq queries in spaceheater, update the mock
# accordingly. Known coupling points:
#
#   get_repo_id()    - '--jq .id' for repository ID lookup
#   cmd_start()      - '--jq '.codespaces | .[] | "\(.name)\t\(.display_name // .name)"''
#                      for tab-separated codespace name/display_name pairs
#   cmd_list()       - Full JSON response (no --jq) for codespace list display
#   cmd_cleanup()    - '--jq' queries for filtering Shutdown and Available codespaces
#
# The mock matches these patterns using shell case statements. Changes to the main
# script's jq queries may cause tests to silently break if the mock isn't updated.
#
# To detect coupling breaks, grep for '--jq' in the main script and verify all
# patterns are handled by the mock cases below.
create_mock_gh() {
    cat > "${MOCK_BIN_DIR}/gh" << 'EOF'
#!/usr/bin/env bash
# Mock gh CLI for testing

# Log calls for debugging
echo "gh $*" >> "${TEST_TEMP_DIR}/gh-calls.log"

case "$*" in
    "auth status")
        echo "✓ Logged in to github.com as testuser (oauth_token)"
        echo "✓ Git operations for github.com configured to use https protocol."
        exit 0
        ;;

    # Explicit match for repo ID query with --jq
    "api /repos/testorg/testrepo --jq .id")
        echo "12345678"
        exit 0
        ;;

    # Explicit match for repo info (without --jq)
    "api /repos/testorg/testrepo")
        echo '{"id": 12345678, "default_branch": "main", "full_name": "testorg/testrepo"}'
        exit 0
        ;;

    # Explicit match for machines API with --jq (used by get_default_machine)
    "api /repos/testorg/testrepo/codespaces/machines --jq .machines[0].name")
        echo "basicLinux32gb"
        exit 0
        ;;

    # Explicit match for machines API (without --jq)
    "api /repos/testorg/testrepo/codespaces/machines")
        echo '{"machines":[{"name":"basicLinux32gb","display_name":"2 cores, 8 GB RAM","cpus":2}],"total_count":1}'
        exit 0
        ;;

    # Explicit match for codespace list with --jq (used by cmd_start for searching)
    "api /user/codespaces?repository_id=12345678 --jq "*)
        # Return tab-separated format for name and display_name
        if [[ -f "${FIXTURES}/codespaces.json" ]]; then
            # Simulate the jq output for the query used in cmd_start
            cat "${FIXTURES}/codespaces.json" | command jq -r '.codespaces | .[] | "\(.name)\t\(.display_name // .name)"' 2>/dev/null || echo ""
        fi
        exit 0
        ;;

    # Original case for non-jq codespace list (used by cmd_list)
    "api /user/codespaces?repository_id=12345678")
        if [[ -f "${FIXTURES}/codespaces.json" ]]; then
            cat "${FIXTURES}/codespaces.json"
        else
            echo '{"codespaces": []}'
        fi
        exit 0
        ;;

    "codespace create"*)
        echo "Creating codespace in testorg/testrepo..."
        echo "✓ Codespace created: test-created-$(date +%s)"
        exit 0
        ;;

    "codespace stop"*)
        echo "Stopping codespace: $3"
        exit 0
        ;;

    "codespace delete"*)
        echo "Deleting codespace: $3"
        exit 0
        ;;

    "codespace code"*|"codespace ssh"*)
        echo "Opening codespace: ${4:-$3}"
        exit 0
        ;;

    "repo view"*)
        echo "testorg/testrepo"
        exit 0
        ;;

    *)
        echo "Error: Mock gh - unhandled command: $*" >&2
        exit 1
        ;;
esac
EOF
    chmod +x "${MOCK_BIN_DIR}/gh"
}

# Create mock jq command (for tests that need specific jq behavior)
create_mock_jq() {
    # Just pass through to real jq if it exists
    if command -v jq >/dev/null 2>&1; then
        ln -s "$(command -v jq)" "${MOCK_BIN_DIR}/jq"
    else
        # Minimal mock that just cats input
        cat > "${MOCK_BIN_DIR}/jq" << 'EOF'
#!/usr/bin/env bash
cat
EOF
        chmod +x "${MOCK_BIN_DIR}/jq"
    fi
}

# Create mock git command
create_mock_git() {
    cat > "${MOCK_BIN_DIR}/git" << 'EOF'
#!/usr/bin/env bash
case "$1" in
    "rev-parse")
        if [[ "$2" == "--show-toplevel" ]]; then
            echo "/Users/test/testorg/testrepo"
        elif [[ "$2" == "--abbrev-ref" && "$3" == "HEAD" ]]; then
            echo "main"
        fi
        exit 0
        ;;
    "remote")
        if [[ "$2" == "get-url" ]]; then
            echo "https://github.com/testorg/testrepo.git"
        fi
        exit 0
        ;;
    *)
        echo "Error: Mock git - unhandled command: $*" >&2
        exit 1
        ;;
esac
EOF
    chmod +x "${MOCK_BIN_DIR}/git"
}

# Verify gh was called with expected arguments
assert_gh_called_with() {
    local expected="$1"
    if [[ -f "${TEST_TEMP_DIR}/gh-calls.log" ]]; then
        if grep -q "$expected" "${TEST_TEMP_DIR}/gh-calls.log"; then
            return 0
        else
            echo "Expected gh to be called with: $expected" >&2
            echo "Actual calls:" >&2
            cat "${TEST_TEMP_DIR}/gh-calls.log" >&2
            return 1
        fi
    else
        echo "No gh calls recorded" >&2
        return 1
    fi
}

# Count how many times gh was called
count_gh_calls() {
    if [[ -f "${TEST_TEMP_DIR}/gh-calls.log" ]]; then
        wc -l < "${TEST_TEMP_DIR}/gh-calls.log" | tr -d ' '
    else
        echo "0"
    fi
}
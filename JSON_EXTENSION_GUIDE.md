# JSON Output Extension Guide

This guide explains how to extend JSON output support to other spaceheater commands using the reusable utilities we've created.

## Core Utilities Available

### 1. Temperature Calculation
```bash
get_temperature_jq_filter()
```
Returns the JQ filter for calculating temperature from codespace state. This centralizes the temperature logic (hot/warm/cold/transitioning) in one place.

### 2. Git Status Utilities
```bash
get_git_clean_jq_filter()           # Determines if git is clean
get_git_status_normalization_filter() # Normalizes git status with defaults
```

### 3. Age Calculation
```bash
get_age_calculation_filter()
```
Calculates age in days and seconds from timestamps.

### 4. Field Mapping
```bash
get_codespace_json_fields [include_optional]
```
Returns standard codespace field mappings. Pass `false` to exclude optional fields like web_url, recent_folders, etc.

### 5. Complete Filter Builder
```bash
build_codespace_json_filter [include_optional]
```
Combines all utilities into a complete transformation filter.

### 6. Output Helpers
```bash
output_single_codespace_json <action> <codespace_name> [message]
output_multiple_codespaces_json <action> <codespace_names...>
```

## How to Add JSON Support to a Command

### Pattern 1: List-Style Commands

For commands that return multiple codespaces (like `list`):

```bash
cmd_example() {
  init_repo_config

  if [ "${OUTPUT_FORMAT:-}" = "json" ]; then
    local codespace_filter=$(build_codespace_json_filter true)

    get_all_codespaces | jq --arg repo "$REPO" "
      (now | todate) as \$current_time |
      {
        codespaces: (.codespaces | map($codespace_filter) | sort_by(.created_at) | reverse),
        repository: \$repo,
        timestamp: \$current_time
      }
    "
    return
  fi

  # Regular text output...
}
```

### Pattern 2: Single Codespace Commands

For commands that operate on a single codespace (like `start`, `stop`, `delete`):

```bash
cmd_start() {
  init_repo_config
  # ... find codespace_name ...

  if [ "${OUTPUT_FORMAT:-}" = "json" ]; then
    # Start the codespace
    gh codespace start -c "$codespace_name"

    # Output JSON result
    output_single_codespace_json "start" "$codespace_name" "Codespace started successfully"
    return
  fi

  # Regular text output...
}
```

### Pattern 3: Multiple Operation Commands

For commands that create/delete multiple codespaces (like `create`, `clean`):

```bash
cmd_create() {
  init_repo_config
  local count="${1:-1}"
  local -a created_names=()

  # Create codespaces and collect names
  for i in $(seq 1 "$count"); do
    local name=$(gh codespace create ... | extract_name)
    created_names+=("$name")
  done

  if [ "${OUTPUT_FORMAT:-}" = "json" ]; then
    output_multiple_codespaces_json "create" "${created_names[@]}"
    return
  fi

  # Regular text output...
}
```

### Pattern 4: Simple Status Commands

For commands like `config` or `version`:

```bash
cmd_config() {
  init_repo_config

  if [ "${OUTPUT_FORMAT:-}" = "json" ]; then
    jq -n \
      --arg repo "$REPO" \
      --arg branch "$BRANCH" \
      --arg machine "${MACHINE:-default}" \
      '{
        repository: $repo,
        branch: $branch,
        machine: $machine,
        # ... other config fields
      }'
    return
  fi

  # Regular text output...
}
```

## Testing JSON Output

When adding JSON support to a command, add corresponding tests:

```bash
@test "command supports --json flag" {
  create_mock_gh
  run "$SPACEHEATER" command --json
  [ "$status" -eq 0 ]

  # Verify valid JSON
  echo "$output" | jq empty

  # Check expected fields
  [[ $(echo "$output" | jq -r '.field') != "null" ]]
}
```

## Benefits of This Approach

1. **DRY Principle**: Temperature logic is maintained in one place
2. **Consistency**: All commands output similar JSON structure
3. **Maintainability**: Changes to temperature calculation or field mappings only need to be made once
4. **Extensibility**: Easy to add new fields or modify existing ones
5. **Type Safety**: JQ filters ensure consistent data types
6. **Error Handling**: JSON error output is handled globally

## Future Enhancements

Consider adding:
- JSON streaming for real-time updates
- Pagination support for large result sets
- Field filtering (e.g., `--json-fields=name,state,temperature`)
- JSON Schema validation
- API versioning for JSON output format
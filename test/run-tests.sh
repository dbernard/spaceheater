#!/usr/bin/env bash
# Bats wrapper that streams output, persists a log, and prints a trailing
# failure summary so failures survive `tail -N` truncation of suite output.
#
# Usage:
#   bash test/run-tests.sh                          # run full suite
#   bash test/run-tests.sh --filter-status failed   # rerun only failures
#   bash test/run-tests.sh test/foo.bats            # run specific file
#
# Side effects:
#   - Writes full output to .test-output.log (gitignored via *.log)
#   - Bats persists rerun state under test/.bats/ (gitignored)

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
LOG_FILE="${REPO_ROOT}/.test-output.log"

# Bats only persists per-run status (used by --filter-status failed) if this
# directory already exists.
mkdir -p "${REPO_ROOT}/test/.bats/run-logs"

# Default to running the whole test/ directory when no positional test
# path was given (so flag-only invocations like `--filter-status failed`
# still target the suite).
has_path=false
for arg in "$@"; do
  if [[ -e "$arg" ]]; then
    has_path=true
    break
  fi
done
if [[ "$has_path" == "false" ]]; then
  set -- "$@" "test/"
fi

set +e
bats --print-output-on-failure "$@" 2>&1 | tee "$LOG_FILE"
status=${PIPESTATUS[0]}
set -e

if [[ "$status" -ne 0 ]]; then
  echo
  echo "=== FAILURES ==="
  grep -E '^(not ok |#)' "$LOG_FILE" || true
  echo "================"
  echo "Full output: ${LOG_FILE}"
  echo "Rerun only failures: make test-failed"
fi

exit "$status"

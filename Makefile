.PHONY: help install uninstall test test-failed lint check clean

# ShellCheck minimum severity: error, warning (default), info, style
SHELLCHECK_SEVERITY ?= warning

# Default target
help:
	@echo "spaceheater - Makefile targets:"
	@echo ""
	@echo "  make install     Install spaceheater to your system"
	@echo "  make uninstall   Uninstall spaceheater from your system"
	@echo "  make test        Run test suite (writes .test-output.log)"
	@echo "  make test-failed Rerun only tests that failed last run"
	@echo "  make lint        Check shell script syntax and run ShellCheck"
	@echo "  make check       Check prerequisites"
	@echo "  make clean       Clean test artifacts"
	@echo ""

# Install spaceheater
install:
	@echo "Running installer..."
	@bash install.sh

# Uninstall spaceheater
uninstall:
	@echo "Running uninstaller..."
	@bash uninstall.sh

# Run test suite. On failure, the wrapper prints a trailing
# "=== FAILURES ===" block so `tail -N` of the output is enough to
# see what failed without rerunning the suite.
test: lint
	@if command -v bats >/dev/null 2>&1; then \
		echo "Running Bats test suite..."; \
		bash test/run-tests.sh; \
	else \
		echo "⚠️  Bats test framework not found"; \
		echo "   Install from: https://github.com/bats-core/bats-core"; \
		echo "   • macOS: brew install bats-core"; \
		echo "   • Ubuntu/Debian: apt-get install bats"; \
		echo "   • npm: npm install -g bats"; \
		echo ""; \
		echo "Falling back to basic smoke tests..."; \
		bash -c './spaceheater version' && \
		bash -c './spaceheater help > /dev/null' && \
		echo "✓ Basic smoke tests passed"; \
	fi

# Rerun only the tests that failed in the previous `make test` run.
# Relies on bats' run-log under test/.bats/run-logs/.
test-failed:
	@if ! command -v bats >/dev/null 2>&1; then \
		echo "✗ bats not installed"; exit 1; \
	fi
	@if [ -z "$$(ls -A test/.bats/run-logs/ 2>/dev/null)" ]; then \
		echo "No previous test run found. Run 'make test' first."; \
		exit 1; \
	fi
	@bash test/run-tests.sh --filter-status failed

# Lint shell scripts
lint:
	@echo "Checking shell script syntax..."
	@bash -n spaceheater
	@bash -n install.sh
	@if [ -f uninstall.sh ]; then bash -n uninstall.sh; fi
	@echo "✓ No syntax errors"
	@if command -v shellcheck >/dev/null 2>&1; then \
		echo "Running ShellCheck (-S $(SHELLCHECK_SEVERITY))..." && \
		shellcheck -S $(SHELLCHECK_SEVERITY) spaceheater install.sh && \
		(if [ -f uninstall.sh ]; then shellcheck -S $(SHELLCHECK_SEVERITY) uninstall.sh; fi) && \
		(if [ -f test/test_helper.bash ]; then shellcheck -S $(SHELLCHECK_SEVERITY) test/test_helper.bash; fi) && \
		echo "✓ ShellCheck passed"; \
	else \
		echo "⚠ ShellCheck not installed (recommended: brew install shellcheck)"; \
	fi

# Check prerequisites
check:
	@echo "Checking prerequisites..."
	@command -v bash >/dev/null 2>&1 || { echo "✗ bash not found"; exit 1; }
	@echo "✓ bash found: $$(bash --version | head -1)"
	@command -v gh >/dev/null 2>&1 || { echo "✗ gh (GitHub CLI) not found"; exit 1; }
	@echo "✓ gh found: $$(gh --version | head -1)"
	@command -v python3 >/dev/null 2>&1 || { echo "✗ python3 not found"; exit 1; }
	@echo "✓ python3 found: $$(python3 --version)"
	@command -v git >/dev/null 2>&1 || { echo "✗ git not found"; exit 1; }
	@echo "✓ git found: $$(git --version)"
	@gh auth status >/dev/null 2>&1 || { echo "⚠ Not authenticated with GitHub (run: gh auth login)"; exit 0; }
	@echo "✓ GitHub authenticated"
	@echo ""
	@echo "All prerequisites satisfied!"

# Clean test artifacts
clean:
	@echo "Cleaning test artifacts..."
	@rm -rf spaceheater-test-*
	@rm -f test/*.log
	@rm -rf test/tmp
	@rm -rf test/.bats
	@rm -f .test-output.log
	@echo "✓ Test artifacts cleaned"

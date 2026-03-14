.PHONY: help install uninstall test lint check clean

# Default target
help:
	@echo "spaceheater - Makefile targets:"
	@echo ""
	@echo "  make install     Install spaceheater to your system"
	@echo "  make uninstall   Uninstall spaceheater from your system"
	@echo "  make test        Run test suite"
	@echo "  make lint        Check shell script syntax"
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

# Run test suite
test: lint
	@if command -v bats >/dev/null 2>&1; then \
		echo "Running Bats test suite..."; \
		bats test/*.bats; \
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

# Lint shell scripts
lint:
	@echo "Checking shell script syntax..."
	@bash -n spaceheater
	@bash -n install.sh
	@if [ -f uninstall.sh ]; then bash -n uninstall.sh; fi
	@echo "✓ No syntax errors"

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
	@echo "✓ Test artifacts cleaned"

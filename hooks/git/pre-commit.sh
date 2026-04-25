#!/bin/bash
# CHP Pre-Commit Hook
# Installed to .git/hooks/pre-commit
# Runs before each commit — blocking

# CHP-MANAGED

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
exec "$PROJECT_ROOT/core/dispatcher.sh" pre-commit "$@"

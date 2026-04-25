#!/bin/bash
# CHP Pre-Rebase Hook
# Installed to .git/hooks/pre-rebase
# Runs before a rebase operation

# CHP-MANAGED

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
exec "$PROJECT_ROOT/core/dispatcher.sh" pre-rebase "$@"


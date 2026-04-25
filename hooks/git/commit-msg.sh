#!/bin/bash
# CHP Commit-Msg Hook
# Installed to .git/hooks/commit-msg
# Runs after commit message is provided

# CHP-MANAGED

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
exec "$PROJECT_ROOT/core/dispatcher.sh" commit-msg "$@"

# Exit with dispatcher's exit code

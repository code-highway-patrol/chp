#!/usr/bin/env bash
# CHP Post-Merge Hook
# Installed to .git/hooks/post-merge
# Runs after a merge has been completed

# CHP-MANAGED

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
exec "$PROJECT_ROOT/core/dispatcher.sh" post-merge "$@"

# Always allow merge to succeed

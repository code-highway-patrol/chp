#!/usr/bin/env bash
# CHP Post-Update Hook
# Installed to .git/hooks/post-update
# Runs on remote repository after updates have been pushed

# CHP-MANAGED

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
exec "$PROJECT_ROOT/core/dispatcher.sh" post-update "$@"

# Always allow update to succeed

#!/usr/bin/env bash
# CHP Post-Applypatch Hook
# Installed to .git/hooks/post-applypatch
# Runs after a patch has been applied

# CHP-MANAGED

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
exec "$PROJECT_ROOT/core/dispatcher.sh" post-applypatch "$@"

# Always allow patch application to succeed

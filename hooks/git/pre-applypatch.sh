#!/usr/bin/env bash
# CHP Pre-Applypatch Hook
# Installed to .git/hooks/pre-applypatch
# Runs before a patch is applied

# CHP-MANAGED

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
exec "$PROJECT_ROOT/core/dispatcher.sh" pre-applypatch "$@"


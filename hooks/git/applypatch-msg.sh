#!/usr/bin/env bash
# CHP Applypatch-Message Hook
# Installed to .git/hooks/applypatch-msg
# Validates the commit message of a patch

# CHP-MANAGED

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
exec "$PROJECT_ROOT/core/dispatcher.sh" applypatch-msg "$@"


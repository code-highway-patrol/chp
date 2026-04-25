#!/usr/bin/env bash
# CHP Prepare-Commit-Message Hook
# Installed to .git/hooks/prepare-commit-msg
# Runs before the commit message editor is shown

# CHP-MANAGED

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
exec "$PROJECT_ROOT/core/dispatcher.sh" prepare-commit-msg "$@"

# Always allow commit message preparation to succeed

#!/usr/bin/env bash
# CHP Pre-Response Hook
# Installed to .claude/hooks/pre-response.sh
# Runs before response is sent to user - can trigger regeneration

# CHP-MANAGED

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
exec "$PROJECT_ROOT/core/dispatcher.sh" pre-response "$@"


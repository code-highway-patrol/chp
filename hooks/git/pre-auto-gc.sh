#!/bin/bash
# CHP Pre-Auto-GC Hook
# Installed to .git/hooks/pre-auto-gc
# Runs before automatic garbage collection

# CHP-MANAGED

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../../core/dispatcher.sh" pre-auto-gc "$@"

# Always allow garbage collection to proceed
exit 0

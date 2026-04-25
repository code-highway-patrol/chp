#!/bin/bash
# CHP Pre-Applypatch Hook
# Installed to .git/hooks/pre-applypatch
# Runs before a patch is applied

# CHP-MANAGED

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../../core/dispatcher.sh" pre-applypatch "$@"

exit $?

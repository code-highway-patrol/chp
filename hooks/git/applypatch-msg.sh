#!/bin/bash
# CHP Applypatch-Message Hook
# Installed to .git/hooks/applypatch-msg
# Validates the commit message of a patch

# CHP-MANAGED

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../../core/dispatcher.sh" applypatch-msg "$@"

exit $?

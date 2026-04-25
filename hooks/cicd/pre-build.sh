#!/bin/bash
# CHP Pre-Build Hook
# Installed to .chp/cicd-hooks/pre-build.sh
# Runs before build process starts - can block build on failure

# CHP-MANAGED

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../../core/dispatcher.sh" pre-build "$@"

exit $?

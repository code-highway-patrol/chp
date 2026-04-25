#!/bin/bash
# CHP Post-Build Hook
# Installed to .chp/cicd-hooks/post-build.sh
# Runs after build completes - reports status but doesn't block

# CHP-MANAGED

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../../core/dispatcher.sh" post-build "$@"

exit $?

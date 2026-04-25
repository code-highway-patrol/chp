#!/bin/bash
# CHP Pre-Build Hook
# Installed to CI/CD pipeline before build
# Runs before build process starts

# CHP-MANAGED

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../../core/dispatcher.sh" pre-build "$@"

# Exit with dispatcher's exit code
exit $?

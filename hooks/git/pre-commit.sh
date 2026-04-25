#!/bin/bash
# CHP Pre-Commit Hook
# Installed to .git/hooks/pre-commit
# Runs before a commit is created

# CHP-MANAGED

# Calculate CHP_BASE from .git/hooks going up to repo root
CHP_BASE="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
source "$CHP_BASE/core/dispatcher.sh" pre-commit "$@"

# Exit with dispatcher's exit code
exit $?

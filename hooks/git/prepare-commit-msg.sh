#!/usr/bin/env bash
# CHP prepare-commit-msg Hook — installed to .git/hooks/prepare-commit-msg
# CHP-MANAGED

CHP_BASE="${CHP_BASE:-__CHP_BASE_DEFAULT__}"
exec "$CHP_BASE/core/dispatcher.sh" prepare-commit-msg "$@"

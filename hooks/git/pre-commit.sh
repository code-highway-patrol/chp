#!/usr/bin/env bash
# CHP pre-commit Hook — installed to .git/hooks/pre-commit
# CHP-MANAGED

CHP_BASE="${CHP_BASE:-__CHP_BASE_DEFAULT__}"
exec "$CHP_BASE/core/dispatcher.sh" pre-commit "$@"

#!/usr/bin/env bash
# CHP pre-prompt Hook — installed to .claude/hooks/pre-prompt
# CHP-MANAGED

CHP_BASE="${CHP_BASE:-__CHP_BASE_DEFAULT__}"
exec "$CHP_BASE/core/dispatcher.sh" pre-prompt "$@"

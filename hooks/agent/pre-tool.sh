#!/usr/bin/env bash
# CHP pre-tool Hook — installed to .claude/hooks/pre-tool
# CHP-MANAGED

CHP_BASE="${CHP_BASE:-__CHP_BASE_DEFAULT__}"
exec "$CHP_BASE/core/dispatcher.sh" pre-tool "$@"

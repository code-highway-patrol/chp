#!/usr/bin/env bash
# CHP applypatch-msg Hook — installed to .git/hooks/applypatch-msg
# CHP-MANAGED

CHP_BASE="${CHP_BASE:-__CHP_BASE_DEFAULT__}"
exec "$CHP_BASE/core/dispatcher.sh" applypatch-msg "$@"

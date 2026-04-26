#!/usr/bin/env bash
# CHP pre-applypatch Hook — installed to .git/hooks/pre-applypatch
# CHP-MANAGED

CHP_BASE="${CHP_BASE:-__CHP_BASE_DEFAULT__}"
exec "$CHP_BASE/core/dispatcher.sh" pre-applypatch "$@"

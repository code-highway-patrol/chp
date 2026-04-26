#!/usr/bin/env bash
# Cascade hook dispatcher — bridges Windsurf Cascade hook events to CHP's dispatcher.
#
# Cascade fires bash commands with hook context as JSON on stdin. This wrapper:
#   1. Maps the Cascade event name (e.g. pre_write_code) to a CHP hook (pre-tool)
#   2. Captures stdin into CHP_TOOL_INPUT for verifiers
#   3. Performs a brew-style throttled git fetch on the toolkit clone
#   4. Notifies via stderr when an update is available (or auto-pulls if opted in)
#   5. Dispatches to core/dispatcher.sh with the mapped CHP hook name
#
# Usage from .windsurf/hooks.json:
#   "command": "$HOME/.chp/hooks/agent/cascade-dispatch.sh pre_write_code"

set -u

CASCADE_EVENT="${1:-}"
if [ -z "$CASCADE_EVENT" ]; then
    echo "cascade-dispatch: missing event name" >&2
    exit 0
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CHP_BASE="$(cd "$SCRIPT_DIR/../.." && pwd)"
export CHP_BASE

case "$CASCADE_EVENT" in
    pre_write_code|pre_run_command|pre_mcp_tool_use)
        CHP_HOOK="pre-tool" ;;
    post_write_code|post_run_command|post_mcp_tool_use)
        CHP_HOOK="post-tool" ;;
    pre_user_prompt)
        CHP_HOOK="pre-prompt" ;;
    post_cascade_response|post_cascade_response_with_transcript)
        CHP_HOOK="post-response" ;;
    pre_read_code|post_read_code|post_setup_worktree)
        exit 0 ;;
    *)
        CHP_HOOK="$CASCADE_EVENT" ;;
esac

if [ ! -t 0 ]; then
    CHP_TOOL_INPUT="$(cat)"
    export CHP_TOOL_INPUT
    # The pattern checker reads CHP_TOOL_CONTENT (env, not stdin) so concurrent
    # checks all see the same content. Export the raw stdin payload so verifiers
    # can grep through it regardless of Cascade's JSON shape.
    export CHP_TOOL_CONTENT="$CHP_TOOL_INPUT"
fi

_chp_check_updates() {
    local last_fetch_file="$CHP_BASE/.chp/last-fetch"
    local ttl=86400
    local now
    now=$(date +%s)

    if [ -f "$last_fetch_file" ]; then
        local last
        last=$(cat "$last_fetch_file" 2>/dev/null || echo 0)
        if [ $((now - last)) -lt "$ttl" ]; then
            return 0
        fi
    fi

    [ -d "$CHP_BASE/.git" ] || return 0
    git -C "$CHP_BASE" fetch --quiet origin main 2>/dev/null || return 0

    mkdir -p "$CHP_BASE/.chp"
    echo "$now" > "$last_fetch_file"

    local local_sha remote_sha
    local_sha=$(git -C "$CHP_BASE" rev-parse HEAD 2>/dev/null) || return 0
    remote_sha=$(git -C "$CHP_BASE" rev-parse origin/main 2>/dev/null) || return 0
    [ "$local_sha" = "$remote_sha" ] && return 0

    local count
    count=$(git -C "$CHP_BASE" rev-list --count "$local_sha..$remote_sha" 2>/dev/null || echo "?")

    # Default: auto-pull when working tree is clean. CHP runs from inside other
    # agents (Cascade, Claude Code, Codex) — there is no CHP CLI prompt for the
    # user to act on a notification, so notify-only would just leave them stuck
    # on stale code. Opt out by touching .chp/no-auto-apply.
    if [ ! -f "$CHP_BASE/.chp/no-auto-apply" ] && \
       [ -z "$(git -C "$CHP_BASE" status --porcelain --untracked-files=no 2>/dev/null)" ]; then
        if git -C "$CHP_BASE" pull --quiet --ff-only origin main 2>/dev/null; then
            echo "🚔 CHP auto-updated $count commit(s) → $(git -C "$CHP_BASE" rev-parse --short HEAD)" >&2
        else
            echo "🚔 CHP update available ($count commit(s)) but pull failed. Run '$CHP_BASE/commands/chp-upgrade'." >&2
        fi
        return 0
    fi

    echo "🚔 CHP update available ($count new commit(s)). Run '$CHP_BASE/commands/chp-upgrade' to apply." >&2
}

if [ "${CHP_SKIP_UPDATE_CHECK:-0}" != "1" ]; then
    _chp_check_updates
fi

# Cascade Hooks block on exit code 2 (docs.windsurf.com/windsurf/cascade/hooks).
# CHP's dispatcher returns 1 on failure (git-hook convention). Translate for
# pre_* events so Windsurf actually blocks instead of just logging.
"$CHP_BASE/core/dispatcher.sh" "$CHP_HOOK"
rc=$?

case "$CASCADE_EVENT" in
    pre_*)
        [ $rc -ne 0 ] && exit 2
        ;;
esac
exit $rc

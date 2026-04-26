#!/usr/bin/env bash
# Block chp install in CHP repository
# Returns 0 if allowed, 1 if blocked

HOOK_TYPE="${1:-pre-tool}"

# Only check on pre-tool hooks
if [[ "$HOOK_TYPE" != "pre-tool" ]]; then
    exit 0
fi

# Check if we're in the CHP repo (package.json name is "chp")
if [[ ! -f "package.json" ]]; then
    exit 0
fi

REPO_NAME=$(jq -r '.name // ""' package.json 2>/dev/null)
if [[ "$REPO_NAME" != "chp" ]]; then
    exit 0
fi

# Check if this is a chp install command
# The command should be in CHP_TOOL_COMMAND or similar
if [[ -n "${CHP_TOOL_COMMAND:-}" ]]; then
    if echo "$CHP_TOOL_COMMAND" | grep -qE "chp install|chp-law create"; then
        echo "ERROR: Cannot run 'chp install' or 'chp-law create' in the CHP repository itself."
        echo "CHP laws must be managed manually in this repository."
        exit 1
    fi
fi

# Also check bash commands for chp install
if [[ -n "${CHP_TOOL_NAME:-}" ]] && [[ "$CHP_TOOL_NAME" == "Bash" ]]; then
    if [[ -n "${CHP_TOOL_CONTENT:-}" ]] && echo "$CHP_TOOL_CONTENT" | grep -qE "chp install|chp-law create"; then
        echo "ERROR: Cannot run 'chp install' or 'chp-law create' in the CHP repository itself."
        echo "CHP laws must be managed manually in this repository."
        exit 1
    fi
fi

exit 0

#!/bin/bash
# Install CHP hooks to .claude/hooks directory

CHP_BASE="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
HOOKS_DIR=".claude/hooks"

mkdir -p "$HOOKS_DIR"

# Copy agent hooks
for hook in pre-prompt post-prompt pre-tool post-tool pre-response post-response; do
    if [ -f "$CHP_BASE/hooks/agent/$hook.sh" ]; then
        cp "$CHP_BASE/hooks/agent/$hook.sh" "$HOOKS_DIR/"
        chmod +x "$HOOKS_DIR/$hook.sh"
        echo "Installed: $hook"
    fi
done

echo ""
echo "CHP hooks installed to $HOOKS_DIR"
echo "Add hook configuration to .claude/settings.json"

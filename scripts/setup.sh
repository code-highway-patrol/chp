#!/usr/bin/env bash
# CHP Setup - One-command installation
# Usage: bash scripts/setup.sh

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CHP_BASE="$(cd "$SCRIPT_DIR/.." && pwd)"

source "$CHP_BASE/core/common.sh"
source "$CHP_BASE/core/hook-registry.sh"
source "$CHP_BASE/core/detector.sh"
source "$CHP_BASE/core/installer.sh"

echo ""
echo "=== CHP Setup ==="
echo ""

# 1. Check dependencies
echo "Checking dependencies..."

missing=0
for cmd in bash git jq; do
    if command -v "$cmd" >/dev/null 2>&1; then
        log_info "  $cmd: found"
    else
        log_error "  $cmd: MISSING"
        missing=$((missing + 1))
    fi
done

if [ $missing -gt 0 ]; then
    log_error "Install missing dependencies and re-run setup."
    exit 1
fi

echo ""

# 2. Initialize hook registry
echo "Initializing hook registry..."
init_hook_registry
log_info "Registry ready at .chp/hook-registry.json"
echo ""

# 3. Scan laws and register them with hooks (batched for performance)
echo "Scanning laws..."
declare -A hook_to_laws
registered_hooks=0
registered_laws=0

for law_dir in "$CHP_BASE/docs/chp/laws"/*/; do
    law_name=$(basename "$law_dir")
    law_json="$law_dir/law.json"

    if [ ! -f "$law_json" ]; then
        continue
    fi

    enabled=$(jq -r '.enabled // true' "$law_json" 2>/dev/null)
    if [ "$enabled" != "true" ]; then
        log_info "  $law_name: disabled, skipping"
        continue
    fi

    hooks=$(jq -r '.hooks[] // empty' "$law_json" 2>/dev/null)
    if [ -z "$hooks" ]; then
        log_info "  $law_name: no hooks defined"
        continue
    fi

    while IFS= read -r hook_type; do
        hook_type=$(echo "$hook_type" | tr -d '\r')
        [ -z "$hook_type" ] && continue
        # Collect hook->law mappings in memory instead of writing immediately
        hook_to_laws["$hook_type"]+="$law_name "
        registered_hooks=$((registered_hooks + 1))
    done <<< "$hooks"

    registered_laws=$((registered_laws + 1))
    log_info "  $law_name: registered"
done

# Batch write all hook registrations in a single operation
echo ""
log_info "Writing $registered_hooks hook bindings in single batch..."
tmp_file=$(mktemp)
cat > "$tmp_file" << 'EOF'
{
  "hooks": {
EOF

first=true
for hook_type in "${!hook_to_laws[@]}"; do
    laws="${hook_to_laws[$hook_type]}"
    # Convert space-separated list to JSON array
    laws_array=$(echo "$laws" | tr ' ' '\n' | jq -R . | jq -s .)

    if [ "$first" = true ]; then
        first=false
    else
        printf ',\n' >> "$tmp_file"
    fi
    printf '    "%s": {"laws": %s, "enabled": true, "blocking": true}' "$hook_type" "$laws_array" >> "$tmp_file"
done

cat >> "$tmp_file" << 'EOF'

  },
  "version": "1.0"
}
EOF

mv "$tmp_file" "$HOOK_REGISTRY"
log_info "Registry batch-write complete"

echo ""
log_info "Registered $registered_laws laws with $registered_hooks hook bindings"
echo ""

# 4. Install git hooks
echo "Installing git hooks..."
if can_install_git_hooks; then
    ensure_hooks_installed
else
    log_warn "Not a git repository, skipping git hook installation"
fi
echo ""

# 5. Install Claude Code hooks (if .claude directory exists)
if [ -d ".claude" ]; then
    echo "Installing Claude Code agent hooks..."
    ensure_hooks_installed
    echo ""
fi

# 6. Summary
echo "=== Setup Complete ==="
echo ""
echo "Laws:    $registered_laws"
echo "Hooks:   $registered_hooks bindings"
echo ""
echo "Quick start:"
echo "  bash commands/chp-hooks list       # See all hooks"
echo "  bash commands/chp-status           # See current status"
echo "  bash commands/chp-law create       # Create a new law"
echo ""

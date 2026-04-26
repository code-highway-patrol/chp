#!/bin/bash
# Test hook registry functions

set -e  # Exit on test failures

# Get the script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../core/common.sh"
source "$SCRIPT_DIR/../core/hook-registry.sh"

# Setup test environment
TEST_REGISTRY="$CHP_BASE/.chp/hook-registry.json.test"
TEST_CHP_BASE="$CHP_BASE"

# Backup original registry if exists
backup_registry() {
    if [ -f "$TEST_REGISTRY" ]; then
        mv "$TEST_REGISTRY" "$TEST_REGISTRY.backup"
    fi
}

restore_registry() {
    if [ -f "$TEST_REGISTRY.backup" ]; then
        mv "$TEST_REGISTRY.backup" "$TEST_REGISTRY"
    elif [ -f "$TEST_REGISTRY" ]; then
        rm "$TEST_REGISTRY"
    fi
}

# Set up test environment
backup_registry

# Override registry location for testing
export CHP_BASE="$TEST_CHP_BASE"
export HOOK_REGISTRY="$TEST_REGISTRY"

cleanup() {
    restore_registry
}
trap cleanup EXIT

echo "Testing hook-registry.sh functions..."
echo "Using test registry: $TEST_REGISTRY"
echo ""

# Test 1: Registry initialization
echo "Test 1: Registry initialization creates file"
rm -f "$TEST_REGISTRY"
init_hook_registry
if [ -f "$TEST_REGISTRY" ]; then
    echo "  ✓ Registry file created"
    # Check structure
    if jq -e '.hooks' "$TEST_REGISTRY" >/dev/null 2>&1; then
        echo "  ✓ Registry has 'hooks' key"
    else
        echo "  ✗ Registry missing 'hooks' key"
        exit 1
    fi
    if jq -e '.version' "$TEST_REGISTRY" >/dev/null 2>&1; then
        echo "  ✓ Registry has 'version' key"
    else
        echo "  ✗ Registry missing 'version' key"
        exit 1
    fi
else
    echo "  ✗ Registry file NOT created"
    exit 1
fi
echo ""

# Test 2: Register a law to a hook
echo "Test 2: Register a law to a hook"
rm -f "$TEST_REGISTRY"
init_hook_registry
register_hook_law "pre-commit" "no-console-log"
laws=$(get_hook_laws "pre-commit")
if echo "$laws" | grep -q "no-console-log"; then
    echo "  ✓ Law 'no-console-log' registered to pre-commit"
else
    echo "  ✗ Law NOT registered"
    echo "    Got laws: $laws"
    exit 1
fi
echo ""

# Test 3: Register multiple laws
echo "Test 3: Register multiple laws to same hook"
rm -f "$TEST_REGISTRY"
init_hook_registry
register_hook_law "pre-commit" "no-console-log"
register_hook_law "pre-commit" "no-api-keys"
laws=$(get_hook_laws "pre-commit")
law_count=$(echo "$laws" | jq '. | length')
if [ "$law_count" -eq 2 ]; then
    echo "  ✓ Two laws registered"
else
    echo "  ✗ Expected 2 laws, got $law_count"
    echo "    Laws: $laws"
    exit 1
fi
echo ""

# Test 4: Unregister a law
echo "Test 4: Unregister a law from a hook"
rm -f "$TEST_REGISTRY"
init_hook_registry
register_hook_law "pre-commit" "no-console-log"
register_hook_law "pre-commit" "no-api-keys"
unregister_hook_law "pre-commit" "no-console-log"
laws=$(get_hook_laws "pre-commit")
if echo "$laws" | grep -q "no-console-log"; then
    echo "  ✗ Law still present after unregister"
    exit 1
else
    echo "  ✓ Law successfully unregistered"
fi
remaining_count=$(echo "$laws" | jq '. | length')
if [ "$remaining_count" -eq 1 ]; then
    echo "  ✓ One law remains"
else
    echo "  ✗ Expected 1 law, got $remaining_count"
    exit 1
fi
echo ""

# Test 5: Get laws for non-existent hook
echo "Test 5: Get laws for non-existent hook"
laws=$(get_hook_laws "non-existent")
if [ "$laws" = "[]" ] || [ "$laws" = "" ]; then
    echo "  ✓ Returns empty array for non-existent hook"
else
    echo "  ✗ Unexpected result for non-existent hook: $laws"
    exit 1
fi
echo ""

# Test 6: Set and check blocking behavior
echo "Test 6: Set and check blocking behavior"
rm -f "$TEST_REGISTRY"
init_hook_registry
register_hook_law "pre-commit" "test-law"
set_hook_blocking "pre-commit" true
if is_hook_blocking "pre-commit"; then
    echo "  ✓ Hook is blocking (true)"
else
    echo "  ✗ Hook should be blocking"
    exit 1
fi

set_hook_blocking "pre-commit" false
if is_hook_blocking "pre-commit"; then
    echo "  ✗ Hook should not be blocking"
    exit 1
else
    echo "  ✓ Hook is not blocking (false)"
fi
echo ""

# Test 7: Set and check enabled state
echo "Test 7: Set and check enabled state"
rm -f "$TEST_REGISTRY"
init_hook_registry
register_hook_law "pre-commit" "test-law"
set_hook_enabled "pre-commit" true
if is_hook_enabled "pre-commit"; then
    echo "  ✓ Hook is enabled (true)"
else
    echo "  ✗ Hook should be enabled"
    exit 1
fi

set_hook_enabled "pre-commit" false
if is_hook_enabled "pre-commit"; then
    echo "  ✗ Hook should not be enabled"
    exit 1
else
    echo "  ✓ Hook is not enabled (false)"
fi
echo ""

# Test 8: List hooks
echo "Test 8: List all registered hooks"
rm -f "$TEST_REGISTRY"
init_hook_registry
register_hook_law "pre-commit" "law1"
register_hook_law "pre-tool" "law2"
register_hook_law "post-commit" "law3"

hooks=$(list_hooks)
hook_count=$(echo "$hooks" | jq '. | length')
if [ "$hook_count" -eq 3 ]; then
    echo "  ✓ Three hooks registered"
else
    echo "  ✗ Expected 3 hooks, got $hook_count"
    echo "    Hooks: $hooks"
    exit 1
fi
echo ""

# Test 9: Re-registering same law doesn't duplicate
echo "Test 9: Re-registering same law doesn't duplicate"
rm -f "$TEST_REGISTRY"
init_hook_registry
register_hook_law "pre-commit" "no-console-log"
register_hook_law "pre-commit" "no-console-log"
laws=$(get_hook_laws "pre-commit")
law_count=$(echo "$laws" | jq '. | length')
if [ "$law_count" -eq 1 ]; then
    echo "  ✓ No duplicate on re-registration"
else
    echo "  ✗ Expected 1 law, got $law_count"
    exit 1
fi
echo ""

# Test 10: _ensure_registry creates registry if missing
echo "Test 10: _ensure_registry creates registry if missing"
rm -f "$TEST_REGISTRY"
_ensure_registry
if [ -f "$TEST_REGISTRY" ]; then
    echo "  ✓ Registry created by _ensure_registry"
else
    echo "  ✗ Registry NOT created"
    exit 1
fi
echo ""

# Cleanup
rm -f "$TEST_REGISTRY"

echo ""
echo "All tests passed!"

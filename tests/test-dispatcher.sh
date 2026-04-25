#!/bin/bash
# Test dispatcher functions

set -e  # Exit on test failures

# Get the script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../core/common.sh"
source "$SCRIPT_DIR/../core/hook-registry.sh"
source "$SCRIPT_DIR/../core/tightener.sh"

# Setup test environment
TEST_REGISTRY="$CHP_BASE/.chp/hook-registry.json.test"
TEST_CHP_BASE="$CHP_BASE"
TEST_LAWS_DIR="$CHP_BASE/docs/chp/laws"

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

cleanup_test_law() {
    if [ -d "$TEST_LAWS_DIR/test-dispatcher-law" ]; then
        rm -rf "$TEST_LAWS_DIR/test-dispatcher-law"
    fi
}

# Set up test environment
backup_registry

# Override registry location for testing
export CHP_BASE="$TEST_CHP_BASE"
export HOOK_REGISTRY="$TEST_REGISTRY"

cleanup() {
    restore_registry
    cleanup_test_law
}
trap cleanup EXIT

echo "Testing dispatcher.sh functions..."
echo "Using test registry: $TEST_REGISTRY"
echo ""

# Test 1: get_hook_context returns correct git commands
echo "Test 1: get_hook_context returns correct git commands"
source "$SCRIPT_DIR/../core/dispatcher.sh"

context=$(get_hook_context "pre-commit")
if [ "$context" = "git diff --cached --name-only" ]; then
    echo "  ✓ pre-commit context correct"
else
    echo "  ✗ pre-commit context incorrect: $context"
    exit 1
fi

context=$(get_hook_context "pre-push")
if [ "$context" = "git diff --name-only HEAD @{u}" ]; then
    echo "  ✓ pre-push context correct"
else
    echo "  ✗ pre-push context incorrect: $context"
    exit 1
fi

context=$(get_hook_context "commit-msg")
if [ "$context" = ".git/COMMIT_EDITMSG" ]; then
    echo "  ✓ commit-msg context correct"
else
    echo "  ✗ commit-msg context incorrect: $context"
    exit 1
fi

context=$(get_hook_context "unknown-hook")
if [ -z "$context" ]; then
    echo "  ✓ Unknown hook returns empty context"
else
    echo "  ✗ Unknown hook should return empty context: $context"
    exit 1
fi
echo ""

# Test 2: Dispatch hook with no laws registered
echo "Test 2: Dispatch hook with no laws registered"
rm -f "$TEST_REGISTRY"
init_hook_registry
dispatch_hook "pre-commit"
echo "  ✓ Dispatch with no laws completes without error"
echo ""

# Test 3: Create test law and register it
echo "Test 3: Create test law and register it"
cleanup_test_law

mkdir -p "$TEST_LAWS_DIR/test-dispatcher-law"

# Create law.json
cat > "$TEST_LAWS_DIR/test-dispatcher-law/law.json" << 'EOF'
{
  "name": "test-dispatcher-law",
  "description": "Test law for dispatcher",
  "severity": "medium",
  "failures": 0,
  "tightening_level": 0,
  "enabled": true
}
EOF

# Create verify.sh that succeeds
cat > "$TEST_LAWS_DIR/test-dispatcher-law/verify.sh" << 'EOF'
#!/bin/bash
echo "Test law verification passed"
exit 0
EOF
chmod +x "$TEST_LAWS_DIR/test-dispatcher-law/verify.sh"

# Create guidance.md
cat > "$TEST_LAWS_DIR/test-dispatcher-law/guidance.md" << 'EOF'
# Test Law Guidance

This is a test law for dispatcher testing.
EOF

# Register the law
rm -f "$TEST_REGISTRY"
init_hook_registry
register_hook_law "pre-commit" "test-dispatcher-law"

laws=$(get_hook_laws "pre-commit")
if echo "$laws" | grep -q "test-dispatcher-law"; then
    echo "  ✓ Test law registered successfully"
else
    echo "  ✗ Test law not registered"
    exit 1
fi
echo ""

# Test 4: Dispatch hook runs the law
echo "Test 4: Dispatch hook runs the law"
output=$(dispatch_hook "pre-commit" 2>&1)
if echo "$output" | grep -q "Test law verification passed"; then
    echo "  ✓ Law verify.sh was executed"
else
    echo "  ✗ Law verify.sh was not executed"
    echo "    Output: $output"
    exit 1
fi

if echo "$output" | grep -q "passed: 1"; then
    echo "  ✓ Summary shows 1 law passed"
else
    echo "  ✗ Summary doesn't show 1 law passed"
    echo "    Output: $output"
    exit 1
fi
echo ""

# Test 5: Dispatch with failing law
echo "Test 5: Dispatch with failing law"
# Update verify.sh to fail
cat > "$TEST_LAWS_DIR/test-dispatcher-law/verify.sh" << 'EOF'
#!/bin/bash
echo "Test law verification failed"
exit 1
EOF
chmod +x "$TEST_LAWS_DIR/test-dispatcher-law/verify.sh"

output=$(dispatch_hook "pre-commit" 2>&1 || true)
if echo "$output" | grep -q "Test law verification failed"; then
    echo "  ✓ Failing law verify.sh was executed"
else
    echo "  ✗ Failing law verify.sh was not executed"
    echo "    Output: $output"
    exit 1
fi

if echo "$output" | grep -q "failed: 1"; then
    echo "  ✓ Summary shows 1 law failed"
else
    echo "  ✗ Summary doesn't show 1 law failed"
    echo "    Output: $output"
    exit 1
fi
echo ""

# Test 6: Blocking hook with failure returns exit code 1
echo "Test 6: Blocking hook with failure returns exit code 1"
set_hook_blocking "pre-commit" true

if dispatch_hook "pre-commit" >/dev/null 2>&1; then
    echo "  ✗ Blocking hook should return exit code 1 on failure"
    exit 1
else
    exit_code=$?
    if [ $exit_code -eq 1 ]; then
        echo "  ✓ Blocking hook returns exit code 1 on failure"
    else
        echo "  ✗ Unexpected exit code: $exit_code"
        exit 1
    fi
fi
echo ""

# Test 7: Non-blocking hook with failure returns exit code 0
echo "Test 7: Non-blocking hook with failure returns exit code 0"
set_hook_blocking "pre-commit" false

if dispatch_hook "pre-commit" >/dev/null 2>&1; then
    echo "  ✓ Non-blocking hook returns exit code 0 despite failure"
else
    echo "  ✗ Non-blocking hook should return exit code 0"
    exit 1
fi
echo ""

# Test 8: Disabled hook doesn't run laws
echo "Test 8: Disabled hook doesn't run laws"
set_hook_enabled "pre-commit" false

output=$(dispatch_hook "pre-commit" 2>&1)
if echo "$output" | grep -q "Test law verification failed"; then
    echo "  ✗ Disabled hook should not run laws"
    exit 1
else
    echo "  ✓ Disabled hook doesn't run laws"
fi
echo ""

# Test 9: Handle missing law directory gracefully
echo "Test 9: Handle missing law directory gracefully"
rm -f "$TEST_REGISTRY"
init_hook_registry
register_hook_law "pre-commit" "non-existent-law"

output=$(dispatch_hook "pre-commit" 2>&1)
if echo "$output" | grep -q "Law directory not found"; then
    echo "  ✓ Missing law directory handled gracefully"
else
    echo "  ✗ Should warn about missing law directory"
    echo "    Output: $output"
    exit 1
fi
echo ""

# Test 10: Handle missing verify.sh gracefully
echo "Test 10: Handle missing verify.sh gracefully"
cleanup_test_law
mkdir -p "$TEST_LAWS_DIR/test-dispatcher-law"
cat > "$TEST_LAWS_DIR/test-dispatcher-law/law.json" << 'EOF'
{
  "name": "test-dispatcher-law",
  "description": "Test law for dispatcher",
  "severity": "medium",
  "failures": 0,
  "tightening_level": 0,
  "enabled": true
}
EOF
# Don't create verify.sh

rm -f "$TEST_REGISTRY"
init_hook_registry
register_hook_law "pre-commit" "test-dispatcher-law"

output=$(dispatch_hook "pre-commit" 2>&1)
if echo "$output" | grep -q "verify.sh not found"; then
    echo "  ✓ Missing verify.sh handled gracefully"
else
    echo "  ✗ Should warn about missing verify.sh"
    echo "    Output: $output"
    exit 1
fi
echo ""

# Cleanup
rm -f "$TEST_REGISTRY"
cleanup_test_law

echo ""
echo "All tests passed!"

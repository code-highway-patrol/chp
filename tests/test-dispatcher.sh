#!/bin/bash
# Test dispatcher functions
# Uses a temp directory with its own CHP structure for full isolation

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Create isolated test environment
TEST_ROOT="$(mktemp -d)"
mkdir -p "$TEST_ROOT/docs/chp/laws" "$TEST_ROOT/.chp"

# Initialize git repo for git-based hook context
cd "$TEST_ROOT" && git init -q

# Copy core scripts to test root
cp -r "$SCRIPT_DIR/../core" "$TEST_ROOT/core"

# Set up test CHP_BASE
export CHP_BASE="$TEST_ROOT"
export LAWS_DIR="$TEST_ROOT/docs/chp/laws"
export HOOK_REGISTRY="$TEST_ROOT/.chp/hook-registry.json"

cleanup() {
    rm -rf "$TEST_ROOT"
}
trap cleanup EXIT

# Source after setting env
source "$TEST_ROOT/core/common.sh"
source "$TEST_ROOT/core/hook-registry.sh"
source "$TEST_ROOT/core/verifier.sh"
[ -f "$TEST_ROOT/core/tightener.sh" ] && source "$TEST_ROOT/core/tightener.sh"
source "$TEST_ROOT/core/dispatcher.sh"

echo "Testing dispatcher.sh functions..."
echo ""

# Test 1: get_hook_context returns correct git commands
echo "Test 1: get_hook_context returns correct git commands"

context=$(get_hook_context "pre-commit")
if [ "$context" = "git diff --cached --name-only" ]; then
    echo "  ✓ pre-commit context correct"
else
    echo "  ✗ pre-commit context incorrect: $context"
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
echo '{"hooks":{},"version":"1.0"}' > "$HOOK_REGISTRY"
dispatch_hook "pre-commit" >/dev/null 2>&1
echo "  ✓ Dispatch with no laws completes without error"
echo ""

# Test 3: Create test law and register it
echo "Test 3: Create test law and register it"
TEST_LAW_DIR="$LAWS_DIR/test-dispatcher-law"
mkdir -p "$TEST_LAW_DIR"

cat > "$TEST_LAW_DIR/law.json" << 'EOF'
{
  "name": "test-dispatcher-law",
  "severity": "medium",
  "failures": 0,
  "tightening_level": 0,
  "enabled": true
}
EOF

cat > "$TEST_LAW_DIR/verify.sh" << 'EOF'
#!/bin/bash
echo "Test law verification passed"
exit 0
EOF
chmod +x "$TEST_LAW_DIR/verify.sh"

cat > "$TEST_LAW_DIR/guidance.md" << 'EOF'
# Test Law
EOF

echo '{"hooks":{},"version":"1.0"}' > "$HOOK_REGISTRY"
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
echo ""

# Test 5: Dispatch with failing law
echo "Test 5: Dispatch with failing law"
cat > "$TEST_LAW_DIR/verify.sh" << 'EOF'
#!/bin/bash
echo "Test law verification failed"
exit 1
EOF
chmod +x "$TEST_LAW_DIR/verify.sh"

output=$(dispatch_hook "pre-commit" 2>&1 || true)
if echo "$output" | grep -q "Test law verification failed"; then
    echo "  ✓ Failing law verify.sh was executed"
else
    echo "  ✗ Failing law verify.sh was not executed"
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
    echo "  ✓ Blocking hook returns exit code 1 on failure"
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
echo '{"hooks":{},"version":"1.0"}' > "$HOOK_REGISTRY"
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
TEST_LAW_DIR="$LAWS_DIR/test-dispatcher-law"
rm -rf "$TEST_LAW_DIR"
mkdir -p "$TEST_LAW_DIR"
cat > "$TEST_LAW_DIR/law.json" << 'EOF'
{
  "name": "test-dispatcher-law",
  "severity": "medium",
  "failures": 0,
  "tightening_level": 0,
  "enabled": true
}
EOF

echo '{"hooks":{},"version":"1.0"}' > "$HOOK_REGISTRY"
register_hook_law "pre-commit" "test-dispatcher-law"

output=$(dispatch_hook "pre-commit" 2>&1 || true)
if echo "$output" | grep -q "verify.sh not found"; then
    echo "  ✓ Missing verify.sh handled gracefully"
else
    echo "  ✗ Should warn about missing verify.sh"
    echo "    Output: $output"
    exit 1
fi
echo ""

echo "All tests passed!"

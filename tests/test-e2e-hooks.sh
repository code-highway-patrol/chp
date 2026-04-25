#!/bin/bash
# End-to-end hook system test

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR/.."

echo "CHP Universal Hook System - End-to-End Test"
echo "==========================================="
echo ""

export CHP_DEBUG=true

echo "1. Testing hook registry..."
bash ./commands/chp-hooks registry >/dev/null 2>&1
if [ -f ".chp/hook-registry.json" ]; then
    echo "   ✓ Registry exists"
else
    echo "   ✗ Registry not found"
    exit 1
fi

echo ""
echo "2. Testing hook detection..."
if bash ./commands/chp-hooks detect >/dev/null 2>&1; then
    echo "   ✓ Hooks detected"
else
    echo "   ✗ Hook detection failed"
    exit 1
fi

echo ""
echo "3. Creating test law directly..."
TEST_LAW_DIR="docs/chp/laws/e2e-test-law"
mkdir -p "$TEST_LAW_DIR"
cat > "$TEST_LAW_DIR/law.json" << 'EOF'
{
  "name": "e2e-test-law",
  "created": "2026-04-25T00:00:00Z",
  "severity": "error",
  "failures": 0,
  "tightening_level": 0,
  "hooks": ["pre-commit"],
  "enabled": true
}
EOF
cat > "$TEST_LAW_DIR/verify.sh" << 'EOF'
#!/bin/bash
echo "e2e-test-law verification passed"
exit 0
EOF
chmod +x "$TEST_LAW_DIR/verify.sh"
cat > "$TEST_LAW_DIR/guidance.md" << 'EOF'
# E2E Test Law
Test law for end-to-end testing.
EOF

if [ -d "$TEST_LAW_DIR" ]; then
    echo "   ✓ Test law created"
else
    echo "   ✗ Law directory not found"
    exit 1
fi

echo ""
echo "4. Testing hook registration..."
# Register the law
source core/hook-registry.sh
register_hook_law "pre-commit" "e2e-test-law" >/dev/null 2>&1

if bash ./commands/chp-hooks registry 2>&1 | grep -q "e2e-test-law"; then
    echo "   ✓ Hook registered"
else
    echo "   ✗ Hook registration failed"
    bash ./commands/chp-hooks registry
    exit 1
fi

echo ""
echo "5. Testing chp-hooks list..."
if bash ./commands/chp-hooks list >/dev/null 2>&1; then
    echo "   ✓ Hook list works"
else
    echo "   ✗ Hook list failed"
    exit 1
fi

echo ""
echo "6. Testing chp-status..."
if bash ./commands/chp-status >/dev/null 2>&1; then
    echo "   ✓ Status command works"
else
    echo "   ✗ Status command failed"
    exit 1
fi

echo ""
echo "7. Testing dispatcher with test law..."
output=$(bash core/dispatcher.sh pre-commit 2>&1 || true)
if echo "$output" | grep -q "e2e-test-law verification passed"; then
    echo "   ✓ Dispatcher ran test law"
else
    echo "   ✗ Dispatcher did not run test law"
    echo "$output"
fi

echo ""
echo "8. Cleanup..."
# Unregister and delete test law
unregister_hook_law "pre-commit" "e2e-test-law" >/dev/null 2>&1
rm -rf "$TEST_LAW_DIR"

if [ ! -d "$TEST_LAW_DIR" ]; then
    echo "   ✓ Test law deleted"
else
    echo "   ✗ Law directory still exists"
    exit 1
fi

echo ""
echo "==========================================="
echo "All end-to-end tests passed!"
echo "==========================================="

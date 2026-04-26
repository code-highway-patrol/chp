#!/bin/bash
# Test verification runner

set -e  # Exit on test failures

source "$(dirname "$0")/../core/common.sh"
source "$(dirname "$0")/../core/verifier.sh"

echo "Testing verifier.sh functions..."

# Setup: Create a test law
TEST_LAW_DIR="$CHP_BASE/docs/chp/laws/test-verifier-law"
mkdir -p "$TEST_LAW_DIR"

# Create law.json
cat > "$TEST_LAW_DIR/law.json" << 'EOF'
{
  "name": "test-verifier-law",
  "description": "Test law for verifier",
  "severity": "error",
  "hooks": ["pre-commit"],
  "created": "2026-04-24",
  "failures": 0,
  "tightening_level": 0
}
EOF

# Test 1: verify_law with passing verification
echo "Test 1: verify_law with passing verification"
cat > "$TEST_LAW_DIR/verify.sh" << 'EOF'
#!/bin/bash
# Passing verification
exit 0
EOF
chmod +x "$TEST_LAW_DIR/verify.sh"

if verify_law "test-verifier-law"; then
    echo "  ✓ Law verification passed"
else
    echo "  ✗ Law verification should have passed"
    exit 1
fi

# Test 2: verify_law with failing verification
echo "Test 2: verify_law with failing verification"
cat > "$TEST_LAW_DIR/verify.sh" << 'EOF'
#!/bin/bash
# Failing verification
echo "Test violation detected"
exit 1
EOF
chmod +x "$TEST_LAW_DIR/verify.sh"

if ! verify_law "test-verifier-law"; then
    echo "  ✓ Law verification failed as expected"
else
    echo "  ✗ Law verification should have failed"
    exit 1
fi

# Test 3: verify_law with non-existent law
echo "Test 3: verify_law with non-existent law"
if ! verify_law "non-existent-law"; then
    echo "  ✓ Non-existent law handled correctly"
else
    echo "  ✗ Non-existent law should fail"
    exit 1
fi

# Test 4: verify_hook_laws
echo "Test 4: verify_hook_laws"
# Reset test law to passing state
cat > "$TEST_LAW_DIR/verify.sh" << 'EOF'
#!/bin/bash
exit 0
EOF
chmod +x "$TEST_LAW_DIR/verify.sh"

# Create another test law for the same hook
TEST_LAW_DIR2="$CHP_BASE/docs/chp/laws/test-verifier-law-2"
mkdir -p "$TEST_LAW_DIR2"
cat > "$TEST_LAW_DIR2/law.json" << 'EOF'
{
  "name": "test-verifier-law-2",
  "description": "Second test law",
  "severity": "warn",
  "hooks": ["pre-commit"],
  "created": "2026-04-24",
  "failures": 0,
  "tightening_level": 0
}
EOF
cat > "$TEST_LAW_DIR2/verify.sh" << 'EOF'
#!/bin/bash
exit 0
EOF
chmod +x "$TEST_LAW_DIR2/verify.sh"

if verify_hook_laws "pre-commit"; then
    echo "  ✓ Hook laws verification passed"
else
    echo "  ✗ Hook laws verification should have passed"
    exit 1
fi

# Cleanup
rm -rf "$TEST_LAW_DIR" "$TEST_LAW_DIR2"

echo ""
echo "All tests passed!"

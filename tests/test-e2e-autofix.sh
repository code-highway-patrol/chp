#!/usr/bin/env bash
# End-to-end test for auto-fix feature

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR/.."

echo "=== CHP Auto-Fix E2E Test ==="
echo ""

# Setup test repo
TEST_DIR=$(mktemp -d)
cd "$TEST_DIR"
git init
git config user.email "test@example.com"
git config user.name "Test User"

# Install CHP hooks
cp -r "$SCRIPT_DIR/../docs/chp/laws" ./laws/
cp -r "$SCRIPT_DIR/../core" ./core/
cp -r "$SCRIPT_DIR/../agents" ./agents/

# Set CHP environment variables
export CHP_BASE="$PWD"
export LAWS_DIR="$PWD/laws"

# Create test law with autoFix: ask
mkdir -p "laws/test-autofix"
cat > "laws/test-autofix/law.json" << 'EOF'
{
  "name": "test-autofix",
  "intent": "Test auto-fix feature",
  "autoFix": "ask",
  "severity": "error",
  "hooks": ["pre-commit"],
  "enabled": true,
  "include": ["*.js"],
  "checks": []
}
EOF

cat > "laws/test-autofix/verify.sh" << 'EOF'
#!/usr/bin/env bash
if grep -q "BAD_PATTERN" "$1" 2>/dev/null; then
    echo "FAIL:BAD_PATTERN found"
    exit 1
fi
exit 0
EOF
chmod +x "laws/test-autofix/verify.sh"

cat > "laws/test-autofix/guidance.md" << 'EOF'
# Test Auto-Fix Law

Replace BAD_PATTERN with GOOD_PATTERN.
EOF

# Create violating file
echo "console.log('BAD_PATTERN here')" > test.js
git add test.js

# Run dispatcher (simulates pre-commit hook)
echo "Running dispatcher..."
if ./core/dispatcher.sh pre-commit 2>&1 | grep -q "FAIL"; then
    echo "✓ Violation detected as expected"
else
    echo "✗ Violation should have been detected"
    exit 1
fi

# Cleanup
cd -
rm -rf "$TEST_DIR"

echo ""
echo "=== E2E Test Passed ==="

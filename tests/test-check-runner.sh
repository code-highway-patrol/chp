#!/bin/bash
# Test check-runner and checker functions
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TEST_ROOT="$(mktemp -d)"
mkdir -p "$TEST_ROOT/docs/chp/laws" "$TEST_ROOT/.chp" "$TEST_ROOT/core/checkers"

# Copy core scripts
mkdir -p "$TEST_ROOT/core"
cp -r "$SCRIPT_DIR/../core"/*.sh "$TEST_ROOT/core/"
mkdir -p "$TEST_ROOT/core/checkers"
cp -r "$SCRIPT_DIR/../core/checkers"/*.sh "$TEST_ROOT/core/checkers/" 2>/dev/null || true

export CHP_BASE="$TEST_ROOT"
export LAWS_DIR="$TEST_ROOT/docs/chp/laws"

cleanup() { rm -rf "$TEST_ROOT"; }
trap cleanup EXIT

source "$TEST_ROOT/core/common.sh"

echo "Testing check-runner..."
echo ""

# Test 1: pattern checker detects a pattern in staged diff
echo "Test 1: pattern checker detects violations"

# Create a test file with a violation
mkdir -p "$TEST_ROOT/src"
echo 'console.log("debug")' > "$TEST_ROOT/src/app.ts"
cd "$TEST_ROOT"
git init >/dev/null 2>&1
git add src/app.ts >/dev/null 2>&1

# Run pattern checker
source "$TEST_ROOT/core/checkers/pattern.sh"
CONFIG='{"pattern":"console[.]log[(]"}'
RESULT=$(check_pattern "pre-commit" "$CONFIG" "" || true)
if [[ "$RESULT" == FAIL* ]]; then
    echo "  ✓ Pattern checker detected console.log"
else
    echo "  ✗ Pattern checker should have failed: $RESULT"
    exit 1
fi

echo ""

# Test 2: pattern checker passes when no violation
echo "Test 2: pattern checker passes clean files"

rm -f "$TEST_ROOT/src/app.ts"
echo 'logger.info("clean")' > "$TEST_ROOT/src/app.ts"
git add src/app.ts >/dev/null 2>&1

RESULT=$(check_pattern "pre-commit" "$CONFIG" "")
if [[ "$RESULT" == "PASS" ]]; then
    echo "  ✓ Pattern checker passed clean file"
else
    echo "  ✗ Pattern checker should have passed: $RESULT"
    exit 1
fi

echo ""
echo "All tests passed!"

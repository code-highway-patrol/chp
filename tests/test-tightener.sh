#!/bin/bash
# Test tightener.sh functions

set -e  # Exit on test failures

source "$(dirname "$0")/../core/common.sh"
source "$(dirname "$0")/../core/tightener.sh"

echo "Testing tightener.sh functions..."

# Setup: Create a test law
TEST_LAW_DIR="$CHP_BASE/docs/chp/laws/test-tightener-law"
mkdir -p "$TEST_LAW_DIR"

# Create law.json
cat > "$TEST_LAW_DIR/law.json" << 'EOF'
{
  "name": "test-tightener-law",
  "description": "Test law for tightener",
  "severity": "error",
  "hooks": ["pre-commit"],
  "created": "2026-04-24",
  "failures": 0,
  "tightening_level": 0
}
EOF

# Test 1: record_failure increments failure count
echo "Test 1: record_failure increments failure count"
record_failure "test-tightener-law"
failures=$(get_law_meta "test-tightener-law" "failures")
if [ "$failures" = "1" ]; then
    echo "  ✓ Failure count incremented to 1"
else
    echo "  ✗ Expected failures=1, got $failures"
    exit 1
fi

# Test 2: record_failure increments tightening level
echo "Test 2: record_failure increments tightening level"
tightening_level=$(get_law_meta "test-tightener-law" "tightening_level")
if [ "$tightening_level" = "1" ]; then
    echo "  ✓ Tightening level incremented to 1"
else
    echo "  ✗ Expected tightening_level=1, got $tightening_level"
    exit 1
fi

# Test 3: record_failure handles multiple failures
echo "Test 3: record_failure handles multiple failures"
record_failure "test-tightener-law"
record_failure "test-tightener-law"
failures=$(get_law_meta "test-tightener-law" "failures")
tightening_level=$(get_law_meta "test-tightener-law" "tightening_level")
if [ "$failures" = "3" ] && [ "$tightening_level" = "3" ]; then
    echo "  ✓ Multiple failures tracked correctly (failures=$failures, tightening_level=$tightening_level)"
else
    echo "  ✗ Expected failures=3 and tightening_level=3, got failures=$failures, tightening_level=$tightening_level"
    exit 1
fi

# Test 4: record_failure fails with non-existent law
echo "Test 4: record_failure fails with non-existent law"
if ! record_failure "non-existent-law" 2>/dev/null; then
    echo "  ✓ Non-existent law handled correctly"
else
    echo "  ✗ Non-existent law should fail"
    exit 1
fi

# Test 5: record_failure fails with empty law name
echo "Test 5: record_failure fails with empty law name"
if ! record_failure "" 2>/dev/null; then
    echo "  ✓ Empty law name handled correctly"
else
    echo "  ✗ Empty law name should fail"
    exit 1
fi

# Test 6: reset_failures resets failure count
echo "Test 6: reset_failures resets failure count"
# First, set some failures
record_failure "test-tightener-law"
failures_before=$(get_law_meta "test-tightener-law" "failures")
# Now reset
reset_failures "test-tightener-law"
failures_after=$(get_law_meta "test-tightener-law" "failures")
if [ "$failures_after" = "0" ]; then
    echo "  ✓ Failures reset to 0 (was $failures_before)"
else
    echo "  ✗ Expected failures=0 after reset, got $failures_after"
    exit 1
fi

# Test 7: reset_failures resets tightening level
echo "Test 7: reset_failures resets tightening level"
# Set some failures first
record_failure "test-tightener-law"
record_failure "test-tightener-law"
tightening_before=$(get_law_meta "test-tightener-law" "tightening_level")
# Now reset
reset_failures "test-tightener-law"
tightening_after=$(get_law_meta "test-tightener-law" "tightening_level")
if [ "$tightening_after" = "0" ]; then
    echo "  ✓ Tightening level reset to 0 (was $tightening_before)"
else
    echo "  ✗ Expected tightening_level=0 after reset, got $tightening_after"
    exit 1
fi

# Test 8: reset_failures fails with non-existent law
echo "Test 8: reset_failures fails with non-existent law"
if ! reset_failures "non-existent-law" 2>/dev/null; then
    echo "  ✓ Non-existent law handled correctly"
else
    echo "  ✗ Non-existent law should fail"
    exit 1
fi

# Test 9: reset_failures fails with empty law name
echo "Test 9: reset_failures fails with empty law name"
if ! reset_failures "" 2>/dev/null; then
    echo "  ✓ Empty law name handled correctly"
else
    echo "  ✗ Empty law name should fail"
    exit 1
fi

# Cleanup
rm -rf "$TEST_LAW_DIR"

echo ""
echo "All tests passed!"

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

# Test 3: check runner reads checks from law.json and dispatches
echo "Test 3: check runner dispatches pattern checks from law.json"

source "$TEST_ROOT/core/check-runner.sh"

# Create a law with pattern checks
TEST_LAW_DIR="$LAWS_DIR/test-check-runner"
mkdir -p "$TEST_LAW_DIR"

cat > "$TEST_LAW_DIR/law.json" << 'LAWEOF'
{
  "name": "test-check-runner",
  "enabled": true,
  "checks": [
    {
      "id": "no-console-log",
      "type": "pattern",
      "config": {"pattern": "console[.]log[(]"},
      "severity": "block",
      "message": "Use logger.info() instead of console.log()"
    }
  ]
}
LAWEOF

# Create a violating file
echo 'console.log("violation")' > "$TEST_ROOT/src/bad.ts"
cd "$TEST_ROOT"
git add src/bad.ts >/dev/null 2>&1

set +e
RESULT=$(run_checks "test-check-runner" "pre-commit" 2>/dev/null)
EXIT_CODE=$?
set -e

if [[ $EXIT_CODE -ne 0 ]]; then
    echo "  ✓ Check runner detected violation from law.json checks"
else
    echo "  ✗ Check runner should have failed: $RESULT"
    exit 1
fi

# Verify per-check result output
if echo "$RESULT" | grep -q "no-console-log.*FAIL"; then
    echo "  ✓ Per-check result includes check ID"
else
    echo "  ✗ Per-check result missing check ID: $RESULT"
    exit 1
fi

echo ""

# Test 4: check runner passes when all checks pass
echo "Test 4: check runner passes when all checks pass"

echo 'logger.info("clean")' > "$TEST_ROOT/src/bad.ts"
cd "$TEST_ROOT"
git add src/bad.ts >/dev/null 2>&1

set +e
RESULT=$(run_checks "test-check-runner" "pre-commit" 2>/dev/null)
EXIT_CODE=$?
set -e

if [[ $EXIT_CODE -eq 0 ]]; then
    echo "  ✓ Check runner passes clean files"
else
    echo "  ✗ Check runner should have passed: $RESULT"
    exit 1
fi

echo ""

# Test 5: warn-severity checks don't cause failure
echo "Test 5: warn-severity checks don't cause failure"

cat > "$TEST_LAW_DIR/law.json" << 'LAWEOF'
{
  "name": "test-check-runner",
  "enabled": true,
  "checks": [
    {
      "id": "no-console-log",
      "type": "pattern",
      "config": {"pattern": "console[.]log[(]"},
      "severity": "warn",
      "message": "Use logger.info() instead of console.log()"
    }
  ]
}
LAWEOF

echo 'console.log("violation")' > "$TEST_ROOT/src/bad.ts"
cd "$TEST_ROOT"
git add src/bad.ts >/dev/null 2>&1

set +e
RESULT=$(run_checks "test-check-runner" "pre-commit" 2>/dev/null)
EXIT_CODE=$?
set -e

if [[ $EXIT_CODE -eq 0 ]]; then
    echo "  ✓ Warn-severity check doesn't block"
else
    echo "  ✗ Warn-severity check should not block: $RESULT"
    exit 1
fi

# Verify it still reports the violation
if echo "$RESULT" | grep -q "no-console-log.*FAIL"; then
    echo "  ✓ Warn-severity violation still reported"
else
    echo "  ✗ Warn-severity violation should be reported: $RESULT"
    exit 1
fi

echo ""

# Test 6: threshold checker detects oversized files
echo "Test 6: threshold checker detects oversized files"

source "$TEST_ROOT/core/checkers/threshold.sh"

# Create a long file (60 lines)
for i in $(seq 1 60); do echo "line $i"; done > "$TEST_ROOT/src/long.ts"
cd "$TEST_ROOT"
git add src/long.ts >/dev/null 2>&1

CONFIG='{"metric":"file_line_count","max":50}'
RESULT=$(check_threshold "pre-commit" "$CONFIG" "" || true)
if [[ "$RESULT" == FAIL* ]]; then
    echo "  ✓ Threshold checker detected oversized file"
else
    echo "  ✗ Threshold checker should have failed: $RESULT"
    exit 1
fi

echo ""

# Test 7: threshold checker passes under limit
echo "Test 7: threshold checker passes under limit"

rm -f "$TEST_ROOT/src/long.ts"
git reset src/long.ts >/dev/null 2>&1 || true
echo "short file" > "$TEST_ROOT/src/short.ts"
cd "$TEST_ROOT"
git add src/short.ts >/dev/null 2>&1

RESULT=$(check_threshold "pre-commit" "$CONFIG" "")
if [[ "$RESULT" == "PASS" ]]; then
    echo "  ✓ Threshold checker passed short file"
else
    echo "  ✗ Threshold checker should have passed: $RESULT"
    exit 1
fi

echo ""

# Test 8: structural checker - test_file_exists assertion
echo "Test 8: structural checker - test_file_exists assertion"

source "$TEST_ROOT/core/checkers/structural.sh"

# Create source file without matching test
echo 'export function foo() {}' > "$TEST_ROOT/src/utils.ts"
cd "$TEST_ROOT"
git add src/utils.ts >/dev/null 2>&1

CONFIG='{"assert":"test_file_exists","source_pattern":"src/","test_pattern":"tests/"}'
RESULT=$(check_structural "pre-commit" "$CONFIG" "" || true)
if [[ "$RESULT" == FAIL* ]]; then
    echo "  ✓ Structural checker detected missing test file"
else
    echo "  ✗ Structural checker should have failed: $RESULT"
    exit 1
fi

echo ""

# Test 9: structural checker passes when test exists
echo "Test 9: structural checker passes when test exists"

mkdir -p "$TEST_ROOT/tests"
echo 'test("foo", () => {})' > "$TEST_ROOT/tests/utils.test.ts"
cd "$TEST_ROOT"
git add tests/utils.test.ts >/dev/null 2>&1

RESULT=$(check_structural "pre-commit" "$CONFIG" "")
if [[ "$RESULT" == "PASS" ]]; then
    echo "  ✓ Structural checker passed with test file present"
else
    echo "  ✗ Structural checker should have passed: $RESULT"
    exit 1
fi

echo ""

# Test 10: agent checker outputs prompt context
echo "Test 10: agent checker outputs prompt for agent hooks"

source "$TEST_ROOT/core/checkers/agent.sh"

CONFIG='{"prompt":"Are these variable names meaningful?"}'
RESULT=$(check_agent "pre-tool" "$CONFIG" "")
if [[ "$RESULT" == PASS* ]]; then
    echo "  ✓ Agent checker outputs context for pre-tool hooks"
else
    echo "  ✗ Agent checker should output context: $RESULT"
    exit 1
fi

echo ""

# Test 11: agent checker skips for non-agent hooks
echo "Test 11: agent checker skips for non-agent hooks"

RESULT=$(check_agent "pre-commit" "$CONFIG" "")
if [[ "$RESULT" == SKIP* ]]; then
    echo "  ✓ Agent checker skips for git hooks"
else
    echo "  ✗ Agent checker should skip for git hooks: $RESULT"
    exit 1
fi

echo ""
echo "All tests passed!"

#!/usr/bin/env bash
# Tests for fix-trigger.sh

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../core/common.sh"
source "$SCRIPT_DIR/../core/logger.sh"
source "$SCRIPT_DIR/../core/fix-trigger.sh"

logger_init

# Test: trigger_fix skips when autoFix is never
test_trigger_fix_skips_when_autofix_never() {
    local test_law_dir="$LAWS_DIR/test-autofix-never"
    mkdir -p "$test_law_dir"
    echo '{"name":"test-autofix-never","autoFix":"never","severity":"error","hooks":["pre-commit"],"enabled":true}' > "$test_law_dir/law.json"
    echo "# Test guidance" > "$test_law_dir/guidance.md"

    # Enable debug mode to see log_debug output
    export CHP_DEBUG=true
    local output
    output=$(trigger_fix "test-autofix-never" "pre-commit" 2>&1)
    unset CHP_DEBUG

    if echo "$output" | grep -q "skipping fix flow"; then
        echo "PASS: trigger_fix skips when autoFix is never"
        return 0
    else
        echo "FAIL: trigger_fix should skip when autoFix is never"
        echo "Got output: $output"
        return 1
    fi
}

# Test: trigger_fix proceeds when autoFix is ask
test_trigger_fix_proceeds_when_autofix_ask() {
    local test_law_dir="$LAWS_DIR/test-autofix-ask"
    mkdir -p "$test_law_dir"
    echo '{"name":"test-autofix-ask","autoFix":"ask","severity":"error","hooks":["pre-commit"],"enabled":true}' > "$test_law_dir/law.json"
    echo "# Test guidance" > "$test_law_dir/guidance.md"

    local output
    output=$(trigger_fix "test-autofix-ask" "pre-commit" 2>&1)

    if echo "$output" | grep -q "Auto-fix available"; then
        echo "PASS: trigger_fix proceeds when autoFix is ask"
        return 0
    else
        echo "FAIL: trigger_fix should proceed when autoFix is ask"
        echo "Got output: $output"
        return 1
    fi
}

# Test: trigger_fix handles missing guidance gracefully
test_trigger_fix_handles_missing_guidance() {
    local test_law_dir="$LAWS_DIR/test-no-guidance"
    mkdir -p "$test_law_dir"
    echo '{"name":"test-no-guidance","autoFix":"ask","severity":"error","hooks":["pre-commit"],"enabled":true}' > "$test_law_dir/law.json"
    # No guidance.md

    local output
    output=$(trigger_fix "test-no-guidance" "pre-commit" 2>&1)

    if echo "$output" | grep -q "cannot auto-fix"; then
        echo "PASS: trigger_fix handles missing guidance gracefully"
        return 0
    else
        echo "FAIL: trigger_fix should handle missing guidance"
        echo "Got output: $output"
        return 1
    fi
}

# Run tests
echo "Running fix-trigger tests..."
echo ""

test_trigger_fix_skips_when_autofix_never
test_trigger_fix_proceeds_when_autofix_ask
test_trigger_fix_handles_missing_guidance

# Cleanup
rm -rf "$LAWS_DIR/test-autofix-never" "$LAWS_DIR/test-autofix-ask" "$LAWS_DIR/test-no-guidance"

echo ""
echo "All fix-trigger tests passed!"

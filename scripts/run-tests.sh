#!/bin/bash
# CHP Test Runner
# Runs all test scripts in tests/ directory

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TESTS_DIR="$SCRIPT_DIR/../tests"

passed=0
failed=0
errors=()

echo ""
echo "=== CHP Test Suite ==="
echo ""

for test_file in "$TESTS_DIR"/test-*.sh; do
    [ -f "$test_file" ] || continue

    name=$(basename "$test_file" .sh)
    printf "  %-35s" "$name"

    if bash "$test_file" >/dev/null 2>&1; then
        echo "PASS"
        passed=$((passed + 1))
    else
        exit_code=$?
        echo "FAIL (exit $exit_code)"
        failed=$((failed + 1))
        errors+=("$name")
    fi
done

echo ""
echo "Results: $passed passed, $failed failed"

if [ $failed -gt 0 ]; then
    echo ""
    echo "Failed tests:"
    for name in "${errors[@]}"; do
        echo "  - $name"
    done
    echo ""
    echo "Run individually for details:"
    for name in "${errors[@]}"; do
        echo "  bash tests/$name.sh"
    done
    exit 1
fi

echo ""
exit 0

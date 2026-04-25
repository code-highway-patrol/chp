#!/bin/bash
# Test hook detection

set -e  # Exit on test failures

source "$(dirname "$0")/../core/common.sh"
source "$(dirname "$0")/../core/detector.sh"

echo "Testing detector.sh functions..."

# Test detect_git_hooks
echo "Test 1: detect_git_hooks in git repo"
if [ -d .git ]; then
    hooks=$(detect_git_hooks)
    if echo "$hooks" | grep -q "pre-commit"; then
        echo "  ✓ pre-commit detected"
    else
        echo "  ✗ pre-commit NOT detected"
        exit 1
    fi
else
    echo "  ⊘ SKIP: Not in a git repository"
fi

# Test detect_available_hooks
echo "Test 2: detect_available_hooks"
all_hooks=$(detect_available_hooks)
if [ -n "$all_hooks" ]; then
    echo "  ✓ Available hooks: $all_hooks"
else
    echo "  ✗ No hooks detected"
    exit 1
fi

# Test deduplication
echo "Test 3: hook deduplication"
hook_count=$(echo "$all_hooks" | wc -w)
unique_count=$(echo "$all_hooks" | tr ' ' '\n' | sort -u | wc -l)
if [ "$hook_count" -eq "$unique_count" ]; then
    echo "  ✓ No duplicate hooks"
else
    echo "  ✗ Duplicate hooks found"
    exit 1
fi

# Test pretool detection (create temp file)
echo "Test 4: pretool detection"
touch .pretool
pretool_hooks=$(detect_pretool_hooks)
rm .pretool
if echo "$pretool_hooks" | grep -q "pre-write"; then
    echo "  ✓ pretool pre-write detected"
else
    echo "  ✗ pretool pre-write NOT detected"
    exit 1
fi

echo ""
echo "All tests passed!"

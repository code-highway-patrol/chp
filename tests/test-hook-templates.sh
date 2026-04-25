#!/bin/bash
# Test hook templates

source "$(dirname "$0")/../core/common.sh"

echo "Testing Hook Templates"
echo "====================="
echo ""

# Track overall test status
all_tests_passed=true

# Test git hook templates
echo "Testing git hook templates..."
git_hooks=(
    "pre-commit"
    "post-commit"
    "pre-push"
    "post-merge"
    "commit-msg"
    "prepare-commit-msg"
    "pre-rebase"
    "post-checkout"
    "post-rewrite"
    "applypatch-msg"
    "pre-applypatch"
    "post-applypatch"
    "update"
    "pre-auto-gc"
    "post-update"
)

for hook in "${git_hooks[@]}"; do
    template="$CHP_BASE/hooks/git/$hook.sh"
    if [ -f "$template" ]; then
        if grep -q "# CHP-MANAGED" "$template" && grep -q "dispatcher.sh" "$template"; then
            echo "  ✓ $hook"
        else
            echo "  ✗ $hook (missing CHP markers)"
            all_tests_passed=false
        fi
    else
        echo "  ✗ $hook (not found)"
        all_tests_passed=false
    fi
done

# Test agent hook templates
echo ""
echo "Testing agent hook templates..."
agent_hooks=(
    "pre-prompt"
    "post-prompt"
    "pre-tool"
    "post-tool"
    "pre-response"
    "post-response"
)

for hook in "${agent_hooks[@]}"; do
    template="$CHP_BASE/hooks/agent/$hook.sh"
    if [ -f "$template" ]; then
        if grep -q "# CHP-MANAGED" "$template" && grep -q "dispatcher.sh" "$template"; then
            echo "  ✓ $hook"
        else
            echo "  ✗ $hook (missing CHP markers)"
            all_tests_passed=false
        fi
    else
        echo "  ✗ $hook (not found)"
        all_tests_passed=false
    fi
done

# Test CI/CD hook templates
echo ""
echo "Testing CI/CD hook templates..."
cicd_hooks=(
    "pre-build"
    "post-build"
    "pre-deploy"
    "post-deploy"
)

for hook in "${cicd_hooks[@]}"; do
    template="$CHP_BASE/hooks/cicd/$hook.sh"
    if [ -f "$template" ]; then
        if grep -q "# CHP-MANAGED" "$template" && grep -q "dispatcher.sh" "$template"; then
            echo "  ✓ $hook"
        else
            echo "  ✗ $hook (missing CHP markers)"
            all_tests_passed=false
        fi
    else
        echo "  ✗ $hook (not found)"
        all_tests_passed=false
    fi
done

echo ""
echo "====================="
if [ "$all_tests_passed" = true ]; then
    echo "✓ All hook template tests passed!"
    exit 0
else
    echo "✗ Some hook template tests failed!"
    exit 1
fi

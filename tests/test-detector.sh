#!/bin/bash
# Test hook detection for all hook types

set -e  # Exit on test failures

source "$(dirname "$0")/../core/common.sh"
source "$(dirname "$0")/../core/detector.sh"

echo "Testing detector.sh functions..."
echo ""

# Test detect_all_git_hooks
echo "Test 1: detect_all_git_hooks returns all 15 git hook types"
all_git_hooks=$(detect_all_git_hooks)
expected_git_hooks="pre-commit post-commit pre-push post-merge commit-msg prepare-commit-msg pre-rebase post-checkout post-rewrite applypatch-msg pre-applypatch post-applypatch update pre-auto-gc post-update"

# Check each expected hook is present
for hook in $expected_git_hooks; do
    if echo "$all_git_hooks" | grep -qw "$hook"; then
        echo "  ✓ $hook found"
    else
        echo "  ✗ $hook NOT found"
        exit 1
    fi
done

# Verify count
git_hook_count=$(echo "$all_git_hooks" | wc -w)
if [ "$git_hook_count" -eq 15 ]; then
    echo "  ✓ All 15 git hooks detected"
else
    echo "  ✗ Expected 15 git hooks, got $git_hook_count"
    exit 1
fi

# Test detect_all_agent_hooks with .claude directory
echo ""
echo "Test 2: detect_all_agent_hooks with .claude directory"
mkdir -p .claude
all_agent_hooks=$(detect_all_agent_hooks)
expected_agent_hooks="pre-prompt post-prompt pre-tool post-tool pre-response post-response"

for hook in $expected_agent_hooks; do
    if echo "$all_agent_hooks" | grep -qw "$hook"; then
        echo "  ✓ $hook found"
    else
        echo "  ✗ $hook NOT found"
        rm -rf .claude
        exit 1
    fi
done
rm -rf .claude

# Test detect_all_agent_hooks without .claude directory
echo ""
echo "Test 3: detect_all_agent_hooks without .claude directory"
all_agent_hooks=$(detect_all_agent_hooks)
if [ -z "$all_agent_hooks" ]; then
    echo "  ✓ No agent hooks when .claude doesn't exist"
else
    echo "  ✗ Should return empty when .claude doesn't exist"
    exit 1
fi

# Test detect_all_cicd_hooks with .github/workflows
echo ""
echo "Test 4: detect_all_cicd_hooks with .github/workflows"
mkdir -p .github/workflows
touch .github/workflows/test.yml
all_cicd_hooks=$(detect_all_cicd_hooks)
expected_cicd_hooks="pre-build post-build pre-deploy post-deploy"

for hook in $expected_cicd_hooks; do
    if echo "$all_cicd_hooks" | grep -qw "$hook"; then
        echo "  ✓ $hook found"
    else
        echo "  ✗ $hook NOT found"
        rm -rf .github
        exit 1
    fi
done
rm -rf .github

# Test detect_all_cicd_hooks with .gitlab-ci.yml
echo ""
echo "Test 5: detect_all_cicd_hooks with .gitlab-ci.yml"
touch .gitlab-ci.yml
all_cicd_hooks=$(detect_all_cicd_hooks)
if echo "$all_cicd_hooks" | grep -qw "pre-build"; then
    echo "  ✓ CI/CD hooks detected with .gitlab-ci.yml"
else
    echo "  ✗ CI/CD hooks NOT detected with .gitlab-ci.yml"
    rm .gitlab-ci.yml
    exit 1
fi
rm .gitlab-ci.yml

# Test detect_all_cicd_hooks with Jenkinsfile
echo ""
echo "Test 6: detect_all_cicd_hooks with Jenkinsfile"
touch Jenkinsfile
all_cicd_hooks=$(detect_all_cicd_hooks)
if echo "$all_cicd_hooks" | grep -qw "pre-build"; then
    echo "  ✓ CI/CD hooks detected with Jenkinsfile"
else
    echo "  ✗ CI/CD hooks NOT detected with Jenkinsfile"
    rm Jenkinsfile
    exit 1
fi
rm Jenkinsfile

# Test detect_all_cicd_hooks with .chp/cicd-enabled
echo ""
echo "Test 7: detect_all_cicd_hooks with .chp/cicd-enabled"
mkdir -p .chp
touch .chp/cicd-enabled
all_cicd_hooks=$(detect_all_cicd_hooks)
if echo "$all_cicd_hooks" | grep -qw "pre-build"; then
    echo "  ✓ CI/CD hooks detected with .chp/cicd-enabled"
else
    echo "  ✗ CI/CD hooks NOT detected with .chp/cicd-enabled"
    rm -rf .chp
    exit 1
fi
rm -rf .chp

# Test detect_all_cicd_hooks without any CI/CD config
echo ""
echo "Test 8: detect_all_cicd_hooks without any CI/CD config"
all_cicd_hooks=$(detect_all_cicd_hooks)
if [ -z "$all_cicd_hooks" ]; then
    echo "  ✓ No CI/CD hooks when no config exists"
else
    echo "  ✗ Should return empty when no CI/CD config exists"
    exit 1
fi

# Test detect_all_hooks
echo ""
echo "Test 9: detect_all_hooks combines all hook types"
mkdir -p .claude
mkdir -p .github/workflows
touch .github/workflows/test.yml

all_hooks=$(detect_all_hooks)

# Should contain git hooks
if echo "$all_hooks" | grep -qw "pre-commit"; then
    echo "  ✓ Git hooks included"
else
    echo "  ✗ Git hooks NOT included"
    rm -rf .claude .github
    exit 1
fi

# Should contain agent hooks
if echo "$all_hooks" | grep -qw "pre-prompt"; then
    echo "  ✓ Agent hooks included"
else
    echo "  ✗ Agent hooks NOT included"
    rm -rf .claude .github
    exit 1
fi

# Should contain CI/CD hooks
if echo "$all_hooks" | grep -qw "pre-build"; then
    echo "  ✓ CI/CD hooks included"
else
    echo "  ✗ CI/CD hooks NOT included"
    rm -rf .claude .github
    exit 1
fi

rm -rf .claude .github

# Test deduplication in detect_all_hooks
echo ""
echo "Test 10: detect_all_hooks deduplicates hooks"
hook_count=$(echo "$all_hooks" | wc -w)
unique_count=$(echo "$all_hooks" | tr ' ' '\n' | sort -u | wc -l)
if [ "$hook_count" -eq "$unique_count" ]; then
    echo "  ✓ No duplicate hooks in detect_all_hooks"
else
    echo "  ✗ Duplicate hooks found"
    exit 1
fi

# Test get_hook_category
echo ""
echo "Test 11: get_hook_category for various hook types"

category=$(get_hook_category "pre-commit")
if [ "$category" = "git" ]; then
    echo "  ✓ pre-commit category: git"
else
    echo "  ✗ pre-commit category should be 'git', got '$category'"
    exit 1
fi

category=$(get_hook_category "pre-prompt")
if [ "$category" = "agent" ]; then
    echo "  ✓ pre-prompt category: agent"
else
    echo "  ✗ pre-prompt category should be 'agent', got '$category'"
    exit 1
fi

category=$(get_hook_category "pre-build")
if [ "$category" = "cicd" ]; then
    echo "  ✓ pre-build category: cicd"
else
    echo "  ✗ pre-build category should be 'cicd', got '$category'"
    exit 1
fi

category=$(get_hook_category "unknown-hook")
if [ "$category" = "unknown" ]; then
    echo "  ✓ unknown-hook category: unknown"
else
    echo "  ✗ unknown-hook category should be 'unknown', got '$category'"
    exit 1
fi

# Test is_hook_available
echo ""
echo "Test 12: is_hook_available for various scenarios"

# Test with git hook (always available)
if is_hook_available "pre-commit"; then
    echo "  ✓ pre-commit is available"
else
    echo "  ✗ pre-commit should be available"
    exit 1
fi

# Test with agent hook when .claude doesn't exist
# Save current state
if [ -d ".claude" ]; then
    claude_existed=true
    mv .claude .claude.test_backup
else
    claude_existed=false
fi

if is_hook_available "pre-prompt"; then
    echo "  ✗ pre-prompt should NOT be available without .claude"
    # Restore .claude before exit
    if [ "$claude_existed" = true ]; then
        mv .claude.test_backup .claude
    fi
    exit 1
else
    echo "  ✓ pre-prompt not available without .claude"
fi

# Restore .claude if it existed
if [ "$claude_existed" = true ]; then
    mv .claude.test_backup .claude
    mkdir -p .claude
else
    mkdir -p .claude
fi

# Test with agent hook when .claude exists
mkdir -p .claude
if is_hook_available "pre-prompt"; then
    echo "  ✓ pre-prompt is available with .claude"
else
    echo "  ✗ pre-prompt should be available with .claude"
    rm -rf .claude
    exit 1
fi
rm -rf .claude

# Test with CI/CD hook when no config exists
if is_hook_available "pre-build"; then
    echo "  ✗ pre-build should NOT be available without CI/CD config"
    exit 1
else
    echo "  ✓ pre-build not available without CI/CD config"
fi

# Test with CI/CD hook when config exists
mkdir -p .chp
touch .chp/cicd-enabled
if is_hook_available "pre-build"; then
    echo "  ✓ pre-build is available with CI/CD config"
else
    echo "  ✗ pre-build should be available with CI/CD config"
    rm -rf .chp
    exit 1
fi
rm -rf .chp

# Test backwards compatibility
echo ""
echo "Test 13: backwards compatibility - detect_git_hooks"
old_git_hooks=$(detect_git_hooks)
if [ -n "$old_git_hooks" ]; then
    echo "  ✓ detect_git_hooks still works"
else
    echo "  ✗ detect_git_hooks should return hooks"
    exit 1
fi

echo ""
echo "Test 14: backwards compatibility - detect_pretool_hooks"
touch .pretool
old_pretool_hooks=$(detect_pretool_hooks)
rm .pretool
if echo "$old_pretool_hooks" | grep -q "pre-write"; then
    echo "  ✓ detect_pretool_hooks still works"
else
    echo "  ✗ detect_pretool_hooks should return pre-write"
    exit 1
fi

echo ""
echo "Test 15: backwards compatibility - detect_available_hooks"
available_hooks=$(detect_available_hooks)
if [ -n "$available_hooks" ]; then
    echo "  ✓ detect_available_hooks still works"
else
    echo "  ✗ detect_available_hooks should return hooks"
    exit 1
fi

echo ""
echo "=========================================="
echo "All tests passed!"
echo "=========================================="

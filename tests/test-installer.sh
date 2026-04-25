#!/bin/bash
# Test universal hook installation for all hook types

set -e

# Source dependencies
source "$(dirname "$0")/../core/common.sh"
source "$(dirname "$0")/../core/detector.sh"
source "$(dirname "$0")/../core/installer.sh"

echo "Testing universal hook installation..."
echo ""

# Setup: create a self-contained test directory with CHP structure
TEST_DIR="$(mktemp -d)"
mkdir -p "$TEST_DIR/.git/hooks" "$TEST_DIR/.claude/hooks"
mkdir -p "$TEST_DIR/hooks/git" "$TEST_DIR/hooks/agent"
mkdir -p "$TEST_DIR/docs/chp/laws" "$TEST_DIR/.chp"
echo '{"hooks":{},"version":"1.0"}' > "$TEST_DIR/.chp/hook-registry.json"

# Init a real git repo so git-based checks pass
git init "$TEST_DIR" >/dev/null 2>&1

# Helper: create a test template
make_template() {
    local category="$1" hook="$2"
    local file="$TEST_DIR/hooks/$category/$hook.sh"
    echo "#!/bin/bash" > "$file"
    echo "# CHP-MANAGED: Do not edit this line" >> "$file"
    echo "# CHP template for $hook" >> "$file"
    echo "echo '$hook hook running'" >> "$file"
}

cleanup() {
    cd /
    rm -rf "$TEST_DIR"
}
trap cleanup EXIT

cd "$TEST_DIR"

# Override CHP_BASE so all paths resolve to test dir
_ORIG_CHP_BASE="$CHP_BASE"
_ORIG_LAWS_DIR="$LAWS_DIR"
export CHP_BASE="$TEST_DIR"
export LAWS_DIR="$TEST_DIR/docs/chp/laws"
export HOOK_REGISTRY="$TEST_DIR/.chp/hook-registry.json"

echo "Test 1: backup_existing_hook backs up non-CHP hooks"
echo "#!/bin/bash" > .git/hooks/pre-commit
echo "echo 'custom hook'" >> .git/hooks/pre-commit
chmod +x .git/hooks/pre-commit

if backup_existing_hook ".git/hooks/pre-commit" >/dev/null 2>&1; then
    backup_files=$(ls .git/hooks/ | grep "pre-commit.chp-backup" || true)
    if [ -n "$backup_files" ]; then
        echo "  ✓ Non-CHP hook backed up"
    else
        echo "  ✗ Backup file not created"
        exit 1
    fi
else
    echo "  ✗ backup_existing_hook failed"
    exit 1
fi

echo ""
echo "Test 2: backup_existing_hook doesn't back up CHP hooks"
echo "#!/bin/bash" > .git/hooks/pre-push
echo "# CHP-MANAGED: Do not edit this line" >> .git/hooks/pre-push
chmod +x .git/hooks/pre-push

if backup_existing_hook ".git/hooks/pre-push" >/dev/null 2>&1; then
    backup_files=$(ls .git/hooks/ | grep "pre-push.chp-backup" || true)
    if [ -z "$backup_files" ]; then
        echo "  ✓ CHP hook not backed up"
    else
        echo "  ✗ CHP hook should not be backed up"
        exit 1
    fi
else
    echo "  ✗ backup_existing_hook failed"
    exit 1
fi

echo ""
echo "Test 3: install_hook_template for git hooks"
make_template "git" "pre-commit"

if install_hook_template "pre-commit" "git" >/dev/null 2>&1; then
    if [ -f ".git/hooks/pre-commit" ] && [ -x ".git/hooks/pre-commit" ]; then
        echo "  ✓ Git hook installed and executable"
    else
        echo "  ✗ Git hook not installed or not executable"
        exit 1
    fi
else
    echo "  ✗ install_hook_template failed for git"
    exit 1
fi

echo ""
echo "Test 4: install_hook_template for agent hooks"
make_template "agent" "pre-prompt"

if install_hook_template "pre-prompt" "agent" >/dev/null 2>&1; then
    if [ -f ".claude/hooks/pre-prompt" ]; then
        echo "  ✓ Agent hook installed"
    else
        echo "  ✗ Agent hook not installed"
        exit 1
    fi
else
    echo "  ✗ install_hook_template failed for agent"
    exit 1
fi

echo ""
echo "Test 5: uninstall_hook_template removes CHP hooks"
if uninstall_hook_template "pre-commit" "git" >/dev/null 2>&1; then
    if [ ! -f ".git/hooks/pre-commit" ]; then
        echo "  ✓ Git hook uninstalled"
    else
        echo "  ✗ Git hook still exists"
        exit 1
    fi
else
    echo "  ✗ uninstall_hook_template failed"
    exit 1
fi

echo ""
echo "Test 6: install_law_hooks installs all hooks from law.json"
make_template "git" "pre-commit"
make_template "git" "pre-push"
make_template "agent" "pre-prompt"

TEST_LAW_DIR="$LAWS_DIR/test-law"
mkdir -p "$TEST_LAW_DIR"
cat > "$TEST_LAW_DIR/law.json" << 'EOF'
{
  "name": "test-law",
  "created": "2026-04-24T00:00:00Z",
  "severity": "error",
  "failures": 0,
  "tightening_level": 0,
  "hooks": ["pre-commit", "pre-push", "pre-prompt"],
  "enabled": true
}
EOF

if install_law_hooks "test-law" >/dev/null 2>&1; then
    if [ -f ".git/hooks/pre-commit" ] && [ -f ".git/hooks/pre-push" ] && [ -f ".claude/hooks/pre-prompt" ]; then
        echo "  ✓ All hooks installed for law"
    else
        echo "  ✗ Not all hooks installed"
        exit 1
    fi
else
    echo "  ✗ install_law_hooks failed"
    exit 1
fi

echo ""
echo "Test 7: uninstall_law_hooks removes all hooks for a law"
if uninstall_law_hooks "test-law" >/dev/null 2>&1; then
    if [ ! -f ".git/hooks/pre-commit" ] && [ ! -f ".git/hooks/pre-push" ] && [ ! -f ".claude/hooks/pre-prompt" ]; then
        echo "  ✓ All hooks uninstalled for law"
    else
        echo "  ✗ Some hooks still exist"
        exit 1
    fi
else
    echo "  ✗ uninstall_law_hooks failed"
    exit 1
fi

echo ""
echo "Test 8: Backwards compatibility - install_hook still works"
if install_hook "test-law" "pre-commit" >/dev/null 2>&1; then
    if [ -f ".git/hooks/pre-commit" ]; then
        echo "  ✓ Legacy install_hook still works"
    else
        echo "  ✗ Legacy install_hook failed"
        exit 1
    fi
else
    echo "  ✗ Legacy install_hook failed"
    exit 1
fi

echo ""
echo "Test 9: Backwards compatibility - uninstall_hook still works"
if uninstall_hook "test-law" "pre-commit" >/dev/null 2>&1; then
    if [ ! -f ".git/hooks/pre-commit" ]; then
        echo "  ✓ Legacy uninstall_hook still works"
    else
        echo "  ✗ Legacy uninstall_hook failed"
        exit 1
    fi
else
    echo "  ✗ Legacy uninstall_hook failed"
    exit 1
fi

echo ""
echo "Test 10: Graceful handling of missing templates"
# commit-msg template doesn't exist in test dir
if install_hook_template "commit-msg" "git" >/dev/null 2>&1; then
    echo "  ✗ Should fail gracefully for missing template"
    exit 1
else
    echo "  ✓ Missing template handled gracefully"
fi

echo ""
echo "Test 11: _install_git_hook helper function"
make_template "git" "commit-msg"

if _install_git_hook "commit-msg" >/dev/null 2>&1; then
    if [ -f ".git/hooks/commit-msg" ]; then
        echo "  ✓ _install_git_hook works"
    else
        echo "  ✗ _install_git_hook failed"
        exit 1
    fi
else
    echo "  ✗ _install_git_hook failed"
    exit 1
fi

echo ""
echo "Test 12: _uninstall_git_hook helper function"
if _uninstall_git_hook "commit-msg" >/dev/null 2>&1; then
    if [ ! -f ".git/hooks/commit-msg" ]; then
        echo "  ✓ _uninstall_git_hook works"
    else
        echo "  ✗ _uninstall_git_hook failed"
        exit 1
    fi
else
    echo "  ✗ _uninstall_git_hook failed"
    exit 1
fi

echo ""
echo "Test 13: _install_agent_hook helper function"
make_template "agent" "post-prompt"

if _install_agent_hook "post-prompt" >/dev/null 2>&1; then
    if [ -f ".claude/hooks/post-prompt" ]; then
        echo "  ✓ _install_agent_hook works"
    else
        echo "  ✗ _install_agent_hook failed"
        exit 1
    fi
else
    echo "  ✗ _install_agent_hook failed"
    exit 1
fi

echo ""
echo "Test 14: _uninstall_agent_hook helper function"
if _uninstall_agent_hook "post-prompt" >/dev/null 2>&1; then
    if [ ! -f ".claude/hooks/post-prompt" ]; then
        echo "  ✓ _uninstall_agent_hook works"
    else
        echo "  ✗ _uninstall_agent_hook failed"
        exit 1
    fi
else
    echo "  ✗ _uninstall_agent_hook failed"
    exit 1
fi

# Restore original CHP_BASE
export CHP_BASE="$_ORIG_CHP_BASE"
export LAWS_DIR="$_ORIG_LAWS_DIR"

echo ""
echo "=========================================="
echo "All tests passed!"
echo "=========================================="

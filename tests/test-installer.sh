#!/bin/bash
# Test universal hook installation for all hook types

set -e  # Exit on test failures

# Source dependencies
source "$(dirname "$0")/../core/common.sh"
source "$(dirname "$0")/../core/detector.sh"
source "$(dirname "$0")/../core/installer.sh"

echo "Testing universal hook installation..."
echo ""

# Setup test environment
TEST_DIR="$(mktemp -d)"
cd "$TEST_DIR"
mkdir -p .git/hooks .claude/hooks

# Cleanup function
cleanup() {
    cd /
    rm -rf "$TEST_DIR"
}
trap cleanup EXIT

echo "Test 1: backup_existing_hook backs up non-CHP hooks"
# Create a non-CHP hook
echo "#!/bin/bash" > .git/hooks/pre-commit
echo "echo 'custom hook'" >> .git/hooks/pre-commit
chmod +x .git/hooks/pre-commit

if backup_existing_hook ".git/hooks/pre-commit" > /dev/null 2>&1; then
    # Check if backup exists by looking for the pattern
    backup_files=$(ls .git/hooks/ | grep "pre-commit.chp-backup" || true)
    if [ -n "$backup_files" ]; then
        echo "  ✓ Non-CHP hook backed up"
    else
        echo "  ✗ Backup file not created"
        ls -la .git/hooks/
        exit 1
    fi
else
    echo "  ✗ backup_existing_hook failed"
    exit 1
fi

echo ""
echo "Test 2: backup_existing_hook doesn't back up CHP hooks"
# Create a CHP-managed hook
echo "#!/bin/bash" > .git/hooks/pre-push
echo "# CHP-MANAGED: Do not edit this line" >> .git/hooks/pre-push
chmod +x .git/hooks/pre-push

if backup_existing_hook ".git/hooks/pre-push" > /dev/null 2>&1; then
    # Check that NO backup was created
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
# First create a template
mkdir -p "$CHP_BASE/hooks/git"
echo "#!/bin/bash" > "$CHP_BASE/hooks/git/pre-commit.sh"
echo "# CHP-MANAGED: Do not edit this line" >> "$CHP_BASE/hooks/git/pre-commit.sh"
echo "# CHP template for pre-commit" >> "$CHP_BASE/hooks/git/pre-commit.sh"
echo "echo 'pre-commit hook running'" >> "$CHP_BASE/hooks/git/pre-commit.sh"

if install_hook_template "pre-commit" "git" > /dev/null 2>&1; then
    if [ -f ".git/hooks/pre-commit" ]; then
        # Check if hook is executable
        if [ -x ".git/hooks/pre-commit" ]; then
            echo "  ✓ Git hook installed and executable"
        else
            echo "  ✗ Git hook not executable"
            exit 1
        fi
    else
        echo "  ✗ Git hook not installed"
        exit 1
    fi
else
    echo "  ✗ install_hook_template failed for git"
    exit 1
fi

echo ""
echo "Test 4: install_hook_template for agent hooks"
mkdir -p .claude/hooks
echo "#!/bin/bash" > "$CHP_BASE/hooks/agent/pre-prompt.sh"
echo "# CHP-MANAGED: Do not edit this line" >> "$CHP_BASE/hooks/agent/pre-prompt.sh"
echo "# CHP template for pre-prompt" >> "$CHP_BASE/hooks/agent/pre-prompt.sh"
echo "echo 'pre-prompt hook running'" >> "$CHP_BASE/hooks/agent/pre-prompt.sh"

if install_hook_template "pre-prompt" "agent" > /dev/null 2>&1; then
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
if uninstall_hook_template "pre-commit" "git" > /dev/null 2>&1; then
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
# Create a test law
TEST_LAW_DIR="$CHP_BASE/docs/chp/laws/test-law"
mkdir -p "$TEST_LAW_DIR"
cat > "$TEST_LAW_DIR/law.json" << EOF
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

if install_law_hooks "test-law" > /dev/null 2>&1; then
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
if uninstall_law_hooks "test-law" > /dev/null 2>&1; then
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
if install_hook "test-law" "pre-commit" > /dev/null 2>&1; then
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
if uninstall_hook "test-law" "pre-commit" > /dev/null 2>&1; then
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
# Remove the template file
rm -f "$CHP_BASE/hooks/git/commit-msg.sh"

if install_hook_template "commit-msg" "git" > /dev/null 2>&1; then
    echo "  ✗ Should fail gracefully for missing template"
    exit 1
else
    echo "  ✓ Missing template handled gracefully"
fi

echo ""
echo "Test 11: _install_git_hook helper function"
echo "#!/bin/bash" > "$CHP_BASE/hooks/git/commit-msg.sh"
echo "# CHP-MANAGED: Do not edit this line" >> "$CHP_BASE/hooks/git/commit-msg.sh"
echo "# CHP template" >> "$CHP_BASE/hooks/git/commit-msg.sh"

if _install_git_hook "commit-msg" > /dev/null 2>&1; then
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
if _uninstall_git_hook "commit-msg" > /dev/null 2>&1; then
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
echo "#!/bin/bash" > "$CHP_BASE/hooks/agent/post-prompt.sh"
echo "# CHP-MANAGED: Do not edit this line" >> "$CHP_BASE/hooks/agent/post-prompt.sh"
echo "# CHP template" >> "$CHP_BASE/hooks/agent/post-prompt.sh"

if _install_agent_hook "post-prompt" > /dev/null 2>&1; then
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
if _uninstall_agent_hook "post-prompt" > /dev/null 2>&1; then
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

# Clean up test law
rm -rf "$TEST_LAW_DIR"

echo ""
echo "=========================================="
echo "All tests passed!"
echo "=========================================="

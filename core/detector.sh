#!/bin/bash
# Detect available hook systems

source "$(dirname "${BASH_SOURCE[0]}")/common.sh"

# ============================================================================
# LEGACY FUNCTIONS (maintained for backwards compatibility)
# ============================================================================

# Detect git hooks (legacy - returns subset)
detect_git_hooks() {
    if [ -d .git ]; then
        echo "pre-commit pre-push pre-merge-commit"
    fi
}

# Detect pretool hooks (legacy)
detect_pretool_hooks() {
    if [ -f .pretool ] || [ -d .pretool ]; then
        echo "pre-write pre-commit pre-push"
    fi
}

# Detect all available hooks (legacy - uses new functions internally now)
detect_available_hooks() {
    detect_all_hooks
}

# ============================================================================
# NEW FUNCTIONS - comprehensive hook detection
# ============================================================================

# Detect all git hook types (all 15 standard git hooks)
detect_all_git_hooks() {
    echo "pre-commit post-commit pre-push post-merge commit-msg prepare-commit-msg pre-rebase post-checkout post-rewrite applypatch-msg pre-applypatch post-applypatch update pre-auto-gc post-update"
}

# Detect all agent/AI hook types
detect_all_agent_hooks() {
    # Only return agent hooks if .claude directory exists
    if [ -d .claude ]; then
        echo "pre-prompt post-prompt pre-tool post-tool pre-response post-response"
    fi
}

# Detect all CI/CD hook types
detect_all_cicd_hooks() {
    # Check for CI/CD configuration files
    local has_cicd=false

    # Check for GitHub Actions
    if [ -d .github/workflows ] && [ -n "$(ls -A .github/workflows/*.yml 2>/dev/null || ls -A .github/workflows/*.yaml 2>/dev/null)" ]; then
        has_cicd=true
    fi

    # Check for GitLab CI
    if [ -f .gitlab-ci.yml ]; then
        has_cicd=true
    fi

    # Check for Jenkins
    if [ -f Jenkinsfile ]; then
        has_cicd=true
    fi

    # Check for CHP-specific CI/CD marker
    if [ -f .chp/cicd-enabled ]; then
        has_cicd=true
    fi

    # Return CI/CD hooks if any config exists
    if [ "$has_cicd" = "true" ]; then
        echo "pre-build post-build pre-deploy post-deploy"
    fi
}

# Detect all available hooks across all systems (deduplicated)
detect_all_hooks() {
    local all_hooks=""

    # Always include git hooks (they're always available in git repos)
    all_hooks="$all_hooks $(detect_all_git_hooks)"

    # Add agent hooks if .claude exists
    all_hooks="$all_hooks $(detect_all_agent_hooks)"

    # Add CI/CD hooks if configured
    all_hooks="$all_hooks $(detect_all_cicd_hooks)"

    # Deduplicate and return
    echo "$all_hooks" | tr ' ' '\n' | sort -u | tr '\n' ' ' | xargs
}

# Get the category of a hook type
get_hook_category() {
    local hook_type="$1"

    # Check git hooks
    local git_hooks="pre-commit post-commit pre-push post-merge commit-msg prepare-commit-msg pre-rebase post-checkout post-rewrite applypatch-msg pre-applypatch post-applypatch update pre-auto-gc post-update"
    if echo "$git_hooks" | grep -qw "$hook_type"; then
        echo "git"
        return
    fi

    # Check agent hooks
    local agent_hooks="pre-prompt post-prompt pre-tool post-tool pre-response post-response"
    if echo "$agent_hooks" | grep -qw "$hook_type"; then
        echo "agent"
        return
    fi

    # Check CI/CD hooks
    local cicd_hooks="pre-build post-build pre-deploy post-deploy"
    if echo "$cicd_hooks" | grep -qw "$hook_type"; then
        echo "cicd"
        return
    fi

    # Unknown category
    echo "unknown"
}

# Check if a specific hook type is available
is_hook_available() {
    local hook_type="$1"

    # Get all available hooks
    local available_hooks=$(detect_all_hooks)

    # Check if the requested hook is in the available list
    if echo "$available_hooks" | grep -qw "$hook_type"; then
        return 0  # true
    else
        return 1  # false
    fi
}

# ============================================================================
# MAIN EXECUTION
# ============================================================================

# Main if run directly
if [ "${BASH_SOURCE[0]}" = "$0" ]; then
    detect_available_hooks
fi

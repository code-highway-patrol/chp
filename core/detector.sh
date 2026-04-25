#!/bin/bash
# Detect available hook systems

source "$(dirname "${BASH_SOURCE[0]}")/common.sh"

# Legacy functions (maintained for backwards compatibility)

detect_git_hooks() {
    if [ -d .git ]; then
        echo "pre-commit pre-push pre-merge-commit"
    fi
}

detect_pretool_hooks() {
    if [ -f .pretool ] || [ -d .pretool ]; then
        echo "pre-write pre-commit pre-push"
    fi
}

detect_available_hooks() {
    detect_all_hooks
}

detect_all_git_hooks() {
    echo "pre-commit post-commit pre-push post-merge commit-msg prepare-commit-msg pre-rebase post-checkout post-rewrite applypatch-msg pre-applypatch post-applypatch update pre-auto-gc post-update"
}

detect_all_agent_hooks() {
    if [ -d .claude ]; then
        echo "pre-prompt post-prompt pre-tool post-tool pre-response post-response"
    fi
}

detect_all_cicd_hooks() {
    local has_cicd=false

    if [ -d .github/workflows ] && [ -n "$(ls -A .github/workflows/*.yml 2>/dev/null || ls -A .github/workflows/*.yaml 2>/dev/null)" ]; then
        has_cicd=true
    fi

    if [ -f .gitlab-ci.yml ]; then
        has_cicd=true
    fi

    if [ -f Jenkinsfile ]; then
        has_cicd=true
    fi

    if [ -f .chp/cicd-enabled ]; then
        has_cicd=true
    fi

    if [ "$has_cicd" = "true" ]; then
        echo "pre-build post-build pre-deploy post-deploy"
    fi
}

detect_all_hooks() {
    local all_hooks=""

    all_hooks="$all_hooks $(detect_all_git_hooks)"
    all_hooks="$all_hooks $(detect_all_agent_hooks)"
    all_hooks="$all_hooks $(detect_all_cicd_hooks)"

    echo "$all_hooks" | tr ' ' '\n' | sort -u | tr '\n' ' ' | xargs
}

get_hook_category() {
    local hook_type="$1"

    local git_hooks="pre-commit post-commit pre-push post-merge commit-msg prepare-commit-msg pre-rebase post-checkout post-rewrite applypatch-msg pre-applypatch post-applypatch update pre-auto-gc post-update"
    if echo "$git_hooks" | grep -qw "$hook_type"; then
        echo "git"
        return
    fi

    local agent_hooks="pre-prompt post-prompt pre-tool post-tool pre-response post-response"
    if echo "$agent_hooks" | grep -qw "$hook_type"; then
        echo "agent"
        return
    fi

    local cicd_hooks="pre-build post-build pre-deploy post-deploy"
    if echo "$cicd_hooks" | grep -qw "$hook_type"; then
        echo "cicd"
        return
    fi

    echo "unknown"
}

is_hook_available() {
    local hook_type="$1"
    local available_hooks=$(detect_all_hooks)

    if echo "$available_hooks" | grep -qw "$hook_type"; then
        return 0
    else
        return 1
    fi
}

if [ "${BASH_SOURCE[0]}" = "$0" ]; then
    detect_available_hooks
fi

#!/bin/bash
# Detect available hook systems

source "$(dirname "${BASH_SOURCE[0]}")/common.sh"

# Detect git hooks
detect_git_hooks() {
    if [ -d .git ]; then
        echo "pre-commit pre-push pre-merge-commit"
    fi
}

# Detect pretool hooks
detect_pretool_hooks() {
    if [ -f .pretool ] || [ -d .pretool ]; then
        echo "pre-write pre-commit pre-push"
    fi
}

# Detect all available hooks
detect_available_hooks() {
    local all_hooks=""

    # Check git
    if [ -d .git ]; then
        all_hooks="$all_hooks $(detect_git_hooks)"
    fi

    # Check pretool
    if [ -f .pretool ] || [ -d .pretool ]; then
        all_hooks="$all_hooks $(detect_pretool_hooks)"
    fi

    # Deduplicate and return
    echo "$all_hooks" | tr ' ' '\n' | sort -u | tr '\n' ' ' | xargs
}

# Main if run directly
if [ "${BASH_SOURCE[0]}" = "$0" ]; then
    detect_available_hooks
fi

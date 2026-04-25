#!/bin/bash
# Interactive prompting utilities for CHP CLI

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    echo "Error: This file should be sourced, not executed directly."
    echo "Usage: source core/interactive.sh"
    exit 1
fi

# This file is sourced, so no strict mode (would affect parent)

# Usage: prompt_choice "Question" "Option 1" "Option 2" ...
# Returns: selected option number (1-indexed)
prompt_choice() {
    local question="$1"
    shift
    local options=("$@")

    while true; do
        echo ""
        echo "$question"
        for i in "${!options[@]}"; do
            echo "  $((i+1))) ${options[$i]}"
        done
        echo ""

        read -rp "Choose one: " choice

        if [[ ! "$choice" =~ ^[0-9]+$ ]]; then
            echo "Invalid choice. Please enter a number."
            continue
        fi

        if [[ $choice -lt 1 || $choice -gt ${#options[@]} ]]; then
            echo "Invalid choice. Please enter a number between 1 and ${#options[@]}."
            continue
        fi

        echo "${options[$((choice-1))]}"
        return 0
    done
}

# Usage: prompt_yes_no "Question"
# Returns: 0 for yes, 1 for no
prompt_yes_no() {
    local question="$1"

    while true; do
        read -rp "$question (y/n): " response
        case "$response" in
            y|Y|yes|YES) return 0 ;;
            n|N|no|NO) return 1 ;;
            *) echo "Please answer y or n." ;;
        esac
    done
}

# Usage: prompt_text "Question" "default_value"
prompt_text() {
    local question="$1"
    local default="$2"

    if [[ -n "$default" ]]; then
        read -rp "$question [$default]: " response
        echo "${response:-$default}"
    else
        read -rp "$question: " response
        echo "$response"
    fi
}

# Usage: display_preview "name" "severity" "hooks" "pattern" "files" "exceptions"
display_preview() {
    local law_name="$1"
    local severity="$2"
    local hooks="$3"
    local pattern="$4"
    local files="$5"
    local exceptions="$6"

    echo ""
    echo "=================================="
    echo "  Law Preview: $law_name"
    echo "=================================="
    echo ""
    echo "  Pattern: $pattern"
    echo "  Files: $files"
    echo "  Severity: $severity"
    echo "  Hooks: $hooks"
    if [[ -n "$exceptions" && "$exceptions" != "none" ]]; then
        echo "  Exceptions: $exceptions"
    fi
    echo ""
    echo "  Files created:"
    echo "    - docs/chp/laws/$law_name/law.json"
    echo "    - docs/chp/laws/$law_name/verify.sh"
    echo "    - docs/chp/laws/$law_name/guidance.md"
    echo ""

    echo "  Hooks installed:"
    local IFS=','
    for hook in $hooks; do
        case "$hook" in
            pre-commit) echo "    - .git/hooks/pre-commit" ;;
            pre-push) echo "    - .git/hooks/pre-push" ;;
            pre-merge-commit) echo "    - .git/hooks/pre-merge-commit" ;;
        esac
    done
    echo ""
}

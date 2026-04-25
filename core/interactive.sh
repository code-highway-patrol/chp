#!/bin/bash
# Interactive prompting utilities for CHP CLI
# This file should be sourced, not executed directly

# Guard against direct execution
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    echo "Error: This file should be sourced, not executed directly."
    echo "Usage: source core/interactive.sh"
    exit 1
fi

# Note: We don't set strict mode here since this file is sourced,
# and it would affect the parent script's behavior

# Prompt user with a question and multiple choice options
# Usage: prompt_choice "Question text" "Option 1" "Option 2" "Option 3" ...
# Returns: The selected option number (1-indexed)
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

        # Validate choice is a number
        if [[ ! "$choice" =~ ^[0-9]+$ ]]; then
            echo "Invalid choice. Please enter a number."
            continue
        fi

        # Validate choice is in range
        if [[ $choice -lt 1 || $choice -gt ${#options[@]} ]]; then
            echo "Invalid choice. Please enter a number between 1 and ${#options[@]}."
            continue
        fi

        echo "${options[$((choice-1))]}"
        return 0
    done
}

# Prompt for yes/no confirmation
# Usage: prompt_yes_no "Question text"
# Returns: 0 for yes, 1 for no
prompt_yes_no() {
    local question="$1"
    local response
    
    while true; do
        read -rp "$question (y/n): " response
        case "$response" in
            y|Y|yes|YES) return 0 ;;
            n|N|no|NO) return 1 ;;
            *) echo "Please answer y or n." ;;
        esac
    done
}

# Prompt for text input with default
# Usage: prompt_text "Question" "default_value"
prompt_text() {
    local question="$1"
    local default="$2"
    local response
    
    if [[ -n "$default" ]]; then
        read -rp "$question [$default]: " response
        echo "${response:-$default}"
    else
        read -rp "$question: " response
        echo "$response"
    fi
}

# Display a preview of what will be created
# Usage: display_preview "Law name" "severity" "hooks" "pattern" "files" "exceptions"
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
    echo "    • docs/chp/laws/$law_name/law.json"
    echo "    • docs/chp/laws/$law_name/verify.sh"
    echo "    • docs/chp/laws/$law_name/guidance.md"
    echo ""

    # Show which hooks will be installed
    echo "  Hooks installed:"
    local IFS=','
    for hook in $hooks; do
        case "$hook" in
            pre-commit) echo "    • .git/hooks/pre-commit" ;;
            pre-push) echo "    • .git/hooks/pre-push" ;;
            pre-merge-commit) echo "    • .git/hooks/pre-merge-commit" ;;
        esac
    done
    echo ""
}

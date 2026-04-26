#!/usr/bin/env bash
# Pattern checker — grep-based pattern matching for atomic checks

# Usage: check_pattern <hook_type> <config_json> <context_file>
# config_json: {"pattern": "regex", "skip_extensions": ["md","json","sh"]}
# Returns: PASS, FAIL:<message>, or SKIP

check_pattern() {
    local hook_type="$1"
    local config_json="$2"

    local pattern
    pattern=$(echo "$config_json" | jq -r '.pattern // empty')

    if [[ -z "$pattern" ]]; then
        echo "SKIP:pattern:not-configured"
        return 0
    fi

    local skip_ext
    skip_ext=$(echo "$config_json" | jq -r '.skip_extensions // ["md","json","txt","sh","yml","yaml","lock","gitignore"] | join("|")')

    local violations=0
    local violating_files=()

    case "$hook_type" in
        pre-commit)
            local staged_files
            staged_files=$(git diff --cached --name-only --diff-filter=ACM 2>/dev/null)

            if [[ -z "$staged_files" ]]; then
                echo "PASS"
                return 0
            fi

            while IFS= read -r file; do
                [[ -z "$file" ]] && continue
                echo "$file" | grep -qE "\\.(${skip_ext})$" && continue
                [[ ! -f "$file" ]] && continue

                # Match only added lines (+), not deletions or surrounding context.
                # Without this filter, deleting code near an unchanged violation
                # makes pre-commit reject the deletion — false positive.
                if git diff --cached "$file" 2>/dev/null | grep -E '^\+' | grep -v '^\+\+\+' | grep -qE "$pattern"; then
                    violations=$((violations + 1))
                    violating_files+=("$file")
                fi
            done <<< "$staged_files"
            ;;
        pre-push|post-commit)
            local files
            if git rev-parse @{u} >/dev/null 2>&1; then
                files=$(git diff --name-only HEAD @{u} 2>/dev/null)
            else
                files=$(git diff --name-only HEAD^..HEAD 2>/dev/null)
            fi

            if [[ -z "$files" ]]; then
                echo "PASS"
                return 0
            fi

            while IFS= read -r file; do
                [[ -z "$file" ]] && continue
                echo "$file" | grep -qE "\\.(${skip_ext})$" && continue
                [[ ! -f "$file" ]] && continue

                if grep -qE "$pattern" "$file" 2>/dev/null; then
                    violations=$((violations + 1))
                    violating_files+=("$file")
                fi
            done <<< "$files"
            ;;
        pre-tool|post-tool)
            local content="${CHP_TOOL_CONTENT:-$(cat 2>/dev/null)}"
            if [[ -n "$content" ]] && echo "$content" | grep -qE "$pattern"; then
                violations=1
                violating_files+=("${CHP_FILE_PATH:-tool-input}")
            fi
            ;;
        *)
            echo "SKIP:pattern:unsupported-hook:$hook_type"
            return 0
            ;;
    esac

    if [[ $violations -gt 0 ]]; then
        local msg="Pattern '${pattern}' found in ${violations} file(s): ${violating_files[*]}"
        echo "FAIL:${msg}"
        return 1
    fi

    echo "PASS"
    return 0
}

#!/usr/bin/env bash
# Threshold checker — metric-based threshold checking for atomic checks

# Usage: check_threshold <hook_type> <config_json> <context_file>
# config_json: {"metric": "file_line_count", "max": 50} or {"metric": "import_count", "min": 1}
# Supported metrics: file_line_count, import_count, nesting_depth, function_line_count
# Returns: PASS, FAIL:<message>, or SKIP

check_threshold() {
    local hook_type="$1"
    local config_json="$2"

    local metric
    metric=$(echo "$config_json" | jq -r '.metric // empty')

    if [[ -z "$metric" ]]; then
        echo "SKIP:threshold:metric-not-configured"
        return 0
    fi

    local min_val
    local max_val
    min_val=$(echo "$config_json" | jq -r '.min // empty')
    max_val=$(echo "$config_json" | jq -r '.max // empty')

    if [[ -z "$min_val" && -z "$max_val" ]]; then
        echo "SKIP:threshold:no-threshold-configured"
        return 0
    fi

    local skip_ext
    skip_ext=$(echo "$config_json" | jq -r '.skip_extensions // ["md","json","txt","sh","yml","yaml","lock","gitignore"] | join("|")')

    local violations=0
    local violating_files=()
    local violation_details=()

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

                local metric_value
                local check_failed=false

                case "$metric" in
                    file_line_count)
                        metric_value=$(wc -l < "$file" 2>/dev/null | tr -d ' ')
                        ;;
                    import_count)
                        metric_value=$(grep -cE '^(import |require\(|export |from )' "$file" 2>/dev/null || echo 0)
                        ;;
                    nesting_depth)
                        metric_value=$(calculate_nesting_depth "$file")
                        ;;
                    function_line_count)
                        metric_value=$(calculate_function_line_count "$file")
                        ;;
                    *)
                        echo "SKIP:threshold:unsupported-metric:$metric"
                        return 0
                        ;;
                esac

                # Check min threshold
                if [[ -n "$min_val" ]]; then
                    if [[ "$metric_value" -lt "$min_val" ]]; then
                        check_failed=true
                        violation_details+=("$file: ${metric}=${metric_value} (min: ${min_val})")
                    fi
                fi

                # Check max threshold
                if [[ -n "$max_val" ]]; then
                    if [[ "$metric_value" -gt "$max_val" ]]; then
                        check_failed=true
                        violation_details+=("$file: ${metric}=${metric_value} (max: ${max_val})")
                    fi
                fi

                if [[ "$check_failed" == true ]]; then
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

                local metric_value
                local check_failed=false

                case "$metric" in
                    file_line_count)
                        metric_value=$(wc -l < "$file" 2>/dev/null | tr -d ' ')
                        ;;
                    import_count)
                        metric_value=$(grep -cE '^(import |require\(|export |from )' "$file" 2>/dev/null || echo 0)
                        ;;
                    nesting_depth)
                        metric_value=$(calculate_nesting_depth "$file")
                        ;;
                    function_line_count)
                        metric_value=$(calculate_function_line_count "$file")
                        ;;
                    *)
                        echo "SKIP:threshold:unsupported-metric:$metric"
                        return 0
                        ;;
                esac

                # Check min threshold
                if [[ -n "$min_val" ]]; then
                    if [[ "$metric_value" -lt "$min_val" ]]; then
                        check_failed=true
                        violation_details+=("$file: ${metric}=${metric_value} (min: ${min_val})")
                    fi
                fi

                # Check max threshold
                if [[ -n "$max_val" ]]; then
                    if [[ "$metric_value" -gt "$max_val" ]]; then
                        check_failed=true
                        violation_details+=("$file: ${metric}=${metric_value} (max: ${max_val})")
                    fi
                fi

                if [[ "$check_failed" == true ]]; then
                    violations=$((violations + 1))
                    violating_files+=("$file")
                fi
            done <<< "$files"
            ;;
        *)
            echo "SKIP:threshold:unsupported-hook:$hook_type"
            return 0
            ;;
    esac

    if [[ $violations -gt 0 ]]; then
        local msg="Threshold '${metric}' violated in ${violations} file(s): ${violation_details[*]}"
        echo "FAIL:${msg}"
        return 1
    fi

    echo "PASS"
    return 0
}

# Helper: Calculate maximum brace nesting depth in a file
calculate_nesting_depth() {
    local file="$1"
    local max_depth=0
    local current_depth=0

    while IFS= read -r line; do
        # Count opening braces
        local open_count=$(echo "$line" | grep -o '{' | wc -l | tr -d ' ')
        # Count closing braces
        local close_count=$(echo "$line" | grep -o '}' | wc -l | tr -d ' ')

        current_depth=$((current_depth + open_count - close_count))

        if [[ $current_depth -gt $max_depth ]]; then
            max_depth=$current_depth
        fi
    done < "$file"

    echo "$max_depth"
}

# Helper: Approximate lines between function declarations
calculate_function_line_count() {
    local file="$1"
    local max_lines=0
    local current_lines=0
    local in_function=false

    while IFS= read -r line; do
        # Detect function declarations (simplified)
        if echo "$line" | grep -qE '(function\s+\w+|^\s*\w+\s*\([^)]*\)\s*{|const\s+\w+\s*=\s*\([^)]*\)\s*=>|export\s+(const|function)\s+\w+)'; then
            if [[ "$in_function" == true ]]; then
                if [[ $current_lines -gt $max_lines ]]; then
                    max_lines=$current_lines
                fi
            fi
            in_function=true
            current_lines=0
        elif [[ "$in_function" == true ]]; then
            current_lines=$((current_lines + 1))
            # Count closing braces at start of line as function end
            if echo "$line" | grep -qE '^}'; then
                if [[ $current_lines -gt $max_lines ]]; then
                    max_lines=$current_lines
                fi
                in_function=false
                current_lines=0
            fi
        fi
    done < "$file"

    # Handle case where file ends while still in function
    if [[ "$in_function" == true && $current_lines -gt $max_lines ]]; then
        max_lines=$current_lines
    fi

    echo "$max_lines"
}

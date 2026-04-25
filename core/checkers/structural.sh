#!/usr/bin/env bash
# Structural checker — validates code conventions and structural invariants

# Usage: check_structural <hook_type> <config_json> <context_file>
# config_json: {"assert": "test_file_exists", "source_pattern": "src/", "test_pattern": "tests/"}
# Returns: PASS, FAIL:<message>, or SKIP

check_structural() {
    local hook_type="$1"
    local config_json="$2"
    local context_file="$3"

    local assertion
    assertion=$(echo "$config_json" | jq -r '.assert // empty')

    if [[ -z "$assertion" ]]; then
        echo "SKIP:structural:no-assertion-configured"
        return 0
    fi

    case "$assertion" in
        test_file_exists)
            _check_test_file_exists "$hook_type" "$config_json"
            ;;
        no_circular_imports)
            _check_no_circular_imports "$hook_type" "$config_json"
            ;;
        auth_middleware_present)
            _check_auth_middleware_present "$hook_type" "$config_json"
            ;;
        *)
            echo "SKIP:structural:unknown-assertion:$assertion"
            return 0
            ;;
    esac
}

# Check that each staged source file has a corresponding test file
_check_test_file_exists() {
    local hook_type="$1"
    local config_json="$2"

    local source_pattern
    local test_pattern
    source_pattern=$(echo "$config_json" | jq -r '.source_pattern // "src/"')
    test_pattern=$(echo "$config_json" | jq -r '.test_pattern // "tests/"')

    local missing_tests=0
    local missing_files=()

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
                # Check if file matches source pattern
                if [[ "$file" != "$source_pattern"* ]]; then
                    continue
                fi

                # Skip non-code files
                local ext="${file##*.}"
                if [[ "$ext" =~ ^(md|json|txt|yml|yaml|lock|gitignore)$ ]]; then
                    continue
                fi

                # Build expected test file path
                local base_name="${file#$source_pattern}"
                local test_file="${test_pattern}${base_name}"

                # Try common test file patterns
                local found=0
                for test_variant in \
                    "$test_file" \
                    "${test_file%.*}.test.${ext}" \
                    "${test_file%.*}.spec.${ext}" \
                    "${test_file}.test"
                do
                    if [[ -f "$test_variant" ]]; then
                        found=1
                        break
                    fi
                done

                if [[ $found -eq 0 ]]; then
                    missing_tests=$((missing_tests + 1))
                    missing_files+=("$file")
                fi
            done <<< "$staged_files"
            ;;
        *)
            echo "SKIP:structural:test_file_exists:unsupported-hook:$hook_type"
            return 0
            ;;
    esac

    if [[ $missing_tests -gt 0 ]]; then
        local msg="Missing test files for ${missing_tests} source file(s): ${missing_files[*]}"
        echo "FAIL:${msg}"
        return 1
    fi

    echo "PASS"
    return 0
}

# Check for circular imports between files
_check_no_circular_imports() {
    local hook_type="$1"
    local config_json="$2"

    case "$hook_type" in
        pre-commit)
            local staged_files
            staged_files=$(git diff --cached --name-only --diff-filter=ACM 2>/dev/null)

            if [[ -z "$staged_files" ]]; then
                echo "PASS"
                return 0
            fi

            # Build import graph from staged files
            declare -A import_graph
            declare -a files_to_check

            while IFS= read -r file; do
                [[ -z "$file" ]] && continue
                [[ ! -f "$file" ]] && continue

                # Only check code files
                local ext="${file##*.}"
                if [[ ! "$ext" =~ ^(ts|js|tsx|jsx|py|go|rs)$ ]]; then
                    continue
                fi

                files_to_check+=("$file")
            done <<< "$staged_files"

            # For each file, extract imports and check for cycles
            local has_cycle=0
            local cycle_path=()

            for file in "${files_to_check[@]}"; do
                if _detect_cycle "$file" "" "${files_to_check[@]}"; then
                    has_cycle=1
                    break
                fi
            done

            if [[ $has_cycle -eq 1 ]]; then
                echo "FAIL:Circular import detected involving: $file"
                return 1
            fi
            ;;
        *)
            echo "SKIP:structural:no_circular_imports:unsupported-hook:$hook_type"
            return 0
            ;;
    esac

    echo "PASS"
    return 0
}

# Helper to detect cycles using DFS
_detect_cycle() {
    local current_file="$1"
    local path="$2"
    shift 2
    local -a all_files=("$@")

    # Check if we're already in the path (cycle detected)
    if [[ ":$path:" == *":$current_file:"* ]]; then
        return 0  # Cycle found
    fi

    local new_path="${path}:${current_file}"

    # Extract imports from current file
    local imports
    imports=$(_extract_imports "$current_file")

    # Check each import
    while IFS= read -r import; do
        [[ -z "$import" ]] && continue

        # Check if this import is in our file set
        for file in "${all_files[@]}"; do
            if [[ "$file" == *"$import"* ]] || [[ "$file" == "$import" ]]; then
                if _detect_cycle "$file" "$new_path" "${all_files[@]}"; then
                    return 0  # Cycle found
                fi
            fi
        done
    done <<< "$imports"

    return 1  # No cycle from this path
}

# Extract import statements from a file
_extract_imports() {
    local file="$1"
    local ext="${file##*.}"

    case "$ext" in
        ts|js|tsx|jsx)
            # Extract import paths (relative imports only)
            grep -oE 'from ["\x27]([^"\x27]+)["\x27]' "$file" 2>/dev/null | \
                grep -oE '["\x27][.][^"\x27]+["\x27]' | \
                sed 's/["\x27]//g' | \
                sed 's/^[.][/]*//'
            ;;
        py)
            # Extract Python imports
            grep -oE 'from [^. ]+ import|import [^. ]+' "$file" 2>/dev/null | \
                sed 's/from //g' | \
                sed 's/import //g' | \
                sed 's/ .*//g'
            ;;
        *)
            # For other languages, return empty
            echo ""
            ;;
    esac
}

# Check that route files contain auth middleware
_check_auth_middleware_present() {
    local hook_type="$1"
    local config_json="$2"

    local route_pattern
    route_pattern=$(echo "$config_json" | jq -r '.route_pattern // "routes/"')

    case "$hook_type" in
        pre-commit)
            local staged_files
            staged_files=$(git diff --cached --name-only --diff-filter=ACM 2>/dev/null)

            if [[ -z "$staged_files" ]]; then
                echo "PASS"
                return 0
            fi

            local missing_auth=0
            local missing_files=()

            while IFS= read -r file; do
                [[ -z "$file" ]] && continue
                [[ ! -f "$file" ]] && continue

                # Check if file matches route pattern
                if [[ "$file" != *"$route_pattern"* ]]; then
                    continue
                fi

                # Skip non-code files
                local ext="${file##*.}"
                if [[ "$ext" =~ ^(md|json|txt|yml|yaml|lock|gitignore)$ ]]; then
                    continue
                fi

                # Check for auth middleware patterns
                local has_auth=0
                local auth_patterns=(
                    "auth"
                    "authenticate"
                    "requireAuth"
                    "ensureAuthenticated"
                    "middleware.*auth"
                    "@UseGuards.*Auth"
                    "passport.authenticate"
                    "jwt"
                    "session"
                )

                for pattern in "${auth_patterns[@]}"; do
                    if grep -qiE "$pattern" "$file" 2>/dev/null; then
                        has_auth=1
                        break
                    fi
                done

                if [[ $has_auth -eq 0 ]]; then
                    # Check if file defines routes (not just utilities)
                    if grep -qiE "(router|route|get|post|put|delete|patch|@Controller|@Get|@Post)" "$file" 2>/dev/null; then
                        missing_auth=$((missing_auth + 1))
                        missing_files+=("$file")
                    fi
                fi
            done <<< "$staged_files"

            if [[ $missing_auth -gt 0 ]]; then
                local msg="Auth middleware missing from ${missing_auth} route file(s): ${missing_files[*]}"
                echo "FAIL:${msg}"
                return 1
            fi
            ;;
        *)
            echo "SKIP:structural:auth_middleware_present:unsupported-hook:$hook_type"
            return 0
            ;;
    esac

    echo "PASS"
    return 0
}

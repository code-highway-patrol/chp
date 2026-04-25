#!/bin/bash
# Probe — verify laws actually detect violations they claim to check
# Creates temp git repo, plants known violations, runs verify.sh, reports results

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/common.sh"

CHECKERS_DIR="$SCRIPT_DIR/checkers"

# Generate a string that matches a regex pattern
# Uses perl to generate a matching string for simple patterns
generate_matching_content() {
    local pattern="$1"
    # Normalize: strip regex escapes for matching
    local norm="${pattern//\\./.}"
    case "$norm" in
        *console.log*)    echo "console.log(\"probe test\");" ;;
        *console.debug*)  echo "console.debug(\"probe test\");" ;;
        *console.error*)  echo "console.error(\"probe test\");" ;;
        *alert\(*)        echo "alert(\"probe test\");" ;;
        *TODO*)           echo "// TODO: probe test" ;;
        *FIXME*)          echo "// FIXME: probe test" ;;
        *HACK*)           echo "// HACK: probe test" ;;
        *XXX*)            echo "// XXX: probe test" ;;
        *sk-*)            echo "const key = \"sk-test1234567890123456789012\";" ;;
        *AIza*)           echo "const key = \"AIzaSyA12345678901234567890123456789012\";" ;;
        *AKIA*)           echo "const key = \"AKIAIOSFODNN7EXAMPLE\";" ;;
        *ghp_*)           echo "const key = \"ghp_1234567890abcdef1234567890abcdef1234\";" ;;
        *xoxb-*)          echo "const token = \"xoxb-PROBE_TEST-NOT_REAL-XXXXXXXXXXXXXXXXXX\";" ;;
        *xoxp-*)          echo "const token = \"xoxp-123456789012-123456789012-abcdefghijklmnopqrstuvwx\";" ;;
        *password*|*api_key*|*secret*|*token*)
            echo "const password = \"hardcoded_probe_value\";" ;;
        *)                echo "PROBE_PATTERN_MATCH_${pattern}__test_value" ;;
    esac
}

# Generate clean content that should NOT trigger a pattern
generate_clean_content() {
    local pattern="$1"
    echo "// Clean file - no violations"
}

# Set up a temp git repo for probing
setup_probe_repo() {
    local repo_dir="$1"
    mkdir -p "$repo_dir"
    cd "$repo_dir"
    git init -q 2>/dev/null
    git config user.email "probe@chp.dev" 2>/dev/null
    git config user.name "CHP Probe" 2>/dev/null
    # Initial commit so HEAD exists
    echo "init" > .gitignore
    git add .gitignore 2>/dev/null
    git commit -q -m "init" 2>/dev/null
}

# Clean up probe repo
cleanup_probe_repo() {
    local repo_dir="$1"
    cd "$CHP_BASE"
    rm -rf "$repo_dir" 2>/dev/null
}

# Run a single probe against a law
# Returns: 0 = probe passed (law works), 1 = probe failed (law has gaps)
probe_law() {
    local law_name="$1"
    local law_json="$LAWS_DIR/$law_name/law.json"

    if [[ ! -f "$law_json" ]]; then
        echo "SKIP:$law_name:no-law-json"
        return 0
    fi

    local checks_json
    checks_json=$(jq -c '.checks // []' "$law_json" 2>/dev/null)

    if [[ "$checks_json" == "[]" || -z "$checks_json" ]]; then
        echo "SKIP:$law_name:no-checks"
        return 0
    fi

    local check_count
    check_count=$(echo "$checks_json" | jq 'length')
    local probe_pass=0
    local probe_fail=0
    local probe_skip=0
    local -a results=()

    local probe_dir
    probe_dir=$(mktemp -d -t chp_probe_XXXXXX)

    for ((i=0; i<check_count; i++)); do
        local check_id check_type check_config check_severity
        check_id=$(echo "$checks_json" | jq -r ".[$i].id // \"check-$i\"")
        check_type=$(echo "$checks_json" | jq -r ".[$i].type // empty")
        check_config=$(echo "$checks_json" | jq -c ".[$i].config // {}")
        check_severity=$(echo "$checks_json" | jq -r ".[$i].severity // \"warn\"")

        if [[ "$check_type" == "agent" ]]; then
            results+=("$check_id:SKIP:advisory-only")
            ((probe_skip++))
            continue
        fi

        # Probe based on check type
        case "$check_type" in
            pattern)
                local pattern
                pattern=$(echo "$check_config" | jq -r '.pattern // empty')
                if [[ -z "$pattern" ]]; then
                    results+=("$check_id:SKIP:no-pattern")
                    ((probe_skip++))
                    continue
                fi

                # Setup clean repo
                cleanup_probe_repo "$probe_dir" 2>/dev/null
                setup_probe_repo "$probe_dir"

                # Test 1: positive case (should be detected)
                local violating_content
                violating_content=$(generate_matching_content "$pattern")
                echo "$violating_content" > "$probe_dir/probe_test.js"
                git -C "$probe_dir" add probe_test.js 2>/dev/null

                # Run verify.sh in the probe repo context
                cd "$probe_dir"
                local verify_script="$LAWS_DIR/$law_name/verify.sh"
                if [[ -f "$verify_script" ]]; then
                    local verify_output
                    verify_output=$(HOOK_TYPE=pre-commit bash "$verify_script" 2>/dev/null)
                    # Check JSONL output for FAIL status (works for both block and warn severity)
                    local has_fail
                    has_fail=$(echo "$verify_output" | grep -c '"status":"FAIL"' || true)
                    if [[ "$has_fail" -gt 0 ]]; then
                        results+=("$check_id:PASS:detected-violation")
                        ((probe_pass++))
                    else
                        results+=("$check_id:FAIL:missed-violation")
                        ((probe_fail++))
                    fi
                else
                    results+=("$check_id:SKIP:no-verify-sh")
                    ((probe_skip++))
                fi

                # Test 2: negative case (should pass)
                cleanup_probe_repo "$probe_dir" 2>/dev/null
                setup_probe_repo "$probe_dir"

                local clean_content
                clean_content=$(generate_clean_content "$pattern")
                echo "$clean_content" > "$probe_dir/probe_clean.js"
                git -C "$probe_dir" add probe_clean.js 2>/dev/null

                cd "$probe_dir"
                if [[ -f "$verify_script" ]]; then
                    local clean_output
                    clean_output=$(HOOK_TYPE=pre-commit bash "$verify_script" 2>/dev/null)
                    local clean_has_fail
                    clean_has_fail=$(echo "$clean_output" | grep -c '"status":"FAIL"' || true)
                    if [[ "$clean_has_fail" -eq 0 ]]; then
                        results+=("$check_id:PASS:clean-passes")
                        ((probe_pass++))
                    else
                        results+=("$check_id:FAIL:false-positive")
                        ((probe_fail++))
                    fi
                fi
                ;;

            threshold)
                local metric max_val min_val
                metric=$(echo "$check_config" | jq -r '.metric // empty')
                max_val=$(echo "$check_config" | jq -r '.max // empty')
                min_val=$(echo "$check_config" | jq -r '.min // empty')
                results+=("$check_id:SKIP:threshold-auto-probe-unsupported")
                ((probe_skip++))
                ;;

            structural)
                results+=("$check_id:SKIP:structural-auto-probe-unsupported")
                ((probe_skip++))
                ;;

            *)
                results+=("$check_id:SKIP:unknown-type:$check_type")
                ((probe_skip++))
                ;;
        esac
    done

    # Load probes.json if it exists for explicit test cases
    local probes_file="$LAWS_DIR/$law_name/probes.json"
    if [[ -f "$probes_file" ]]; then
        local probe_count
        probe_count=$(jq '.probes | length' "$probes_file" 2>/dev/null)
        for ((p=0; p<probe_count; p++)); do
            local desc content should_detect
            desc=$(jq -r ".probes[$p].description // \"probe-$p\"" "$probes_file")
            content=$(jq -r ".probes[$p].content // \"\"" "$probes_file")
            should_detect=$(jq -r ".probes[$p].shouldDetect // true" "$probes_file")

            cleanup_probe_repo "$probe_dir" 2>/dev/null
            setup_probe_repo "$probe_dir"

            # Write probe content
            local ext
            ext=$(jq -r ".probes[$p].extension // \"js\"" "$probes_file")
            echo "$content" > "$probe_dir/probe_explicit.$ext"
            git -C "$probe_dir" add "probe_explicit.$ext" 2>/dev/null

            cd "$probe_dir"
            local verify_script="$LAWS_DIR/$law_name/verify.sh"
            if [[ -f "$verify_script" ]]; then
                local probe_output
                probe_output=$(HOOK_TYPE=pre-commit bash "$verify_script" 2>/dev/null)
                local probe_has_fail
                probe_has_fail=$(echo "$probe_output" | grep -c '"status":"FAIL"' || true)

                if [[ "$should_detect" == "true" ]]; then
                    if [[ "$probe_has_fail" -gt 0 ]]; then
                        results+=("probe:$desc:PASS:detected")
                        ((probe_pass++))
                    else
                        results+=("probe:$desc:FAIL:missed")
                        ((probe_fail++))
                    fi
                else
                    if [[ "$probe_has_fail" -eq 0 ]]; then
                        results+=("probe:$desc:PASS:clean")
                        ((probe_pass++))
                    else
                        results+=("probe:$desc:FAIL:false-positive")
                        ((probe_fail++))
                    fi
                fi
            fi
        done
    fi

    # Cleanup
    cd "$CHP_BASE"
    rm -rf "$probe_dir" 2>/dev/null

    # Output results
    echo ""
    echo "Probe: $law_name"
    echo "  Passed: $probe_pass  Failed: $probe_fail  Skipped: $probe_skip"
    echo ""
    for result in "${results[@]}"; do
        local status="${result%%:*}"
        local rest="${result#*:}"
        case "$status" in
            PASS) echo "  PASS  $rest" ;;
            FAIL) echo "  FAIL  $rest" ;;
            *)    echo "  SKIP  $rest" ;;
        esac
    done
    echo ""

    if [[ $probe_fail -gt 0 ]]; then
        return 1
    fi
    return 0
}

# Run probes for all enabled laws
probe_all() {
    local total_pass=0
    local total_fail=0
    local total_skip=0
    local -a summary=()

    for law_dir in "$LAWS_DIR"/*; do
        [[ ! -d "$law_dir" ]] && continue
        local name
        name=$(basename "$law_dir")

        local enabled
        enabled=$(jq -r '.enabled // true' "$law_dir/law.json" 2>/dev/null)
        [[ "$enabled" == "false" ]] && continue

        local output
        output=$(probe_law "$name" 2>&1)
        local exit_code=$?
        echo "$output"

        # Count results from output
        local p f s
        p=$(echo "$output" | grep -c "PASS" || true)
        f=$(echo "$output" | grep -c "FAIL" || true)
        s=$(echo "$output" | grep -c "SKIP" || true)
        total_pass=$((total_pass + p))
        total_fail=$((total_fail + f))
        total_skip=$((total_skip + s))

        summary+=("$name:$exit_code")
    done

    echo "================================"
    echo "  Probe Summary"
    echo "================================"
    echo ""
    printf "  %-25s %s\n" "Law" "Status"
    printf "  %-25s %s\n" "---" "------"
    for entry in "${summary[@]}"; do
        local sname="${entry%%:*}"
        local scode="${entry##*:}"
        if [[ "$scode" == "0" ]]; then
            printf "  %-25s %s\n" "$sname" "PASS"
        else
            printf "  %-25s %s\n" "$sname" "FAIL"
        fi
    done
    echo ""
    echo "  Total: $total_pass passed, $total_fail failed, $total_skip skipped"
    echo ""

    [[ $total_fail -gt 0 ]] && return 1
    return 0
}

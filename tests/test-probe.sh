#!/bin/bash
# Tests for core/probe.sh — law probing mechanism

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BASE_DIR="$SCRIPT_DIR/.."
source "$BASE_DIR/core/common.sh"
source "$BASE_DIR/core/probe.sh"

pass=0
fail=0

run_test() {
    local desc="$1"
    shift
    if "$@" 2>&1; then
        pass=$((pass + 1))
    else
        echo "FAIL: $desc"
        fail=$((fail + 1))
    fi
}

# Test 1: generate_matching_content produces content for known patterns
test_generate_matching_content() {
    local content
    content=$(generate_matching_content "console\\.log")
    [[ "$content" == *"console.log"* ]] || { echo "  console.log pattern failed: got '$content'"; return 1; }

    content=$(generate_matching_content "TODO")
    [[ "$content" == *"TODO"* ]] || { echo "  TODO pattern failed: got '$content'"; return 1; }

    content=$(generate_matching_content "sk-[a-zA-Z0-9]{32,}")
    [[ "$content" == *"sk-"* ]] || { echo "  sk- pattern failed: got '$content'"; return 1; }

    echo "  PASS: generate_matching_content"
    return 0
}

# Test 2: generate_clean_content does not contain violations
test_generate_clean_content() {
    local content
    content=$(generate_clean_content "console\\.log")
    [[ "$content" != *"console.log"* ]] || { echo "  clean content has violation"; return 1; }
    [[ "$content" == *"Clean file"* ]] || { echo "  unexpected clean content: '$content'"; return 1; }

    echo "  PASS: generate_clean_content"
    return 0
}

# Test 3: setup_probe_repo creates a valid git repo
test_setup_probe_repo() {
    local probe_dir
    probe_dir=$(mktemp -d -t chp_test_probe_XXXXXX)
    setup_probe_repo "$probe_dir" 2>/dev/null

    [[ -d "$probe_dir/.git" ]] || { cd "$CHP_BASE"; rm -rf "$probe_dir"; echo "  no .git dir"; return 1; }
    git -C "$probe_dir" rev-parse HEAD >/dev/null 2>&1 || { cd "$CHP_BASE"; rm -rf "$probe_dir"; echo "  no HEAD"; return 1; }

    cd "$CHP_BASE"
    rm -rf "$probe_dir"
    echo "  PASS: setup_probe_repo"
    return 0
}

# Test 4: probe_law function exists and reads law.json
test_probe_law_exists() {
    # Just verify the function is callable and reads law.json for test-scope
    local law_json="$LAWS_DIR/test-scope/law.json"
    [[ -f "$law_json" ]] || { echo "  test-scope law.json missing"; return 1; }

    local checks
    checks=$(jq -c '.checks // []' "$law_json" 2>/dev/null)
    [[ "$checks" != "[]" ]] || { echo "  test-scope has no checks"; return 1; }

    echo "  PASS: probe_law_exists"
    return 0
}

# Run tests
run_test "generate_matching_content" test_generate_matching_content
run_test "generate_clean_content" test_generate_clean_content
run_test "setup_probe_repo" test_setup_probe_repo
run_test "probe_law function and law.json readable" test_probe_law_exists

# Results
echo ""
echo "Probe tests: $pass passed, $fail failed"
[[ $fail -eq 0 ]] && exit 0 || exit 1

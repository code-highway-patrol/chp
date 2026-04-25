#!/bin/bash
# Tests for commands/chp-doctor — framework health check

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BASE_DIR="$SCRIPT_DIR/.."
source "$BASE_DIR/core/common.sh"

pass=0
fail=0

run_test() {
    local desc="$1"
    shift
    if "$@" >/dev/null 2>&1; then
        pass=$((pass + 1))
    else
        echo "FAIL: $desc"
        fail=$((fail + 1))
    fi
}

# Test 1: Doctor runs and produces output
test_doctor_runs() {
    local output
    output=$(bash "$BASE_DIR/commands/chp-doctor" 2>&1)
    # Should produce output (may have issues, but shouldn't crash)
    echo "$output" | grep -q "CHP Doctor" || return 1
    echo "$output" | grep -q "Results:" || return 1
    return 0
}

# Test 2: Doctor detects missing guidance.md
test_doctor_missing_guidance() {
    local tmp_law="$LAWS_DIR/doctor-test-law"
    mkdir -p "$tmp_law"

    # Create minimal law.json
    echo '{"id":"doctor-test-law","name":"doctor-test-law","intent":"test","hooks":["pre-commit"],"enabled":true}' > "$tmp_law/law.json"
    echo '#!/bin/bash' > "$tmp_law/verify.sh"
    # No guidance.md

    local output
    output=$(bash "$BASE_DIR/commands/chp-doctor" 2>&1)
    local exit_code=$?

    # Cleanup
    rm -rf "$tmp_law"

    # Should report the missing file
    echo "$output" | grep -qi "missing" || return 1
    return 0
}

# Test 3: Doctor detects invalid JSON
test_doctor_invalid_json() {
    local tmp_law="$LAWS_DIR/doctor-test-invalid"
    mkdir -p "$tmp_law"

    echo '{invalid json' > "$tmp_law/law.json"
    echo '#!/bin/bash' > "$tmp_law/verify.sh"
    echo "# Guidance" > "$tmp_law/guidance.md"

    local output
    output=$(bash "$BASE_DIR/commands/chp-doctor" 2>&1)

    # Cleanup
    rm -rf "$tmp_law"

    # Should report invalid JSON
    echo "$output" | grep -qi "invalid JSON" || return 1
    return 0
}

# Test 4: Doctor detects non-executable verify.sh (Unix only)
test_doctor_non_executable() {
    # Skip on Windows where chmod doesn't affect executability
    if [[ "$(uname -s)" == MINGW* || "$(uname -s)" == MSYS* || "$(uname -s)" == CYGWIN* ]]; then
        echo "  SKIP: non-executable test (Windows)"
        return 0
    fi

    local tmp_law="$LAWS_DIR/doctor-test-noexec"
    mkdir -p "$tmp_law"

    echo '{"id":"doctor-test-noexec","intent":"test","hooks":["pre-commit"],"enabled":true}' > "$tmp_law/law.json"
    echo '#!/bin/bash' > "$tmp_law/verify.sh"
    chmod -x "$tmp_law/verify.sh"
    echo "# Guidance" > "$tmp_law/guidance.md"

    local output
    output=$(bash "$BASE_DIR/commands/chp-doctor" 2>&1)

    # Cleanup
    rm -rf "$tmp_law"

    # Should report non-executable for our test law
    echo "$output" | grep -qi "doctor-test-noexec.*not executable" || return 1
    return 0
}

# Run tests
run_test "doctor runs and produces output" test_doctor_runs
run_test "doctor detects missing guidance.md" test_doctor_missing_guidance
run_test "doctor detects invalid JSON" test_doctor_invalid_json
run_test "doctor detects non-executable verify.sh" test_doctor_non_executable

# Results
echo ""
echo "Doctor tests: $pass passed, $fail failed"
[[ $fail -eq 0 ]] && exit 0 || exit 1

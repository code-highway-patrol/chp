# Law Mutation Layer Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Create a single mutation layer (`core/law-mutate.sh`) that atomically updates all three law files (law.json, verify.sh, guidance.md), and refactor all existing write paths to use it.

**Architecture:** A sourced Bash script providing mutation functions. Every existing write path in `core/tightener.sh`, `commands/chp-law`, and `core/dispatcher.sh` delegates to these functions instead of writing directly. A consistency validator runs at dispatch time to catch drift.

**Tech Stack:** Bash, jq

---

### Task 1: Create `core/law-mutate.sh` with validation and field mutation

**Files:**
- Create: `core/law-mutate.sh`

- [ ] **Step 1: Write `core/law-mutate.sh` with guard, sources, and `validate_consistency`**

```bash
#!/bin/bash
# Atomic law mutation — all three files updated together

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    echo "Error: This file should be sourced, not executed directly." >&2
    exit 1
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/common.sh"
source "$SCRIPT_DIR/law-builder.sh"

# Validate that all three law files exist and agree
# Usage: validate_consistency <law_name>
# Returns: 0 if consistent, 1 if drifted
validate_consistency() {
    local law_name="$1"

    if [[ -z "$law_name" ]]; then
        log_error "Law name is required"
        return 1
    fi

    read -r law_dir law_json guidance_md < <(get_law_paths "$law_name")

    # All three files must exist
    if [[ ! -f "$law_json" ]]; then
        log_error "law.json missing for: $law_name"
        return 1
    fi
    if [[ ! -f "$guidance_md" ]]; then
        log_error "guidance.md missing for: $law_name"
        return 1
    fi
    if [[ ! -f "$law_dir/verify.sh" ]]; then
        log_error "verify.sh missing for: $law_name"
        return 1
    fi

    local drifted=false

    # law.json name must match directory name
    local json_name
    json_name=$(jq -r '.name // empty' "$law_json" 2>/dev/null)
    if [[ "$json_name" != "$law_name" ]]; then
        log_error "law.json name '$json_name' != directory name '$law_name'"
        drifted=true
    fi

    # severity must match guidance.md header
    local json_severity
    json_severity=$(jq -r '.severity // empty' "$law_json" 2>/dev/null)
    local guidance_severity
    guidance_severity=$(grep -oP '\*\*Severity:\*\*\s*\K\w+' "$guidance_md" 2>/dev/null | head -1)
    if [[ -n "$json_severity" && -n "$guidance_severity" && "$json_severity" != "$guidance_severity" ]]; then
        log_error "Severity mismatch: law.json='$json_severity' guidance.md='$guidance_severity'"
        drifted=true
    fi

    # failures must match guidance.md header
    local json_failures
    json_failures=$(jq -r '.failures // 0' "$law_json" 2>/dev/null)
    local guidance_failures
    guidance_failures=$(grep -oP '\*\*Failures:\*\*\s*\K\d+' "$guidance_md" 2>/dev/null | head -1)
    if [[ -n "$guidance_failures" && "$json_failures" != "$guidance_failures" ]]; then
        log_error "Failures mismatch: law.json='$json_failures' guidance.md='$guidance_failures'"
        drifted=true
    fi

    # verify.sh must exist and reference check-runner (if law has checks)
    local check_count
    check_count=$(jq '.checks // [] | length' "$law_json" 2>/dev/null)
    if [[ "$check_count" -gt 0 ]]; then
        if ! grep -q 'check-runner\|run_checks' "$law_dir/verify.sh" 2>/dev/null; then
            log_error "verify.sh missing check-runner reference but law has $check_count checks"
            drifted=true
        fi
    fi

    if $drifted; then
        return 1
    fi

    return 0
}
```

- [ ] **Step 2: Add `_sync_guidance_header` helper to `core/law-mutate.sh`**

Append to `core/law-mutate.sh`:

```bash
# Update a single header field in guidance.md
# Usage: _sync_guidance_header <guidance_md> <field> <value>
_sync_guidance_header() {
    local guidance_md="$1"
    local field="$2"
    local value="$3"

    if [[ ! -f "$guidance_md" ]]; then
        return 1
    fi

    # Replace **Field:** <old> with **Field:** <new>
    # Use a temp file for atomic write
    sed "s/^\*\*${field}:\*\* .*/*${field}:* ${value}/" "$guidance_md" > "${guidance_md}.tmp"
    mv "${guidance_md}.tmp" "$guidance_md"
}

# Append a changelog entry to guidance.md
# Usage: _append_guidance_entry <guidance_md> <entry_text>
_append_guidance_entry() {
    local guidance_md="$1"
    local entry_text="$2"
    local timestamp
    timestamp=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

    cat >> "$guidance_md" <<EOF

---

**${entry_text}:** $timestamp
EOF
}
```

- [ ] **Step 3: Add `mutate_field` to `core/law-mutate.sh`**

Append to `core/law-mutate.sh`:

```bash
# Atomically update a single field in law.json + sync guidance.md
# Usage: mutate_field <law_name> <field> <value>
mutate_field() {
    local law_name="$1"
    local field="$2"
    local value="$3"

    if [[ -z "$law_name" ]]; then
        log_error "Law name is required"
        return 1
    fi

    if ! law_exists "$law_name"; then
        log_error "Law does not exist: $law_name"
        return 1
    fi

    read -r law_dir law_json guidance_md < <(get_law_paths "$law_name")

    if [[ ! -f "$law_json" ]]; then
        log_error "law.json not found for: $law_name"
        return 1
    fi

    # Write to law.json atomically
    jq --arg val "$value" ".$field = \$val" "$law_json" > "${law_json}.tmp" && \
    mv "${law_json}.tmp" "$law_json"

    # Sync guidance.md header for fields that appear there
    case "$field" in
        severity)
            _sync_guidance_header "$guidance_md" "Severity" "$value"
            _append_guidance_entry "$guidance_md" "Configuration changed"
            ;;
        failures)
            _sync_guidance_header "$guidance_md" "Failures" "$value"
            ;;
    esac

    # Regenerate verify.sh if hooks change
    if [[ "$field" == "hooks" ]]; then
        local hooks_str
        hooks_str=$(jq -r '.hooks | join(",")' "$law_json" 2>/dev/null)
        build_verify_with_checks "$law_name" > "$law_dir/verify.sh"
        chmod +x "$law_dir/verify.sh"
        _append_guidance_entry "$guidance_md" "Hooks updated to $hooks_str"
    fi

    return 0
}
```

- [ ] **Step 4: Add `mutate_status`, `mutate_failure`, `mutate_reset` to `core/law-mutate.sh`**

Append to `core/law-mutate.sh`:

```bash
# Atomically enable or disable a law
# Usage: mutate_status <law_name> <enabled|disabled>
mutate_status() {
    local law_name="$1"
    local status="$2"

    if [[ -z "$law_name" ]]; then
        log_error "Law name is required"
        return 1
    fi

    if ! law_exists "$law_name"; then
        log_error "Law does not exist: $law_name"
        return 1
    fi

    read -r law_dir law_json guidance_md < <(get_law_paths "$law_name")

    local bool_val="true"
    if [[ "$status" == "disabled" ]]; then
        bool_val="false"
    fi

    jq --argjson enabled "$bool_val" '.enabled = $enabled' "$law_json" > "${law_json}.tmp" && \
    mv "${law_json}.tmp" "$law_json"

    _append_guidance_entry "$guidance_md" "Law $status"

    log_info "Law '$law_name' $status"
    return 0
}

# Atomically record a failure across all three files
# Usage: mutate_failure <law_name> [check_id]
mutate_failure() {
    local law_name="$1"
    local check_id="${2:-}"

    if [[ -z "$law_name" ]]; then
        log_error "Law name is required"
        return 1
    fi

    if ! law_exists "$law_name"; then
        log_error "Law does not exist: $law_name"
        return 1
    fi

    read -r law_dir law_json guidance_md < <(get_law_paths "$law_name")

    local failures
    failures=$(get_law_meta "$law_name" "failures")
    failures=$((failures + 1))

    local tightening_level
    tightening_level=$(get_law_meta "$law_name" "tightening_level")
    tightening_level=$((tightening_level + 1))

    jq --arg failures "$failures" \
       --arg tightening_level "$tightening_level" \
       '.failures = ($failures | tonumber) |
        .tightening_level = ($tightening_level | tonumber)' \
       "$law_json" > "${law_json}.tmp" && \
    mv "${law_json}.tmp" "$law_json"

    # Sync failures count in guidance header
    _sync_guidance_header "$guidance_md" "Failures" "$failures"

    # Append violation entry
    local timestamp
    timestamp=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
    local check_label=""
    if [[ -n "$check_id" ]]; then
        check_label=" (check: $check_id)"
    fi

    cat >> "$guidance_md" <<EOF

---

**Violation recorded:** $timestamp (Total: $failures)${check_label}

This law has been violated $failures time(s). The guidance has been automatically strengthened.

**Previous violations indicate this pattern is easy to miss. Pay extra attention.**
EOF

    if [[ -n "$check_id" ]]; then
        log_warn "Law '$law_name' check '$check_id' failed (failure #$failures, tightening level $tightening_level)"
    else
        log_warn "Law '$law_name' failed (failure #$failures, tightening level $tightening_level)"
    fi

    return 0
}

# Atomically reset failure state across all three files
# Usage: mutate_reset <law_name>
mutate_reset() {
    local law_name="$1"

    if [[ -z "$law_name" ]]; then
        log_error "Law name is required"
        return 1
    fi

    if ! law_exists "$law_name"; then
        log_error "Law does not exist: $law_name"
        return 1
    fi

    read -r law_dir law_json guidance_md < <(get_law_paths "$law_name")

    jq '.failures = 0 | .tightening_level = 0' \
       "$law_json" > "${law_json}.tmp" && \
    mv "${law_json}.tmp" "$law_json"

    # Sync failures header
    _sync_guidance_header "$guidance_md" "Failures" "0"

    # Truncate violation history (everything after first --- separator)
    if grep -q "^---" "$guidance_md"; then
        sed -n '1,/^---$/p' "$guidance_md" > "$guidance_md.tmp"
        mv "$guidance_md.tmp" "$guidance_md"
    fi

    log_info "Law '$law_name' reset (failures and tightening level cleared)"
    return 0
}
```

- [ ] **Step 5: Add `mutate_checks` to `core/law-mutate.sh`**

Append to `core/law-mutate.sh`:

```bash
# Atomically modify the checks array + regenerate verify.sh + update guidance.md
# Usage: mutate_checks <law_name> <action> <check_json>
# Actions: add, remove, update
# check_json: JSON object for add/update, check ID string for remove
mutate_checks() {
    local law_name="$1"
    local action="$2"
    local check_data="$3"

    if [[ -z "$law_name" ]]; then
        log_error "Law name is required"
        return 1
    fi

    if ! law_exists "$law_name"; then
        log_error "Law does not exist: $law_name"
        return 1
    fi

    read -r law_dir law_json guidance_md < <(get_law_paths "$law_name")

    case "$action" in
        add)
            jq --argjson check "$check_data" '.checks += [$check]' \
               "$law_json" > "${law_json}.tmp" && \
            mv "${law_json}.tmp" "$law_json"

            local check_id
            check_id=$(echo "$check_data" | jq -r '.id // "unknown"')
            local check_type
            check_type=$(echo "$check_data" | jq -r '.type // "unknown"')
            local check_sev
            check_sev=$(echo "$check_data" | jq -r '.severity // "warn"')
            _append_guidance_entry "$guidance_md" "Check added: $check_id ($check_type, $check_sev)"
            ;;
        remove)
            jq --arg cid "$check_data" '.checks |= map(select(.id != $cid))' \
               "$law_json" > "${law_json}.tmp" && \
            mv "${law_json}.tmp" "$law_json"

            _append_guidance_entry "$guidance_md" "Check removed: $check_data"
            ;;
        update)
            local check_id
            check_id=$(echo "$check_data" | jq -r '.id // empty')
            if [[ -z "$check_id" ]]; then
                log_error "update action requires check JSON with 'id' field"
                return 1
            fi
            jq --argjson check "$check_data" --arg cid "$check_id" \
               '(.checks[] | select(.id == $cid)) = $check' \
               "$law_json" > "${law_json}.tmp" && \
            mv "${law_json}.tmp" "$law_json"

            _append_guidance_entry "$guidance_md" "Check updated: $check_id"
            ;;
        *)
            log_error "Unknown mutate_checks action: $action (use add, remove, or update)"
            return 1
            ;;
    esac

    # Regenerate verify.sh
    build_verify_with_checks "$law_name" > "$law_dir/verify.sh"
    chmod +x "$law_dir/verify.sh"

    log_info "Checks updated for law: $law_name (action: $action)"
    return 0
}
```

- [ ] **Step 6: Commit the new script**

```bash
git add core/law-mutate.sh
git commit -m "feat: add core/law-mutate.sh atomic law mutation layer"
```

---

### Task 2: Write tests for `core/law-mutate.sh`

**Files:**
- Create: `tests/test-law-mutate.sh`

- [ ] **Step 1: Write the test file**

```bash
#!/bin/bash
# Test law-mutate.sh functions

set -e

source "$(dirname "$0")/../core/common.sh"
source "$(dirname "$0")/../core/law-builder.sh"
source "$(dirname "$0")/../core/law-mutate.sh"

echo "Testing law-mutate.sh functions..."

# Setup: Create a test law with all three files
TEST_LAW_DIR="$LAWS_DIR/test-mutate-law"
mkdir -p "$TEST_LAW_DIR"

cat > "$TEST_LAW_DIR/law.json" << 'EOF'
{
  "name": "test-mutate-law",
  "created": "2026-04-25T00:00:00Z",
  "severity": "error",
  "failures": 0,
  "tightening_level": 0,
  "hooks": ["pre-commit"],
  "enabled": true,
  "checks": [
    {
      "id": "test-check",
      "type": "pattern",
      "config": { "pattern": "TODO" },
      "severity": "block",
      "message": "No TODOs"
    }
  ]
}
EOF

cat > "$TEST_LAW_DIR/verify.sh" << 'EOF'
#!/bin/bash
LAW_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CHP_BASE="$(cd "$LAW_DIR/../../../../" && pwd)"
source "$CHP_BASE/core/common.sh"
source "$CHP_BASE/core/check-runner.sh"
run_checks "test-mutate-law" "${1:-pre-commit}"
exit $?
EOF
chmod +x "$TEST_LAW_DIR/verify.sh"

cat > "$TEST_LAW_DIR/guidance.md" << 'EOF'
# Law: test-mutate-law

**Severity:** error
**Created:** 2026-04-25T00:00:00Z
**Failures:** 0

## Purpose
Test law for mutation testing.
EOF

# --- mutate_field tests ---

# Test 1: mutate_field updates law.json severity
echo "Test 1: mutate_field updates severity in law.json"
mutate_field "test-mutate-law" "severity" "warn"
severity=$(get_law_meta "test-mutate-law" "severity")
if [[ "$severity" == "warn" ]]; then
    echo "  ✓ severity updated to warn in law.json"
else
    echo "  ✗ Expected severity=warn, got $severity"
    exit 1
fi

# Test 2: mutate_field syncs severity to guidance.md
echo "Test 2: mutate_field syncs severity to guidance.md"
guidance_severity=$(grep -oP '\*\*Severity:\*\*\s*\K\w+' "$TEST_LAW_DIR/guidance.md" | head -1)
if [[ "$guidance_severity" == "warn" ]]; then
    echo "  ✓ severity synced to guidance.md"
else
    echo "  ✗ Expected guidance severity=warn, got $guidance_severity"
    exit 1
fi

# Test 3: mutate_field fails for non-existent law
echo "Test 3: mutate_field fails for non-existent law"
if ! mutate_field "no-such-law" "severity" "error" 2>/dev/null; then
    echo "  ✓ Non-existent law rejected"
else
    echo "  ✗ Should have failed for non-existent law"
    exit 1
fi

# Reset severity for remaining tests
mutate_field "test-mutate-law" "severity" "error"

# --- mutate_status tests ---

# Test 4: mutate_status disables law
echo "Test 4: mutate_status disables law"
mutate_status "test-mutate-law" "disabled"
enabled=$(get_law_meta "test-mutate-law" "enabled")
if [[ "$enabled" == "false" ]]; then
    echo "  ✓ law.json enabled=false"
else
    echo "  ✗ Expected enabled=false, got $enabled"
    exit 1
fi

# Test 5: mutate_status enables law
echo "Test 5: mutate_status enables law"
mutate_status "test-mutate-law" "enabled"
enabled=$(get_law_meta "test-mutate-law" "enabled")
if [[ "$enabled" == "true" ]]; then
    echo "  ✓ law.json enabled=true"
else
    echo "  ✗ Expected enabled=true, got $enabled"
    exit 1
fi

# --- mutate_failure tests ---

# Test 6: mutate_failure increments failures
echo "Test 6: mutate_failure increments failures"
mutate_failure "test-mutate-law"
failures=$(get_law_meta "test-mutate-law" "failures")
if [[ "$failures" == "1" ]]; then
    echo "  ✓ failures=1 in law.json"
else
    echo "  ✗ Expected failures=1, got $failures"
    exit 1
fi

# Test 7: mutate_failure syncs failures to guidance.md
echo "Test 7: mutate_failure syncs failures to guidance.md"
guidance_failures=$(grep -oP '\*\*Failures:\*\*\s*\K\d+' "$TEST_LAW_DIR/guidance.md" | head -1)
if [[ "$guidance_failures" == "1" ]]; then
    echo "  ✓ failures synced to guidance.md"
else
    echo "  ✗ Expected guidance failures=1, got $guidance_failures"
    exit 1
fi

# Test 8: mutate_failure appends violation to guidance.md
echo "Test 8: mutate_failure appends violation entry"
if grep -q "Violation recorded" "$TEST_LAW_DIR/guidance.md"; then
    echo "  ✓ violation entry present in guidance.md"
else
    echo "  ✗ No violation entry found in guidance.md"
    exit 1
fi

# --- mutate_reset tests ---

# Test 9: mutate_reset clears failures
echo "Test 9: mutate_reset clears failures"
mutate_failure "test-mutate-law"
mutate_failure "test-mutate-law"
mutate_reset "test-mutate-law"
failures=$(get_law_meta "test-mutate-law" "failures")
tightening=$(get_law_meta "test-mutate-law" "tightening_level")
if [[ "$failures" == "0" && "$tightening" == "0" ]]; then
    echo "  ✓ failures and tightening_level reset to 0"
else
    echo "  ✗ Expected failures=0 tightening=0, got failures=$failures tightening=$tightening"
    exit 1
fi

# Test 10: mutate_reset syncs failures to guidance.md
echo "Test 10: mutate_reset syncs failures to guidance.md"
guidance_failures=$(grep -oP '\*\*Failures:\*\*\s*\K\d+' "$TEST_LAW_DIR/guidance.md" | head -1)
if [[ "$guidance_failures" == "0" ]]; then
    echo "  ✓ failures reset in guidance.md header"
else
    echo "  ✗ Expected guidance failures=0, got $guidance_failures"
    exit 1
fi

# --- mutate_checks tests ---

# Test 11: mutate_checks add
echo "Test 11: mutate_checks adds a check"
new_check='{"id":"new-check","type":"pattern","config":{"pattern":"FIXME"},"severity":"warn","message":"No FIXMEs"}'
mutate_checks "test-mutate-law" "add" "$new_check"
check_count=$(jq '.checks | length' "$TEST_LAW_DIR/law.json")
if [[ "$check_count" == "2" ]]; then
    echo "  ✓ check added (count=$check_count)"
else
    echo "  ✗ Expected 2 checks, got $check_count"
    exit 1
fi

# Test 12: mutate_checks regenerates verify.sh
echo "Test 12: mutate_checks regenerates verify.sh"
if grep -q "run_checks" "$TEST_LAW_DIR/verify.sh"; then
    echo "  ✓ verify.sh contains run_checks"
else
    echo "  ✗ verify.sh missing run_checks"
    exit 1
fi

# Test 13: mutate_checks remove
echo "Test 13: mutate_checks removes a check"
mutate_checks "test-mutate-law" "remove" "new-check"
check_count=$(jq '.checks | length' "$TEST_LAW_DIR/law.json")
if [[ "$check_count" == "1" ]]; then
    echo "  ✓ check removed (count=$check_count)"
else
    echo "  ✗ Expected 1 check, got $check_count"
    exit 1
fi

# --- validate_consistency tests ---

# Test 14: validate_consistency passes for consistent law
echo "Test 14: validate_consistency passes for consistent law"
if validate_consistency "test-mutate-law"; then
    echo "  ✓ consistent law passes validation"
else
    echo "  ✗ Valid law should pass validation"
    exit 1
fi

# Test 15: validate_consistency detects severity drift
echo "Test 15: validate_consistency detects severity drift"
# Manually break law.json to create drift
jq '.severity = "info"' "$TEST_LAW_DIR/law.json" > "${TEST_LAW_DIR}/law.json.tmp" && \
mv "${TEST_LAW_DIR}/law.json.tmp" "$TEST_LAW_DIR/law.json"
if ! validate_consistency "test-mutate-law" 2>/dev/null; then
    echo "  ✓ drift detected correctly"
else
    echo "  ✗ Should have detected severity drift"
    exit 1
fi
# Fix the drift
mutate_field "test-mutate-law" "severity" "error"

# Cleanup
rm -rf "$TEST_LAW_DIR"

echo ""
echo "All tests passed!"
```

- [ ] **Step 2: Run the tests**

```bash
bash tests/test-law-mutate.sh
```

Expected: all 15 tests pass.

- [ ] **Step 3: Commit**

```bash
git add tests/test-law-mutate.sh
git commit -m "test: add law-mutate.sh test suite"
```

---

### Task 3: Refactor `core/tightener.sh` to delegate to `law-mutate.sh`

**Files:**
- Modify: `core/tightener.sh` (entire file)

This replaces the direct `jq` writes in `record_failure` and `reset_failures` with calls to `mutate_failure` and `mutate_reset`.

- [ ] **Step 1: Rewrite `core/tightener.sh`**

The existing file sources `common.sh` and `logger.sh`, then defines `record_failure` and `reset_failures` with inline `jq` writes. Replace the entire file body with delegation to `law-mutate.sh`:

```bash
#!/bin/bash
# Tightening logic for law violations — delegates to law-mutate.sh

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    echo "Error: This file should be sourced, not executed directly." >&2
    echo "Usage: source core/tightener.sh" >&2
    exit 1
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/common.sh"
source "$SCRIPT_DIR/logger.sh"
source "$SCRIPT_DIR/law-mutate.sh"

record_failure() {
    local law_name="$1"
    local check_id="${2:-}"

    if [[ -z "$law_name" ]]; then
        log_error "Law name is required"
        return 1
    fi

    if ! law_exists "$law_name"; then
        log_error "Law does not exist: $law_name"
        return 1
    fi

    mutate_failure "$law_name" "$check_id"

    logger_init
    logger_violation "$law_name" "tightening" "failed" "violation-trend" "address the pattern causing repeated violations"

    return 0
}

reset_failures() {
    local law_name="$1"

    if [[ -z "$law_name" ]]; then
        log_error "Law name is required"
        return 1
    fi

    if ! law_exists "$law_name"; then
        log_error "Law does not exist: $law_name"
        return 1
    fi

    mutate_reset "$law_name"

    return 0
}

if [ "${BASH_SOURCE[0]}" = "$0" ]; then
    record_failure "$1"
fi
```

- [ ] **Step 2: Run existing tightener tests to verify no regression**

```bash
bash tests/test-tightener.sh
```

Expected: all tests pass (behavior unchanged, just delegation).

- [ ] **Step 3: Commit**

```bash
git add core/tightener.sh
git commit -m "refactor: tightener delegates to law-mutate.sh for atomic writes"
```

---

### Task 4: Refactor `commands/chp-law` update/disable/enable to use `law-mutate.sh`

**Files:**
- Modify: `commands/chp-law` — add source for `law-mutate.sh`, replace inline jq in `update_law`, `disable_law`, `enable_law`

- [ ] **Step 1: Add `law-mutate.sh` source to `commands/chp-law`**

In `commands/chp-law`, after the existing source lines (around line 10), add:

```bash
source "$SCRIPT_DIR/../core/law-mutate.sh"
```

The source block should read:

```bash
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../core/common.sh"
source "$SCRIPT_DIR/../core/detector.sh"
source "$SCRIPT_DIR/../core/installer.sh"
source "$SCRIPT_DIR/../core/tightener.sh"
source "$SCRIPT_DIR/../core/law-mutate.sh"

# Source interactive and builder modules
source "$SCRIPT_DIR/../core/interactive.sh"
source "$SCRIPT_DIR/../core/law-builder.sh"
source "$SCRIPT_DIR/../core/probe.sh"
```

- [ ] **Step 2: Replace `disable_law` body**

Replace the `disable_law` function (lines 610-642) with:

```bash
disable_law() {
    local law_name="$1"

    if [[ -z "$law_name" ]]; then
        log_error "Law name is required"
        return 1
    fi

    if ! law_exists "$law_name"; then
        log_error "Law does not exist: $law_name"
        return 1
    fi

    local enabled
    enabled=$(get_law_meta "$law_name" "enabled")

    if [[ "$enabled" == "false" ]]; then
        log_info "Law already disabled: $law_name"
        return 0
    fi

    mutate_status "$law_name" "disabled"

    return 0
}
```

- [ ] **Step 3: Replace `enable_law` body**

Replace the `enable_law` function (lines 645-677) with:

```bash
enable_law() {
    local law_name="$1"

    if [[ -z "$law_name" ]]; then
        log_error "Law name is required"
        return 1
    fi

    if ! law_exists "$law_name"; then
        log_error "Law does not exist: $law_name"
        return 1
    fi

    local enabled
    enabled=$(get_law_meta "$law_name" "enabled")

    if [[ "$enabled" == "true" ]]; then
        log_info "Law already enabled: $law_name"
        return 0
    fi

    mutate_status "$law_name" "enabled"

    return 0
}
```

- [ ] **Step 4: Replace inline `jq` writes in `update_law`**

In the `update_law` function, replace the severity update block (around lines 753-758):

Old:
```bash
    if [[ -n "$new_severity" ]]; then
        jq ".severity = \"$new_severity\"" "$law_json" > "${law_json}.tmp" && \
            mv "${law_json}.tmp" "$law_json"
        log_info "Updated severity to: $new_severity"
        updated=true
    fi
```

New:
```bash
    if [[ -n "$new_severity" ]]; then
        mutate_field "$law_name" "severity" "$new_severity"
        log_info "Updated severity to: $new_severity"
        updated=true
    fi
```

Replace the hooks update block (around lines 760-766):

Old:
```bash
    if [[ -n "$new_hooks" ]]; then
        local hooks_array=$(echo "$new_hooks" | jq -R . | jq -s -c .)
        jq ".hooks = $hooks_array" "$law_json" > "${law_json}.tmp" && \
            mv "${law_json}.tmp" "$law_json"
        log_info "Updated hooks to: $new_hooks"
        updated=true
    fi
```

New:
```bash
    if [[ -n "$new_hooks" ]]; then
        local hooks_array
        hooks_array=$(echo "$new_hooks" | jq -R . | jq -s -c .)
        echo "$hooks_array" | jq -r '.[]' | while read -r h; do
            echo "$h"
        done
        hooks_csv=$(echo "$hooks_array" | jq -r 'join(",")')
        jq --argjson ha "$hooks_array" '.hooks = $ha' "$law_json" > "${law_json}.tmp" && \
            mv "${law_json}.tmp" "$law_json"
        build_verify_with_checks "$law_name" > "$law_dir/verify.sh"
        chmod +x "$law_dir/verify.sh"
        log_info "Updated hooks to: $new_hooks"
        updated=true
    fi
```

Replace the add-hook block (around lines 768-773):

Old:
```bash
    if [[ -n "$add_hook" ]]; then
        jq ".hooks += [\"$add_hook\"]" "$law_json" > "${law_json}.tmp" && \
            mv "${law_json}.tmp" "$law_json"
        log_info "Added hook: $add_hook"
        updated=true
    fi
```

New:
```bash
    if [[ -n "$add_hook" ]]; then
        jq --arg h "$add_hook" '.hooks += [$h]' "$law_json" > "${law_json}.tmp" && \
            mv "${law_json}.tmp" "$law_json"
        build_verify_with_checks "$law_name" > "$law_dir/verify.sh"
        chmod +x "$law_dir/verify.sh"
        _append_guidance_entry "$law_dir/guidance.md" "Hook added: $add_hook"
        log_info "Added hook: $add_hook"
        updated=true
    fi
```

Replace the remove-hook block (around lines 775-780):

Old:
```bash
    if [[ -n "$remove_hook" ]]; then
        jq ".hooks -= [\"$remove_hook\"]" "$law_json" > "${law_json}.tmp" && \
            mv "${law_json}.tmp" "$law_json"
        log_info "Removed hook: $remove_hook"
        updated=true
    fi
```

New:
```bash
    if [[ -n "$remove_hook" ]]; then
        jq --arg h "$remove_hook" '.hooks -= [$h]' "$law_json" > "${law_json}.tmp" && \
            mv "${law_json}.tmp" "$law_json"
        build_verify_with_checks "$law_name" > "$law_dir/verify.sh"
        chmod +x "$law_dir/verify.sh"
        _append_guidance_entry "$law_dir/guidance.md" "Hook removed: $remove_hook"
        log_info "Removed hook: $remove_hook"
        updated=true
    fi
```

Replace the add-check block (around lines 799-806):

Old:
```bash
    if [[ -n "$new_check_json" ]]; then
        jq --argjson check "$new_check_json" '.checks += [$check]' "$law_json" > "${law_json}.tmp" && \
            mv "${law_json}.tmp" "$law_json"
        build_verify_with_checks "$law_name" > "$law_dir/verify.sh"
        chmod +x "$law_dir/verify.sh"
        log_info "Added check to law: $law_name"
        updated=true
    fi
```

New:
```bash
    if [[ -n "$new_check_json" ]]; then
        mutate_checks "$law_name" "add" "$new_check_json"
        log_info "Added check to law: $law_name"
        updated=true
    fi
```

Replace the check-severity block (around lines 808-815):

Old:
```bash
    if [[ -n "$target_check" && -n "$target_check_severity" ]]; then
        jq --arg cid "$target_check" --arg sev "$target_check_severity" \
            '(.checks[] | select(.id == $cid)).severity = $sev' \
            "$law_json" > "${law_json}.tmp" && \
            mv "${law_json}.tmp" "$law_json"
        log_info "Updated check '$target_check' severity to: $target_check_severity"
        updated=true
    fi
```

New:
```bash
    if [[ -n "$target_check" && -n "$target_check_severity" ]]; then
        local updated_check
        updated_check=$(jq --arg cid "$target_check" '.checks[] | select(.id == $cid)' "$law_json")
        if [[ -n "$updated_check" ]]; then
            updated_check=$(echo "$updated_check" | jq --arg sev "$target_check_severity" '.severity = $sev')
            mutate_checks "$law_name" "update" "$updated_check"
            log_info "Updated check '$target_check' severity to: $target_check_severity"
        fi
        updated=true
    fi
```

- [ ] **Step 5: Run the law-mutate tests and tightener tests together**

```bash
bash tests/test-law-mutate.sh && bash tests/test-tightener.sh
```

Expected: all tests pass.

- [ ] **Step 6: Commit**

```bash
git add commands/chp-law
git commit -m "refactor: chp-law delegates to law-mutate.sh for atomic updates"
```

---

### Task 5: Add consistency validation to dispatcher

**Files:**
- Modify: `core/dispatcher.sh` — add `validate_consistency` call before law enforcement

- [ ] **Step 1: Source `law-mutate.sh` in `dispatcher.sh`**

In `core/dispatcher.sh`, after the existing source lines (around line 8), add:

```bash
source "$SCRIPT_DIR/law-mutate.sh"
```

The source block should read:

```bash
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/common.sh"
source "$SCRIPT_DIR/hook-registry.sh"
source "$SCRIPT_DIR/verifier.sh"
source "$SCRIPT_DIR/check-runner.sh"
source "$SCRIPT_DIR/law-mutate.sh"
```

- [ ] **Step 2: Add consistency check in `dispatch_hook` before running verify**

In the `dispatch_hook` function, after the enabled check (around line 139) and before the scope check, add a consistency validation:

```bash
        # Validate law file consistency
        if ! validate_consistency "$law_name" 2>/dev/null; then
            log_warn "Law '$law_name' has inconsistent files — guidance may be stale"
        fi
```

This goes between the enabled check and the `check_law_scope` call.

- [ ] **Step 3: Run dispatcher tests**

```bash
bash tests/test-dispatcher.sh
```

Expected: all existing tests pass (validation is non-blocking, just a warning).

- [ ] **Step 4: Commit**

```bash
git add core/dispatcher.sh
git commit -m "feat: dispatcher warns on law file drift"
```

---

### Task 6: Final integration test

**Files:**
- Test only (no new files)

- [ ] **Step 1: Run the full test suite**

```bash
bash tests/test-law-mutate.sh && bash tests/test-tightener.sh && bash tests/test-dispatcher.sh
```

Expected: all tests pass.

- [ ] **Step 2: Verify existing laws are still consistent**

```bash
for law in docs/chp/laws/*/; do
    name=$(basename "$law")
    source core/common.sh
    source core/law-mutate.sh
    validate_consistency "$name"
done
```

Expected: all existing laws pass validation (or report expected drift in guidance.md).

- [ ] **Step 3: Commit any remaining changes**

```bash
git add -A
git commit -m "chore: sync law files for consistency with new mutation layer"
```

# CHP Logging System Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build a shell-based logging system that records all CHP events (violations, evaluations, hook triggers, law changes) to a JSONL file at `.chp/logs.jsonl`.

**Architecture:** Single-file JSONL logging with a reusable `logger.sh` module that other scripts source and call. Log entries are JSON objects with timestamp, event_type, and relevant context fields.

**Tech Stack:** Bash shell scripts, JSONL format, file system operations

---

## Task 1: Create the logger.sh module

**Files:**
- Create: `core/logger.sh`

- [ ] **Step 1: Create the logger.sh file with all logging functions**

```bash
#!/bin/bash
# core/logger.sh - CHP Logging System

CHP_LOG_DIR=".chp"
CHP_LOG_FILE="$CHP_LOG_DIR/logs.jsonl"

# Initialize log directory and file
logger_init() {
    mkdir -p "$CHP_LOG_DIR" 2>/dev/null
    touch "$CHP_LOG_FILE" 2>/dev/null
}

# Escape special characters for JSON
# Args: string_to_escape
# Outputs: Escaped string on stdout
_json_escape() {
    local string="$1"
    # Escape backslashes first, then double quotes, then newlines
    string="${string//\\/\\\\}"
    string="${string//\"/\\\"}"
    string="${string//$'\n'/\\n}"
    string="${string//$'\r'/\\r}"
    string="${string//$'\t'/\\t}"
    echo "$string"
}

# Log an event with arbitrary key-value pairs
# Usage: logger_log "event_type" "key1" "value1" "key2" "value2" ...
logger_log() {
    local event_type="$1"
    shift

    # Skip if log file doesn't exist (logger_init not called)
    if [[ ! -f "$CHP_LOG_FILE" ]]; then
        return 0
    fi

    local timestamp=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
    local entry="{\"timestamp\":\"$timestamp\",\"event_type\":\"$event_type\""

    # Parse key-value pairs
    while [[ $# -gt 0 ]]; do
        local key="$1"
        local value="$2"
        # Escape JSON special characters in value
        value=$(_json_escape "$value")
        entry="$entry,\"$key\":\"$value\""
        shift 2
    done

    entry="$entry}"
    echo "$entry" >> "$CHP_LOG_FILE" 2>/dev/null
}

# Log a violation event
# Args: law_id, action, result, pattern, fix, files (optional), hook_type (optional)
logger_violation() {
    local law_id="$1"
    local action="$2"
    local result="$3"
    local pattern="$4"
    local fix="$5"
    local files="${6:-}"
    local hook_type="${7:-}"

    logger_log "violation" \
        "law_id" "$law_id" \
        "action" "$action" \
        "result" "$result" \
        "pattern" "$pattern" \
        "fix" "$fix" \
        "files" "$files" \
        "hook_type" "$hook_type"
}

# Log an evaluation event
# Args: law_id, action, result, files (optional)
logger_evaluation() {
    local law_id="$1"
    local action="$2"
    local result="$3"
    local files="${4:-}"

    logger_log "evaluation" \
        "law_id" "$law_id" \
        "action" "$action" \
        "result" "$result" \
        "files" "$files"
}

# Log a hook trigger event
# Args: hook_type, laws (comma-separated list)
logger_hook_trigger() {
    local hook_type="$1"
    local laws="$2"

    logger_log "hook_trigger" \
        "hook_type" "$hook_type" \
        "laws" "$laws"
}

# Log a hook installation event
# Args: hook_type, laws (comma-separated list), action (install/uninstall)
logger_hook_install() {
    local hook_type="$1"
    local laws="$2"
    local action="${3:-install}"

    logger_log "hook_install" \
        "hook_type" "$hook_type" \
        "laws" "$laws" \
        "action" "$action"
}

# Log a law change event
# Args: law_id, details (JSON string with action, hooks, etc.)
logger_law_change() {
    local law_id="$1"
    local details="$2"

    logger_log "law_change" \
        "law_id" "$law_id" \
        "details" "$details"
}
```

- [ ] **Step 2: Make the file executable**

Run: `chmod +x core/logger.sh`
Expected: File becomes executable

- [ ] **Step 3: Commit**

```bash
git add core/logger.sh
git commit -m "feat: add logger.sh module for CHP logging system"
```

---

## Task 2: Integrate logging into verifier.sh

**Files:**
- Modify: `core/verifier.sh`

- [ ] **Step 1: Add logger.sh source and initialization**

After line 4 (after sourcing common.sh), add:

```bash
# Source logger
source "$(dirname "${BASH_SOURCE[0]}")/logger.sh"

# Initialize logger
logger_init
```

- [ ] **Step 2: Add logging to verify_law function**

Modify the verify_law function (around line 158-204) to add logging. Replace the entire function with:

```bash
# Verify a single law
verify_law() {
    local law_name="$1"

    if [[ -z "$law_name" ]]; then
        log_error "Law name is required"
        return 1
    fi

    if ! law_exists "$law_name"; then
        log_error "Law does not exist: $law_name"
        return 1
    fi

    local law_dir="$LAWS_DIR/$law_name"
    local law_json="$law_dir/law.json"
    local verify_script="$law_dir/verify.sh"

    # Check if law is enabled
    local enabled
    enabled=$(jq -r 'if has("enabled") then .enabled else "true" end' "$law_json" 2>/dev/null)

    if [[ "$enabled" != "true" ]]; then
        log_info "Law is disabled, skipping verification: $law_name"
        return 0
    fi

    if [[ ! -f "$verify_script" ]]; then
        log_error "Verification script not found: $verify_script"
        return 1
    fi

    if [[ ! -x "$verify_script" ]]; then
        log_error "Verification script not executable: $verify_script"
        return 1
    fi

    # Run the verification script
    if bash "$verify_script"; then
        # Log successful evaluation
        logger_evaluation "$law_name" "verification" "passed"
        return 0
    else
        local exit_code=$?
        # Log failed evaluation as violation
        logger_violation "$law_name" "verification" "failed" "verification-script" "fix the issue reported by verify.sh"
        # Record the failure and trigger tightening
        record_failure "$law_name"
        return $exit_code
    fi
}
```

- [ ] **Step 3: Add hook trigger logging to verify_hook_laws function**

At the beginning of verify_hook_laws function (around line 207, after the validation), add:

```bash
    # Log hook trigger
    local law_list=$(find "$LAWS_DIR" -mindepth 1 -maxdepth 1 -type d -exec basename {} \; | tr '\n' ',' | sed 's/,$//')
    logger_hook_trigger "$hook_type" "$law_list"
```

- [ ] **Step 4: Commit**

```bash
git add core/verifier.sh
git commit -m "feat: integrate logging into verifier.sh"
```

---

## Task 3: Integrate logging into dispatcher.sh

**Files:**
- Modify: `core/dispatcher.sh`

- [ ] **Step 1: Add logger.sh source and initialization**

After line 10 (after sourcing common.sh), add:

```bash
# Source logger
source "$SCRIPT_DIR/logger.sh"

# Initialize logger
logger_init
```

- [ ] **Step 2: Add hook trigger logging at the start of dispatch_hook**

After line 64 (after the validation and debug message), add:

```bash
    # Log hook trigger
    local law_list=$(IFS=,; echo "${law_names[*]}")
    logger_hook_trigger "$hook_type" "$law_list"
```

- [ ] **Step 3: Add evaluation logging for each law result**

Inside the for loop (around line 143, after the verify script runs), modify the success/failure logging:

Replace:
```bash
        if "$verify_script" "${hook_args[@]}"; then
            log_debug "Law '$law_name' passed"
            ((passed++))
        else
            local exit_code=$?
            log_error "Law '$law_name' failed with exit code $exit_code"
            ((failed++))

            # Record failure if tightener is available
            if command -v record_failure >/dev/null 2>&1; then
                record_failure "$law_name"
            fi
        fi
```

With:
```bash
        if "$verify_script" "${hook_args[@]}"; then
            log_debug "Law '$law_name' passed"
            logger_evaluation "$law_name" "dispatch" "passed"
            ((passed++))
        else
            local exit_code=$?
            log_error "Law '$law_name' failed with exit code $exit_code"
            logger_violation "$law_name" "dispatch" "failed" "law-verification" "fix the issue reported by verify.sh" "" "$hook_type"
            ((failed++))

            # Record failure if tightener is available
            if command -v record_failure >/dev/null 2>&1; then
                record_failure "$law_name"
            fi
        fi
```

- [ ] **Step 4: Commit**

```bash
git add core/dispatcher.sh
git commit -m "feat: integrate logging into dispatcher.sh"
```

---

## Task 4: Integrate logging into tightener.sh

**Files:**
- Modify: `core/tightener.sh`

- [ ] **Step 1: Add logger.sh source and initialization**

After line 4 (after sourcing common.sh), add:

```bash
# Source logger
source "$(dirname "${BASH_SOURCE[0]}")/logger.sh"

# Initialize logger
logger_init
```

- [ ] **Step 2: Add law change logging to record_failure function**

At the end of the record_failure function (around line 57, before the return 0), add:

```bash
    # Log law change (tightening)
    local details="{\"action\":\"tightened\",\"failures\":$failures,\"tightening_level\":$tightening_level}"
    logger_law_change "$law_name" "$details"
```

- [ ] **Step 3: Add law change logging to reset_failures function**

At the end of the reset_failures function (around line 91, before the return 0), add:

```bash
    # Log law change (reset)
    logger_law_change "$law_name" "{\"action\":\"reset\"}"
```

- [ ] **Step 4: Commit**

```bash
git add core/tightener.sh
git commit -m "feat: integrate logging into tightener.sh"
```

---

## Task 5: Integrate logging into installer.sh

**Files:**
- Modify: `core/installer.sh`

- [ ] **Step 1: Add logger.sh source and initialization**

After line 6 (after sourcing detector.sh), add:

```bash
# Source logger
source "$(dirname "${BASH_SOURCE[0]}")/logger.sh"

# Initialize logger on first use (lazy init)
_logger_init_once() {
    if [[ ! -f "$CHP_LOG_FILE" ]]; then
        logger_init
    fi
}
```

- [ ] **Step 2: Add hook install logging to install_hook_template function**

At the end of the install_hook_template function (around line 193, before the return 0), add:

```bash
    # Log hook installation
    _logger_init_once
    logger_hook_install "$hook_type" "$hook_category" "install"
```

- [ ] **Step 3: Add hook uninstall logging to uninstall_hook_template function**

At the end of the uninstall_hook_template function (around line 226, before the return 0), add:

```bash
    # Log hook uninstallation
    _logger_init_once
    logger_hook_install "$hook_type" "$hook_category" "uninstall"
```

- [ ] **Step 4: Commit**

```bash
git add core/installer.sh
git commit -m "feat: integrate logging into installer.sh"
```

---

## Task 6: Update .gitignore

**Files:**
- Modify: `.gitignore`

- [ ] **Step 1: Add logs.jsonl to gitignore**

Add this line to the end of `.gitignore`:

```gitignore
.chp/logs.jsonl
```

- [ ] **Step 2: Commit**

```bash
git add .gitignore
git commit -m "chore: add .chp/logs.jsonl to gitignore"
```

---

## Task 7: Create logger tests

**Files:**
- Create: `tests/test-logger.sh`

- [ ] **Step 1: Write the logger test file**

```bash
#!/bin/bash
# Test logger module

set -e  # Exit on test failures

source "$(dirname "$0")/../core/common.sh"
source "$(dirname "$0")/../core/logger.sh"

echo "Testing logger.sh functions..."

# Setup: Create a temp log file for testing
TEST_LOG_FILE="$CHP_BASE/.chp/test-logs.jsonl"
CHP_LOG_FILE="$TEST_LOG_FILE"
export CHP_LOG_FILE

# Clean up any existing test log
rm -f "$TEST_LOG_FILE"

# Test 1: logger_init creates log file and directory
echo "Test 1: logger_init creates log file and directory"
logger_init
if [[ -f "$TEST_LOG_FILE" ]]; then
    echo "  ✓ Log file created"
else
    echo "  ✗ Log file should exist"
    exit 1
fi

# Test 2: logger_log creates valid JSON entries
echo "Test 2: logger_log creates valid JSON entries"
logger_log "test_event" "key1" "value1" "key2" "value2"
LAST_LINE=$(tail -n 1 "$TEST_LOG_FILE")
if echo "$LAST_LINE" | jq empty 2>/dev/null; then
    echo "  ✓ Log entry is valid JSON"
else
    echo "  ✗ Log entry should be valid JSON"
    echo "    Got: $LAST_LINE"
    exit 1
fi

# Test 3: Log entry has required fields
echo "Test 3: Log entry has required fields"
TIMESTAMP=$(echo "$LAST_LINE" | jq -r '.timestamp')
EVENT_TYPE=$(echo "$LAST_LINE" | jq -r '.event_type')
KEY1=$(echo "$LAST_LINE" | jq -r '.key1')
KEY2=$(echo "$LAST_LINE" | jq -r '.key2')

if [[ -n "$TIMESTAMP" ]] && [[ "$EVENT_TYPE" == "test_event" ]] && [[ "$KEY1" == "value1" ]] && [[ "$KEY2" == "value2" ]]; then
    echo "  ✓ All required fields present"
else
    echo "  ✗ Missing or incorrect fields"
    echo "    timestamp: $TIMESTAMP"
    echo "    event_type: $EVENT_TYPE"
    echo "    key1: $KEY1"
    echo "    key2: $KEY2"
    exit 1
fi

# Test 4: logger_violation creates violation entries
echo "Test 4: logger_violation creates violation entries"
logger_violation "test-law" "test-action" "blocked" "test-pattern" "test-fix"
LAST_LINE=$(tail -n 1 "$TEST_LOG_FILE")
VIOLATION_EVENT=$(echo "$LAST_LINE" | jq -r '.event_type')
LAW_ID=$(echo "$LAST_LINE" | jq -r '.law_id')
RESULT=$(echo "$LAST_LINE" | jq -r '.result')

if [[ "$VIOLATION_EVENT" == "violation" ]] && [[ "$LAW_ID" == "test-law" ]] && [[ "$RESULT" == "blocked" ]]; then
    echo "  ✓ Violation entry correct"
else
    echo "  ✗ Violation entry incorrect"
    echo "    Got: $LAST_LINE"
    exit 1
fi

# Test 5: logger_evaluation creates evaluation entries
echo "Test 5: logger_evaluation creates evaluation entries"
logger_evaluation "test-law" "test-action" "passed"
LAST_LINE=$(tail -n 1 "$TEST_LOG_FILE")
EVAL_EVENT=$(echo "$LAST_LINE" | jq -r '.event_type')
RESULT=$(echo "$LAST_LINE" | jq -r '.result')

if [[ "$EVAL_EVENT" == "evaluation" ]] && [[ "$RESULT" == "passed" ]]; then
    echo "  ✓ Evaluation entry correct"
else
    echo "  ✗ Evaluation entry incorrect"
    echo "    Got: $LAST_LINE"
    exit 1
fi

# Test 6: logger_hook_trigger creates hook trigger entries
echo "Test 6: logger_hook_trigger creates hook trigger entries"
logger_hook_trigger "pre-commit" "law1,law2,law3"
LAST_LINE=$(tail -n 1 "$TEST_LOG_FILE")
HOOK_EVENT=$(echo "$LAST_LINE" | jq -r '.event_type')
HOOK_TYPE=$(echo "$LAST_LINE" | jq -r '.hook_type')
LAWS=$(echo "$LAST_LINE" | jq -r '.laws')

if [[ "$HOOK_EVENT" == "hook_trigger" ]] && [[ "$HOOK_TYPE" == "pre-commit" ]] && [[ "$LAWS" == "law1,law2,law3" ]]; then
    echo "  ✓ Hook trigger entry correct"
else
    echo "  ✗ Hook trigger entry incorrect"
    echo "    Got: $LAST_LINE"
    exit 1
fi

# Test 7: logger_hook_install creates hook install entries
echo "Test 7: logger_hook_install creates hook install entries"
logger_hook_install "pre-push" "law1" "install"
LAST_LINE=$(tail -n 1 "$TEST_LOG_FILE")
INSTALL_EVENT=$(echo "$LAST_LINE" | jq -r '.event_type')
ACTION=$(echo "$LAST_LINE" | jq -r '.action')

if [[ "$INSTALL_EVENT" == "hook_install" ]] && [[ "$ACTION" == "install" ]]; then
    echo "  ✓ Hook install entry correct"
else
    echo "  ✗ Hook install entry incorrect"
    echo "    Got: $LAST_LINE"
    exit 1
fi

# Test 8: logger_law_change creates law change entries
echo "Test 8: logger_law_change creates law change entries"
logger_law_change "test-law" '{"action":"created"}'
LAST_LINE=$(tail -n 1 "$TEST_LOG_FILE")
CHANGE_EVENT=$(echo "$LAST_LINE" | jq -r '.event_type')
DETAILS=$(echo "$LAST_LINE" | jq -r '.details')

if [[ "$CHANGE_EVENT" == "law_change" ]] && [[ "$DETAILS" == '{"action":"created"}' ]]; then
    echo "  ✓ Law change entry correct"
else
    echo "  ✗ Law change entry incorrect"
    echo "    Got: $LAST_LINE"
    exit 1
fi

# Test 9: Special characters are properly escaped
echo "Test 9: Special characters are properly escaped"
logger_log "test" "message" 'Line with "quotes" and \backslashes and
newlines'
LAST_LINE=$(tail -n 1 "$TEST_LOG_FILE")
MESSAGE=$(echo "$LAST_LINE" | jq -r '.message')

if [[ "$MESSAGE" == 'Line with "quotes" and \backslashes and
newlines' ]]; then
    echo "  ✓ Special characters escaped correctly"
else
    echo "  ✗ Special characters not escaped correctly"
    echo "    Expected: 'Line with \"quotes\" and \backslashes and\nnewlines'"
    echo "    Got: '$MESSAGE'"
    exit 1
fi

# Test 10: Multiple entries are properly delimited (one per line)
echo "Test 10: Multiple entries are properly delimited"
LINE_COUNT=$(wc -l < "$TEST_LOG_FILE")
if [[ $LINE_COUNT -ge 9 ]]; then  # We've logged at least 9 entries
    echo "  ✓ Each log entry on its own line (count: $LINE_COUNT)"
else
    echo "  ✗ Expected at least 9 lines, got: $LINE_COUNT"
    exit 1
fi

# Clean up
rm -f "$TEST_LOG_FILE"

echo ""
echo "All logger tests passed! ✓"
```

- [ ] **Step 2: Make the test file executable**

Run: `chmod +x tests/test-logger.sh`
Expected: File becomes executable

- [ ] **Step 3: Run the tests**

Run: `bash tests/test-logger.sh`
Expected: All tests pass

- [ ] **Step 4: Commit**

```bash
git add tests/test-logger.sh
git commit -m "test: add logger.sh unit tests"
```

---

## Task 8: Manual integration test

**Files:**
- Test existing functionality with logging

- [ ] **Step 1: Create a test law to verify logging works end-to-end**

Run these commands:

```bash
# Create a test law
mkdir -p docs/chp/laws/test-logging-law

# Create law.json
cat > docs/chp/laws/test-logging-law/law.json << 'EOF'
{
  "name": "test-logging-law",
  "description": "Test law for logging system",
  "severity": "error",
  "hooks": ["pre-commit"],
  "created": "2026-04-25",
  "failures": 0,
  "tightening_level": 0
}
EOF

# Create a verify.sh that will fail
cat > docs/chp/laws/test-logging-law/verify.sh << 'EOF'
#!/bin/bash
echo "Test logging violation"
exit 1
EOF
chmod +x docs/chp/laws/test-logging-law/verify.sh
```

- [ ] **Step 2: Run verification to trigger logging**

Run: `bash core/verifier.sh test-logging-law`
Expected: Verification fails, law is recorded

- [ ] **Step 3: Check the log file was created and contains entries**

Run: `cat .chp/logs.jsonl | jq .`
Expected: JSONL entries with violation and law_change events

- [ ] **Step 4: Clean up test law**

Run:
```bash
rm -rf docs/chp/laws/test-logging-law
```

- [ ] **Step 5: Commit (no changes needed, just verification)**

This task is for manual verification only.

---

## Task 9: Documentation

**Files:**
- Create: `docs/chp/LOGGING.md`

- [ ] **Step 1: Create logging documentation**

```markdown
# CHP Logging System

## Overview

CHP logs all events to `.chp/logs.jsonl` in JSONL format (one JSON object per line). This includes violations, evaluations, hook triggers, and law changes.

## Log File Location

- **Path:** `.chp/logs.jsonl`
- **Format:** JSONL (JSON Lines)
- **Git Status:** Ignored (local only)

## Log Entry Schema

Each log entry is a JSON object with these fields:

| Field | Type | Description |
|-------|------|-------------|
| `timestamp` | string | ISO 8601 timestamp (UTC) |
| `event_type` | string | Type of event: `violation`, `evaluation`, `hook_trigger`, `hook_install`, `law_change` |
| `law_id` | string (optional) | ID of the law involved |
| `action` | string (optional) | Action being evaluated |
| `result` | string (optional) | Result: `blocked`, `warned`, `fixed`, `passed`, `failed` |
| `pattern` | string (optional) | Pattern that matched (for violations) |
| `fix` | string (optional) | Suggested fix |
| `files` | string (optional) | Comma-separated list of files |
| `hook_type` | string (optional) | Hook that was triggered |
| `details` | string (optional) | Additional context (JSON string) |

## Event Types

### violation
Logged when a law is violated.

```json
{"timestamp":"2026-04-25T12:00:00Z","event_type":"violation","law_id":"no-api-keys","action":"verification","result":"failed","pattern":"sk_.*","fix":"use environment variable","files":"src/config.ts","hook_type":"pre-commit"}
```

### evaluation
Logged when an action is evaluated against a law.

```json
{"timestamp":"2026-04-25T12:01:00Z","event_type":"evaluation","law_id":"max-line-length","action":"verification","result":"passed","files":"src/index.ts"}
```

### hook_trigger
Logged when a hook is triggered.

```json
{"timestamp":"2026-04-25T12:02:00Z","event_type":"hook_trigger","hook_type":"pre-commit","laws":"no-api-keys,no-console-log"}
```

### hook_install
Logged when a hook is installed or uninstalled.

```json
{"timestamp":"2026-04-25T12:03:00Z","event_type":"hook_install","hook_type":"pre-push","laws":"no-secrets","action":"install"}
```

### law_change
Logged when a law is created, modified, or tightened.

```json
{"timestamp":"2026-04-25T12:04:00Z","event_type":"law_change","law_id":"no-api-keys","details":"{\"action\":\"tightened\",\"failures\":3,\"tightening_level\":1}"}
```

## Viewing Logs

### View all logs
```bash
cat .chp/logs.jsonl | jq .
```

### View violations only
```bash
jq 'select(.event_type == "violation")' .chp/logs.jsonl
```

### View logs for a specific law
```bash
jq 'select(.law_id == "no-api-keys")' .chp/logs.jsonl
```

### Count events by type
```bash
jq -r '.event_type' .chp/logs.jsonl | sort | uniq -c
```

### View recent violations
```bash
jq 'select(.event_type == "violation")' .chp/logs.jsonl | tail -10
```

## Log Rotation

The log file grows unbounded. For projects with high activity, consider setting up log rotation:

```bash
# Archive and rotate logs manually
mv .chp/logs.jsonl ".chp/logs-$(date +%Y%m%d).jsonl"
# New log file will be created on next CHP operation
```

## Troubleshooting

**Logs not appearing?**
- Check that `.chp` directory exists
- Verify `logger.sh` is being sourced in the relevant script
- Check file permissions on `.chp/logs.jsonl`

**Invalid JSON in logs?**
- This can happen if the system crashes mid-write
- Skip bad lines: `jq '. as $line | try . catch empty' .chp/logs.jsonl`
```

- [ ] **Step 2: Commit**

```bash
git add docs/chp/LOGGING.md
git commit -m "docs: add logging system documentation"
```

---

## Completion

All tasks complete! The CHP logging system is now integrated and operational.

**Verification checklist:**
- [ ] Run `bash tests/test-logger.sh` - all tests pass
- [ ] Trigger a violation and verify `.chp/logs.jsonl` is created
- [ ] Check log entries are valid JSON: `jq . < .chp/logs.jsonl`
- [ ] Verify git ignores `.chp/logs.jsonl`

**Next steps:**
- Consider adding log rotation for long-running projects
- Add analysis tools for log insights
- Consider adding structured queries for common patterns

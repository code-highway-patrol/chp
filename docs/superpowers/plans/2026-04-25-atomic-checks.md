# Atomic Checks Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Refactor CHP law verification from monolithic verify.sh scripts to composable atomic checks declared in law.json, with per-check severity, four checker types (pattern, threshold, structural, agent), and per-check violation tracking.

**Architecture:** Each law.json gains a `checks` array. A new `core/check-runner.sh` orchestrator reads checks and dispatches to type-specific checkers in `core/checkers/<type>.sh`. The dispatcher, tightener, CLI commands, and agent prompts are updated to understand per-check granularity. Existing laws are migrated to the new format.

**Tech Stack:** Bash, jq, git

---

## File Structure

| File | Responsibility |
|------|---------------|
| `core/checkers/pattern.sh` | Grep-based pattern matching |
| `core/checkers/threshold.sh` | Metric counting with min/max thresholds |
| `core/checkers/structural.sh` | Convention assertions (test file exists, etc.) |
| `core/checkers/agent.sh` | Subjective checks that output agent prompts |
| `core/check-runner.sh` | Reads checks from law.json, dispatches to checkers, aggregates results |
| `core/dispatcher.sh` | Updated: uses check-runner instead of calling verify.sh directly |
| `core/tightener.sh` | Updated: per-check violation tracking |
| `core/law-builder.sh` | Updated: builds checks array in law.json |
| `core/interactive.sh` | Updated: check composition prompts |
| `commands/chp-law` | Updated: create/update/list with check support |
| `docs/chp/laws/*/law.json` | Migrated: all existing laws get checks arrays |
| `docs/chp/laws/*/verify.sh` | Replaced: auto-generated orchestration scripts |
| `agents/chief.md` | Updated: understands atomic check composition |
| `agents/officer.md` | Updated: reports per-check results |
| `agents/detective.md` | Updated: tightens individual checks |
| `tests/test-check-runner.sh` | New: test suite for check-runner and checkers |
| `tests/test-dispatcher.sh` | Updated: tests for per-check dispatch |

---

### Task 1: Create pattern checker

**Files:**
- Create: `core/checkers/pattern.sh`

- [ ] **Step 1: Write the test**

Create `tests/test-check-runner.sh`:

```bash
#!/bin/bash
# Test check-runner and checker functions
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TEST_ROOT="$(mktemp -d)"
mkdir -p "$TEST_ROOT/docs/chp/laws" "$TEST_ROOT/.chp" "$TEST_ROOT/core/checkers"

# Copy core scripts
cp -r "$SCRIPT_DIR/../core" "$TEST_ROOT/core"
mkdir -p "$TEST_ROOT/core/checkers"

export CHP_BASE="$TEST_ROOT"
export LAWS_DIR="$TEST_ROOT/docs/chp/laws"

cleanup() { rm -rf "$TEST_ROOT"; }
trap cleanup EXIT

source "$TEST_ROOT/core/common.sh"

echo "Testing check-runner..."
echo ""

# Test 1: pattern checker detects a pattern in staged diff
echo "Test 1: pattern checker detects violations"

# Create a test file with a violation
mkdir -p "$TEST_ROOT/src"
echo 'console.log("debug")' > "$TEST_ROOT/src/app.ts"
cd "$TEST_ROOT"
git init >/dev/null 2>&1
git add src/app.ts >/dev/null 2>&1

# Run pattern checker
source "$TEST_ROOT/core/checkers/pattern.sh"
CONFIG='{"pattern":"console\\.log\\("}'
RESULT=$(check_pattern "pre-commit" "$CONFIG" "")
if [[ "$RESULT" == FAIL* ]]; then
    echo "  ✓ Pattern checker detected console.log"
else
    echo "  ✗ Pattern checker should have failed: $RESULT"
    exit 1
fi

echo ""

# Test 2: pattern checker passes when no violation
echo "Test 2: pattern checker passes clean files"

rm -f "$TEST_ROOT/src/app.ts"
echo 'logger.info("clean")' > "$TEST_ROOT/src/app.ts"
git add src/app.ts >/dev/null 2>&1

RESULT=$(check_pattern "pre-commit" "$CONFIG" "")
if [[ "$RESULT" == "PASS" ]]; then
    echo "  ✓ Pattern checker passed clean file"
else
    echo "  ✗ Pattern checker should have passed: $RESULT"
    exit 1
fi

echo ""
echo "All tests passed!"
```

- [ ] **Step 2: Run test to verify it fails**

Run: `bash tests/test-check-runner.sh`
Expected: FAIL — `core/checkers/pattern.sh` does not exist

- [ ] **Step 3: Write pattern checker**

Create `core/checkers/pattern.sh`:

```bash
#!/bin/bash
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

                if git diff --cached "$file" 2>/dev/null | grep -qE "$pattern"; then
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
```

- [ ] **Step 4: Run test to verify it passes**

Run: `bash tests/test-check-runner.sh`
Expected: All tests passed!

- [ ] **Step 5: Commit**

```bash
git add core/checkers/pattern.sh tests/test-check-runner.sh
git commit -m "feat: add pattern checker for atomic checks"
```

---

### Task 2: Create check runner orchestrator

**Files:**
- Create: `core/check-runner.sh`

- [ ] **Step 1: Add tests for check runner**

Append to `tests/test-check-runner.sh` before the final `echo "All tests passed!"`:

```bash
# Test 3: check runner reads checks from law.json and dispatches
echo "Test 3: check runner dispatches pattern checks from law.json"

source "$TEST_ROOT/core/check-runner.sh"

# Create a law with pattern checks
TEST_LAW_DIR="$LAWS_DIR/test-check-runner"
mkdir -p "$TEST_LAW_DIR"

cat > "$TEST_LAW_DIR/law.json" << 'LAWEOF'
{
  "name": "test-check-runner",
  "enabled": true,
  "checks": [
    {
      "id": "no-console-log",
      "type": "pattern",
      "config": {"pattern": "console\\.log\\("},
      "severity": "block",
      "message": "Use logger.info() instead of console.log()"
    }
  ]
}
LAWEOF

# Create a violating file
echo 'console.log("violation")' > "$TEST_ROOT/src/bad.ts"
cd "$TEST_ROOT"
git add src/bad.ts >/dev/null 2>&1

RESULT=$(run_checks "test-check-runner" "pre-commit" 2>/dev/null)
EXIT_CODE=$?

if [[ $EXIT_CODE -ne 0 ]]; then
    echo "  ✓ Check runner detected violation from law.json checks"
else
    echo "  ✗ Check runner should have failed: $RESULT"
    exit 1
fi

# Verify per-check result output
if echo "$RESULT" | grep -q "no-console-log.*FAIL"; then
    echo "  ✓ Per-check result includes check ID"
else
    echo "  ✗ Per-check result missing check ID: $RESULT"
    exit 1
fi

echo ""

# Test 4: check runner passes when all checks pass
echo "Test 4: check runner passes when all checks pass"

echo 'logger.info("clean")' > "$TEST_ROOT/src/bad.ts"
cd "$TEST_ROOT"
git add src/bad.ts >/dev/null 2>&1

RESULT=$(run_checks "test-check-runner" "pre-commit" 2>/dev/null)
EXIT_CODE=$?

if [[ $EXIT_CODE -eq 0 ]]; then
    echo "  ✓ Check runner passes clean files"
else
    echo "  ✗ Check runner should have passed: $RESULT"
    exit 1
fi

echo ""

# Test 5: warn-severity checks don't cause failure
echo "Test 5: warn-severity checks don't cause failure"

cat > "$TEST_LAW_DIR/law.json" << 'LAWEOF'
{
  "name": "test-check-runner",
  "enabled": true,
  "checks": [
    {
      "id": "no-console-log",
      "type": "pattern",
      "config": {"pattern": "console\\.log\\("},
      "severity": "warn",
      "message": "Use logger.info() instead of console.log()"
    }
  ]
}
LAWEOF

echo 'console.log("violation")' > "$TEST_ROOT/src/bad.ts"
cd "$TEST_ROOT"
git add src/bad.ts >/dev/null 2>&1

RESULT=$(run_checks "test-check-runner" "pre-commit" 2>/dev/null)
EXIT_CODE=$?

if [[ $EXIT_CODE -eq 0 ]]; then
    echo "  ✓ Warn-severity check doesn't block"
else
    echo "  ✗ Warn-severity check should not block: $RESULT"
    exit 1
fi

# Verify it still reports the violation
if echo "$RESULT" | grep -q "no-console-log.*FAIL"; then
    echo "  ✓ Warn-severity violation still reported"
else
    echo "  ✗ Warn-severity violation should be reported: $RESULT"
    exit 1
fi
```

- [ ] **Step 2: Run test to verify it fails**

Run: `bash tests/test-check-runner.sh`
Expected: FAIL — `core/check-runner.sh` does not exist

- [ ] **Step 3: Write check runner**

Create `core/check-runner.sh`:

```bash
#!/bin/bash
# Check runner — orchestrates atomic checks from law.json
# Reads the checks array and dispatches each to core/checkers/<type>.sh

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/common.sh"

CHECKERS_DIR="$SCRIPT_DIR/checkers"

# Usage: run_checks <law_name> <hook_type> [hook_args...]
# Returns: 0 if no block-level failures, 1 if any block check fails
# Output: per-check results as JSONL
run_checks() {
    local law_name="$1"
    local hook_type="$2"
    shift 2

    local law_json="$LAWS_DIR/$law_name/law.json"

    if [[ ! -f "$law_json" ]]; then
        log_error "law.json not found for law: $law_name"
        return 2
    fi

    local checks_json
    checks_json=$(jq -c '.checks // []' "$law_json" 2>/dev/null)

    if [[ "$checks_json" == "[]" || -z "$checks_json" ]]; then
        log_debug "No checks defined for law: $law_name"
        return 0
    fi

    local check_count
    check_count=$(echo "$checks_json" | jq 'length')
    local block_failures=0
    local warn_failures=0
    local passes=0
    local -a results=()

    for ((i=0; i<check_count; i++)); do
        local check_id check_type check_config check_severity check_message
        check_id=$(echo "$checks_json" | jq -r ".[$i].id // \"check-$i\"")
        check_type=$(echo "$checks_json" | jq -r ".[$i].type // empty")
        check_config=$(echo "$checks_json" | jq -c ".[$i].config // {}")
        check_severity=$(echo "$checks_json" | jq -r ".[$i].severity // \"warn\"")
        check_message=$(echo "$checks_json" | jq -r ".[$i].message // \"\"")

        # Find the checker script
        local checker_script="$CHECKERS_DIR/${check_type}.sh"

        if [[ ! -f "$checker_script" ]]; then
            log_warn "Checker not found: $check_type (check: $check_id)"
            results+=("{\"check_id\":\"$check_id\",\"type\":\"$check_type\",\"status\":\"SKIP\",\"reason\":\"checker-not-found\"}")
            continue
        fi

        # Source and run the checker
        source "$checker_script"
        local check_result
        check_result=$(check_"$check_type" "$hook_type" "$check_config" "$@" 2>/dev/null)
        local check_exit=$?

        local status
        if [[ "$check_result" == PASS* ]]; then
            status="PASS"
            ((passes++))
        elif [[ "$check_result" == FAIL* ]]; then
            status="FAIL"
            if [[ "$check_severity" == "block" ]]; then
                ((block_failures++))
            else
                ((warn_failures++))
            fi
        else
            status="SKIP"
        fi

        local fail_detail=""
        if [[ "$status" == "FAIL" ]]; then
            fail_detail="${check_result#FAIL:}"
        fi

        results+=("{\"check_id\":\"$check_id\",\"type\":\"$check_type\",\"severity\":\"$check_severity\",\"status\":\"$status\",\"detail\":\"${fail_detail}\",\"message\":\"$check_message\"}")

        log_debug "Check $check_id ($check_type): $status (severity: $check_severity)"
    done

    # Output all results
    for result in "${results[@]}"; do
        echo "$result"
    done

    log_debug "Checks complete for $law_name: passes=$passes, blocks=$block_failures, warns=$warn_failures" >&2

    if [[ $block_failures -gt 0 ]]; then
        return 1
    fi
    return 0
}

# Usage: get_overall_severity <law_name>
# Returns the highest severity across all checks
get_overall_severity() {
    local law_name="$1"
    local law_json="$LAWS_DIR/$law_name/law.json"

    if [[ ! -f "$law_json" ]]; then
        echo "warn"
        return
    fi

    local checks_json
    checks_json=$(jq -c '.checks // []' "$law_json" 2>/dev/null)

    if [[ "$checks_json" == "[]" || -z "$checks_json" ]]; then
        jq -r '.severity // "warn"' "$law_json"
        return
    fi

    # If any check is block, overall is block
    local has_block
    has_block=$(echo "$checks_json" | jq '[.[] | select(.severity == "block")] | length')
    if [[ "$has_block" -gt 0 ]]; then
        echo "block"
        return
    fi

    local has_warn
    has_warn=$(echo "$checks_json" | jq '[.[] | select(.severity == "warn")] | length')
    if [[ "$has_warn" -gt 0 ]]; then
        echo "warn"
        return
    fi

    echo "log"
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `bash tests/test-check-runner.sh`
Expected: All tests passed!

- [ ] **Step 5: Commit**

```bash
git add core/check-runner.sh tests/test-check-runner.sh
git commit -m "feat: add check runner orchestrator for atomic checks"
```

---

### Task 3: Create threshold checker

**Files:**
- Create: `core/checkers/threshold.sh`

- [ ] **Step 1: Add tests for threshold checker**

Append to `tests/test-check-runner.sh` before the final `echo "All tests passed!"`:

```bash
# Test 6: threshold checker detects oversized files
echo "Test 6: threshold checker detects oversized files"

source "$TEST_ROOT/core/checkers/threshold.sh"

# Create a long file (60 lines)
for i in $(seq 1 60); do echo "line $i"; done > "$TEST_ROOT/src/long.ts"
cd "$TEST_ROOT"
git add src/long.ts >/dev/null 2>&1

CONFIG='{"metric":"file_line_count","max":50}'
RESULT=$(check_threshold "pre-commit" "$CONFIG" "")
if [[ "$RESULT" == FAIL* ]]; then
    echo "  ✓ Threshold checker detected oversized file"
else
    echo "  ✗ Threshold checker should have failed: $RESULT"
    exit 1
fi

echo ""

# Test 7: threshold checker passes under limit
echo "Test 7: threshold checker passes under limit"

echo "short file" > "$TEST_ROOT/src/short.ts"
cd "$TEST_ROOT"
git add src/short.ts >/dev/null 2>&1

RESULT=$(check_threshold "pre-commit" "$CONFIG" "")
if [[ "$RESULT" == "PASS" ]]; then
    echo "  ✓ Threshold checker passed short file"
else
    echo "  ✗ Threshold checker should have passed: $RESULT"
    exit 1
fi
```

- [ ] **Step 2: Run test to verify it fails**

Run: `bash tests/test-check-runner.sh`
Expected: FAIL — threshold checker not found

- [ ] **Step 3: Write threshold checker**

Create `core/checkers/threshold.sh`:

```bash
#!/bin/bash
# Threshold checker — counts a metric and compares to min/max

# Usage: check_threshold <hook_type> <config_json> <context_file>
# config_json: {"metric": "file_line_count", "max": 50}
# Supported metrics: file_line_count, function_line_count, nesting_depth, import_count
# Returns: PASS, FAIL:<message>, or SKIP

check_threshold() {
    local hook_type="$1"
    local config_json="$2"

    local metric max min
    metric=$(echo "$config_json" | jq -r '.metric // empty')
    max=$(echo "$config_json" | jq -r '.max // empty')
    min=$(echo "$config_json" | jq -r '.min // empty')

    if [[ -z "$metric" ]]; then
        echo "SKIP:threshold:no-metric"
        return 0
    fi

    local files_to_check=()

    case "$hook_type" in
        pre-commit)
            while IFS= read -r file; do
                [[ -z "$file" ]] && continue
                [[ ! -f "$file" ]] && continue
                files_to_check+=("$file")
            done < <(git diff --cached --name-only --diff-filter=ACM 2>/dev/null)
            ;;
        pre-push|post-commit)
            local files
            if git rev-parse @{u} >/dev/null 2>&1; then
                files=$(git diff --name-only HEAD @{u} 2>/dev/null)
            else
                files=$(git diff --name-only HEAD^..HEAD 2>/dev/null)
            fi
            while IFS= read -r file; do
                [[ -z "$file" ]] && continue
                [[ ! -f "$file" ]] && continue
                files_to_check+=("$file")
            done <<< "$files"
            ;;
        *)
            echo "SKIP:threshold:unsupported-hook:$hook_type"
            return 0
            ;;
    esac

    if [[ ${#files_to_check[@]} -eq 0 ]]; then
        echo "PASS"
        return 0
    fi

    local violations=0
    local violating_files=()

    for file in "${files_to_check[@]}"; do
        local value=0

        case "$metric" in
            file_line_count)
                value=$(wc -l < "$file" | tr -d ' ')
                ;;
            import_count)
                value=$(grep -cE '^(import |require\(|from )' "$file" 2>/dev/null || echo "0")
                ;;
            nesting_depth)
                value=$(awk '{ gsub(/[[:space:]]/, ""); depth=0; for(i=1;i<=length;i++){c=substr($0,i,1); if(c=="{")depth++; if(c=="}")depth--} if(depth>max)max=depth } END{print max+0}' "$file" 2>/dev/null || echo "0")
                ;;
            function_line_count)
                # Approximate: count lines between function declarations
                value=$(awk '/^function |^[a-zA-Z_]+\(\)/{if(start)count=NR-start;if(count>max)max=count;start=NR} END{print max+0}' "$file" 2>/dev/null || echo "0")
                ;;
            *)
                echo "SKIP:threshold:unknown-metric:$metric"
                return 0
                ;;
        esac

        local exceeded=false
        if [[ -n "$max" && "$max" != "null" ]] && [[ "$value" -gt "$max" ]]; then
            exceeded=true
        fi
        if [[ -n "$min" && "$min" != "null" ]] && [[ "$value" -lt "$min" ]]; then
            exceeded=true
        fi

        if $exceeded; then
            violations=$((violations + 1))
            violating_files+=("$file ($metric=$value)")
        fi
    done

    if [[ $violations -gt 0 ]]; then
        local limit_desc=""
        [[ -n "$max" && "$max" != "null" ]] && limit_desc="max=$max"
        [[ -n "$min" && "$min" != "null" ]] && limit_desc="${limit_desc:+$limit_desc, }min=$min"
        echo "FAIL:Metric '$metric' exceeded ($limit_desc) in ${violations} file(s): ${violating_files[*]}"
        return 1
    fi

    echo "PASS"
    return 0
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `bash tests/test-check-runner.sh`
Expected: All tests passed!

- [ ] **Step 5: Commit**

```bash
git add core/checkers/threshold.sh
git commit -m "feat: add threshold checker for metric-based checks"
```

---

### Task 4: Create structural checker

**Files:**
- Create: `core/checkers/structural.sh`

- [ ] **Step 1: Add tests for structural checker**

Append to `tests/test-check-runner.sh`:

```bash
# Test 8: structural checker - test_file_exists assertion
echo "Test 8: structural checker - test_file_exists assertion"

source "$TEST_ROOT/core/checkers/structural.sh"

# Create source file without matching test
echo 'export function foo() {}' > "$TEST_ROOT/src/utils.ts"
cd "$TEST_ROOT"
git add src/utils.ts >/dev/null 2>&1

CONFIG='{"assert":"test_file_exists","source_pattern":"src/","test_pattern":"tests/"}'
RESULT=$(check_structural "pre-commit" "$CONFIG" "")
if [[ "$RESULT" == FAIL* ]]; then
    echo "  ✓ Structural checker detected missing test file"
else
    echo "  ✗ Structural checker should have failed: $RESULT"
    exit 1
fi

echo ""

# Test 9: structural checker passes when test exists
echo "Test 9: structural checker passes when test exists"

mkdir -p "$TEST_ROOT/tests"
echo 'test("foo", () => {})' > "$TEST_ROOT/tests/utils.test.ts"
cd "$TEST_ROOT"
git add tests/utils.test.ts >/dev/null 2>&1

RESULT=$(check_structural "pre-commit" "$CONFIG" "")
if [[ "$RESULT" == "PASS" ]]; then
    echo "  ✓ Structural checker passed with test file present"
else
    echo "  ✗ Structural checker should have passed: $RESULT"
    exit 1
fi
```

- [ ] **Step 2: Run test to verify it fails**

Run: `bash tests/test-check-runner.sh`
Expected: FAIL — structural checker not found

- [ ] **Step 3: Write structural checker**

Create `core/checkers/structural.sh`:

```bash
#!/bin/bash
# Structural checker — convention assertions for code structure

# Usage: check_structural <hook_type> <config_json> <context_file>
# config_json: {"assert": "test_file_exists", "source_pattern": "src/", "test_pattern": "tests/"}
# Supported assertions: test_file_exists, no_circular_imports, auth_middleware_present
# Returns: PASS, FAIL:<message>, or SKIP

check_structural() {
    local hook_type="$1"
    local config_json="$2"

    local assertion
    assertion=$(echo "$config_json" | jq -r '.assert // empty')

    if [[ -z "$assertion" ]]; then
        echo "SKIP:structural:no-assertion"
        return 0
    fi

    case "$assertion" in
        test_file_exists)
            _assert_test_file_exists "$hook_type" "$config_json"
            ;;
        no_circular_imports)
            _assert_no_circular_imports "$hook_type" "$config_json"
            ;;
        auth_middleware_present)
            _assert_auth_middleware "$hook_type" "$config_json"
            ;;
        *)
            echo "SKIP:structural:unknown-assertion:$assertion"
            return 0
            ;;
    esac
}

_assert_test_file_exists() {
    local hook_type="$1"
    local config_json="$2"

    local source_pattern test_pattern
    source_pattern=$(echo "$config_json" | jq -r '.source_pattern // "src/"')
    test_pattern=$(echo "$config_json" | jq -r '.test_pattern // "tests/"')

    local files_to_check=()
    case "$hook_type" in
        pre-commit)
            while IFS= read -r file; do
                [[ -z "$file" ]] && continue
                [[ ! -f "$file" ]] && continue
                echo "$file" | grep -qE "\\.(test|spec)\\." && continue
                echo "$file" | grep -qE "^${source_pattern}" || continue
                files_to_check+=("$file")
            done < <(git diff --cached --name-only --diff-filter=ACM 2>/dev/null)
            ;;
        *)
            echo "SKIP:structural:unsupported-hook:$hook_type"
            return 0
            ;;
    esac

    if [[ ${#files_to_check[@]} -eq 0 ]]; then
        echo "PASS"
        return 0
    fi

    local violations=0
    local violating_files=()

    for file in "${files_to_check[@]}"; do
        local basename_noext
        basename_noext=$(basename "$file" | sed 's/\.[^.]*$//')
        local found_test=false

        # Check common test file patterns
        for test_dir in "$test_pattern" "tests" "test" "__tests__"; do
            for ext in ".test.ts" ".test.js" ".spec.ts" ".spec.js"; do
                if [[ -f "${test_dir}/${basename_noext}${ext}" ]]; then
                    found_test=true
                    break 2
                fi
            done
        done

        if ! $found_test; then
            violations=$((violations + 1))
            violating_files+=("$file")
        fi
    done

    if [[ $violations -gt 0 ]]; then
        echo "FAIL:No test file found for ${violations} source file(s): ${violating_files[*]}"
        return 1
    fi

    echo "PASS"
    return 0
}

_assert_no_circular_imports() {
    local hook_type="$1"
    local config_json="$2"

    local files_to_check=()
    case "$hook_type" in
        pre-commit)
            while IFS= read -r file; do
                [[ -z "$file" ]] && continue
                [[ ! -f "$file" ]] && continue
                echo "$file" | grep -qE '\.(ts|js|tsx|jsx)$' || continue
                files_to_check+=("$file")
            done < <(git diff --cached --name-only --diff-filter=ACM 2>/dev/null)
            ;;
        *)
            echo "SKIP:structural:unsupported-hook:$hook_type"
            return 0
            ;;
    esac

    if [[ ${#files_to_check[@]} -eq 0 ]]; then
        echo "PASS"
        return 0
    fi

    local violations=0
    for file in "${files_to_check[@]}"; do
        local imports
        imports=$(grep -oE "(from|import)[[:space:]]+'\\./|\"\\./" "$file" 2>/dev/null || true)
        if [[ -n "$imports" ]]; then
            local import_file
            import_file=$(echo "$imports" | grep -oE '\\.\\./[^'\"]+' | head -1)
            if [[ -n "$import_file" ]] && grep -q "$(basename "$file" | sed 's/\.[^.]*$//')" "$import_file" 2>/dev/null; then
                violations=$((violations + 1))
            fi
        fi
    done

    if [[ $violations -gt 0 ]]; then
        echo "FAIL:Circular imports detected in ${violations} file(s)"
        return 1
    fi

    echo "PASS"
    return 0
}

_assert_auth_middleware() {
    local hook_type="$1"
    local config_json="$2"

    local route_pattern
    route_pattern=$(echo "$config_json" | jq -r '.route_pattern // "routes/"')

    local files_to_check=()
    case "$hook_type" in
        pre-commit)
            while IFS= read -r file; do
                [[ -z "$file" ]] && continue
                [[ ! -f "$file" ]] && continue
                echo "$file" | grep -qE "^${route_pattern}" || continue
                files_to_check+=("$file")
            done < <(git diff --cached --name-only --diff-filter=ACM 2>/dev/null)
            ;;
        *)
            echo "SKIP:structural:unsupported-hook:$hook_type"
            return 0
            ;;
    esac

    if [[ ${#files_to_check[@]} -eq 0 ]]; then
        echo "PASS"
        return 0
    fi

    local violations=0
    local violating_files=()

    for file in "${files_to_check[@]}"; do
        if ! grep -qE "(auth|authenticate|verifyToken|jwt)" "$file" 2>/dev/null; then
            violations=$((violations + 1))
            violating_files+=("$file")
        fi
    done

    if [[ $violations -gt 0 ]]; then
        echo "FAIL:No auth middleware found in ${violations} route file(s): ${violating_files[*]}"
        return 1
    fi

    echo "PASS"
    return 0
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `bash tests/test-check-runner.sh`
Expected: All tests passed!

- [ ] **Step 5: Commit**

```bash
git add core/checkers/structural.sh
git commit -m "feat: add structural checker for convention assertions"
```

---

### Task 5: Create agent checker

**Files:**
- Create: `core/checkers/agent.sh`

- [ ] **Step 1: Add tests for agent checker**

Append to `tests/test-check-runner.sh`:

```bash
# Test 10: agent checker outputs prompt context
echo "Test 10: agent checker outputs prompt for agent hooks"

source "$TEST_ROOT/core/checkers/agent.sh"

CONFIG='{"prompt":"Are these variable names meaningful?"}'
RESULT=$(check_agent "pre-tool" "$CONFIG" "")
if [[ "$RESULT" == PASS* ]]; then
    echo "  ✓ Agent checker outputs context for pre-tool hooks"
else
    echo "  ✗ Agent checker should output context: $RESULT"
    exit 1
fi

echo ""

# Test 11: agent checker skips for non-agent hooks
echo "Test 11: agent checker skips for non-agent hooks"

RESULT=$(check_agent "pre-commit" "$CONFIG" "")
if [[ "$RESULT" == SKIP* ]]; then
    echo "  ✓ Agent checker skips for git hooks"
else
    echo "  ✗ Agent checker should skip for git hooks: $RESULT"
    exit 1
fi
```

- [ ] **Step 2: Run test to verify it fails**

Run: `bash tests/test-check-runner.sh`
Expected: FAIL — agent checker not found

- [ ] **Step 3: Write agent checker**

Create `core/checkers/agent.sh`:

```bash
#!/bin/bash
# Agent checker — subjective checks that output prompts for AI judgment
# These only activate in agent hook contexts (pre-tool, post-tool, etc.)
# In git hook contexts, they SKIP (can't judge subjectively without an AI)

# Usage: check_agent <hook_type> <config_json> <context_file>
# config_json: {"prompt": "Are these variable names meaningful?"}
# Returns: PASS with additionalContext for agent hooks, SKIP for git hooks

check_agent() {
    local hook_type="$1"
    local config_json="$2"

    local prompt_text
    prompt_text=$(echo "$config_json" | jq -r '.prompt // empty')

    if [[ -z "$prompt_text" ]]; then
        echo "SKIP:agent:no-prompt"
        return 0
    fi

    # Agent checks only run in agent hook contexts
    case "$hook_type" in
        pre-tool|post-tool|pre-prompt|post-prompt|pre-response|post-response)
            # Output the prompt as additional context for the agent
            local context_json
            context_json=$(jq -n \
                --arg prompt "$prompt_text" \
                '{"additionalContext": $prompt}')

            echo "PASS:${context_json}"
            return 0
            ;;
        *)
            # Git hooks can't judge subjectively — skip silently
            echo "SKIP:agent:non-agent-context"
            return 0
            ;;
    esac
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `bash tests/test-check-runner.sh`
Expected: All tests passed!

- [ ] **Step 5: Commit**

```bash
git add core/checkers/agent.sh
git commit -m "feat: add agent checker for subjective AI-judged checks"
```

---

### Task 6: Update dispatcher to use check runner

**Files:**
- Modify: `core/dispatcher.sh`

- [ ] **Step 1: Update tests for per-check dispatch**

Add to `tests/test-dispatcher.sh` before the final echo:

```bash
# Test 11: Dispatcher uses check-runner for laws with checks array
echo "Test 11: Dispatcher uses check-runner for laws with checks array"

# Recreate the test law with checks format
rm -rf "$LAWS_DIR/test-dispatcher-law"
TEST_LAW_DIR="$LAWS_DIR/test-dispatcher-law"
mkdir -p "$TEST_LAW_DIR"

cat > "$TEST_LAW_DIR/law.json" << 'EOF'
{
  "name": "test-dispatcher-law",
  "severity": "error",
  "failures": 0,
  "tightening_level": 0,
  "enabled": true,
  "checks": [
    {
      "id": "always-fail",
      "type": "pattern",
      "config": {"pattern": "ALWAYS_FAIL_PATTERN_XYZ"},
      "severity": "block",
      "message": "This check always fails for testing"
    }
  ]
}
EOF

# Create a verify.sh that uses check-runner
cat > "$TEST_LAW_DIR/verify.sh" << 'VERIFYEOF'
#!/bin/bash
LAW_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CHP_BASE="$(cd "$LAW_DIR/../../../../" && pwd)"
source "$CHP_BASE/core/common.sh"
source "$CHP_BASE/core/check-runner.sh"
run_checks "test-dispatcher-law" "pre-commit"
exit $?
VERIFYEOF
chmod +x "$TEST_LAW_DIR/verify.sh"

# Create a file that matches the pattern
echo 'ALWAYS_FAIL_PATTERN_XYZ' > "$TEST_ROOT/src/fail.ts"
cd "$TEST_ROOT"
git add src/fail.ts >/dev/null 2>&1

echo '{\"hooks\":{},\"version\":\"1.0\"}' > "$HOOK_REGISTRY"
register_hook_law "pre-commit" "test-dispatcher-law"
set_hook_blocking "pre-commit" true

output=$(dispatch_hook "pre-commit" 2>&1 || true)
if echo "$output" | grep -q "always-fail.*FAIL"; then
    echo "  ✓ Dispatcher reports per-check failure"
else
    echo "  ✗ Dispatcher should report per-check failure: $output"
    exit 1
fi
```

- [ ] **Step 2: Run test to verify it fails**

Run: `bash tests/test-dispatcher.sh`
Expected: FAIL on Test 11 — check-runner not sourced

- [ ] **Step 3: Update dispatcher to source check-runner**

In `core/dispatcher.sh`, add after the existing source lines (line 6):

```bash
source "$SCRIPT_DIR/check-runner.sh"
```

The top of dispatcher.sh becomes:

```bash
#!/bin/bash
# Central Hook Dispatcher - Routes hook events to registered laws

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/common.sh"
source "$SCRIPT_DIR/hook-registry.sh"
source "$SCRIPT_DIR/verifier.sh"
source "$SCRIPT_DIR/check-runner.sh"
```

- [ ] **Step 4: Run test to verify it passes**

Run: `bash tests/test-dispatcher.sh`
Expected: All tests passed!

- [ ] **Step 5: Commit**

```bash
git add core/dispatcher.sh tests/test-dispatcher.sh
git commit -m "feat: update dispatcher to source check-runner"
```

---

### Task 7: Update tightener for per-check tracking

**Files:**
- Modify: `core/tightener.sh`

- [ ] **Step 1: Update tightener to accept optional check_id**

In `core/tightener.sh`, update `record_failure()` to accept an optional second argument `check_id`. After line 14 (`local law_name="$1"`), add:

```bash
    local check_id="${2:-}"
```

Update the log line near the end (line 56) to include check_id:

```bash
    if [[ -n "$check_id" ]]; then
        log_warn "Law '$law_name' check '$check_id' failed (failure #$failures, tightening level $tightening_level)"
    else
        log_warn "Law '$law_name' failed (failure #$failures, tightening level $tightening_level)"
    fi
```

Update the guidance append to include check_id when present:

Replace the heredoc that appends to guidance.md with:

```bash
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
```

- [ ] **Step 2: Run existing tests to verify nothing broke**

Run: `bash tests/test-dispatcher.sh && bash tests/test-check-runner.sh`
Expected: All tests passed!

- [ ] **Step 3: Commit**

```bash
git add core/tightener.sh
git commit -m "feat: update tightener for per-check violation tracking"
```

---

### Task 8: Update dispatcher to pass check results to tightener

**Files:**
- Modify: `core/dispatcher.sh`

- [ ] **Step 1: Update dispatcher failure recording to parse check results**

In `core/dispatcher.sh`, update the failure handling block (around lines 146-162). Replace the section that calls `record_failure` with logic that parses per-check JSONL results:

```bash
        else
            log_error "Law '$law_name' failed with exit code $verify_exit"
            ((failed++))

            # For pre-tool hooks, output only the block JSON and stop
            if [[ "$hook_type" == "pre-tool" || "$hook_type" == "pre-write" ]]; then
                echo "$verify_stdout"
                if command -v record_failure >/dev/null 2>&1; then
                    _record_check_failures "$law_name" "$verify_stdout" >&2
                fi
                return 1
            fi

            if command -v _record_check_failures >/dev/null 2>&1; then
                _record_check_failures "$law_name" "$verify_stdout"
            elif command -v record_failure >/dev/null 2>&1; then
                record_failure "$law_name"
            fi
        fi
```

Add the `_record_check_failures` helper function before `dispatch_hook()`:

```bash
# Record failures per check from JSONL output, falling back to law-level
_record_check_failures() {
    local law_name="$1"
    local stdout="$2"

    local has_check_results=false
    if [[ -n "$stdout" ]]; then
        while IFS= read -r line; do
            local check_id status
            check_id=$(echo "$line" | jq -r '.check_id // empty' 2>/dev/null)
            status=$(echo "$line" | jq -r '.status // empty' 2>/dev/null)
            if [[ -n "$check_id" ]]; then
                has_check_results=true
                if [[ "$status" == "FAIL" ]]; then
                    record_failure "$law_name" "$check_id"
                fi
            fi
        done <<< "$stdout"
    fi

    if ! $has_check_results; then
        record_failure "$law_name"
    fi
}
```

- [ ] **Step 2: Run tests**

Run: `bash tests/test-dispatcher.sh`
Expected: All tests passed!

- [ ] **Step 3: Commit**

```bash
git add core/dispatcher.sh
git commit -m "feat: dispatcher records per-check failures"
```

---

### Task 9: Update law-builder for check composition

**Files:**
- Modify: `core/law-builder.sh`

- [ ] **Step 1: Update build_law_json to include checks**

In `core/law-builder.sh`, add a new function `build_law_json_with_checks` after `build_law_json`:

```bash
# Build law.json with atomic checks
# Usage: build_law_json_with_checks <name> <severity> <hooks> <checks_json> <enabled>
build_law_json_with_checks() {
    local name="$1"
    local severity="$2"
    local hooks="$3"
    local checks_json="$4"
    local enabled="${5:-true}"

    local hooks_array=$(jq -nR --arg h "$hooks" '$h | split(",") | map(select(length > 0))')

    # If checks_json is a file path, read it; otherwise use as-is
    local checks
    if [[ -f "$checks_json" ]]; then
        checks=$(cat "$checks_json")
    else
        checks="$checks_json"
    fi

    # Validate checks is valid JSON array
    if ! echo "$checks" | jq -e 'type == "array"' >/dev/null 2>&1; then
        checks="[]"
    fi

    jq -n \
        --arg name "$name" \
        --arg severity "$severity" \
        --argjson hooks "$hooks_array" \
        --argjson checks "$checks" \
        --arg enabled "$enabled" \
        '{
            "name": $name,
            "created": (now | todate),
            "severity": $severity,
            "failures": 0,
            "tightening_level": 0,
            "hooks": $hooks,
            "checks": $checks,
            "enabled": ($enabled == "true")
        }'
}
```

- [ ] **Step 2: Add check builder helpers**

Append to `core/law-builder.sh`:

```bash
# Build a single check JSON object
# Usage: build_check <id> <type> <config_json> <severity> <message>
build_check() {
    local id="$1"
    local check_type="$2"
    local config_json="$3"
    local severity="${4:-warn}"
    local message="${5:-}"

    jq -n \
        --arg id "$id" \
        --arg type "$check_type" \
        --argjson config "$config_json" \
        --arg severity "$severity" \
        --arg message "$message" \
        '{
            "id": $id,
            "type": $type,
            "config": $config,
            "severity": $severity,
            "message": $message
        }'
}

# Build auto-generated verify.sh that uses check-runner
# Usage: build_verify_with_checks <law_name>
build_verify_with_checks() {
    local law_name="$1"

    cat <<VERIFYEOF
#!/bin/bash
# AUTO-GENERATED by CHP — uses atomic check runner
# Verification script for law: $law_name

LAW_DIR="\$(cd "\$(dirname "\${BASH_SOURCE[0]}")" && pwd)"
CHP_BASE="\$(cd "\$LAW_DIR/../../../../" && pwd)"

source "\$CHP_BASE/core/common.sh"
source "\$CHP_BASE/core/check-runner.sh"

run_checks "$law_name" "\${1:-pre-commit}"
exit \$?
VERIFYEOF
}
```

- [ ] **Step 3: Run tests**

Run: `bash tests/test-check-runner.sh`
Expected: All tests passed! (law-builder changes don't break existing tests)

- [ ] **Step 4: Commit**

```bash
git add core/law-builder.sh
git commit -m "feat: update law-builder for atomic check composition"
```

---

### Task 10: Update chp-law create for check-based laws

**Files:**
- Modify: `commands/chp-law`
- Modify: `core/interactive.sh`

- [ ] **Step 1: Update interactive.sh with check composition prompt**

Add a new function `display_checks_preview` to `core/interactive.sh`:

```bash
# Display a preview of checks for a law
# Usage: display_checks_preview <law_name> <checks_json>
display_checks_preview() {
    local law_name="$1"
    local checks_json="$2"

    echo ""
    echo "=================================="
    echo "  Law Preview: $law_name"
    echo "=================================="
    echo ""
    echo "  Atomic Checks:"

    local count
    count=$(echo "$checks_json" | jq 'length')

    for ((i=0; i<count; i++)); do
        local id type severity
        id=$(echo "$checks_json" | jq -r ".[$i].id")
        type=$(echo "$checks_json" | jq -r ".[$i].type")
        severity=$(echo "$checks_json" | jq -r ".[$i].severity")

        if [[ $i -eq $((count-1)) ]]; then
            echo "  └─ $type:$id [$severity]"
        else
            echo "  ├─ $type:$id [$severity]"
        fi
    done

    echo ""
}
```

- [ ] **Step 2: Update chp-law create to build checks-based laws**

In `commands/chp-law`, update the `create_law()` function. After the `mkdir -p "$law_dir"` line, replace the law.json generation block with:

```bash
    # Build checks array based on detected pattern
    local checks='[]'

    if [[ -n "$pattern" && "$pattern" != "Custom pattern" ]]; then
        # Extract a check ID from the law name
        local check_id="${law_name//-/_}"
        local check_config
        check_config=$(jq -n --arg p "$pattern" '{"pattern": $p}')

        checks=$(build_check "$check_id" "pattern" "$check_config" "$severity" "$pattern")
        checks="[$checks]"
    fi

    # Create law.json with checks
    if [[ "$checks" != "[]" ]]; then
        build_law_json_with_checks "$law_name" "$severity" "$hooks_str" "$checks" > "$law_dir/law.json"
    else
        build_law_json "$law_name" "$severity" "$hooks_str" > "$law_dir/law.json"
    fi
```

Replace the verify.sh generation block with:

```bash
    # Create verify.sh (auto-generated using check-runner)
    build_verify_with_checks "$law_name" > "$law_dir/verify.sh"
    chmod +x "$law_dir/verify.sh"
```

- [ ] **Step 3: Update chp-law list to show per-check breakdown**

Replace the `list_laws_cmd()` function:

```bash
list_laws_cmd() {
    log_info "Listing all laws..."

    local law_count=0
    for law_dir in "$LAWS_DIR"/*; do
        if [ -d "$law_dir" ]; then
            law_count=$((law_count + 1))
            local name=$(basename "$law_dir")
            local severity=$(get_law_meta "$name" "severity")
            local failures=$(get_law_meta "$name" "failures")
            local enabled=$(get_law_meta "$name" "enabled")
            local law_json="$law_dir/law.json"

            local status="enabled"
            if [[ "$enabled" == "false" ]]; then
                status="disabled"
            fi

            echo "  $name [$severity] ($status, $failures failures)"

            # Show per-check breakdown if checks exist
            if command -v jq >/dev/null 2>&1 && [[ -f "$law_json" ]]; then
                local checks_json
                checks_json=$(jq -c '.checks // []' "$law_json" 2>/dev/null)
                local check_count
                check_count=$(echo "$checks_json" | jq 'length' 2>/dev/null)

                if [[ "$check_count" -gt 0 ]]; then
                    for ((i=0; i<check_count; i++)); do
                        local cid ctype cseverity
                        cid=$(echo "$checks_json" | jq -r ".[$i].id // \"check-$i\"")
                        ctype=$(echo "$checks_json" | jq -r ".[$i].type // \"?\"")
                        cseverity=$(echo "$checks_json" | jq -r ".[$i].severity // \"warn\"")

                        if [[ $i -eq $((check_count-1)) ]]; then
                            echo "    └─ $ctype:$cid [$cseverity]"
                        else
                            echo "    ├─ $ctype:$cid [$cseverity]"
                        fi
                    done
                fi
            fi
        fi
    done

    if [[ $law_count -eq 0 ]]; then
        log_info "No laws found"
    else
        log_info "Total laws: $law_count"
    fi

    return 0
}
```

- [ ] **Step 4: Update chp-law update for per-check operations**

Add new options to the `update_law()` function's argument parsing:

```bash
            --add-check)
                # Parse check details from next argument (JSON)
                shift
                local new_check_json="$1"
                # Append to checks array
                jq --argjson check "$new_check_json" '.checks += [$check]' "$law_json" > "${law_json}.tmp" && \
                    mv "${law_json}.tmp" "$law_json"
                # Regenerate verify.sh
                build_verify_with_checks "$law_name" > "$law_dir/verify.sh"
                chmod +x "$law_dir/verify.sh"
                log_info "Added check to law: $law_name"
                updated=true
                ;;
            --check=*)
                local target_check="${1#*=}"
                ;;
            --check-severity=*)
                local target_check_severity="${1#*=}"
                ;;
```

Add check-severity update logic after the existing update application block:

```bash
    # Update individual check severity
    if [[ -n "$target_check" && -n "$target_check_severity" ]]; then
        jq --arg cid "$target_check" --arg sev "$target_check_severity" \
            '(.checks[] | select(.id == $cid)).severity = $sev' \
            "$law_json" > "${law_json}.tmp" && \
            mv "${law_json}.tmp" "$law_json"
        log_info "Updated check '$target_check' severity to: $target_check_severity"
        updated=true
    fi
```

Update the usage help to document new options:

```bash
Update Options:
    --severity=<level>         Change severity
    --hooks=<list>             Replace all hooks
    --add-hook=<hook>          Add a hook
    --remove-hook=<hook>       Remove a hook
    --add-check=<json>         Add an atomic check (JSON object)
    --check=<id> --check-severity=<level>  Update a specific check's severity
    --set-guidance             Open guidance.md for editing
```

- [ ] **Step 5: Run tests**

Run: `bash tests/test-dispatcher.sh && bash tests/test-check-runner.sh`
Expected: All tests passed!

- [ ] **Step 6: Commit**

```bash
git add commands/chp-law core/interactive.sh
git commit -m "feat: update chp-law CLI for atomic check creation and listing"
```

---

### Task 11: Migrate existing laws to checks format

**Files:**
- Modify: `docs/chp/laws/no-console-log/law.json`
- Modify: `docs/chp/laws/no-console-log/verify.sh`
- Modify: `docs/chp/laws/no-todos/law.json`
- Modify: `docs/chp/laws/no-todos/verify.sh`
- Modify: `docs/chp/laws/no-alerts/law.json`
- Modify: `docs/chp/laws/no-alerts/verify.sh`
- Modify: `docs/chp/laws/no-api-keys/law.json`
- Modify: `docs/chp/laws/no-api-keys/verify.sh`
- Modify: `docs/chp/laws/mandarin-only/law.json`
- Modify: `docs/chp/laws/mandarin-only/verify.sh`
- Modify: `docs/chp/laws/commit-metrics/law.json`
- Modify: `docs/chp/laws/commit-metrics/verify.sh`
- Modify: `docs/chp/laws/test-scope/law.json`
- Modify: `docs/chp/laws/test-scope/verify.sh`

- [ ] **Step 1: Migrate no-console-log**

Update `docs/chp/laws/no-console-log/law.json` — add `checks` array preserving existing metadata:

```json
{
  "_comment": "AUTO-GENERATED by CHP — do not edit manually. Use 'chp refine <law>' to update.",
  "name": "no-console-log",
  "created": "2026-04-25T04:05:10Z",
  "severity": "error",
  "failures": 16,
  "tightening_level": 16,
  "hooks": ["pre-commit"],
  "enabled": true,
  "checks": [
    {
      "id": "console-log",
      "type": "pattern",
      "config": {
        "pattern": "console\\.log\\("
      },
      "severity": "block",
      "message": "Use logger.info() instead of console.log()"
    }
  ]
}
```

Replace `docs/chp/laws/no-console-log/verify.sh`:

```bash
#!/bin/bash
# AUTO-GENERATED by CHP — uses atomic check runner
# Verification script for law: no-console-log

LAW_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CHP_BASE="$(cd "$LAW_DIR/../../../../" && pwd)"

source "$CHP_BASE/core/common.sh"
source "$CHP_BASE/core/check-runner.sh"

run_checks "no-console-log" "${1:-pre-commit}"
exit $?
```

- [ ] **Step 2: Migrate no-todos**

Update `docs/chp/laws/no-todos/law.json`:

```json
{
  "_comment": "AUTO-GENERATED by CHP — do not edit manually. Use 'chp refine <law>' to update.",
  "name": "no-todos",
  "created": "2026-04-25T05:35:43Z",
  "severity": "error",
  "failures": 26,
  "tightening_level": 26,
  "hooks": ["pre-commit", "pre-push", "pre-tool"],
  "enabled": true,
  "checks": [
    {
      "id": "todo-comments",
      "type": "pattern",
      "config": {
        "pattern": "(TODO|FIXME|HACK|XXX)",
        "skip_extensions": ["md", "json", "txt", "sh", "yml", "yaml", "lock", "gitignore"]
      },
      "severity": "block",
      "message": "Remove TODO/FIXME/HACK comments or reference an issue ticket"
    }
  ]
}
```

Replace `docs/chp/laws/no-todos/verify.sh`:

```bash
#!/bin/bash
# AUTO-GENERATED by CHP — uses atomic check runner
# Verification script for law: no-todos

LAW_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CHP_BASE="$(cd "$LAW_DIR/../../../../" && pwd)"

source "$CHP_BASE/core/common.sh"
source "$CHP_BASE/core/check-runner.sh"

run_checks "no-todos" "${1:-pre-commit}"
exit $?
```

- [ ] **Step 3: Migrate no-alerts**

Update `docs/chp/laws/no-alerts/law.json`:

```json
{
  "_comment": "AUTO-GENERATED by CHP — do not edit manually. Use 'chp refine <law>' to update.",
  "name": "no-alerts",
  "created": "2026-04-25T07:52:30Z",
  "severity": "warn",
  "failures": 0,
  "tightening_level": 0,
  "hooks": ["pre-commit", "pre-push"],
  "enabled": true,
  "checks": [
    {
      "id": "alert-call",
      "type": "pattern",
      "config": {
        "pattern": "alert\\("
      },
      "severity": "warn",
      "message": "Use toast notifications or modal dialogs instead of alert()"
    }
  ]
}
```

Replace `docs/chp/laws/no-alerts/verify.sh`:

```bash
#!/bin/bash
# AUTO-GENERATED by CHP — uses atomic check runner
# Verification script for law: no-alerts

LAW_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CHP_BASE="$(cd "$LAW_DIR/../../../../" && pwd)"

source "$CHP_BASE/core/common.sh"
source "$CHP_BASE/core/check-runner.sh"

run_checks "no-alerts" "${1:-pre-commit}"
exit $?
```

- [ ] **Step 4: Migrate no-api-keys**

Update `docs/chp/laws/no-api-keys/law.json`:

```json
{
  "id": "no-api-keys",
  "name": "no-api-keys",
  "intent": "Prevent API keys, tokens, and secrets from being committed",
  "severity": "error",
  "failures": 1,
  "tightening_level": 1,
  "hooks": ["pre-commit", "pre-push", "pre-tool", "post-tool"],
  "enabled": true,
  "checks": [
    {
      "id": "stripe-key",
      "type": "pattern",
      "config": {"pattern": "sk-[a-zA-Z0-9]{32,}"},
      "severity": "block",
      "message": "Stripe secret key detected — use environment variable"
    },
    {
      "id": "google-key",
      "type": "pattern",
      "config": {"pattern": "AIza[0-9A-Za-z\\-_]{35}"},
      "severity": "block",
      "message": "Google API key detected — use environment variable"
    },
    {
      "id": "aws-key",
      "type": "pattern",
      "config": {"pattern": "AKIA[0-9A-Z]{16}"},
      "severity": "block",
      "message": "AWS access key detected — use environment variable or IAM role"
    },
    {
      "id": "github-token",
      "type": "pattern",
      "config": {"pattern": "gh[pousr]_[a-zA-Z0-9]{36}"},
      "severity": "block",
      "message": "GitHub token detected — use environment variable"
    },
    {
      "id": "slack-token",
      "type": "pattern",
      "config": {"pattern": "xox[bop]-[0-9]{11,13}-[0-9]{11,13}-[a-zA-Z0-9]{24}"},
      "severity": "block",
      "message": "Slack token detected — use environment variable"
    }
  ]
}
```

Replace `docs/chp/laws/no-api-keys/verify.sh`:

```bash
#!/bin/bash
# AUTO-GENERATED by CHP — uses atomic check runner
# Verification script for law: no-api-keys

LAW_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CHP_BASE="$(cd "$LAW_DIR/../../../../" && pwd)"

source "$CHP_BASE/core/common.sh"
source "$CHP_BASE/core/check-runner.sh"

run_checks "no-api-keys" "${1:-pre-commit}"
exit $?
```

- [ ] **Step 5: Migrate mandarin-only**

Update `docs/chp/laws/mandarin-only/law.json`:

```json
{
  "id": "mandarin-only",
  "name": "mandarin-only",
  "intent": "All text output, file content, and responses must be in simplified Mandarin Chinese",
  "severity": "error",
  "failures": 8,
  "tightening_level": 8,
  "hooks": ["pre-tool"],
  "enabled": true,
  "checks": [
    {
      "id": "mandarin-context",
      "type": "agent",
      "config": {
        "prompt": "你的身份：你是一个只能使用简体中文进行交流的助手。你输出的每一个句子都必须是简体中文。代码标识符保持英文，但所有描述性文字必须是简体中文。自检：这段话是简体中文吗？如果不是，重写。"
      },
      "severity": "block",
      "message": "Content must be in simplified Mandarin Chinese"
    }
  ]
}
```

Replace `docs/chp/laws/mandarin-only/verify.sh`:

```bash
#!/bin/bash
# AUTO-GENERATED by CHP — uses atomic check runner
# Verification script for law: mandarin-only

LAW_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CHP_BASE="$(cd "$LAW_DIR/../../../../" && pwd)"

source "$CHP_BASE/core/common.sh"
source "$CHP_BASE/core/check-runner.sh"

run_checks "mandarin-only" "${1:-pre-tool}"
exit $?
```

- [ ] **Step 6: Migrate commit-metrics (no checks needed)**

Update `docs/chp/laws/commit-metrics/law.json`:

```json
{
  "_comment": "AUTO-GENERATED by CHP — do not edit manually. Use 'chp refine <law>' to update.",
  "name": "commit-metrics",
  "created": "2026-04-25T04:33:44Z",
  "severity": "info",
  "failures": 0,
  "tightening_level": 0,
  "hooks": ["post-commit"],
  "enabled": true,
  "checks": []
}
```

Leave `docs/chp/laws/commit-metrics/verify.sh` unchanged — it has custom logic that doesn't fit the check model (it collects metrics, not enforces rules).

- [ ] **Step 7: Migrate test-scope**

Update `docs/chp/laws/test-scope/law.json`:

```json
{
  "id": "test-scope",
  "name": "test-scope",
  "intent": "Test law for scope filtering - only applies to TypeScript files",
  "severity": "warn",
  "hooks": ["pre-commit"],
  "enabled": true,
  "checks": [
    {
      "id": "todo-in-ts",
      "type": "pattern",
      "config": {
        "pattern": "TODO"
      },
      "severity": "warn",
      "message": "TODO found in TypeScript file"
    }
  ]
}
```

Replace `docs/chp/laws/test-scope/verify.sh`:

```bash
#!/bin/bash
# AUTO-GENERATED by CHP — uses atomic check runner
# Verification script for law: test-scope

LAW_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CHP_BASE="$(cd "$LAW_DIR/../../../../" && pwd)"

source "$CHP_BASE/core/common.sh"
source "$CHP_BASE/core/check-runner.sh"

run_checks "test-scope" "${1:-pre-commit}"
exit $?
```

- [ ] **Step 8: Run all tests**

Run: `bash tests/test-dispatcher.sh && bash tests/test-check-runner.sh && bash tests/test-installer.sh`
Expected: All tests passed!

- [ ] **Step 9: Commit**

```bash
git add docs/chp/laws/
git commit -m "feat: migrate all existing laws to atomic checks format"
```

---

### Task 12: Update agent prompts

**Files:**
- Modify: `agents/chief.md`
- Modify: `agents/officer.md`
- Modify: `agents/detective.md`

- [ ] **Step 1: Update chief.md**

In `agents/chief.md`, add a section after "Law Creation and Registration:":

```markdown
Atomic Check Composition:

When creating laws, decompose the enforcement intent into atomic checks:
- Each check has a type: pattern (grep), threshold (metric), structural (convention), or agent (subjective)
- Each check has its own severity: block, warn, or log
- Recommend check types based on rule nature:
  - Simple pattern match → pattern type (e.g., console.log, API keys)
  - Measurable metric → threshold type (e.g., file length, complexity)
  - Code convention → structural type (e.g., test file exists, auth middleware)
  - Subjective quality → agent type (e.g., meaningful names, clear docs)
- Laws are composable: one law can contain multiple checks of different types
- Use chp-law create to build laws with checks, or chp-law update --add-check to add checks later
```

- [ ] **Step 2: Update officer.md**

In `agents/officer.md`, add a section after "Verification Execution:":

```markdown
Atomic Check Reporting:

When reporting verification results, identify the specific check that failed:
- Report the check ID, type, and severity (not just the law name)
- Example: "Law 'no-console-log' check 'console-log' (pattern, block) failed in src/app.ts"
- For agent-type checks, apply your own judgment using the check's configured prompt
- Different checks in the same law can have different severities
- A law fails overall only if any block-severity check fails; warn checks are reported but don't block

Check types you'll encounter:
- pattern: grep-based regex matching on diffs or files
- threshold: metric counting (file length, complexity, import count) vs min/max
- structural: convention assertions (test files, import rules, middleware)
- agent: subjective prompts requiring AI judgment
```

- [ ] **Step 3: Update detective.md**

In `agents/detective.md`, add a section after "Guidance Tightening:":

```markdown
Per-Check Tightening:

Tighten individual checks independently, not just whole laws:
- Track violation history per check ID (not just per law)
- Escalate severity: log → warn → block based on violation frequency for that specific check
- Adjust threshold configs: lower max or raise min for threshold-type checks
- Never tighten across check boundaries — each check tightens independently
- When a law has multiple checks, identify which specific check is being violated and tighten only that one
```

- [ ] **Step 4: Commit**

```bash
git add agents/chief.md agents/officer.md agents/detective.md
git commit -m "feat: update agent prompts for atomic check awareness"
```

---

### Task 13: Update chp:write-laws skill

**Files:**
- Modify: `.claude-plugin/plugins/chp/skills/write-laws/SKILL.md`

- [ ] **Step 1: Read current write-laws skill**

Read `.claude-plugin/plugins/chp/skills/write-laws/SKILL.md` to understand current structure.

- [ ] **Step 2: Add atomic check composition guidance**

Add a section to the skill that instructs the agent to compose laws from atomic checks. The section should cover:

- Decompose law intent into atomic checks
- Choose check types: pattern, threshold, structural, agent
- Set per-check severity levels
- Use `chp-law create` with check flags or `chp-law update --add-check`
- Auto-generated verify.sh uses `check-runner.sh`

- [ ] **Step 3: Commit**

```bash
git add .claude-plugin/plugins/chp/skills/write-laws/SKILL.md
git commit -m "feat: update write-laws skill for atomic check composition"
```

---

## Self-Review

**Spec coverage:**
- Atomic check model (checks array in law.json) → Tasks 1-5, 9
- Four checker types → Tasks 1, 3, 4, 5
- Check runner orchestrator → Task 2
- Per-check severity (block/warn/log) → Task 2
- Dispatcher per-check results → Tasks 6, 8
- Per-check violation tracking → Tasks 7, 8
- CLI create/update/list → Task 10
- Agent prompts → Task 12
- Migration → Task 11
- write-laws skill → Task 13

**Placeholder scan:** No TBDs or TODOs in the plan.

**Type consistency:** All functions use consistent names:
- `check_pattern`, `check_threshold`, `check_structural`, `check_agent` across all references
- `run_checks` used consistently in verify.sh templates and dispatcher
- `build_law_json_with_checks`, `build_check`, `build_verify_with_checks` used in law-builder and chp-law
- Check JSON fields: `id`, `type`, `config`, `severity`, `message` — consistent everywhere

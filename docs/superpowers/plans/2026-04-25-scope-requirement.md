# Required Scope Fields for CHP Laws - Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Make `include`/`exclude` scope fields required for all git-hook laws in CHP, ensuring laws declare what files they apply to.

**Architecture:** Add include/exclude to JSON schema, require them conditionally in validation for git-hook laws, update CLI to support these flags, migrate existing laws.

**Tech Stack:** Bash (core), JSON schema, jq, Node.js CLI (Commander.js)

---

## File Structure

| File | Purpose |
|------|---------|
| `docs/chp/law.schema.json` | JSON schema for law.json structure |
| `core/common.sh` | Validation logic for law.json files |
| `commands/chp-law` | CLI for creating/updating laws |
| `.claude-plugin/plugins/chp/skills/write-laws` | Agent skill for law creation |
| `docs/chp/laws/*/law.json` | Individual law metadata files |

---

## Task 1: Add include/exclude to law.schema.json

**Files:**
- Modify: `docs/chp/law.schema.json`

- [ ] **Step 1: Add include and exclude properties to schema**

Open `docs/chp/law.schema.json` and add the following properties after the `checks` property (before line 81):

```json
    "include": {
      "type": "array",
      "items": {
        "type": "string",
        "pattern": "^[^*\\s]*|\\*\\*?|\\*[^*\\s]*(\\*[^*\\s]*)*$"
      },
      "description": "Glob patterns for files this law applies to. Required for git-hook laws (pre-commit, pre-push, post-commit, commit-msg, etc.). Agent-only laws are exempt."
    },
    "exclude": {
      "type": "array",
      "items": {
        "type": "string"
      },
      "description": "Glob patterns exempt from this law. Overrides include patterns."
    }
```

The pattern validates basic glob syntax (allows `*`, `**`, and normal strings).

- [ ] **Step 2: Validate the schema is valid JSON**

Run: `jq empty docs/chp/law.schema.json`

Expected: No output (exit code 0)

- [ ] **Step 3: Commit**

```bash
git add docs/chp/law.schema.json
git commit -m "feat: add include/exclude scope fields to law.schema.json"
```

---

## Task 2: Update validate_law_json() to require scope for git-hook laws

**Files:**
- Modify: `core/common.sh`

- [ ] **Step 1: Add git hooks constant**

At the top of `core/common.sh` (around line 20, after other constants), add:

```bash
# Git hooks that require scope (have file context)
readonly _CHP_GIT_HOOKS=("pre-commit" "pre-push" "post-commit" "commit-msg" "pre-rebase" "post-checkout" "post-merge" "post-rewrite" "applypatch-msg" "pre-applypatch" "post-applypatch" "update" "pre-auto-gc" "post-update")
```

- [ ] **Step 2: Add helper function to check if hook is a git hook**

Add this function after the `validate_law_json()` function (around line 250):

```bash
# Check if a hook type is a git hook (has file context)
# Usage: is_git_hook <hook_name>
# Returns: 0 if git hook, 1 otherwise
is_git_hook() {
    local hook_name="$1"
    for git_hook in "${_CHP_GIT_HOOKS[@]}"; do
        [[ "$hook_name" == "$git_hook" ]] && return 0
    done
    return 1
}
```

- [ ] **Step 3: Add scope validation inside validate_law_json()**

Find the `validate_law_json()` function and add scope validation after the `enabled` check (around line 178, before the `# checks:` comment):

```bash
    # include/exclude: required for git-hook laws
    local hooks_array
    hooks_array=$(jq -r '.hooks[] // empty' "$law_json" 2>/dev/null)

    local has_git_hook=false
    while IFS= read -r hook; do
        [[ -n "$hook" ]] && is_git_hook "$hook" && has_git_hook=true
    done <<< "$hooks_array"

    if $has_git_hook; then
        # Git-hook laws require include field
        local include_val
        include_val=$(jq -r '.include // empty' "$law_json" 2>/dev/null)
        local include_type
        include_type=$(jq -r '.include | type' "$law_json" 2>/dev/null)

        if [[ "$include_type" != "array" ]]; then
            issues+=("include must be an array (got: $include_type) - required for git-hook laws")
        elif [[ -z "$include_val" || "$include_val" == "null" ]]; then
            issues+=("include array is empty - git-hook laws must specify what files they apply to")
        else
            local include_count
            include_count=$(jq '.include | length' "$law_json" 2>/dev/null)
            if [[ "$include_count" -eq 0 ]]; then
                issues+=("include array is empty - git-hook laws must specify at least one pattern")
            fi
        fi
    fi

    # Validate exclude if present (optional field)
    local exclude_type
    exclude_type=$(jq -r '.exclude | type' "$law_json" 2>/dev/null)
    if [[ -n "$exclude_type" && "$exclude_type" != "array" && "$exclude_type" != "null" ]]; then
        issues+=("exclude must be an array (got: $exclude_type)")
    fi
```

- [ ] **Step 4: Test the validation**

Create a temporary test file to verify validation works:

```bash
# Test: law without include on git-hook should fail
cat > /tmp/test-law-no-scope.json << 'EOF'
{
  "name": "test-law",
  "severity": "error",
  "hooks": ["pre-commit"],
  "enabled": true
}
EOF

bash -c "source core/common.sh && validate_law_json /tmp/test-law-no-scope.json 2>&1"
```

Expected: Error message about "include array is empty - required for git-hook laws"

```bash
# Test: law with include on git-hook should pass
cat > /tmp/test-law-with-scope.json << 'EOF'
{
  "name": "test-law",
  "severity": "error",
  "hooks": ["pre-commit"],
  "enabled": true,
  "include": ["**/*.js"]
}
EOF

bash -c "source core/common.sh && validate_law_json /tmp/test-law-with-scope.json 2>&1"
```

Expected: No output (exit code 0, validation passes)

```bash
# Test: agent-only law without include should pass
cat > /tmp/test-law-agent.json << 'EOF'
{
  "name": "test-agent-law",
  "severity": "error",
  "hooks": ["pre-tool"],
  "enabled": true
}
EOF

bash -c "source core/common.sh && validate_law_json /tmp/test-law-agent.json 2>&1"
```

Expected: No output (exit code 0, agent-only laws exempt)

- [ ] **Step 5: Clean up test files**

```bash
rm -f /tmp/test-law-*.json
```

- [ ] **Step 6: Commit**

```bash
git add core/common.sh
git commit -m "feat: require include/exclude scope for git-hook laws in validation"
```

---

## Task 3: Add --include and --exclude flags to chp-law create

**Files:**
- Modify: `commands/chp-law`

- [ ] **Step 1: Find the create_law function**

Open `commands/chp-law` and search for the `create_law()` function (around line 80).

- [ ] **Step 2: Add --include and --exclude argument parsing**

Find the argument parsing section in `create_law()` (around line 100-150) and add these new flags. Look for lines like:

```bash
local include_patterns=()
local exclude_patterns=()

while [[ $# -gt 0 ]]; do
    case "$1" in
        # ... existing cases ...
        --include)
            shift
            IFS=',' read -ra include_patterns <<< "$1"
            shift
            ;;
        --exclude)
            shift
            IFS=',' read -ra exclude_patterns <<< "$1"
            shift
            ;;
        *)
            log_error "Unknown option: $1"
            return 1
            ;;
    esac
done
```

Add the `--include` and `--exclude` cases to the existing case statement. Also declare the local variables at the top of the function:

```bash
local include_patterns=()
local exclude_patterns=()
```

- [ ] **Step 3: Add warning when git-hook law created without scope**

After the hooks argument parsing (around line 150-180), add:

```bash
# Check if this is a git-hook law without scope
local has_git_hook=false
local has_include=false

for hook in "${hooks[@]}"; do
    if is_git_hook "$hook"; then
        has_git_hook=true
    fi
done

if [[ ${#include_patterns[@]} -gt 0 ]]; then
    has_include=true
fi

if $has_git_hook && ! $has_include; then
    log_warn "Creating git-hook law without --include. Defaulting to ['**/*'] (all files)."
    log_warn "For better performance, specify which file types this law applies to."
    include_patterns=("**/*")
fi
```

- [ ] **Step 4: Update law.json generation to include scope fields**

Find the section where law.json is written (around line 250-300). Add the include and exclude fields to the JSON:

```bash
# Build the include array JSON
local include_json="[]"
if [[ ${#include_patterns[@]} -gt 0 ]]; then
    include_json=$(printf '%s\n' "${include_patterns[@]}" | jq -R . | jq -s .)
fi

# Build the exclude array JSON
local exclude_json="[]"
if [[ ${#exclude_patterns[@]} -gt 0 ]]; then
    exclude_json=$(printf '%s\n' "${exclude_patterns[@]}" | jq -R . | jq -s .)
fi

# Update the cat > "$law_json" command to include these fields
# Add after the "enabled" line:
cat > "$law_json" <<EOF
{
  "name": "$law_name",
  "intent": "$intent",
  "severity": "$severity",
  "hooks": $(printf '%s\n' "${hooks[@]}" | jq -R . | jq -s .),
  "enabled": $enabled,
  "include": $include_json,
  "exclude": $exclude_json,
  "checks": []
}
EOF
```

Note: The exact existing JSON structure may vary — adapt to match the existing template.

- [ ] **Step 5: Test the create command**

```bash
# Test: Create a law with explicit scope
bash commands/chp-law create test-scope-law --hooks=pre-commit --include="**/*.js,**/*.ts" --yes

# Verify the law.json has the scope
jq '.include' docs/chp/laws/test-scope-law/law.json
```

Expected: `["**/*.js", "**/*.ts"]`

```bash
# Test: Create a git-hook law without scope (should warn and default)
bash commands/chp-law create test-default-scope --hooks=pre-commit --yes

# Verify the warning appeared and include is ["**/*"]
jq '.include' docs/chp/laws/test-default-scope/law.json
```

Expected: Warning message printed, and `["**/*"]` in the JSON

```bash
# Test: Create an agent-only law without scope (should not warn)
bash commands/chp-law create test-agent-scope --hooks=pre-tool --yes
```

Expected: No warning about scope

- [ ] **Step 6: Clean up test laws**

```bash
rm -rf docs/chp/laws/test-scope-law docs/chp/laws/test-default-scope docs/chp/laws/test-agent-scope
```

- [ ] **Step 7: Commit**

```bash
git add commands/chp-law
git commit -m "feat: add --include and --exclude flags to chp-law create"
```

---

## Task 4: Add --include and --exclude flags to chp-law update

**Files:**
- Modify: `commands/chp-law`

- [ ] **Step 1: Find the update_law function**

Open `commands/chp-law` and search for the `update_law()` function (around line 700).

- [ ] **Step 2: Add --include and --exclude argument handling**

Similar to Task 3, add the flag parsing:

```bash
local new_include=()
local new_exclude=()

while [[ $# -gt 0 ]]; do
    case "$1" in
        # ... existing cases ...
        --include)
            shift
            IFS=',' read -ra new_include <<< "$1"
            shift
            ;;
        --exclude)
            shift
            IFS=',' read -ra new_exclude <<< "$1"
            shift
            ;;
        # ... rest of cases ...
    esac
done
```

- [ ] **Step 3: Update the law.json modification logic**

Find where jq updates the law.json (around line 800-850). Add scope field updates:

```bash
# Update include if provided
if [[ ${#new_include[@]} -gt 0 ]]; then
    local include_json
    include_json=$(printf '%s\n' "${new_include[@]}" | jq -R . | jq -s .)
    jq --argjson inc "$include_json" '.include = $inc' "$law_json" > "$law_json.tmp"
    mv "$law_json.tmp" "$law_json"
fi

# Update exclude if provided
if [[ ${#new_exclude[@]} -gt 0 ]]; then
    local exclude_json
    exclude_json=$(printf '%s\n' "${new_exclude[@]}" | jq -R . | jq -s .)
    jq --argjson exc "$exclude_json" '.exclude = $exc' "$law_json" > "$law_json.tmp"
    mv "$law_json.tmp" "$law_json"
fi
```

- [ ] **Step 4: Test the update command**

```bash
# First create a test law
bash commands/chp-law create test-update-scope --hooks=pre-commit --include="**/*.js" --yes

# Update the scope
bash commands/chp-law update test-update-scope --include="**/*.ts,**/*.tsx"

# Verify
jq '.include' docs/chp/laws/test-update-scope/law.json
```

Expected: `["**/*.ts", "**/*.tsx"]`

- [ ] **Step 5: Clean up**

```bash
rm -rf docs/chp/laws/test-update-scope
```

- [ ] **Step 6: Commit**

```bash
git add commands/chp-law
git commit -m "feat: add --include and --exclude flags to chp-law update"
```

---

## Task 5: Update chp:write-laws skill to prompt for scope

**Files:**
- Modify: `.claude-plugin/plugins/chp/skills/write-laws`

- [ ] **Step 1: Open the skill file**

Open `.claude-plugin/plugins/chp/skills/write-laws` (it's a markdown file).

- [ ] **Step 2: Find the "Creating a Law" section**

Search for the section that describes law creation (around line 60-100).

- [ ] **Step 3: Add scope prompting guidance**

After the hooks section, add a new subsection about scope. Find where it says "### Example: No API Keys Law" and add before it:

```markdown
### Scope Requirements

Before creating a law, determine what files it should apply to:

**For git-hook laws** (pre-commit, pre-push, post-commit, commit-msg):
- You MUST specify an `include` array with glob patterns
- Use `--include` when calling `chp-law create`
- If omitted, defaults to `["**/*"]` with a performance warning

**For agent-only laws** (pre-tool, post-tool, pre-response, post-response):
- Scope is optional — these laws don't have file context
- Omit `--include` for agent-only laws

**Common patterns:**
- JavaScript/TypeScript: `--include="**/*.js,**/*.ts,**/*.jsx,**/*.tsx"`
- All files: `--include="**/*"`
- Source only: `--include="src/**/*" --exclude="**/*.test.ts,**/*.spec.ts"`
- Python: `--include="**/*.py"`
```

- [ ] **Step 4: Update the example commands**

Find the `chp-law create` examples and add `--include` flags to git-hook examples:

```bash
# Before:
# chp-law create no-api-keys --hooks=pre-commit,pre-push

# After:
# chp-law create no-api-keys --hooks=pre-commit,pre-push --include="**/*"
```

- [ ] **Step 5: Commit**

```bash
git add .claude-plugin/plugins/chp/skills/write-laws
git commit -m "docs: add scope prompting guidance to chp:write-laws skill"
```

---

## Task 6: Migrate existing law.json files

**Files:**
- Modify: `docs/chp/laws/no-console-log/law.json`
- Modify: `docs/chp/laws/no-api-keys/law.json`
- Modify: `docs/chp/laws/no-todos/law.json`
- Modify: `docs/chp/laws/no-alerts/law.json`
- Modify: `docs/chp/laws/test-scope/law.json`

- [ ] **Step 1: Migrate no-console-log**

```bash
# Add include for JS/TS files
jq '.include = ["**/*.js", "**/*.ts", "**/*.jsx", "**/*.tsx", "**/*.mjs"] | .exclude = ["**/node_modules/**", "**/dist/**", "**/build/**"]' \
  docs/chp/laws/no-console-log/law.json > docs/chp/laws/no-console-log/law.json.tmp
mv docs/chp/laws/no-console-log/law.json.tmp docs/chp/laws/no-console-log/law.json
```

- [ ] **Step 2: Migrate no-api-keys**

```bash
# API keys can be in any file
jq '.include = ["**/*"]' \
  docs/chp/laws/no-api-keys/law.json > docs/chp/laws/no-api-keys/law.json.tmp
mv docs/chp/laws/no-api-keys/law.json.tmp docs/chp/laws/no-api-keys/law.json
```

- [ ] **Step 3: Migrate no-todos**

```bash
# Source code files only
jq '.include = ["**/*.js", "**/*.ts", "**/*.jsx", "**/*.tsx", "**/*.py", "**/*.go", "**/*.rs", "**/*.java", "**/*.c", "**/*.cpp", "**/*.h"]' \
  docs/chp/laws/no-todos/law.json > docs/chp/laws/no-todos/law.json.tmp
mv docs/chp/laws/no-todos/law.json.tmp docs/chp/laws/no-todos/law.json
```

- [ ] **Step 4: Migrate no-alerts**

```bash
# Browser JS only
jq '.include = ["**/*.js", "**/*.ts", "**/*.jsx", "**/*.tsx"]' \
  docs/chp/laws/no-alerts/law.json > docs/chp/laws/no-alerts/law.json.tmp
mv docs/chp/laws/no-alerts/law.json.tmp docs/chp/laws/no-alerts/law.json
```

- [ ] **Step 5: Migrate test-scope**

```bash
# Already TS-only, make it explicit
jq '.include = ["**/*.ts"]' \
  docs/chp/laws/test-scope/law.json > docs/chp/laws/test-scope/law.json.tmp
mv docs/chp/laws/test-scope/law.json.tmp docs/chp/laws/test-scope/law.json
```

- [ ] **Step 6: Verify all migrations pass validation**

```bash
for law in no-console-log no-api-keys no-todos no-alerts test-scope; do
    echo "Validating $law..."
    bash -c "source core/common.sh && validate_law_json docs/chp/laws/$law/law.json" || echo "FAILED: $law"
done
```

Expected: No failures, all laws validate

- [ ] **Step 7: Commit**

```bash
git add docs/chp/laws/*/law.json
git commit -m "feat: add scope include/exclude to existing laws"
```

---

## Task 7: Update CLAUDE.md documentation

**Files:**
- Modify: `CLAUDE.md`

- [ ] **Step 1: Add scope section to law creation guidance**

Find the section about creating laws in CLAUDE.md (around line 40-60) and add after the hooks description:

```markdown
### Law Scope

All git-hook laws MUST declare what files they apply to using the `include` field:

```bash
chp-law create my-law --hooks=pre-commit --include="**/*.js,**/*.ts"
```

Use `--exclude` to exempt files:

```bash
chp-law create my-law --hooks=pre-commit --include="src/**/*" --exclude="**/*.test.ts"
```

Agent-only laws (pre-tool, post-tool) don't require scope.
```

- [ ] **Step 2: Commit**

```bash
git add CLAUDE.md
git commit -m "docs: add scope requirement guidance to CLAUDE.md"
```

---

## Task 8: Final verification and cleanup

**Files:**
- Test: All modified files

- [ ] **Step 1: Run full test suite**

```bash
npm test
```

Expected: All tests pass

- [ ] **Step 2: Verify validation on all existing laws**

```bash
for law_dir in docs/chp/laws/*/; do
    law_name=$(basename "$law_dir")
    echo "Checking $law_name..."
    bash -c "source core/common.sh && validate_law_json $law_dir/law.json" || echo "FAILED: $law_name"
done
```

Expected: All laws validate successfully

- [ ] **Step 3: Test creating a new law with scope**

```bash
bash commands/chp-law create verification-test --hooks=pre-commit --include="**/*.ts" --yes
jq '.include' docs/chp/laws/verification-test/law.json
bash commands/chp-law delete verification-test
```

Expected: Law created with correct include, validation passes

- [ ] **Step 4: Verify verifier.sh still works**

```bash
# The verifier should filter files by scope before running verify.sh
# This is an integration test - verify.sh should only receive scoped files

# Create a test law with TS-only scope
bash commands/chp-law create scope-verify-test --hooks=pre-commit --include="**/*.ts" --yes

# Stage a JS file (should be filtered out by scope)
echo "console.log('test');" > /tmp/test.js
git add /tmp/test.js

# Run the verifier - it should skip this law since no TS files are staged
bash core/verifier.sh pre-commit

# Clean up
git reset /tmp/test.js
rm -f /tmp/test.js
bash commands/chp-law delete scope-verify-test
```

Expected: Verifier skips the law (no TS files in scope)

- [ ] **Step 5: Final commit if any cleanup needed**

If any adjustments were made during verification:

```bash
git add -A
git commit -m "chore: final cleanup and verification for scope requirement"
```

---

## Summary

After completing all tasks:
1. `law.schema.json` defines include/exclude fields
2. `validate_law_json()` requires include for git-hook laws
3. `chp-law` CLI supports --include/--exclude flags
4. `chp:write-laws` skill prompts for scope
5. All existing laws have appropriate scope declared
6. Documentation updated

The verifier.sh runtime already supported include/exclude, so no changes are needed there — it will automatically filter files by scope for each law.

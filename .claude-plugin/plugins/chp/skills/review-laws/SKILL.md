---
name: review-laws
description: Fix inconsistencies in CHP law packages and ensure all files are in sync. Triggers on "review laws", "fix laws", "check laws", "verify laws", "law consistency", "sync laws", "validate laws", "check law files", "are laws consistent", "law drift".
---

# CHP Law Review

Fix inconsistencies in CHP law packages across their three files: `law.json`, `verify.sh`, and `guidance.md`. Reads everything fresh from disk — zero assumptions from the writing process.

**Philosophy:** Fix it. Don't just report it. The only time to ask the user is when both options are equally valid and you genuinely can't decide.

## When to Invoke

Review should run after **most** law operations. Specifically:

- After `chp:write-laws` creates or edits a law (always)
- After `chp:decompose-laws` produces checks that get implemented (always)
- After refining an existing law — adding patterns, changing severity, adjusting hooks (always)
- After manually editing any of the three files (law.json, verify.sh, guidance.md)
- User explicitly says "review law", "fix this law", "is this law consistent?", "check the law"
- User asks "are these files in sync?", "is the law complete?"
- Before relying on an existing law for enforcement
- User suspects law files are out of sync

**When to skip:** The only time to skip review is when you've made a trivial single-file change like toggling `enabled: false` or bumping a version number — changes that can't cause cross-file drift.

## Why Review After Every Change

Any edit to one file (law.json, verify.sh, or guidance.md) risks drift with the other two:

- Adding a pattern to verify.sh without updating law.json → metadata lies about what it checks
- Updating guidance.md without syncing verify.sh → developers read rules that aren't enforced
- Changing severity in law.json without adjusting verify.sh → blocking behavior doesn't match declared severity

Review catches this immediately.

## Process

### 1. Read all three files from disk

```bash
cat docs/chp/laws/<law-name>/law.json
cat docs/chp/laws/<law-name>/verify.sh
cat docs/chp/laws/<law-name>/guidance.md
```

**No context from previous agents.** Read from disk only.

If any file is missing, create it:
- Missing `law.json`: generate from verify.sh patterns and directory name
- Missing `verify.sh`: generate from law.json violations using the closest existing law as template
- Missing `guidance.md`: generate from law.json intent, violations, and fix descriptions

### 2. Run checks and fix everything

Go through each check. Fix issues as you find them. Don't batch — fix immediately.

#### Check A: law.json schema

Required fields must exist and have valid values:

```json
{
  "id": "law-name",              // Required: matches directory name
  "intent": "What this protects", // Required: human-readable description
  "violations": [...],            // Required: non-empty array
  "reaction": "block",            // Required: one of: block, warn, auto_fix
  "hooks": ["pre-commit"],        // Required: non-empty array
  "enabled": true                 // Required: boolean
}
```

Optional fields with defaults:
- `severity`: "error" | "warn" | "info" (default: "error")
- `tags`: array of strings
- `priority`: number (default: 0)

**Fix:** Add missing fields, correct invalid values, fix `id` to match directory name.

#### Check B: law.json vs verify.sh — Patterns Sync

`violations[].pattern` in `law.json` must match what `verify.sh` actually detects.

**Common drift:**
- verify.sh checks for pattern X, but law.json doesn't list it
- law.json declares pattern Y, but verify.sh doesn't check for it
- Pattern format differs (regex escaped differently)

**Fix:** Sync the patterns — update whichever file is behind.
- If verify.sh detects more than law.json declares → update law.json
- If law.json declares more than verify.sh checks → update verify.sh

#### Check C: law.json vs verify.sh — Scope Sync

`include`/`exclude` in `law.json` must match the file filtering in `verify.sh`.

**Common drift:**
- law.json excludes `**/*.test.ts` but verify.sh doesn't filter them out
- verify.sh only checks `.ts` files but law.json has no `include` restriction

**Fix:** Add missing exclude filters to verify.sh, or add include/exclude to law.json.

#### Check D: Exit behavior matches reaction

- `reaction: "block"` → verify.sh exits non-zero on violation
- `reaction: "warn"` → verify.sh exits zero on violation (logs warning)
- `reaction: "auto_fix"` → verify.sh attempts fix and reports outcome

**Fix:** Correct the exit code in verify.sh to match the declared reaction.

#### Check E: law.json vs guidance.md

- `violations[].fix` matches the remediation advice in guidance.md
- guidance.md covers all declared violations
- guidance.md doesn't claim patterns not in the law

**Fix:** Update guidance.md to match the actual law — add missing violations, remove stale ones, align fix advice.

#### Check F: verify.sh vs guidance.md

- Detection patterns in verify.sh are documented in guidance.md
- guidance.md doesn't document patterns that verify.sh doesn't check

**Fix:** Add missing patterns to guidance.md, remove patterns that aren't actually detected.

#### Check G: Test cases (assertions)

Law must have `test-cases.json` with passing and failing examples:

```json
{
  "pass": [
    {"description": "clean code example", "code": "..."},
    {"description": "another valid pattern", "code": "..."}
  ],
  "fail": [
    {"description": "violates pattern X", "code": "...", "violation": "pattern matched"},
    {"description": "violates pattern Y", "code": "...", "violation": "pattern matched"}
  ]
}
```

**Fix:** Create or update `test-cases.json`. Use judgment for quantity based on law complexity:

- **Simple law** (single pattern, obvious): 2-3 pass, 2-3 fail
- **Moderate law** (few patterns, some edge cases): 3-5 pass, 3-5 fail
- **Complex law** (many patterns, subtle edge cases): 5+ pass, 5+ fail

Cover edge cases: boundary conditions, similar-but-valid patterns, whitespace/formatting variations.

### 3. Ask only when genuinely stuck

The only time to propose instead of fix is when you face a true ambiguity where both options are valid:

- `intent` could reasonably mean two different things — ask
- Two patterns conflict and both seem intentional — ask
- You're unsure if a pattern was removed on purpose — ask

In these cases, present the two options with your recommendation. But default to fixing.

### 4. Summary

After all fixes:

```
Fixed <law-name>:
  ✓ law.json: added missing severity field
  ✓ verify.sh: synced patterns to match law.json
  ✓ guidance.md: updated fix instructions
  ✓ test-cases.json: created with 3 pass, 3 fail cases

PASSED: 7 checks
FIXED: 4 issues
ASKED: 0 questions
```

### 5. All-laws mode

When no law name is given, fix every law in `docs/chp/laws/`. Summary table at the end:

```
Law            PASSED  FIXED  ASKED
────────────────────────────────────
no-api-keys        7      3      0
no-console-log     6      0      0
mandarin-only      5      1      1
test-scope         7      0      0
```

## Integration with Other Skills

Other CHP skills should invoke review after completing their work:

### After `chp:write-laws` (always)

Spawn a review agent:
```
Agent prompt: "Run the chp:review-laws skill for the law '<law-name>'. Read all three files fresh from disk, fix all inconsistencies, commit fixes, and report what you changed."
```

### After `chp:decompose-laws` (once checks are implemented)

Same as above — review ensures the implementation matches the decomposition.

### After refining an existing law (any edit)

Invoke chp:review-laws directly for the changed law.

## Common Issues Fixed

### Issue 1: Pattern declared but not checked

**Symptom:** law.json lists pattern, but verify.sh doesn't check for it

**Fix:** Add pattern check to verify.sh:
```bash
# Add to verify.sh
if echo "$content" | grep -qP 'PATTERN_HERE'; then
    log_error "Pattern detected: PATTERN_HERE"
    exit 1
fi
```

### Issue 2: Pattern checked but not declared

**Symptom:** verify.sh checks for pattern, but law.json doesn't list it

**Fix:** Add violation to law.json:
```json
{
  "pattern": "PATTERN_HERE",
  "fix": "How to remediate",
  "satisfies": "Pattern not present"
}
```

### Issue 3: Severity mismatch

**Symptom:** law.json says `reaction: "warn"` but verify.sh exits 1 (blocking)

**Fix:** Align exit code with reaction:
```bash
# For warn: exit 0, just log
if [[ "$reaction" == "warn" ]]; then
    log_warn "Violation detected"
    exit 0
fi
```

### Issue 4: Missing test cases

**Symptom:** No test-cases.json file

**Fix:** Create test-cases.json with realistic examples covering all patterns

### Issue 5: Guidance drift

**Symptom:** guidance.md says "don't use console.log" but law also blocks console.error

**Fix:** Update guidance.md to document all checked patterns

## Quick Reference

| Check | What It Validates |
|-------|-------------------|
| Schema | All required fields exist with valid values |
| Patterns Sync | law.json patterns match verify.sh checks |
| Scope Sync | include/exclude in law.json matches verify.sh filtering |
| Exit Behavior | verify.sh exit code matches reaction |
| Guidance Sync | guidance.md matches actual law behavior |
| Test Cases | test-cases.json exists with valid examples |

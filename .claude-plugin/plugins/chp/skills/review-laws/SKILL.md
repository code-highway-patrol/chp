---
name: review-laws
description: Fix inconsistencies in CHP law packages. Reads law.json, verify.sh, and guidance.md fresh from disk and corrects drift between them. Triggers on "review laws", "fix laws", "check laws", "verify laws".
---

# CHP Law Fixer

Fix inconsistencies in a CHP law package across its three files: `law.json`, `verify.sh`, and `guidance.md`. Reads everything fresh from disk — zero assumptions from the writing process.

**Philosophy:** Fix it. Don't just report it. The only time to ask the user is when both options are equally valid and you genuinely can't decide.

## When to Invoke

Review should run after **most** law operations. Specifically:

- After `chp:write-laws` creates or edits a law (always)
- After `chp:decompose-laws` produces checks that get implemented (always)
- After refining an existing law — adding patterns, changing severity, adjusting hooks (always)
- After manually editing any of the three files (law.json, verify.sh, guidance.md)
- User explicitly says "review law", "fix this law", "is this law consistent?"
- Before relying on an existing law for enforcement

**When to skip:** The only time to skip review is when you've made a trivial single-file change like toggling `enabled: false` or bumping a version number — changes that can't cause cross-file drift.

## Why Review After Every Change

Any edit to one file (law.json, verify.sh, or guidance.md) risks drift with the other two. Adding a pattern to verify.sh without updating law.json means the law metadata lies about what it checks. Updating guidance.md without syncing verify.sh means developers read rules that aren't enforced. Review catches this immediately.

## Process

### 1. Read all three files from disk

```bash
cat docs/chp/laws/<law-name>/law.json
cat docs/chp/laws/<law-name>/verify.sh
cat docs/chp/laws/<law-name>/guidance.md
```

No context from previous agents. Read from disk only.

If any file is missing, create it:
- Missing `law.json`: generate from `verify.sh` patterns and directory name
- Missing `verify.sh`: generate from `law.json` violations using the closest existing law as template
- Missing `guidance.md`: generate from `law.json` intent, violations, and fix descriptions

### 2. Run checks and fix everything

Go through each check. Fix issues as you find them. Don't batch — fix immediately.

#### Check A: law.json schema

- Required fields: `id`, `intent`, `violations`, `reaction`, `hooks`, `enabled`
- `reaction` is one of: `block`, `warn`, `auto_fix`
- `severity` is one of: `error`, `warn`, `info`
- `violations` array is non-empty, each entry has `pattern` and `fix`
- `id` matches the directory name

**Fix:** Add missing fields, correct invalid values, fix `id` to match directory.

#### Check B: law.json vs verify.sh — Patterns

- `violations[].pattern` in `law.json` should cover what `verify.sh` actually detects
- `verify.sh` patterns should cover what `law.json` declares
- `include`/`exclude` in `law.json` should match the file filtering in `verify.sh`

**Fix:** Sync the patterns — update whichever file is behind. If `verify.sh` detects more than `law.json` declares, update `law.json`. If `law.json` declares more than `verify.sh` checks, update `verify.sh`. Add missing exclude filters to `verify.sh` if `law.json` declares them.

#### Check C: Exit behavior

- `block` reaction → `verify.sh` exits non-zero on violation
- `warn` reaction → `verify.sh` exits zero on violation (logs warning)
- `auto_fix` reaction → `verify.sh` attempts fix and reports outcome

**Fix:** Correct the exit code in `verify.sh` to match the declared `reaction`.

#### Check D: law.json vs guidance.md

- `violations[].fix` matches the remediation advice in `guidance.md`
- `guidance.md` covers all declared violations
- `guidance.md` doesn't claim patterns not in the law

**Fix:** Update `guidance.md` to match the actual law — add missing violations, remove stale ones, align fix advice.

#### Check E: verify.sh vs guidance.md

- Detection patterns in `verify.sh` are documented in `guidance.md`
- `guidance.md` doesn't document patterns that `verify.sh` doesn't check

**Fix:** Add missing patterns to `guidance.md`, remove patterns that aren't actually detected.

#### Check F: Test cases (assertions)

- Law must have `test-cases.json` with passing and failing examples
- `pass` array: code snippets that should pass verification
- `fail` array: code snippets that should violate the law
- Test cases must be realistic and cover the patterns in `violations[]`

**Fix:** Create or update `test-cases.json`. Use judgment for quantity based on law complexity:

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

**Guidance for test case quantity:**
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
  - [list each fix: file, what changed, why]
  PASSED: N checks
  FIXED: N issues
  ASKED: N questions (awaiting your input)
```

### 5. All-laws mode

When no law name is given, fix every law in `docs/chp/laws/`. Summary table at the end:

```
Law            PASSED  FIXED  ASKED
no-api-keys        2      3      0
no-console-log     5      0      0
mandarin-only      3      1      1
```

## Integration with Other Skills

Other CHP skills should invoke review after completing their work:

**After `chp:write-laws`** (always):
```
Agent prompt: "Run the chp:review-laws skill for the law '<law-name>'. Read all three files fresh from disk, fix all inconsistencies, commit fixes, and report what you changed."
```

**After `chp:decompose-laws`** (once checks are implemented):
```
Agent prompt: "Run the chp:review-laws skill for the law '<law-name>'. Read all three files fresh from disk, fix all inconsistencies, commit fixes, and report what you changed."
```

**After refining an existing law** (any edit to law.json, verify.sh, or guidance.md):
```
Invoke chp:review-laws directly for the changed law.
```

---
name: review-law
description: Review a CHP law package for inconsistencies between law.json, verify.sh, and guidance.md. Triggers on "review law", "check law", "verify law", "law consistent", "law review".
---

# CHP Law Review

Review a CHP law package for inconsistencies across its three files: `law.json`, `verify.sh`, and `guidance.md`. Catches drift between what the law declares, what it detects, and what it documents.

## When to Invoke

Invoke this skill when:
- User says "review law", "check this law", "is this law consistent?"
- After `chp:write-laws` finishes creating or editing a law
- User wants to validate an existing law before relying on it

## Review Process

### 1. Locate the law package

The law must exist in `docs/chp/laws/<law-name>/`. If no law name is given, review all laws:

```bash
ls -d docs/chp/laws/*/
```

### 2. Read all three files from disk

Read them fresh — do not rely on any context from a previous agent or conversation:

```bash
cat docs/chp/laws/<law-name>/law.json
cat docs/chp/laws/<law-name>/verify.sh
cat docs/chp/laws/<law-name>/guidance.md
```

If any file is missing, that is an immediate finding. Report it and move on.

### 3. Run the consistency checks

For each check below, note the result as PASS, FIX (confident fix applied), or PROPOSAL (needs user decision).

#### Check A: law.json schema

- Required fields present: `id`, `intent`, `violations`, `reaction`, `hooks`, `enabled`
- `reaction` is one of: `block`, `warn`, `auto_fix`
- `severity` is one of: `error`, `warn`, `info` (if present)
- `violations` array is non-empty, each entry has `pattern` and `fix`
- `id` matches the directory name

**Confident fixes:** Missing `enabled: true`, wrong `reaction` value, `id` that doesn't match directory name.

**Proposals:** Empty `violations` array (may be intentional stub), missing optional fields like `tags` or `severity`.

#### Check B: law.json vs verify.sh — Intent alignment

- The `intent` field in `law.json` describes what `verify.sh` actually detects
- Each `violations[].pattern` in `law.json` corresponds to an actual grep/regex in `verify.sh`
- The `include`/`exclude` globs in `law.json` match the file filtering in `verify.sh`

**Confident fixes:** `law.json` `exclude` lists patterns that `verify.sh` doesn't filter (add the filter to `verify.sh`).

**Proposals:** `intent` doesn't match what `verify.sh` detects — this is a judgment call, present both readings to the user.

#### Check C: law.json vs verify.sh — Exit behavior

- If `reaction` is `block`, `verify.sh` exits non-zero on violation
- If `reaction` is `warn`, `verify.sh` exits zero even on violation (logs warning only)
- If `reaction` is `auto_fix`, `verify.sh` attempts remediation and reports outcome

**Confident fixes:** `block` reaction with exit-zero on violation (fix the exit code in `verify.sh`).

**Proposals:** `auto_fix` reaction but `verify.sh` has no remediation logic — may need a new script or a reaction change.

#### Check D: law.json vs guidance.md — Fix guidance

- Each `violations[].fix` in `law.json` aligns with the remediation advice in `guidance.md`
- `guidance.md` covers all declared violations
- `guidance.md` doesn't describe patterns not in `law.json` or `verify.sh`

**Confident fixes:** `guidance.md` mentions a pattern that was removed from the law — remove the stale section.

**Proposals:** `violations[].fix` says one thing, `guidance.md` recommends a different approach — present both to user.

#### Check E: verify.sh vs guidance.md — Pattern coverage

- The detection patterns in `verify.sh` are documented in `guidance.md`
- `guidance.md` doesn't claim detection of patterns not in `verify.sh`
- The examples in `guidance.md` (good/bad) actually trigger/pass `verify.sh`

**Confident fixes:** `guidance.md` lists a pattern that `verify.sh` doesn't check — add the pattern to both or remove from guidance.

**Proposals:** Pattern in `verify.sh` not mentioned in `guidance.md` — may be intentional (internal implementation detail), ask user.

### 4. Apply fixes and report findings

After running all checks:

1. **Apply confident fixes directly** — edit the files, explain what was changed and why
2. **List proposals** — for each ambiguous finding, present:
   - What the inconsistency is
   - Which files are affected
   - Two possible resolutions with trade-offs
   - Your recommendation
3. **Summary** — print a final count:
   ```
   Review complete for <law-name>:
     PASS: 8 checks
     FIXED: 2 issues (list them)
     PROPOSALS: 1 issue (awaiting your decision)
   ```

### 5. If reviewing all laws

When no law name is specified, repeat steps 2-4 for each law in `docs/chp/laws/`. Print a summary table at the end:

```
Law            PASS  FIXED  PROPOSALS
no-api-keys      8      2          1
no-console-log   9      0          0
mandarin-only    7      1          2
```

## Fix Rules

**Always fix without asking:**
- Missing required fields in `law.json`
- `id` doesn't match directory name
- Exit code / reaction mismatch in `verify.sh`
- Stale patterns in `guidance.md` that were removed from the law

**Always propose (never auto-fix):**
- `intent` field doesn't match detection logic
- Scope disagreement between `law.json` and `verify.sh`
- `guidance.md` recommends a different fix than `violations[].fix`
- Adding new patterns not originally intended

## Integration with write-laws

When `chp:write-laws` finishes creating or editing a law, it should spawn this skill as a background agent:

```
Use the Agent tool to spawn a background agent with this prompt:
"Run the chp:review-law skill for the law '<law-name>'. Read all three files fresh from disk, run the full consistency checklist, apply confident fixes, and report proposals."
```

This ensures the reviewer starts with zero assumptions from the writing process.

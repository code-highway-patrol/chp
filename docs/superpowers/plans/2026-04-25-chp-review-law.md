# chp:review-law Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Create a `chp:review-law` skill that cross-checks law packages (law.json, verify.sh, guidance.md) for inconsistencies, with auto-trigger after `chp:write-laws` and manual invocation via `/review-law`.

**Architecture:** A single SKILL.md file defines the review checklist and fix/propose logic. The skill reads all three files from disk and runs consistency checks across them. Confident fixes are applied directly; ambiguous issues are reported as proposals.

**Tech Stack:** Bash (existing verify.sh scripts), JSON (law.json), Markdown (guidance.md, SKILL.md)

---

## File Structure

| Action | File | Purpose |
|--------|------|---------|
| Create | `.claude-plugin/plugins/chp/skills/review-law/SKILL.md` | Skill definition with review checklist and fix logic |
| Modify | `.claude-plugin/plugins/chp/plugin.json` | Register new skill |
| Modify | `.claude-plugin/plugins/chp/skills/write-laws/SKILL.md` | Add auto-trigger step at end |

---

### Task 1: Create the review-law skill file

**Files:**
- Create: `.claude-plugin/plugins/chp/skills/review-law/SKILL.md`

- [ ] **Step 1: Create the SKILL.md file**

```markdown
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

- [ ] Required fields present: `id`, `intent`, `violations`, `reaction`, `hooks`, `enabled`
- [ ] `reaction` is one of: `block`, `warn`, `auto_fix`
- [ ] `severity` is one of: `error`, `warn`, `info` (if present)
- [ ] `violations` array is non-empty, each entry has `pattern` and `fix`
- [ ] `id` matches the directory name

**Confident fixes:** Missing `enabled: true`, wrong `reaction` value, `id` that doesn't match directory name.

**Proposals:** Empty `violations` array (may be intentional stub), missing optional fields like `tags` or `severity`.

#### Check B: law.json vs verify.sh — Intent alignment

- [ ] The `intent` field in `law.json` describes what `verify.sh` actually detects
- [ ] Each `violations[].pattern` in `law.json` corresponds to an actual grep/regex in `verify.sh`
- [ ] The `include`/`exclude` globs in `law.json` match the file filtering in `verify.sh`

**Confident fixes:** `law.json` `exclude` lists patterns that `verify.sh` doesn't filter (add the filter to `verify.sh`).

**Proposals:** `intent` doesn't match what `verify.sh` detects — this is a judgment call, present both readings to the user.

#### Check C: law.json vs verify.sh — Exit behavior

- [ ] If `reaction` is `block`, `verify.sh` exits non-zero on violation
- [ ] If `reaction` is `warn`, `verify.sh` exits zero even on violation (logs warning only)
- [ ] If `reaction` is `auto_fix`, `verify.sh` attempts remediation and reports outcome

**Confident fixes:** `block` reaction with exit-zero on violation (fix the exit code in `verify.sh`).

**Proposals:** `auto_fix` reaction but `verify.sh` has no remediation logic — may need a new script or a reaction change.

#### Check D: law.json vs guidance.md — Fix guidance

- [ ] Each `violations[].fix` in `law.json` aligns with the remediation advice in `guidance.md`
- [ ] `guidance.md` covers all declared violations
- [ ] `guidance.md` doesn't describe patterns not in `law.json` or `verify.sh`

**Confident fixes:** `guidance.md` mentions a pattern that was removed from the law — remove the stale section.

**Proposals:** `violations[].fix` says one thing, `guidance.md` recommends a different approach — present both to user.

#### Check E: verify.sh vs guidance.md — Pattern coverage

- [ ] The detection patterns in `verify.sh` are documented in `guidance.md`
- [ ] `guidance.md` doesn't claim detection of patterns not in `verify.sh`
- [ ] The examples in `guidance.md` (good/bad) actually trigger/pass `verify.sh`

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
```

- [ ] **Step 2: Verify the file was created**

Run: `cat .claude-plugin/plugins/chp/skills/review-law/SKILL.md | head -5`
Expected: Shows the frontmatter with `name: review-law`

- [ ] **Step 3: Commit**

```bash
git add .claude-plugin/plugins/chp/skills/review-law/SKILL.md
git commit -m "feat: add chp:review-law skill definition"
```

---

### Task 2: Register the skill in plugin.json

**Files:**
- Modify: `.claude-plugin/plugins/chp/plugin.json:21-25`

- [ ] **Step 1: Add the skill path to plugin.json**

In `.claude-plugin/plugins/chp/plugin.json`, add `"./skills/review-law"` to the `skills` array:

```json
{
  "name": "chp",
  "displayName": "CHP - Code Health Protocol",
  "description": "Code quality enforcement with traffic laws and automated violation detection",
  "version": "1.0.0",
  "author": {
    "name": "CHP Contributors"
  },
  "homepage": "https://github.com/yourusername/chp",
  "repository": "https://github.com/yourusername/chp",
  "license": "MIT",
  "keywords": [
    "code-quality",
    "linting",
    "enforcement",
    "traffic-laws",
    "pre-commit",
    "hooks"
  ],
  "skills": [
    "./skills/audit",
    "./skills/investigate",
    "./skills/status",
    "./skills/write-laws",
    "./skills/review-law"
  ]
}
```

- [ ] **Step 2: Verify the JSON is valid**

Run: `cat .claude-plugin/plugins/chp/plugin.json | python3 -m json.tool > /dev/null && echo "valid JSON" || echo "invalid JSON"`
Expected: `valid JSON`

- [ ] **Step 3: Commit**

```bash
git add .claude-plugin/plugins/chp/plugin.json
git commit -m "feat: register chp:review-law in plugin.json"
```

---

### Task 3: Add auto-trigger to write-laws skill

**Files:**
- Modify: `.claude-plugin/plugins/chp/skills/write-laws/SKILL.md:415-423` (end of file)

- [ ] **Step 1: Append the review trigger section to write-laws SKILL.md**

Add the following section at the end of `.claude-plugin/plugins/chp/skills/write-laws/SKILL.md`, after the "Common Law Patterns" section:

```markdown

## Post-Write Review

After creating or editing a law, spawn a review agent to cross-check the law package for inconsistencies:

```
Use the Agent tool to spawn a background agent with this prompt:
"Run the chp:review-law skill for the law '<law-name>'. Read all three files fresh from disk, run the full consistency checklist, apply confident fixes, and report proposals."
```

This runs in a separate agent context with fresh eyes — no assumptions from the writing process.
```

- [ ] **Step 2: Verify the section was added**

Run: `tail -10 .claude-plugin/plugins/chp/skills/write-laws/SKILL.md`
Expected: Shows the "Post-Write Review" section

- [ ] **Step 3: Commit**

```bash
git add .claude-plugin/plugins/chp/skills/write-laws/SKILL.md
git commit -m "feat: add review-law auto-trigger to write-laws skill"
```

# chp:review-law — Law Package Verification Skill

## Problem

When `chp:write-laws` creates or edits a law, the three files (`law.json`, `verify.sh`, `guidance.md`) can drift out of sync. The writer's context is polluted by its own assumptions — it wrote the law, so it thinks the law is correct. A separate agent with fresh eyes can catch inconsistencies the writer misses.

## Solution

A dedicated `chp:review-law` skill that reads a law package from disk and cross-checks all three files for consistency. Runs in a separate agent context with zero assumptions from the writing process.

## Inconsistency Checks

### law.json vs verify.sh
- **Intent vs detection**: Does the `intent` field describe what `verify.sh` actually detects?
- **Pattern alignment**: Do `violations[].pattern` descriptions match the actual grep/regex patterns in the script?
- **Scope consistency**: Do `include`/`exclude` globs in `law.json` match the file filtering logic in `verify.sh`?
- **Exit behavior**: Does the exit code match the declared `reaction`? A `block` reaction must exit non-zero on violation; a `warn` reaction should exit zero with logged warnings.

### law.json vs guidance.md
- **Fix guidance**: Do `violations[].fix` descriptions align with what `guidance.md` recommends?
- **Completeness**: Does `guidance.md` cover all declared violations? Does it describe patterns not in `law.json`?

### verify.sh vs guidance.md
- **Pattern coverage**: Does `guidance.md` describe patterns that `verify.sh` doesn't check, or vice versa?
- **Remediation accuracy**: Does the guidance's fix advice actually address what `verify.sh` would flag?

### law.json schema
- Required fields present: `id`, `intent`, `violations`, `reaction`, `hooks`, `enabled`
- Valid types: `reaction` is one of `block|warn|auto_fix`, `severity` is one of `error|warn|info`
- `violations` array is non-empty, each entry has `pattern` and `fix`

## Fix Behavior

- **Confident fixes** — applied directly: typos in `law.json` fields, missing required fields, exit code/reaction mismatch, trivial pattern drift
- **Ambiguous issues** — reported as proposals: intent/pattern disagreement, scope conflicts, guidance that doesn't match violations

The reviewer always reports what it found and what it changed.

## Invocation

### Auto-triggered
`chp:write-laws` spawns `chp:review-law` as a background agent after writing/editing a law. The writer passes the law name to the reviewer.

### Manual
- `/review-law <law-name>` — reviews a specific law
- `/review-law` — reviews all laws in `docs/chp/laws/`

## File Structure

```
.claude-plugin/plugins/chp/skills/review-law/
  skill.md          — skill definition, checklist, fix/propose logic
```

## Changes to Existing Code

- `chp:write-laws` skill: add a final step that spawns `chp:review-law` as a background agent for the written law
- `plugin.json`: register the new skill

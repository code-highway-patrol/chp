# Atomic Checks Design

Date: 2026-04-25

## Problem

Current CHP laws use monolithic `verify.sh` scripts with hand-rolled grep logic. This limits laws to simple pattern matching, makes enforcement all-or-nothing (no per-check severity), and doesn't support subjective or structural rules. Each law is a single check — there's no way to compose multiple concerns into one law.

## Solution

Laws become collections of **atomic checks** declared in `law.json`. Each check has a type, config, severity, and message. A shared set of type-specific checkers in `core/checkers/` handles execution. The verify.sh for each law is auto-generated.

## Atomic Check Model

Each check in a law's `checks` array:

```json
{
  "id": "no-console-log",
  "type": "pattern",
  "config": { "pattern": "console\\.log\\(" },
  "severity": "block",
  "message": "Use logger.info() instead of console.log()"
}
```

### Check Types

| Type | Config fields | What it does |
|------|--------------|--------------|
| `pattern` | `pattern` (regex) | Grep for a regex in staged diff |
| `threshold` | `metric`, `max` (or `min`) | Count something, compare to threshold |
| `structural` | `assert` (named assertion) | Convention check (test file exists, import rules, etc.) |
| `agent` | `prompt` (question for the agent) | Subjective check — agent prompt tells the AI how to judge |

### Severity Levels

- `block` — commit rejected
- `warn` — logged but passes
- `log` — silent tracking only

## Checker Implementations

Location: `core/checkers/<type>.sh`

Interface: `check_<type> <hook_type> <config_json> <context_file>`

Returns: `PASS`, `FAIL:<message>`, or `SKIP`.

### `pattern.sh`

Replaces all current verify.sh grep logic. Reads `pattern` from config, runs against staged diff or target file. Handles file filtering centrally (skip binaries, config, node_modules). All existing pattern-based laws collapse into this checker with different configs.

### `threshold.sh`

Counts a metric and compares. Supported `metric` values: `function_line_count`, `file_line_count`, `nesting_depth`, `import_count`. Returns FAIL when value exceeds `max` or falls below `min`. Works on staged diffs — only checks changed functions/files.

### `structural.sh`

Convention assertions. `assert` values: `test_file_exists`, `no_circular_imports`, `auth_middleware_present`. Each assertion is a named function inside the checker. New assertions are new functions.

### `agent.sh`

Subjective checks for AI judgment. Reads `prompt` from config (e.g., "Are these variable names meaningful?"). Outputs a structured prompt section included in the agent's context. The agent reasons about it during hook execution. Returns SKIP in non-agent contexts (pure git hooks can't judge subjectively).

## Law Lifecycle

### Create

`chp-law create` prompts for law intent, then helps compose atomic checks. Each check gets a type, config, severity. The verify.sh is auto-generated.

```
$ chp-law create no-long-functions

Law name: no-long-functions
Intent: Prevent oversized functions

Add a check:
  Type: threshold
  Metric: function_line_count
  Max: 50
  Severity: warn
  Message: Function exceeds 50 lines — consider splitting

✓ Created docs/chp/laws/no-long-functions/ with 1 check
✓ Generated verify.sh
```

### Verify

Auto-generated verify.sh reads `checks` from law.json, dispatches each to `core/checkers/<type>.sh` (where `<type>` matches the check's `type` field — e.g., `pattern` → `core/checkers/pattern.sh`), collects results. If any `block`-severity check fails, exit 1. Each checker must exist in `core/checkers/` or the check returns SKIP with a warning to stderr.

### Violate

Dispatcher logs per-check failures. Citation log gains a `check_id` field:

```json
{
  "law": "no-console-log",
  "check_id": "pattern-console-log",
  "severity": "block",
  "file": "src/app.ts",
  "line": 42,
  "timestamp": "2026-04-25T10:00:00Z"
}
```

### Tighten

Detective can escalate a check's severity (log → warn → block) based on violation history, and adjust thresholds independently per check. Tightener tracks per-check violation counts.

### Update

`chp-law update` supports:

- `--add-check` — interactive check builder
- `--check <id> --severity <level>` — escalate specific check
- `--check <id> --config.<key> <value>` — adjust check config (e.g., threshold values)

### List

`chp-law list` shows per-check breakdown:

```
no-console-log [block]
  ├─ pattern:console\.log\(\)     [block]
  └─ pattern:console\.debug\(\)   [warn]

no-long-functions [warn]
  └─ threshold:func_length>50     [warn]
```

## Surface Area

| Layer | Change |
|-------|--------|
| `law.json` schema | New `checks` array |
| `core/checkers/` | New directory: `pattern.sh`, `threshold.sh`, `structural.sh`, `agent.sh` |
| `verify.sh` | Auto-generated orchestrator per law |
| `core/dispatcher.sh` | Per-check severity, per-check result reporting |
| `core/tightener.sh` | Per-check violation tracking and escalation |
| `commands/` | `chp-law create` and `chp-law update` accept check flags |
| `agents/chief.md` | Compose laws from atomic checks, recommend check types |
| `agents/officer.md` | Report per-check results, apply judgment for agent-type checks |
| `agents/detective.md` | Tighten individual checks, escalate per check |
| `chp:write-laws` skill | Guide atomic check composition |
| Existing laws | All migrated to `checks` format |

## Agent Prompt Changes

### Chief

- Understands check types and how to compose them
- Decomposes law intent into atomic checks
- Recommends check types based on rule nature (subjective → agent, measurable → threshold, convention → structural)

### Officer

- Reports which specific check failed (not just law name)
- Explains what each check type does and why it flagged
- For agent-type checks, applies own judgment using check's prompt

### Detective

- Tightens individual checks independently
- Escalates severity (warn → block) per check based on violation frequency
- Adjusts threshold configs per check
- Tracks tightening history per check ID

## Migration

All existing laws migrate to the `checks` format. Their current verify.sh logic moves into checker configs. The migration is mechanical — each grep pattern becomes a `pattern`-type check.

Example migration for `no-console-log`:

Before (verify.sh):
```bash
if echo "$DIFF" | grep -qE "console\.log\("; then
  echo "BLOCKED: console.log found"
  exit 1
fi
```

After (law.json):
```json
{
  "checks": [
    {
      "id": "console-log",
      "type": "pattern",
      "config": { "pattern": "console\\.log\\(" },
      "severity": "block",
      "message": "Use logger.info() instead of console.log()"
    }
  ]
}
```

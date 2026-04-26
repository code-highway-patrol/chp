---
name: write-laws
description: Create new CHP laws, brainstorm enforcement ideas, propose rules to add, or tune existing laws. Triggers on "new law", "create law", "write law", "add law", "make a law", "add rule", "create rule", "enforce", "enforce this", "law for this", "rule for this", "come up with laws", "what should we enforce", "create a check", "add a check", "make a rule", "prevent this", "block this", "need a law", "add constraint", "create enforcement".
---

# CHP Law Management

Create new laws and refine existing ones. CHP provides two layers of enforcement:

1. **Suggestive Layer** - Context documents that guide you to follow rules
2. **Verification Layer** - Programmatic checks that catch violations

## Setup (First Time Only)

Before creating laws, ensure hooks are installed:

```bash
# Check if hooks are installed
bash commands/chp-hooks list

# If no hooks are installed, install them
bash commands/chp-hooks install
```

**Auto-install:** When using this skill, hooks will be auto-installed if not present.

## Decompose Before Writing

Before creating a law, assess whether the user's request is clear enough to implement directly:

**Clear and specific** — proceed to Creating a Law below. Examples:
- "no console.log" → single pattern, obvious check
- "no API keys" → well-known patterns, existing templates

**Vague but tractable** — invoke `chp:decompose-laws` first. Examples:
- "no secrets" → could mean API keys, passwords, private keys, tokens...
- "code quality for payments" → what aspects? complexity? coverage? style?
- "GDPR compliance" → multi-faceted, needs decomposition into atomic checks

**When in doubt, decompose.** It's faster to decompose and discard unnecessary checks than to write a law that misses cases.

To decompose:
```
Invoke the chp:decompose-laws skill with the user's concept.
After decomposition is approved, continue to "Check Marketplace Before Writing".
```

## Check Marketplace Before Writing

After decomposing the law into atomic checks (or for clear, specific requests), check if a similar law exists on the marketplace before writing from scratch.

**Query the marketplace:**
```bash
# Search by key terms from the decomposed checks
chp search "console"
chp search "api keys"
chp search "security"
```

**If similar laws are found:**

Present the results to the user and ask what they'd like to do:

> "I found similar laws on the marketplace:
>
> - **No Console Logging** (no-console-log) ★ 42 — Prevents console.log in production code
> - **No Debug Statements** (no-debug) ★ 15 — Blocks console.debug, console.error in non-error contexts
>
> What would you like to do?
> 1. Use a marketplace law instead
> 2. Write a custom law
> 3. Show details of the marketplace law first"

**User response handling:**

- **"Use marketplace law"** → Invoke `chp:marketplace` skill to install the chosen law
- **"Write custom law"** → Proceed to "Creating a Law" below
- **"Show details"** → Display the marketplace law's full description and tags, then re-ask

**If no similar laws found:**

Proceed directly to "Creating a Law" below.

## Creating a Law

When you need to enforce a rule or standard in the repository, use the `chp-law` CLI:

```bash
# Interactive mode (will prompt for confirmation)
bash commands/chp-law create <law-name> --hooks=pre-commit,pre-push

# Non-interactive mode (for agents/automation)
bash commands/chp-law create <law-name> --hooks=pre-commit,pre-push --yes
```

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

### Example: No API Keys Law

```bash
# Create the law
chp-law create no-api-keys --hooks=pre-commit,pre-push --include="**/*"

# This creates:
# - docs/chp/laws/no-api-keys/law.json (metadata)
# - docs/chp/laws/no-api-keys/verify.sh (verification script)
# - docs/chp/no-api-keys.md (suggestive context)
```

### Law Schema

A law file contains the following fields:

**Required Fields:**
- `id` - Unique identifier for the law
- `intent` - High-level description of what the law protects
- `violations` - Array of violation patterns with `pattern`, `fix`, and `satisfies`
- `reaction` - How to respond: `"block"`, `"warn"`, or `"auto_fix"`

**Scope Control:**
- `include` - Glob patterns of files/directories this law applies to (empty = all files)
- `exclude` - Glob patterns to exempt from this law (overrides include)

**Metadata:**
- `tags` - Categories for organizing/filtering laws (e.g., `["security", "secrets"]`)
- `priority` - Higher priority wins when multiple laws conflict (default: 0)
- `author` - Law owner/team
- `documentation` - URL or path to extended documentation
- `version` - Semantic version for tracking law evolution

**Lifecycle:**
- `createdAt` - ISO 8601 timestamp when law was created
- `updatedAt` - ISO 8601 timestamp when law was last updated
- `expiresAt` - ISO 8601 timestamp for temporary laws
- `enabled` - Quick disable without deleting (default: true)

**Conditions:**
- `environment` - Environments where law applies (e.g., `["production", "staging"]`)
- `dependsOn` - Other law IDs that must be satisfied first

**Enforcement:**
- `severity` - Severity level: `"error"`, `"warn"`, or `"info"`
- `hooks` - Array of hooks that trigger this law

### Example Law with Scope Control

```json
{
  "id": "no-api-keys",
  "name": "no-api-keys",
  "intent": "Prevent API keys from being committed to the repository",
  "violations": [
    {
      "pattern": "fileContains(/sk_|AIza|AKIA/, content)",
      "fix": "Remove API key and use environment variable",
      "satisfies": "!fileContains(/sk_|AIza|AKIA/, content)"
    }
  ],
  "reaction": "block",
  "include": ["**/*.ts", "**/*.js", "**/*.json"],
  "exclude": ["**/examples/**", "**/*.example.json"],
  "tags": ["security", "secrets"],
  "priority": 100,
  "author": "security-team",
  "documentation": "/docs/security/api-key-handling.md",
  "version": "1.2.0",
  "environment": ["production", "staging"],
  "enabled": true,
  "hooks": ["pre-commit", "pre-push", "pre-tool"],
  "severity": "error"
}
```

## Composing Laws from Atomic Checks

CHP laws are composed of **atomic checks** — individual verifiable units that each check one specific thing. Each check has a type, configuration, severity level, and failure message. Checks are declared in `law.json` and executed by shared checker scripts in `core/checkers/`.

### Decompose Law Intent into Atomic Checks

When creating a law, break down what the user wants into individual verifiable units. Each unit should check ONE thing.

**Example: "No console logging in production code"**

Decompose into:
1. No `console.log()` — block
2. No `console.debug()` — warn
3. No `console.error()` in non-error-handling contexts — warn

Each becomes a separate check with its own severity.

### Choose Check Types

| Type | When to use | Config fields | Example |
|------|-------------|---------------|---------|
| `pattern` | String/pattern matching (secrets, debug statements, keywords) | `pattern` (regex) | `"pattern": "console\\.log\\("` |
| `threshold` | Measurable limits (file size, function length, complexity) | `metric`, `max`/`min` | `"metric": "function_line_count", "max": 50` |
| `structural` | Convention checks (test files exist, import rules, auth middleware) | `assert` (named assertion) | `"assert": "test_file_exists"` |
| `agent` | Subjective judgment (meaningful names, clear intent, good abstractions) | `prompt` (question for AI) | `"prompt": "Are these variable names meaningful?"` |

**Choosing the right type:**
- If you can grep for it → `pattern`
- If you can count it → `threshold`
- If it's a convention → `structural`
- If it requires judgment → `agent`

### Set Per-Check Severity Levels

Each check has its own severity:

- `block` — commit rejected, operation blocked
- `warn` — logged but passes (counts toward tightening)
- `log` — silent tracking only

**Example mix:**
```json
{
  "checks": [
    {
      "id": "no-console-log",
      "type": "pattern",
      "config": { "pattern": "console\\.log\\(" },
      "severity": "block",
      "message": "Use logger.info() instead of console.log()"
    },
    {
      "id": "no-console-debug",
      "type": "pattern",
      "config": { "pattern": "console\\.debug\\(" },
      "severity": "warn",
      "message": "Prefer logger.debug() over console.debug()"
    }
  ]
}
```

### Create Laws with Checks

**Using `chp-law create` with check flags:**

```bash
# Create a law with a single check
chp-law create no-console-log \
  --hooks=pre-commit,pre-push \
  --check-type=pattern \
  --check-pattern="console\.log\(" \
  --check-severity=block \
  --check-message="Use logger.info() instead"

# Create a law with multiple checks (call multiple times)
chp-law create no-logging \
  --hooks=pre-commit,pre-push \
  --check-type=pattern --check-pattern="console\.log\(" --check-severity=block \
  --check-type=pattern --check-pattern="console\.debug\(" --check-severity=warn
```

**Add checks to existing laws:**

```bash
# Add another check to an existing law
chp-law update no-console-log \
  --add-check \
  --check-type=pattern \
  --check-pattern="console\.error\(" \
  --check-severity=warn
```

**Update individual check properties:**

```bash
# Escalate a check from warn to block
chp-law update no-console-log \
  --check=no-console-debug \
  --severity=block

# Adjust a threshold
chp-law update no-long-functions \
  --check=function-length \
  --config.max=60
```

### Auto-Generated verify.sh

When you create or update a law with checks, the `verify.sh` script is **auto-generated**. You do NOT write verify.sh manually anymore.

The auto-generated verify.sh:
1. Reads the `checks` array from `law.json`
2. Dispatches each check to `core/checkers/<type>.sh`
3. Collects results and exits 1 if any `block`-severity check fails

**Example auto-generated verify.sh structure:**
```bash
#!/bin/bash
source "$(dirname "$0")/../../../core/check-runner.sh"

run_checks "$LAW_NAME" "$HOOK_TYPE" "$@"
```

The `check-runner.sh` script handles all check execution. You only need to:
1. Declare checks in `law.json`
2. Use `chp-law create` or `chp-law update` to add them

### Available Checkers

Located in `core/checkers/`:

- `pattern.sh` — Regex matching against staged diff or files
- `threshold.sh` — Metric counting and comparison
- `structural.sh` — Convention assertions
- `agent.sh` — Subjective AI judgment

Each checker implements the interface: `check_<type> <hook_type> <config_json> <context>`

### Implementing the Verification

> **NOTE: With atomic checks, verify.sh is auto-generated. You do NOT write it manually.**
> However, you MUST still follow the Research-First Protocol below when designing checks.

#### Research-First Protocol

Before writing a single line of verify.sh, you MUST complete these steps **in this exact order**.

---

**Step 1: Read `docs/chp/LAW-PATTERNS.md`.**

This file contains ready-made templates organized by detection type. You must read the relevant section before writing anything.

| If the law involves... | Read this section | Lines to jump to |
|------------------------|-------------------|-------------------|
| String matching (secrets, debug statements, keywords) | Section 1: Regex/Shell | `docs/chp/LAW-PATTERNS.md` line 27 |
| Code structure (nesting, complexity, unused imports) | Section 2: AST-Based | `docs/chp/LAW-PATTERNS.md` line 252 |
| Existing tools (ESLint, Prettier, Semgrep, tsc) | Section 3: Delegated Tools | `docs/chp/LAW-PATTERNS.md` line 416 |
| Context-aware rules (allow in tests, conditional enforcement) | Section 4: Hybrid Patterns | `docs/chp/LAW-PATTERNS.md` line 539 |

If you find a matching template, stop here — use it. Do not write your own logic when a tested template exists.

---

**Step 2: Read existing laws for prior art.**

Run this to see what already exists:
```bash
bash commands/chp-law list
```

Then read the closest match. Here are the current production laws you can learn from:

| Law | What it demonstrates | File to read |
|-----|----------------------|-------------|
| `no-api-keys` | Multi-pattern regex, git staged + pre-tool contexts, temp file handling | `docs/chp/laws/no-api-keys/verify.sh` |
| `no-console-log` | Git diff filtering, file type exclusion, violation reporting | `docs/chp/laws/no-console-log/verify.sh` |

If a similar law exists, copy its structure. Change only the detection patterns — not the boilerplate around them.

---

**Step 3: Check for overlap with existing laws.**

Before implementing, grep the proposed detection patterns against all existing `verify.sh` scripts. If an existing law already checks for the same pattern, surface it to the user and ask whether to proceed.

Run this for each proposed pattern:
```bash
grep -rn 'PROPOSED_PATTERN' docs/chp/laws/*/verify.sh
```

Also check `law.json` intent fields for semantic overlap:
```bash
jq -r '.intent' docs/chp/laws/*/law.json 2>/dev/null
```

**If overlap is found:**

Present the overlapping law(s) to the user before continuing:
> "This looks similar to the existing law `no-console-log`, which already checks for `console\.log`. Do you want to:
> 1. Extend the existing law with additional patterns
> 2. Create a separate law anyway"

Wait for the user's decision. If they choose to extend, switch to [Refining Existing Laws](#refining-existing-laws). If they confirm the new law is different, proceed.

**If no overlap:** move to Step 4.

---

**Step 4: Research the detection method.**

This step is only needed if Steps 1 and 2 did not give you a working approach. If you are unsure about regex patterns, encoding, tool flags, or AST queries — you must research before implementing.

**For regex/encoding questions**, test against real input:
```bash
# Test if a regex actually matches what you think it does
echo "sample text HERE" | grep -P 'YOUR_REGEX'

# For Unicode ranges (Chinese, emoji, RTL), use perl — grep -P Unicode support varies by platform
echo "中文内容" | perl -ne 'while (/[\x{4e00}-\x{9fff}]/g) { print "$&\n" }'

# Check what tools are available before depending on them
which perl jq grep sed 2>/dev/null
```

**For tool delegation questions**, check what's installed:
```bash
# Does this project have ESLint/Prettier/TypeScript?
ls -1 package.json .eslintrc* .prettierrc* tsconfig.json 2>/dev/null

# What ESLint rules are available?
npx eslint --print-config src/index.ts 2>/dev/null | jq '.rules | keys'
```

**You are FORBIDDEN from guessing at:**
- Regex patterns for things you haven't tested
- Unicode character ranges
- Tool CLI flags you haven't verified
- File paths or extensions that might not exist

When in doubt, use a delegated tool (ESLint, Semgrep, tsc) instead of hand-rolling detection.

---

**Step 5: Confirm before writing.**

You must be able to answer YES to all five:

1. Did you read the relevant section of `docs/chp/LAW-PATTERNS.md`? (or confirm no section matches)
2. Did you check existing laws with `bash commands/chp-law list`? (or confirm no similar law exists)
3. Did you grep proposed patterns against existing `verify.sh` scripts? (or user confirmed overlap is acceptable)
4. Are you confident your detection method works? (or did you test it in Step 4)
5. Can you explain WHY your detection method works — not just what it does?

If any answer is NO — go back. Do not write verify.sh yet.

If you cannot reach confidence after research, ask the user for guidance. Shipping a broken check is worse than shipping no check.

---

#### Now implement

After completing the Research-First Protocol, read the law's generated verify.sh template:
```bash
cat docs/chp/laws/<law-name>/verify.sh
```

Then edit it. Use the structure from the closest existing law (Step 2) and the patterns from LAW-PATTERNS.md (Step 1). You should have already confirmed no overlap in Step 3. Do not write from a blank page — always start from a template or existing law.

### Writing the Guidance

Edit the `.md` file to provide context:

```markdown
# Law: No API Keys

**Severity:** Error
**Action:** Blocks commits and pushes

## What this means
Never commit API keys, tokens, or secrets to this repository.

## How to comply
- Use environment variables
- Use `.env` files (already gitignored)
- Use secret management services

## Detection
Scans for patterns: `sk_`, `AIza`, `AKIA`, `Bearer eyJ`
```

## Scope Control Examples

**Apply only to TypeScript files:**
```json
"include": ["**/*.ts"]
```

**Apply to all files except test files:**
```json
"exclude": ["**/*.test.ts", "**/*.spec.ts", "**/test/**"]
```

**Apply to source files only (not build artifacts):**
```json
"include": ["src/**/*"],
"exclude": ["dist/**", "build/**", "**/*.min.js"]
```

**Apply to specific directories:**
```json
"include": ["lib/**/*", "components/**/*"]
```

## Testing Your Law

Before the law is active, you MUST test it:

```bash
# Test the verification script directly with sample input
echo "test content with VIOLATION_PATTERN" | bash docs/chp/laws/<law-name>/verify.sh
# Expected: exit 1 (violation detected)

echo "clean content without violations" | bash docs/chp/laws/<law-name>/verify.sh
# Expected: exit 0 (passes)

# Then test via CHP
chp-law test <law-name>
```

**Both must pass.** If the direct test fails, the detection logic is wrong — go back to research. Do NOT proceed with a law that can't detect its own violation pattern.

## Refining Existing Laws

When a law has false positives, needs new patterns, or requires other adjustments:

### Reduce False Positives

A law flags things that shouldn't be violations. Example: `no-console-log` flags `console.error` which you need.

Edit `verify.sh` to exclude the pattern:

```bash
# Before: grep -q 'console\.log'
# After:  grep -q 'console\.log' | grep -v 'console\.error'
```

Test: `./commands/chp-law test no-console-log`

### Change Severity

Edit `law.json`:

```json
// Before: "severity": "error"
// After:  "severity": "warn"
```

Test: `./commands/chp-law test <law-name>`

### Add New Violation Patterns

Edit `verify.sh` to add patterns:

```bash
# Add Bearer token detection to no-api-keys
patterns+=("Bearer [A-Za-z0-9\\-._~+/]+=*")
```

Test: `./commands/chp-law test <law-name>`

### Adjust Hooks

A law runs at the wrong time. Example: `test-coverage` should run on `pre-push`, not `pre-commit`.

Edit `law.json`:

```json
// Before: "hooks": ["pre-commit"]
// After:  "hooks": ["pre-push"]
```

Then reinstall hooks:
```bash
./commands/chp-hooks disable pre-commit
./commands/chp-hooks enable pre-push
```

### Update Guidance

When documentation doesn't match behavior, edit `guidance.md` to keep it accurate.

### Reset Failure Count

When past issues are resolved and you want a clean slate:

```bash
./commands/chp-law reset <law-name>
```

### Disable vs Delete

**Disable temporarily:** `./commands/chp-law disable <law-name>` — law stays, just stops enforcing. Re-enable with `./commands/chp-law enable <law-name>`.

**Delete permanently:** `./commands/chp-law delete <law-name>` — removes the law directory and unregisters it from all hooks.

### Before Refining

1. Understand why the law exists — read the full guidance
2. Consider the impact — changes affect everyone
3. Document the change in `guidance.md` with rationale
4. Always test after refining: `./commands/chp-law test <law-name>`

## Available Commands

```bash
chp-law create <name> [--hooks=<list>]  # Create new law
chp-law list                            # List all laws
chp-law delete <name>                   # Delete a law
chp-law test <name>                     # Test verification
chp-law reset <name>                    # Reset failure count
chp-law enable <name>                   # Enable a disabled law
chp-law disable <name>                  # Disable without deleting
chp-status                               # Show system status
```

## Hook Types

CHP supports 25+ hook types across Git, AI/Agent, and CI/CD operations:

**Git Hooks (15):** pre-commit, post-commit, pre-push, post-merge, commit-msg, prepare-commit-msg, pre-rebase, post-checkout, post-rewrite, applypatch-msg, pre-applypatch, post-applypatch, update, pre-auto-gc, post-update

**AI/Agent Hooks (6):** pre-prompt, post-prompt, pre-tool, post-tool, pre-response, post-response

**CI/CD Hooks (4):** pre-build, post-build, pre-deploy, post-deploy

Use `chp-hooks detect` to see available hooks and `chp-hooks list` to see installed hooks.

## Auto-Tightening

When a law's verification fails:
1. The operation is blocked
2. Failure count increments
3. Guidance is automatically strengthened with violation history
4. Future attempts get stricter context

## Pattern Reference

Comprehensive pattern library at `docs/chp/LAW-PATTERNS.md`.

When users describe what they want to enforce, match their language to patterns and ask "you mean something like this?"

| User Request | Detection Method | Template |
|--------------|------------------|----------|
| "no API keys" | Regex | `sk_\|AIza\|AKIA` |
| "no console.log" | Regex | `console\.log` |
| "too nested" | AST | Nesting depth check |
| "enforce style" | Delegated | ESLint/Prettier |
| "console in tests only" | Hybrid | Regex + file path |

**Before writing custom verify.sh:**
1. Check `docs/chp/LAW-PATTERNS.md` for existing patterns
2. Match user's request to a pattern
3. Use the provided template
4. Adapt to specific requirements

**For the complete agent flow:**
- See `docs/chp/AGENT-FLOW.md` for step-by-step walkthroughs

## Common Law Patterns

**Security:** no-api-keys, no-hardcoded-credentials, no-debug-endpoints
**Quality:** max-file-size, max-function-length, required-documentation
**Style:** no-console-log, import-ordering, type-annotations

## Post-Write Review

After creating, editing, or refining a law, **always** spawn a review agent:

```
Use the Agent tool to spawn a background agent with this prompt:
"Run the chp:review-laws skill for the law '<law-name>'. Read all three files fresh from disk, fix all inconsistencies, commit fixes, and report what you changed."
```

This runs in a separate agent context with fresh eyes — no assumptions from the writing process. Review catches drift between law.json, verify.sh, and guidance.md that the writer (you) cannot see because you made the changes.

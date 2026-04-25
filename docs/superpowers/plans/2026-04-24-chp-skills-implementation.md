# CHP Skills Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Create 5 missing CHP skills that educate agents on when to use the CHP CLI based on scenarios

**Architecture:** Each skill is a markdown file with frontmatter that maps trigger scenarios to CLI commands. Skills follow the existing pattern of `write-laws` and `scan-repo` - documentation only, no executable code.

**Tech Stack:** Markdown files in `skills/` directory

---

## File Structure

```
skills/
├── investigate/
│   └── skill.md          # NEW - Debug blocked actions
├── audit/
│   └── skill.md          # NEW - Scan codebase for violations
├── plan-check/
│   └── skill.md          # NEW - Preview laws before implementing
├── refine-laws/
│   └── skill.md          # NEW - Tune existing laws
└── onboard/
    └── skill.md          # NEW - Understand project guardrails
```

---

### Task 1: Create `chp:investigate` skill

**Files:**
- Create: `skills/investigate/skill.md`

- [ ] **Step 1: Create the investigate skill directory and file**

```bash
mkdir -p skills/investigate
```

- [ ] **Step 2: Write the investigate skill markdown**

Create `skills/investigate/skill.md`:

```markdown
---
name: investigate
description: Debug why an action was blocked by CHP and understand violation history
---

# CHP Investigation

Debug why an action was blocked by CHP and understand what went wrong.

## When to Invoke

Invoke this skill when:
- A git hook failed with a CHP violation
- A CI/CD pipeline failed
- A tool call was blocked
- You see an error message mentioning "CHP violation"
- You ask "why did this fail?" or "what law blocked this?"

## Investigation Process

### 1. Identify the Blocking Law

Check the error output for the law name. It usually appears as:
```
❌ Error: CHP law <law-name> violated
```
or
```
Verification failed for law: <law-name>
```

### 2. Run Audit on the Law

Use the `chp-audit` command to see the full violation history:

```bash
./commands/chp-audit <law-name>
```

This shows:
- Total violation count
- Tightening level (how strict the law has become)
- Historical violation timestamps

### 3. Read the Law's Guidance

Understand what the law is checking:

```bash
cat docs/chp/laws/<law-name>/guidance.md
```

The guidance document explains:
- What the law checks for
- Good vs bad practice examples
- How to remediate violations

### 4. Understand the Fix

Check the verification script to see what triggered:

```bash
cat docs/chp/laws/<law-name>/verify.sh
```

Look for the `log_error` messages - these explain what pattern was detected.

### 5. Fix and Retest

After making changes:

```bash
# Test the specific law
./commands/chp-law test <law-name>

# Or retry the original action that failed
git commit  # if pre-commit failed
```

## Example

```
Scenario: You try to commit and get blocked
Error: "❌ API key detected in staged files"

1. Identify law: no-api-keys
2. Run audit: ./commands/chp-audit no-api-keys
3. Read guidance: cat docs/chp/laws/no-api-keys/guidance.md
4. Fix: Move API key to .env, add to .gitignore
5. Test: ./commands/chp-law test no-api-keys
6. Retry: git commit
```

## Common Issues

**"Law not found"** - The law name in the error might be different. Run `./commands/chp-law list` to see all laws.

**"Verification passes but commit still fails"** - There might be multiple laws blocking. Check each one.

**"This is a false positive"** - Use `chp:refine-laws` to adjust the law's verification logic.
```

- [ ] **Step 3: Verify the file was created correctly**

```bash
cat skills/investigate/skill.md
```

Expected: Output shows the skill markdown content

- [ ] **Step 4: Commit**

```bash
git add skills/investigate/
git commit -m "feat: add chp:investigate skill for debugging blocked actions"
```

---

### Task 2: Create `chp:audit` skill

**Files:**
- Create: `skills/audit/skill.md`

- [ ] **Step 1: Create the audit skill directory and file**

```bash
mkdir -p skills/audit
```

- [ ] **Step 2: Write the audit skill markdown**

Create `skills/audit/skill.md`:

```markdown
---
name: audit
description: Scan codebase for CHP violations and assess code health
---

# CHP Codebase Audit

Scan the entire repository for CHP law violations and get a comprehensive report on code health.

## When to Invoke

Invoke this skill when:
- User asks "how's our code quality?"
- User asks "are there violations?" or "do we have any issues?"
- Pre-commit or PR review time
- Onboarding to a new codebase
- Periodic code health check
- Before releasing or deploying

## Running the Audit

Use the `chp-scan` command to scan all tracked files:

```bash
# Scan all laws against all files
./commands/chp-scan

# Scan for a specific law only
./commands/chp-scan --law=<law-name>
```

## Interpreting Results

### Output Format

```
==================================
  CHP Repository Scanner
  Mode: DRY-RUN (read-only)
==================================

Scanning for violations of: no-console-log

  Law: no-console-log
  Severity: error
  Historical failures: 7
  Current violations: 3
  Violating files:
    - src/debug.js
    - lib/logger.js
    - app/index.js
```

### Prioritization Strategy

Fix violations in this order:

1. **Error severity** - Blocks commits, must be fixed
2. **High historical failure count** - Recurring problem
3. **High current violation count** - Widespread issue

### Example Prioritization

```
Results:
  no-api-keys (error) - 1 violation        # FIX FIRST (blocking)
  no-console-log (error) - 7 violations    # FIX SECOND (widespread)
  max-line-length (warn) - 12 violations   # FIX THIRD (non-blocking)
```

## Fixing Violations

### Process

1. **Review the violation report** - Note which files violate
2. **Read the law's guidance** - Understand what to fix
   ```bash
   cat docs/chp/laws/<law-name>/guidance.md
   ```
3. **Fix the issues** - Edit the violating files
4. **Re-scan to verify**
   ```bash
   ./commands/chp-scan --law=<law-name>
   ```
5. **Commit your changes**
   ```bash
   git add .
   git commit -m "fix: resolve CHP law violations"
   ```

### Bulk Fixes

For laws with many violations (e.g., 50+ console.log statements):

1. Use find/replace carefully
2. Re-scan after each batch
3. Don't introduce new violations while fixing

## Integration with Workflows

### Pre-Commit

Add to your workflow before committing:

```bash
# Quick scan before committing
./commands/chp-scan

# Fix any violations, then commit
git commit
```

### PR Reviews

Before creating a PR:

```bash
# Scan for violations in your branch
./commands/chp-scan

# Include results in PR description
```

### CI/CD

Add to CI pipeline:

```yaml
- name: Check CHP violations
  run: ./commands/chp-scan
```

## Notes

- The scanner is read-only - no files are modified
- Disabled laws are skipped during scanning
- Results are current snapshot - historical failures are in law.json
```

- [ ] **Step 3: Verify the file was created correctly**

```bash
cat skills/audit/skill.md
```

Expected: Output shows the skill markdown content

- [ ] **Step 4: Commit**

```bash
git add skills/audit/
git commit -m "feat: add chp:audit skill for codebase scanning"
```

---

### Task 3: Create `chp:plan-check` skill

**Files:**
- Create: `skills/plan-check/skill.md`

- [ ] **Step 1: Create the plan-check skill directory and file**

```bash
mkdir -p skills/plan-check
```

- [ ] **Step 2: Write the plan-check skill markdown**

Create `skills/plan-check/skill.md`:

```markdown
---
name: plan-check
description: Preview which CHP laws apply before implementing changes
---

# CHP Plan Check

Preview which CHP laws apply to your planned work before you start implementing. Avoid surprises by understanding guardrails upfront.

## When to Invoke

Invoke this skill when:
- You're about to implement a feature
- You're planning architectural changes
- You ask "what should I watch out for?"
- You're in the planning phase before coding
- Starting work on a new area of the codebase

## Checking Applicable Laws

### List All Active Laws

```bash
./commands/chp-law list
```

Output shows:
```
  no-api-keys | severity: error | failures: 1 | enabled
  no-console-log | severity: error | failures: 7 | enabled
  max-function-length | severity: warn | failures: 0 | enabled
```

### Check System Status

```bash
./commands/chp-status
```

Output shows:
- Which hooks are installed
- Which laws have recent failures
- Hook-to-law mappings

## Understanding What Laws Check

### Read Law Guidance

For each relevant law, read its guidance:

```bash
cat docs/chp/laws/<law-name>/guidance.md
```

This explains:
- What the law checks for
- Good vs bad practice examples
- How to comply

### Check Verification Logic

To understand exactly what triggers violations:

```bash
cat docs/chp/laws/<law-name>/verify.sh
```

Look for:
- Patterns being matched
- File types being checked
- Conditions that trigger failures

## Example Scenarios

### Scenario 1: Adding a New API Endpoint

**Planned work:** Add user authentication endpoint

**Check laws:**
```bash
./commands/chp-law list
```

**Relevant laws to review:**
- `no-api-keys` - Don't commit API keys
- `max-function-length` - Keep handler functions short

**Read guidance:**
```bash
cat docs/chp/laws/no-api-keys/guidance.md
cat docs/chp/laws/max-function-length/guidance.md
```

**Plan accordingly:**
- Use environment variables for API keys
- Split handler into smaller functions if needed

### Scenario 2: Refactoring Database Queries

**Planned work:** Optimize slow database queries

**Check laws:**
```bash
./commands/chp-law list
```

**Relevant laws to review:**
- `no-hardcoded-credentials` - Don't hardcode DB passwords
- `require-transaction` - Use transactions for multi-statement operations

**Plan accordingly:**
- Use connection strings from environment
- Wrap multi-statement operations in transactions

### Scenario 3: Adding Frontend Components

**Planned work:** Create new React components

**Check laws:**
```bash
./commands/chp-law list
```

**Relevant laws to review:**
- `no-console-log` - Don't leave console.log in production code
- `component-naming` - Use consistent naming conventions

**Plan accordingly:**
- Use proper logging instead of console.log
- Follow naming conventions from the start

## Making Changes After Planning

If you discover a law is too restrictive or doesn't fit your use case:

1. **Don't disable it immediately** - Understand why it exists first
2. **Read the full guidance** - There might be a compliant approach
3. **Use `chp:refine-laws`** - If genuinely needed, adjust the law
4. **Discuss with team** - Laws represent team standards

## Quick Reference

| Work Type | Commonly Relevant Laws |
|-----------|----------------------|
| API changes | no-api-keys, no-secrets |
| Frontend | no-console-log, component-naming |
| Database | no-hardcoded-credentials, require-transaction |
| Config files | no-secrets, proper-env-vars |
| Tests | test-coverage, no-skip-tests |
```

- [ ] **Step 3: Verify the file was created correctly**

```bash
cat skills/plan-check/skill.md
```

Expected: Output shows the skill markdown content

- [ ] **Step 4: Commit**

```bash
git add skills/plan-check/
git commit -m "feat: add chp:plan-check skill for previewing applicable laws"
```

---

### Task 4: Create `chp:refine-laws` skill

**Files:**
- Create: `skills/refine-laws/skill.md`

- [ ] **Step 1: Create the refine-laws skill directory and file**

```bash
mkdir -p skills/refine-laws
```

- [ ] **Step 2: Write the refine-laws skill markdown**

Create `skills/refine-laws/skill.md`:

```markdown
---
name: refine-laws
description: Tune existing CHP laws based on new requirements or feedback
---

# CHP Law Refinement

Adjust and tune existing CHP laws when they need updating due to false positives, new requirements, or changing team standards.

## When to Invoke

Invoke this skill when:
- A law has too many false positives
- A law needs new violation patterns
- You want to change a law's severity
- A law's hooks need adjustment
- A law is outdated or no longer relevant
- Team standards have changed

## Law Structure

Each law has three components:

```
docs/chp/laws/<law-name>/
├── law.json       # Metadata (severity, hooks, enabled status)
├── verify.sh      # Verification logic (what to check)
└── guidance.md    # Human-readable documentation
```

## Refinement Scenarios

### Scenario 1: Reduce False Positives

**Problem:** Law flags things that shouldn't be violations

**Example:** `no-console-log` flags `console.error` which you need for error tracking

**Solution:** Edit `verify.sh` to exclude the pattern

```bash
# Edit the verification script
vim docs/chp/laws/no-console-log/verify.sh

# Change the pattern to exclude console.error
# Before: grep -q 'console\.log'
# After: grep -q 'console\.log' | grep -v 'console\.error'
```

**Test the change:**
```bash
./commands/chp-law test no-console-log
```

### Scenario 2: Change Severity

**Problem:** Law is too strict or too lenient

**Example:** `max-function-length` should warn, not error

**Solution:** Edit `law.json`

```bash
# Edit the metadata
vim docs/chp/laws/max-function-length/law.json

# Change severity
# Before: "severity": "error"
# After: "severity": "warn"
```

**Test the change:**
```bash
./commands/chp-law test max-function-length
```

### Scenario 3: Add New Violation Pattern

**Problem:** Law needs to catch additional patterns

**Example:** `no-api-keys` should also catch `Bearer` tokens

**Solution:** Edit `verify.sh` to add the pattern

```bash
vim docs/chp/laws/no-api-keys/verify.sh

# Add to the patterns array
patterns+=("Bearer [A-Za-z0-9\\-._~+/]+=*")  # JWT tokens
```

**Test the change:**
```bash
./commands/chp-law test no-api-keys
```

### Scenario 4: Adjust Hooks

**Problem:** Law runs at the wrong time

**Example:** `test-coverage` should run on pre-push, not pre-commit

**Solution:** Edit `law.json`

```bash
vim docs/chp/laws/test-coverage/law.json

# Change hooks array
# Before: "hooks": ["pre-commit"]
# After: "hooks": ["pre-push"]
```

Reinstall hooks:
```bash
./commands/chp-hooks disable pre-commit
./commands/chp-hooks enable pre-push
```

### Scenario 5: Update Guidance

**Problem:** Documentation doesn't match current behavior

**Solution:** Edit `guidance.md`

```bash
vim docs/chp/laws/<law-name>/guidance.md

# Update examples, remediation steps, or context
```

### Scenario 6: Reset Failure Count

**Problem:** Law has high failure count from past issues, now fixed

**Solution:** Reset the counter

```bash
./commands/chp-law reset <law-name>
```

This resets `failures` to 0 and `tightening_level` to 0 in `law.json`.

## Testing Changes

Always test after refining a law:

```bash
# Test the verification script
./commands/chp-law test <law-name>

# If changing patterns, test with a file that should violate
echo "console.log('test')" > /tmp/test.js
./commands/chp-scan --law=<law-name>

# Verify the law still works as expected
```

## Disabling vs Deleting

### Disable Temporarily

When a law needs to be paused but might be re-enabled:

```bash
./commands/chp-law disable <law-name>
```

The law remains but won't enforce. Re-enable later:
```bash
./commands/chp-law enable <law-name>
```

### Delete Permanently

When a law is no longer needed:

```bash
./commands/chp-law delete <law-name>
```

This removes the law directory and unregisters it from all hooks.

## Before Refining

1. **Understand why the law exists** - Read the full guidance
2. **Check with team** - Laws represent team standards
3. **Consider the impact** - Changes affect everyone
4. **Document the change** - Update guidance.md with rationale

## After Refining

1. **Test thoroughly** - Use `chp-law test`
2. **Update guidance** - Document what changed and why
3. **Communicate** - Let team know about the change
4. **Monitor** - Watch for new violations/failures

## Example Workflow

```
1. Notice no-console-log flags console.error
2. Use chp:refine-laws
3. Edit verify.sh to exclude console.error
4. Test: ./commands/chp-law test no-console-log
5. Update guidance.md to document the exception
6. Commit: git commit -m "refine(no-console-log): allow console.error for error tracking"
```
```

- [ ] **Step 3: Verify the file was created correctly**

```bash
cat skills/refine-laws/skill.md
```

Expected: Output shows the skill markdown content

- [ ] **Step 4: Commit**

```bash
git add skills/refine-laws/
git commit -m "feat: add chp:refine-laws skill for tuning existing laws"
```

---

### Task 5: Create `chp:onboard` skill

**Files:**
- Create: `skills/onboard/skill.md`

- [ ] **Step 1: Create the onboard skill directory and file**

```bash
mkdir -p skills/onboard
```

- [ ] **Step 2: Write the onboard skill markdown**

Create `skills/onboard/skill.md`:

```markdown
---
name: onboard
description: Understand what CHP guardrails are in place for a project
---

# CHP Project Onboarding

Understand what CHP guardrails and traffic laws are enforced in this project.

## When to Invoke

Invoke this skill when:
- You're new to the project
- You ask "what rules are enforced here?"
- You're starting work on an unfamiliar codebase
- You need to understand project constraints
- You want to know what guardrails are in place

## Understanding CHP

CHP (Code Health Protocol) provides **two layers** of enforcement:

### 1. Suggestive Layer
- Context files in `docs/chp/` guide you to follow rules
- Active before you make mistakes
- Helps you self-correct

### 2. Verification Layer
- Scripts in `docs/chp/laws/*/verify.sh` check for violations
- Catches violations when they happen
- Can block commits, pushes, or other actions

## Quick Overview

### Check System Status

```bash
./commands/chp-status
```

This shows:
- Detected hook systems (Git, Agent, CI/CD)
- Active laws with their status
- Installed hooks
- Hook registry mappings

### List All Laws

```bash
./commands/chp-law list
```

This shows each law with:
- Severity level (error, warn, info)
- Failure count
- Enabled status

## Understanding Each Law

For each law, read its guidance:

```bash
cat docs/chp/laws/<law-name>/guidance.md
```

The guidance explains:
- **Purpose** - What the law protects
- **What it checks** - Patterns it looks for
- **Good practice** - Compliant examples
- **Bad practice** - Non-compliant examples
- **Remediation** - How to fix violations

## Law Categories

### Security Laws
Protect against security vulnerabilities:
- `no-api-keys` - No hardcoded API keys
- `no-secrets` - No secrets in code
- `no-hardcoded-credentials` - Use environment variables

### Quality Laws
Maintain code quality:
- `no-console-log` - Remove debug statements
- `max-function-length` - Keep functions manageable
- `require-documentation` - Document public APIs

### Style Laws
Enforce consistency:
- `import-ordering` - Consistent import statements
- `naming-conventions` - Follow naming standards

### Workflow Laws
Process requirements:
- `test-coverage` - Maintain test coverage
- `no-skip-tests` - Don't skip tests in commits

## What Happens on Violation?

### Error Severity
- Action is **blocked**
- You must fix before proceeding
- Failure count increments
- Guidance may auto-tighten

### Warn Severity
- Warning is logged
- Action proceeds
- Still tracked for visibility

### Info Severity
- Informational only
- No blocking
- For awareness

## Hooks Explained

Hooks are **trigger points** where laws run:

### Git Hooks
- `pre-commit` - Before committing
- `pre-push` - Before pushing to remote
- `commit-msg` - Validate commit messages

### Agent Hooks
- `pre-prompt` - Before agent processes request
- `pre-tool` - Before agent uses a tool
- `post-response` - After agent responds

### CI/CD Hooks
- `pre-build` - Before building
- `post-build` - After build completes
- `pre-deploy` - Before deploying

Check which hooks are installed:
```bash
./commands/chp-hooks list
```

## Getting Started Workflow

### 1. First Time Setup

```bash
# See what's enforced
./commands/chp-status

# List all laws
./commands/chp-law list

# Read guidance for each active law
for law in docs/chp/laws/*/guidance.md; do
    echo "=== $(basename $(dirname $law)) ==="
    cat $law
    echo ""
done
```

### 2. Before Starting Work

Use `chp:plan-check` to see which laws apply to your planned work.

### 3. While Working

- Laws run automatically on configured hooks
- If blocked, use `chp:investigate` to debug
- Read the law's guidance for remediation

### 4. When Blocked

```bash
# See what blocked you
./commands/chp-audit <law-name>

# Understand what to fix
cat docs/chp/laws/<law-name>/guidance.md

# Test after fixing
./commands/chp-law test <law-name>
```

## Common Questions

**Q: Can I disable a law?**
A: Use `./commands/chp-law disable <law-name>` but discuss with team first.

**Q: What if a law is wrong?**
A: Use `chp:refine-laws` to adjust it, or discuss with the team.

**Q: How do I suggest a new law?**
A: Use `chp:write-laws` to create one, or discuss with the team.

**Q: Do laws run on every file?**
A: Only on files affected by the hook (e.g., staged files for pre-commit).

## Resources

- **All laws:** `docs/chp/laws/`
- **System status:** `./commands/chp-status`
- **Law management:** `./commands/chp-law`
- **Hook management:** `./commands/chp-hooks`

## Summary

1. Run `./commands/chp-status` for overview
2. Run `./commands/chp-law list` to see all laws
3. Read `guidance.md` for each active law
4. Use `chp:plan-check` before starting work
5. Use `chp:investigate` when blocked
6. Use `chp:refine-laws` to adjust laws if needed
```

- [ ] **Step 3: Verify the file was created correctly**

```bash
cat skills/onboard/skill.md
```

Expected: Output shows the skill markdown content

- [ ] **Step 4: Commit**

```bash
git add skills/onboard/
git commit -m "feat: add chp:onboard skill for project guardrail overview"
```

---

### Task 6: Verify all skills are complete

**Files:**
- Verify: `skills/*/skill.md`

- [ ] **Step 1: List all skill directories**

```bash
ls -la skills/
```

Expected output shows:
```
investigate/
audit/
plan-check/
refine-laws/
onboard/
scan-repo/
write-laws/
```

- [ ] **Step 2: Verify each skill has frontmatter**

```bash
for dir in skills/*/; do
    echo "=== $dir ==="
    head -5 "$dir/skill.md"
done
```

Expected: Each skill shows `---` frontmatter with `name` and `description`

- [ ] **Step 3: Final commit if any adjustments needed**

If any adjustments were made:

```bash
git add skills/
git commit -m "chore: finalize CHP skills implementation"
```

---

## Summary

This plan creates 5 new CHP skills:

| Skill | Purpose |
|-------|---------|
| `chp:investigate` | Debug blocked actions |
| `chp:audit` | Scan codebase for violations |
| `chp:plan-check` | Preview applicable laws |
| `chp:refine-laws` | Tune existing laws |
| `chp:onboard` | Understand project guardrails |

All skills follow the existing CHP skill pattern: markdown documentation that maps scenarios to CLI commands.

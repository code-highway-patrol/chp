# chp:decompose-law — Concept-to-Atomic-Checks Decomposition Skill

## Problem

Users think in vague enforcement concepts ("no secrets", "payment code needs tests", "GDPR compliance") but CHP laws need specific atomic checks with types, configs, and severities. The gap between "I want to enforce X" and "here are the 4 atomic checks that enforce X" is where most design mistakes happen.

## Solution

A standalone `chp:decompose-law` skill that takes a concept, researches the codebase, and outputs a structured list of atomic checks. Each check is typed, configured, and severity-tagged — ready for `chp:write-laws` to implement.

## Pipeline

```
decompose-law → write-laws → review-law
(concept → checks)   (checks → files)    (files → verify consistency)
```

Each skill has one job. Decompose figures out *what* to check. Write-laws figures out *how*. Review-law verifies they match.

## Check Types

From the atomic-checks spec, the skill knows four types:

| Type | Best for | Config fields |
|------|----------|---------------|
| `pattern` | Regex matching (secrets, debug statements, keywords) | `pattern` (regex) |
| `threshold` | Measurable limits (line count, nesting, coverage) | `metric`, `max` or `min` |
| `structural` | Convention checks (test file exists, .gitignore rules) | `assert` (named assertion) |
| `agent` | Subjective judgment (naming quality, error message clarity) | `prompt` (question for AI) |

## Decomposition Process

### 1. Understand the concept

The user provides a concept (as a string, or via conversation). The skill clarifies the intent if ambiguous — "no secrets" could mean API keys, passwords, private keys, or all of the above.

### 2. Research the codebase

Scan the repo to understand the domain:
- What file types exist in the relevant area
- What patterns are already checked by existing laws
- What tools are available (ESLint, TypeScript, etc.)
- Whether existing laws overlap with the concept

```bash
# Check existing laws for overlap
jq -r '.intent' docs/chp/laws/*/law.json 2>/dev/null

# Scan relevant file types
find . -type f -name "*.ts" -o -name "*.js" | head -20
```

### 3. Decompose into atomic checks

Break the concept into 2-5 atomic checks. Each check addresses one concern with the most appropriate type. Prefer `pattern` (simplest, fastest) over `threshold` over `structural` over `agent` (most complex).

Rules:
- Each check tests exactly one thing
- Each check is independently understandable
- The set of checks together covers the concept
- No redundant checks (don't check the same thing two ways)

### 4. Output the decomposition

Structured output for each check:

```
Check 1: <short description>
  Type: pattern | threshold | structural | agent
  Config: { relevant config fields }
  Severity: block | warn | log
  Message: "What to tell the developer when this fires"
```

Then a summary:
```
Decomposition of "<concept>": 4 checks
  pattern:   2 (regex matching)
  threshold: 1 (measurable limit)
  structural: 1 (convention check)
```

### 5. Hand off to write-laws

After the user approves the decomposition, the skill tells them to run:
```
/chp:write-laws <law-name>
```

And provides the decomposition as context — the user can paste it or the skill can describe how to reference it.

## Examples

### "no secrets in code"
```
Check 1: Detect common key prefixes
  Type: pattern
  Config: { "pattern": "sk-[a-zA-Z0-9]{32,}|AIza[0-9A-Za-z\\-_]{35}|AKIA[0-9A-Z]{16}|ghp_[a-zA-Z0-9]{36}" }
  Severity: block
  Message: "API key detected — use environment variables"

Check 2: Detect hardcoded credentials in assignments
  Type: pattern
  Config: { "pattern": "(password|api_key|secret|token)\\s*=\\s*['\"]" }
  Severity: block
  Message: "Hardcoded credential — move to environment variable"

Check 3: Verify .gitignore covers .env files
  Type: structural
  Config: { "assert": "gitignore_contains", "pattern": "*.env" }
  Severity: block
  Message: ".env files not in .gitignore — secrets could be committed"
```

### "payment code needs tests"
```
Check 1: Test file must exist when payment code changes
  Type: structural
  Config: { "assert": "test_file_exists", "source_pattern": "src/payments/**/*.ts", "test_pattern": "tests/payments/**/*.test.ts" }
  Severity: block
  Message: "Payment code changed but no corresponding test file found"

Check 2: Payment code requires 100% statement coverage
  Type: threshold
  Config: { "metric": "statement_coverage", "path": "src/payments/**", "min": 100 }
  Severity: block
  Message: "Payment code coverage below 100%"
```

## File Structure

```
.claude-plugin/plugins/chp/skills/decompose-law/
  SKILL.md          — skill definition, decomposition process, check type reference
```

## Changes to Existing Code

- `plugin.json`: register the new skill

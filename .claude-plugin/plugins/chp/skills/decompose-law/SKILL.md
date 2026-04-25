---
name: decompose-law
description: Break a vague enforcement concept into specific atomic checks. Triggers on "decompose law", "break down law", "what checks do I need", "how to enforce", "decompose".
---

# CHP Law Decomposer

Take a vague enforcement concept ("no secrets", "payment code needs tests", "GDPR compliance") and break it into specific atomic checks with types, configs, and severities. Output is ready for `chp:write-laws` to implement.

## When to Invoke

Invoke this skill when:
- User says "decompose law", "break down this rule", "what checks do I need"
- User has a concept but doesn't know how to express it as atomic checks
- Before `chp:write-laws` when starting from a vague idea
- `chp:write-laws` receives a vague but tractable concept (auto-delegates here)

## Check Types

| Type | Best for | Config fields |
|------|----------|---------------|
| `pattern` | Regex matching (secrets, debug statements, keywords) | `pattern` (regex) |
| `threshold` | Measurable limits (line count, nesting, coverage) | `metric`, `max` or `min` |
| `structural` | Convention checks (test file exists, .gitignore rules) | `assert` (named assertion) |
| `agent` | Subjective judgment (naming quality, error message clarity) | `prompt` (question for AI) |

Prefer simpler types: `pattern` > `threshold` > `structural` > `agent`.

## Decomposition Process

### 1. Understand the concept

The user provides a concept. If it's ambiguous, clarify before decomposing:

- "no secrets" → API keys? Passwords? Private keys? All of the above?
- "code quality" → What aspect? Complexity? Style? Coverage?

Don't guess. Ask.

### 2. Research the codebase

Check what already exists before decomposing:

```bash
# Existing laws — check for overlap
jq -r '.intent' docs/chp/laws/*/law.json 2>/dev/null

# Relevant file types in the target area
find . -type f -name "*.ts" -o -name "*.js" | head -20

# Available tools
ls package.json .eslintrc* tsconfig.json 2>/dev/null
```

If an existing law already covers part of the concept, note the overlap. The user may want to extend an existing law instead of creating a new one.

### 3. Decompose into atomic checks

Rules:
- Each check tests exactly one thing
- Each check is independently understandable
- The set of checks together covers the concept
- No redundant checks (don't test the same thing two ways)
- Aim for 2-5 checks per concept

For each check, determine:
- **Type**: Which check type fits best
- **Config**: The specific parameters
- **Severity**: `block` (must fix), `warn` (should fix), `log` (tracking only)
- **Message**: What to tell the developer when this fires

### 4. Output the decomposition

For each check:

```
Check N: <short description>
  Type: pattern | threshold | structural | agent
  Config: { config fields }
  Severity: block | warn | log
  Message: "developer-facing message"
```

Then a summary:

```
Decomposition of "<concept>": N checks
  pattern:    X (regex matching)
  threshold:  X (measurable limits)
  structural: X (convention checks)
  agent:      X (subjective judgment)
```

### 5. Hand off

After the user approves the decomposition:

```
Run /chp:write-laws <law-name> to implement these checks.
```

The user can reference the decomposition output as context for write-laws.

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

Decomposition of "no secrets in code": 3 checks
  pattern:    2 (regex matching)
  structural: 1 (convention check)
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

Decomposition of "payment code needs tests": 2 checks
  structural: 1 (convention check)
  threshold:  1 (measurable limit)
```

### "GDPR data export compliance"

```
Check 1: Data export endpoints require privacy review file
  Type: structural
  Config: { "assert": "file_exists", "path": ".privacy-review/approved", "trigger_pattern": "export.*\\.ts$" }
  Severity: block
  Message: "Data export endpoint requires privacy team approval"

Check 2: No PII in log statements
  Type: pattern
  Config: { "pattern": "log\\.(info|debug|warn).*\\b(email|phone|address|ssn)\\b" }
  Severity: block
  Message: "PII detected in log statement — use redacted fields"

Check 3: Data retention config must specify max days
  Type: threshold
  Config: { "metric": "config_value", "path": "config/retention.json", "field": "max_days", "max": 365 }
  Severity: warn
  Message: "Data retention exceeds 365 days — verify GDPR compliance"

Decomposition of "GDPR data export compliance": 3 checks
  structural: 1 (convention check)
  pattern:    1 (regex matching)
  threshold:  1 (measurable limit)
```

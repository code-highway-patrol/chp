---
name: write-laws
description: Create new CHP enforcement laws
---

# Create a New Law

## When to Use

- User wants to add a new code rule
- User says "add a law", "create a rule", "enforce", "ban", or "block"

## Process

1. Ask the user what they want to enforce (or infer from context)
2. Determine if the law is **deterministic** or **subjective**:
   - Deterministic: can be checked with a regex pattern (e.g. "no console.log", "tabs not spaces", "no TODO comments")
   - Subjective: requires judgment (e.g. "functions should have clear names", "no hardcoded secrets" where context matters)
3. Read `laws/chp-laws.txt` to check for duplicates
4. Append the new law block to `laws/chp-laws.txt`
5. Confirm what was added

## Law Format

Deterministic law (has `check:` regex):
```
# === Law: no-console-log ===
intent: No console.log statements in production code
check: console\.log\(
reaction: block
```

Subjective law (no `check:` field):
```
# === Law: no-hardcoded-secrets ===
intent: No hardcoded API keys, passwords, tokens, or secrets in source code
reaction: block
```

## Fields

- **id**: Lowercase kebab-case, unique
- **intent**: Plain-language description. For subjective laws, this is what the agent evaluates against.
- **check**: Optional. A regex pattern (grep -E compatible). If present, violations are detected automatically. If absent, the agent uses judgment.
- **reaction**: `block` (must fix) or `warn` (flag but allow)

## Guidelines

- Default to deterministic when possible — it's faster and has zero inference cost
- Use subjective only when the check genuinely requires context or judgment
- Write clear intents even for deterministic laws — the intent documents the "why"

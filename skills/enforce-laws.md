---
name: enforce-laws
description: Enforce CHP traffic laws against the codebase and report violations
---

# CHP Law Enforcement

Enforce registered Code Highway Patrol traffic laws and report any violations found.

## Usage

Invoke this skill when:
- User wants to check code against specific rules
- User asks about violations or non-compliance
- Pre-commit or pre-push validation is needed

## Enforcement Process

1. Load all registered CHP traffic laws from `assets/rules/`
2. Parse and validate each rule definition
3. Apply rules to target files/patterns
4. Collect violations with context
5. Generate violation report

## Violation Types

- **speeding**: Code that's too complex or doing too much
- **reckless-driving**: Dangerous patterns (security risks, anti-patterns)
- **running-red-lights**: Skipping required steps (error handling, validation)
- **improper-lane-change**: Inconsistent patterns or abrupt style changes

## Output

Returns violations with:
- Law ID and name
- Severity level (felony, misdemeanor, infraction)
- File path and line number
- Violation context and explanation
- Suggested fix (when available)

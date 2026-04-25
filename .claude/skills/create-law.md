---
name: create-law
description: Create a new CHP traffic law for code analysis and enforcement
---

# CHP Traffic Law Creation

Create a new Code Highway Patrol traffic law with proper structure and validation.

## Usage

Invoke this skill when:
- User wants to add a new rule or standard
- User requests custom code validation
- New patterns need to be enforced

## Law Structure

A CHP traffic law requires:

```yaml
id: unique-law-id
name: Human Readable Name
description: What this law enforces
severity: felony|misdemeanor|infraction
category: security|performance|style|maintainability
patterns:
  - include: "**/*.js"
    exclude: "**/node_modules/**"
checks:
  - type: pattern|ast|custom
    config: ...
```

## Process

1. Gather requirements from user
2. Define law ID and metadata
3. Specify file patterns to patrol
4. Configure detection logic
5. Add to `assets/rules/` directory
6. Register in law registry

## Validation

After creation, the law is validated for:
- Proper schema compliance
- Unique ID
- Valid pattern syntax
- Testable detection logic

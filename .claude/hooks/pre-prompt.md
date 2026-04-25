---
name: pre-prompt
description: Provide CHP context and guidance before AI agent analysis
trigger:
  event: pre-prompt
  enabled: true
---

# CHP Pre-Prompt Hook

Inject Code Highway Patrol context into AI agent sessions for better analysis.

## Behavior

This hook runs before each user prompt to:
1. Load relevant CHP laws for current context
2. Identify files affected by current operation
3. Provide law context to AI agent
4. Suggest relevant CHP commands

## Context Provided

- Active CHP laws for detected file types
- Recent violations in affected files
- Project-specific standards and conventions
- Recommended analysis approaches

## Example

When user asks "refactor auth.js", hook provides:
- File type: JavaScript
- Applicable laws: js-security, js-style, js-complexity
- Recent violations: 2 warnings
- Standards: ES2022, airbnb-style-guide

This context helps the agent provide CHP-compliant suggestions.

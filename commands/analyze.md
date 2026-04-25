---
name: analyze
description: Run full codebeat analysis with CHP
usage: "chp analyze [options]"
options:
  - name: "--severity"
    description: "Minimum severity level (felony|misdemeanor|infraction)"
    default: "infraction"
  - name: "--scope"
    description: "Analysis scope (all|staged|changed)"
    default: "all"
  - name: "--output"
    description: "Output format (json|text|markdown)"
    default: "text"
  - name: "--fix"
    description: "Automatically fix auto-fixable issues"
    type: "boolean"
    default: false
---

# CHP Analyze Command

Run comprehensive Code Highway Patrol analysis across the codebase.

## Usage

```bash
chp analyze [options]
```

## Options

| Option | Description | Default |
|--------|-------------|---------|
| `--severity` | Minimum severity level (felony\|misdemeanor\|infraction) | infraction |
| `--scope` | Analysis scope (all\|staged\|changed) | all |
| `--output` | Output format (json\|text\|markdown) | text |
| `--fix` | Automatically fix auto-fixable issues | false |

## Examples

```bash
# Patrol entire codebase
chp analyze

# Check only staged files
chp analyze --scope staged

# Show only felonies and misdemeanors
chp analyze --severity misdemeanor

# Issue citations where possible
chp analyze --fix

# Output as JSON for CI/CD
chp analyze --output json > results.json
```

## Output

The analyze command provides:
- Overall codebeat score
- Citations grouped by severity
- File-by-file breakdown
- Actionable recommendations
- Trend comparison to previous patrols

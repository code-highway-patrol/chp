---
name: check
description: Check specific rules or files against CHP traffic laws
usage: "chp check [target] [options]"
options:
  - name: "--law"
    description: "Specific traffic law ID to check"
    type: "string"
  - name: "--file"
    description: "Specific file or pattern to check"
    type: "string"
  - name: "--severity"
    description: "Minimum severity level"
    default: "misdemeanor"
---

# CHP Check Command

Check specific rules, files, or patterns against CHP traffic laws.

## Usage

```bash
chp check [target] [options]
```

## Options

| Option | Description |
|--------|-------------|
| `--law` | Specific traffic law ID to check |
| `--file` | Specific file or pattern to check |
| `--severity` | Minimum severity level |

## Examples

```bash
# Check specific file
chp check src/auth.js

# Check specific traffic law
chp check --law js-speeding

# Check all JS files for felonies
chp check "**/*.js" --severity felony

# Check specific highway (directory)
chp check src/
```

## Output

Detailed findings for the specified target:
- Traffic law violations found
- Line numbers and context
- Severity levels
- Suggested fixes

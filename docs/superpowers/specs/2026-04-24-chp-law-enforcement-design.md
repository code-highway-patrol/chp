# CHP Law Enforcement System Design

**Date:** 2026-04-24
**Status:** Approved

## Overview

A two-layer law enforcement system for the CHP (Code Health Protocol) framework. The system provides both preventive guidance (suggestive layer) and corrective verification (programmatic checks) with automatic feedback loop to strengthen guidance when violations occur.

## Architecture

```
chp/
├── commands/
│   ├── chp-law            # Bash script for law commands
│   └── chp-status         # Bash script for status
├── skills/
│   └── write-laws/
│       └── skill.md       # chp:write-laws skill
├── core/
│   ├── detector.sh        # Detects available hooks (git, pretool)
│   ├── installer.sh       # Installs/uninstalls hooks
│   ├── verifier.sh        # Runs verification logic
│   └── tightener.sh       # Strengthens guidance on failures
└── docs/
    └── chp/
        ├── laws/
        │   └── <law-name>/
        │       ├── law.json    # Law metadata
        │       └── verify.sh   # Verification script
        └── <law-name>.md       # Suggestive guidance
```

## Components

### 1. CLI Commands

**chp-law** - Main law management interface:
- `chp-law create <name> --hooks=<list>` - Create new law
- `chp-law list` - List all laws
- `chp-law delete <name>` - Delete a law
- `chp-law test <name>` - Test verification logic

**chp-status** - Hook and system status:
- Shows installed hooks
- Shows active laws
- Shows recent violations

### 2. Skills

**chp:write-laws** - Teaches agents how to use the CLI for law creation and management.

### 3. Core Components

**detector.sh**
- Scans for available hook systems (git hooks, pretool)
- Returns list of installable hook points

**installer.sh**
- Installs verification scripts into detected hooks
- Uninstalls when laws are deleted
- Manages hook chaining for multiple laws

**verifier.sh**
- Executes all relevant verification scripts
- Collects and formats results
- Returns exit codes (0=pass, 1=block, 2=warn)

**tightener.sh**
- Called when verification fails
- Increments `tightening_level` in law.json
- Appends stricter guidance to the .md file
- Examples of tightening: stronger warnings, examples of violations

## Law Definition Format

**law.json:**
```json
{
  "name": "no-api-keys",
  "description": "Prevents API keys from being committed",
  "severity": "error",
  "hooks": ["pre-commit", "pre-push"],
  "created": "2026-04-24",
  "failures": 0,
  "tightening_level": 0
}
```

**verify.sh:**
```bash
#!/bin/bash
# Exit codes: 0=pass, 1=violation

if git diff --cached --name-only | xargs grep -l "sk_\|AIza\|AKIA" 2>/dev/null; then
    echo "❌ API key detected in staged files"
    exit 1
fi
exit 0
```

**no-api-keys.md (suggestive context):**
```markdown
# Law: No API Keys

**Severity:** Error
**Action:** Blocks commits and pushes

## What this means
Never commit API keys, tokens, or secrets to this repository.

## Alternatives
- Use environment variables
- Use `.env` files (already gitignored)
- Use secret management services

## Detection
Scans for patterns like: `sk_`, `AIza`, `AKIA`
```

## Data Flow

1. **Creation:** User runs `chp-law create <name> --hooks=<list>`
2. **Skill activation:** `chp:write-laws` skill guides the creation process
3. **File generation:** Creates law.json, verify.sh, and .md context file
4. **Hook installation:** installer.sh registers verification with specified hooks
5. **Operation:** When user runs git commit, verifier.sh executes relevant laws
6. **Violation:** If verification fails, operation blocks
7. **Tightening:** tightener.sh updates guidance to be more strict

## Behavior

- **Default action:** Block the operation (commit, push, etc.)
- **Configurable:** Per operation type via law configuration
- **Auto-tightening:** Guidance strengthens on each failure
- **Hook detection:** Automatically discovers available hook systems

## Future Considerations

Out of scope for initial implementation:
- Law deduplication
- Scoped graph of law relationships
- Advanced dependency management

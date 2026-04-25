# CHP Skills Design Document

## Overview

Add missing CHP skills that educate agents on when to use the CHP CLI based on scenarios. Skills are **scenario → command** mappings that guide agents to the right tool at the right time.

## Missing Skills to Implement

### 1. `chp:investigate`

**Purpose:** Debug why an action was blocked by CHP

**Trigger Scenarios:**
- Git hook failed with CHP violation
- CI/CD pipeline failed
- Tool call was blocked
- Agent asks "why did this fail?"
- Error message mentions "CHP violation"

**Guidance Provided:**
- Identify the law that blocked the action from error output
- Run `./commands/chp-audit <law-name>` to see violation history
- Explain what the failure count means
- Show the fix suggestion from the law
- Guide to re-test after fixing

**Example Flow:**
```
Agent sees: "❌ Error: CHP law no-api-keys violated"
Skill triggers: Run audit, see it failed 3 times, guidance says to use env vars
Agent fixes, re-runs verify
```

---

### 2. `chp:audit`

**Purpose:** Scan codebase for violations and assess code health

**Trigger Scenarios:**
- User asks "how's our code quality?"
- User asks "are there violations?"
- Pre-commit or PR review time
- Onboarding to new codebase
- Periodic code health check

**Guidance Provided:**
- Run `./commands/chp-scan` to scan all files
- Interpret violation counts by severity
- Prioritize fixes: error > warn > info
- Show which files have the most violations
- Guide to fix violations and re-scan

**Example Flow:**
```
User: "How's our code quality?"
Skill triggers: Run scan, see 12 violations across 3 laws
Prioritize: Fix the 7 console.log violations first (highest count)
```

---

### 3. `chp:plan-check`

**Purpose:** Preview which laws apply before implementing changes

**Trigger Scenarios:**
- Agent is about to implement a feature
- Agent asks "what should I watch out for?"
- Planning phase before coding
- Architectural discussion

**Guidance Provided:**
- Run `./commands/chp-law list` to see all active laws
- Identify which laws are relevant to the planned work
- Show what each relevant law checks for
- Point to guidance docs for details

**Example Flow:**
```
Agent: "I'm adding a new API endpoint"
Skill triggers: Check laws, see no-api-keys and max-function-length apply
Read guidance for each before starting
```

---

### 4. `chp:refine-laws`

**Purpose:** Tune existing laws based on new requirements or feedback

**Trigger Scenarios:**
- Law has too many false positives
- Law needs new violation patterns
- User wants to change severity
- User wants to adjust hook triggers
- Law is outdated

**Guidance Provided:**
- Edit `docs/chp/laws/<name>/law.json` for metadata
- Edit `docs/chp/laws/<name>/verify.sh` for verification logic
- Edit `docs/chp/laws/<name>/guidance.md` for documentation
- Test changes: `./commands/chp-law test <name>`
- Reset failure count if needed: `./commands/chp-law reset <name>`

**Example Flow:**
```
User: "This no-console-log law is flagging console.error which we need"
Skill triggers: Edit verify.sh to exclude console.error, test it
```

---

### 5. `chp:onboard`

**Purpose:** Understand what guardrails are in place for a project

**Trigger Scenarios:**
- New agent joins project
- User asks "what rules are enforced here?"
- Starting work on unfamiliar codebase
- Need to understand project constraints

**Guidance Provided:**
- Run `./commands/chp-status` for system overview
- Run `./commands/chp-law list` to see all laws
- Explain two-layer system (suggestive + verification)
- Point to `docs/chp/laws/*/guidance.md` for details
- Show which hooks are installed

**Example Flow:**
```
New agent joins
Skill triggers: Show status - 4 laws active, 2 with recent failures
Read guidance for each law to understand constraints
```

---

## File Structure

Each skill follows the existing pattern:

```
skills/
├── investigate/
│   └── skill.md
├── audit/
│   └── skill.md
├── plan-check/
│   └── skill.md
├── refine-laws/
│   └── skill.md
└── onboard/
    └── skill.md
```

Each `skill.md` file contains:
- Frontmatter with `name` and `description`
- When to invoke the skill (trigger scenarios)
- What commands to run
- How to interpret results
- Example flows

## Implementation Notes

- Skills are documentation only - no executable code
- Each skill wraps existing CLI commands
- Skills provide context and guidance on WHEN to use each command
- Follow the pattern of existing `write-laws` and `scan-repo` skills

## Success Criteria

- All 5 skills created and documented
- Skills follow existing CHP skill pattern
- Each skill clearly maps scenarios to CLI commands
- Skills can be invoked by agents when triggers occur

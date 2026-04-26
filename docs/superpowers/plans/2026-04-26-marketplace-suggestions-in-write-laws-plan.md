# Marketplace Suggestions in write-laws Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Integrate marketplace search into the write-laws skill flow to suggest existing laws before writing custom ones.

**Architecture:** Update the write-laws skill documentation to add a new section "Check Marketplace Before Writing" that instructs agents to query the marketplace and present options to users before creating custom laws.

**Tech Stack:** Markdown documentation only. No code changes required — the marketplace CLI commands (`chp search`, `chp install`) already exist.

---

### Task 1: Add "Check Marketplace Before Writing" section to write-laws skill

**Files:**
- Modify: `.claude-plugin/plugins/chp/skills/write-laws/SKILL.md`

- [ ] **Step 1: Locate the insertion point in SKILL.md**

The new section goes between "## Decompose Before Writing" (ends around line 46) and "## Creating a Law" (starts at line 48).

Find the text:
```markdown
To decompose:
```
Invoke the chp:decompose-laws skill with the user's concept.
After decomposition is approved, continue here with the resulting checks.
```

## Creating a Law
```

- [ ] **Step 2: Insert the new section**

Replace the text from Step 1 with:

```markdown
To decompose:
```
Invoke the chp:decompose-laws skill with the user's concept.
After decomposition is approved, continue to "Check Marketplace Before Writing".
```

## Check Marketplace Before Writing

After decomposing the law into atomic checks (or for clear, specific requests), check if a similar law exists on the marketplace before writing from scratch.

**Query the marketplace:**
```bash
# Search by key terms from the decomposed checks
chp search "console"
chp search "api keys"
chp search "security"
```

**If similar laws are found:**

Present the results to the user and ask what they'd like to do:

> "I found similar laws on the marketplace:
>
> - **No Console Logging** (no-console-log) ★ 42 — Prevents console.log in production code
> - **No Debug Statements** (no-debug) ★ 15 — Blocks console.debug, console.error in non-error contexts
>
> What would you like to do?
> 1. Use a marketplace law instead
> 2. Write a custom law
> 3. Show details of the marketplace law first"

**User response handling:**

- **"Use marketplace law"** → Invoke `chp:marketplace` skill to install the chosen law
- **"Write custom law"** → Proceed to "Creating a Law" below
- **"Show details"** → Display the marketplace law's full description and tags, then re-ask

**If no similar laws found:**

Proceed directly to "Creating a Law" below.

## Creating a Law
```

- [ ] **Step 3: Verify the changes**

Read the file to confirm the new section is properly inserted:
```bash
cat .claude-plugin/plugins/chp/skills/write-laws/SKILL.md
```

Expected: The "Check Marketplace Before Writing" section now appears between "Decompose Before Writing" and "Creating a Law".

- [ ] **Step 4: Test the skill invocation**

Trigger the write-laws skill to verify it loads correctly:
```bash
# This is a smoke test — the skill should load without syntax errors
echo "Testing write-laws skill loads..."
head -100 .claude-plugin/plugins/chp/skills/write-laws/SKILL.md
```

Expected: File displays correctly with no markdown syntax errors.

- [ ] **Step 5: Commit**

```bash
git add .claude-plugin/plugins/chp/skills/write-laws/SKILL.md
git commit -m "feat: add marketplace suggestions to write-laws skill

Adds 'Check Marketplace Before Writing' section that instructs
agents to query the marketplace for similar laws before creating
custom ones. Users are presented with options to use marketplace
laws, write custom laws, or see details first.

Co-Authored-By: Claude Opus 4.7 <noreply@anthropic.com>"
```

---

## Verification

After completing all tasks, verify the implementation:

- [ ] **Step 1: Review the updated skill**

```bash
cat .claude-plugin/plugins/chp/skills/write-laws/SKILL.md
```

Confirm:
- New section exists between "Decompose Before Writing" and "Creating a Law"
- Section title is "## Check Marketplace Before Writing"
- Includes marketplace query examples
- Includes user response handling instructions
- Includes fallback for no results

- [ ] **Step 2: Check git status**

```bash
git status
```

Expected: Only the write-laws SKILL.md file is modified.

- [ ] **Step 3: Verify commit exists**

```bash
git log -1 --oneline
```

Expected: Commit message mentions "marketplace suggestions to write-laws skill".

---

## Completion

All tasks complete. The write-laws skill now instructs agents to check the marketplace for similar laws before writing custom ones. When a user invokes write-laws, the agent will:

1. Decompose vague concepts (if needed)
2. Search the marketplace for similar laws
3. Present options to the user
4. Proceed based on user choice

No code changes were required — this leverages the existing `chp search` and `chp install` CLI commands.

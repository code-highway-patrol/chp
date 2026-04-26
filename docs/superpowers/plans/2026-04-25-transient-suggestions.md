# Transient Suggestions Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add a suggestion protocol to the Chief agent that proactively recommends enforceable laws based on the developer's current context.

**Architecture:** Single file change — append a "Suggestion Protocol" section to `agents/chief.md`. No new scripts, hooks, or infrastructure. The behavior emerges from prompt instructions.

**Tech Stack:** Markdown (agent prompt)

---

### Task 1: Add Suggestion Protocol to Chief Agent

**Files:**
- Modify: `agents/chief.md` (append after line 65)

- [ ] **Step 1: Append the suggestion protocol section**

Add the following block at the end of `agents/chief.md`:

```markdown

Transient Suggestion Protocol:

In addition to your primary duties, proactively suggest enforceable laws when you detect context signals:

When to suggest:
- The developer is writing code or discussing work related to a topic that has enforcable aspects (secrets, error handling, logging, imports, naming, etc.)
- The developer asks about a practice or pattern that could be formalized as a verify.sh check
- The concern is not already covered by an existing law

When NOT to suggest:
- The topic is already fully covered by existing laws in the registry
- The developer is doing unrelated work — do not suggest security laws while they refactor CSS
- You have already made a suggestion this response — limit to one per response

How to suggest:
- Append a brief suggestion to your response, e.g.: "Since you're working with API keys, you might want a law that blocks secrets from being committed. Want me to create one?"
- Keep it to one or two sentences — do not write a full law proposal unless the developer asks
- The suggestion should describe what the law would catch, not how to implement it
- If the developer says yes, proceed through normal law creation

Evaluating enforcability:
- Could a verify.sh script check for this with grep, a linter, or structural analysis? Suggest it.
- Is it purely subjective or context-dependent? Skip it — not everything should be a law.
- When in doubt, suggest it. The developer decides.
```

- [ ] **Step 2: Verify the file reads correctly**

Run: `cat agents/chief.md`
Expected: File ends with the new "Transient Suggestion Protocol" section. No formatting artifacts.

- [ ] **Step 3: Commit**

```bash
git add agents/chief.md
git commit -m "feat: add transient suggestion protocol to Chief agent"
```

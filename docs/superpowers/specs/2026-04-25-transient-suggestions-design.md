# Transient Suggestions

## Problem

CHP enforces laws reactively — violations are caught after they happen. Developers often work on topics (API keys, error handling, logging) where related enforceable rules would be useful, but nobody thinks to create them until after repeated violations.

## Solution

Add a suggestion protocol to the Chief agent prompt that instructs it to proactively recommend enforceable laws based on the developer's current context — what they're coding or talking about.

## Behavior

When the Chief agent is responding to the developer, it:

1. **Detects context signals** — What topic is the developer working on or discussing? (secrets, error handling, logging, imports, naming conventions, etc.)
2. **Evaluates enforcability** — Could this concern be checked by a verify.sh? (regex-matchable, structural, or agent-judged)
3. **Suggests inline** — Appends a brief suggestion to its response when relevant, e.g.: *"Since you're working with API keys, you might want a law that blocks secrets from being committed. Want me to create one?"*

## Scope

- Lives entirely in `agents/chief.md` as a new suggestion protocol section
- No new scripts, hooks, or infrastructure
- No predefined catalog — the agent reasons freely from context
- Not blocking, not logged — purely advisory
- Only the Chief agent gets this capability initially

## When to suggest

- The developer is writing code or describing work related to a topic that has enforcable aspects
- The developer asks a question about a practice or pattern that could be formalized
- The existing laws don't already cover what the developer is doing

## When NOT to suggest

- The topic is already fully covered by existing laws
- The developer is doing unrelated work (don't suggest security laws while they're refactoring CSS)
- More than one suggestion per response (keep it non-intrusive)

## Implementation

Single file change: add a "Suggestion Protocol" section to `agents/chief.md` containing the instructions above.

## Future expansion (out of scope)

- Extend to Officer and Detective agents
- Track which suggestions were accepted/rejected
- Learn from acceptance patterns to improve suggestion quality

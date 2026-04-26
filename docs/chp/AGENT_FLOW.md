# Agent Flow: Using LAW-PATTERNS.md

A practical guide for how agents should use the pattern reference when users request laws.

## The Flow

```
┌─────────────────────────────────────────────────────────────────────────┐
│                         USER MAKES REQUEST                               │
│                    "prevent console.log commits"                         │
└─────────────────────────────────────────────────────────────────────────┘
                                    │
                                    ▼
┌─────────────────────────────────────────────────────────────────────────┐
│                    AGENT READS LAW-PATTERNS.md                          │
│                                                                         │
│  1. Search "Quick Reference" table for matching pattern                │
│  2. If match found → Go to that section                                │
│  3. If no match → Scan sections for closest fit                         │
└─────────────────────────────────────────────────────────────────────────┘
                                    │
                                    ▼
┌─────────────────────────────────────────────────────────────────────────┐
│                    PATTERN FOUND: Section 1, Debug Artifacts            │
│                                                                         │
│  **User says:** "no console.log", "remove debug statements"            │
│  **Clarify:** Which methods? Allow in tests?                            │
│  **Template:** Regex-based grep with test file exclusion               │
└─────────────────────────────────────────────────────────────────────────┘
                                    │
                                    ▼
┌─────────────────────────────────────────────────────────────────────────┐
│                    AGENT ASKS CLARIFYING QUESTIONS                      │
│                                                                         │
│  "Should this block all console methods or just console.log?"          │
│  "Should we allow console in test files?"                               │
└─────────────────────────────────────────────────────────────────────────┘
                                    │
                                    ▼
┌─────────────────────────────────────────────────────────────────────────┐
│                    USER RESPONDS                                        │
│                    "just console.log and debugger, allow tests"         │
└─────────────────────────────────────────────────────────────────────────┘
                                    │
                                    ▼
┌─────────────────────────────────────────────────────────────────────────┐
│                    AGENT IMPLEMENTS USING TEMPLATE                      │
│                                                                         │
│  1. Copy template from LAW-PATTERNS.md                                  │
│  2. Adapt based on user responses                                       │
│  3. Create law with chp-law create                                      │
└─────────────────────────────────────────────────────────────────────────┘
                                    │
                                    ▼
┌─────────────────────────────────────────────────────────────────────────┐
│                    LAW CREATED                                          │
│                    ✅ no-console-log with verify.sh                      │
└─────────────────────────────────────────────────────────────────────────┘
```

---

## Real-World Examples

### Example 1: Simple Pattern Match

**User:** "no API keys in code"

**Agent finds:**
```markdown
| "no API keys" | Section 1 | Regex | `sk_\|AIza\|AKIA` |
```

**Agent uses template directly:**
```bash
PATTERNS=("sk_[a-zA-Z0-9]{20,}" "AIza[A-Za-z0-9_-]{35}" "AKIA[0-9A-Z]{16}")
```

**No clarification needed** - pattern is straightforward.

---

### Example 2: Needs Clarification

**User:** "enforce readable code"

**Agent finds:**
```markdown
| "enforce readable code" | ❌ Not quantifiable | Needs clarification |
```

**Agent asks:**
```
What makes code unreadable to you?
- Long lines? → Use max-len rule
- Deep nesting? → Use max-depth rule
- Long functions? → Use max-lines-per-function
- Want to use an existing linter (ESLint/Prettier)?
```

**User responds:** "deep nesting"

**Agent redirects to:**
```markdown
| "too nested" | Section 2 | AST | Nesting depth check |
```

**Uses AST template with max-depth rule.**

---

### Example 3: Multiple Possible Interpretations

**User:** "catch security issues"

**Agent finds multiple matches:**
```markdown
| "no API keys" | Section 1 | Regex | Secrets |
| "find security issues" | Section 3 | Delegated | Semgrep |
| "no unsafe code" | Section 3 | Delegated | Security scan |
```

**Agent asks:**
```
Which security issues should we catch?
- API keys and secrets in code?
- Vulnerable dependencies?
- Unsafe code patterns (SQL injection, XSS)?
- All of the above?
```

**User:** "API keys and secrets"

**Agent uses Section 1 template with secret patterns.**

---

### Example 4: Ambiguous → Hybrid Approach

**User:** "no console.log except in error handlers"

**Agent finds:**
```markdown
| "no console.log" | Section 1 | Regex | Simple block |
```

**But user wants exception** → Need hybrid approach

**Agent asks:**
```
Should console.log be allowed:
- Only in catch blocks?
- Only in files named "*error*"?
- Only in functions with "error" in the name?
```

**User:** "only in catch blocks"

**Agent uses Section 4 (Hybrid) template:**
```bash
# This requires AST analysis, not just regex
# Check if console.log is inside a try/catch
```

**Advises:** "This requires AST analysis. Want to use an ESLint rule instead?"

---

## Decision Trees for Agents

### Is the Request Quantifiable?

```
User request received
│
├─ Can I detect this with grep/file size?
│  ├─ Yes → Section 1 (Regex/Shell)
│  └─ No → Continue
│
├─ Does it require understanding code structure?
│  ├─ Yes → Section 2 (AST)
│  └─ No → Continue
│
├─ Does an existing tool solve this?
│  ├─ Yes → Section 3 (Delegated)
│  └─ No → Continue
│
└─ Does it need context or multiple conditions?
   └─ Yes → Section 4 (Hybrid)
```

### Should I Ask Clarifying Questions?

```
Pattern matched
│
├─ Is the user's request specific and unambiguous?
│  ├─ Yes → Use template directly
│  └─ No → Ask clarifying questions
│
└─ Are there multiple valid interpretations?
   └─ Yes → Present options from pattern reference
```

---

## Quick Reference for Pattern Matching

### Common User Phrases → Pattern Mapping

| User says | Match to | Section | Template |
|-----------|----------|---------|----------|
| "no secrets", "block API keys" | no-api-keys | 1 | Regex secret patterns |
| "no console.log", "remove debug" | no-console-log | 1 | Regex with test exclusion |
| "file too big", "limit size" | max-file-size | 1 | Shell wc/du commands |
| "missing tests", "require coverage" | require-tests | 1 | File existence check |
| "commit format", "ticket number" | commit-message-format | 1 | Regex on commit msg |
| "too nested", "complex callbacks" | max-nesting-depth | 2 | AST depth check |
| "unused imports", "dead code" | no-unused-imports | 2 | TypeScript compiler |
| "unhandled promise", "missing await" | no-unhandled-promises | 2 | AST Promise check |
| "enforce style", "format code" | eslint-rules | 3 | Delegated ESLint |
| "security scan", "find vulns" | security-scan | 3 | Delegated Semgrep |
| "strict types", "no any" | type-check | 3 | Delegated tsc |
| "console in tests only" | Conditional | 4 | Hybrid regex + path |
| "TODO with ticket" | TODO-with-ticket | 4 | Hybrid with exception |
| "import order" | import-order | 4 | Hybrid ESLint/custom |

---

## Template Usage

### Step 1: Find Template
```bash
# In LAW-PATTERNS.md, search for matching pattern
grep -A 20 "no-console-log" docs/chp/LAW-PATTERNS.md
```

### Step 2: Copy Template
```bash
#!/bin/bash
# Copy from LAW-PATTERNS.md
PATTERNS=("console\.log" "debugger")
FILES=$(git diff --cached --name-only | grep -E '\.(js|ts)$' ...)
```

### Step 3: Adapt to Requirements
```bash
# Modify based on user responses
# - Add/remove patterns
# - Change file filters
# - Adjust exclusions
```

### Step 4: Create Law
```bash
chp-law create <name> --hooks=pre-commit,pre-push
# Paste adapted template into verify.sh
```

---

## Example: Full Conversation

```
User: "add a law that prevents committing secrets"

Agent: [Scans LAW-PATTERNS.md]
      Found pattern: "no API keys" in Section 1

Agent: Should this detect:
      - API keys (sk_, AIza, AKIA)?
      - JWT tokens?
      - Database URLs?
      - All secrets?

User: "all secrets"

Agent: [Uses "no-api-keys" template with expanded patterns]

      Created verify.sh:
      PATTERNS=(
        "sk_[a-zA-Z0-9]{20,}"
        "AIza[A-Za-z0-9_-]{35}"
        "AKIA[0-9A-Z]{16}"
        "Bearer eyJ[A-Za-z0-9_-]+\."
        "password\s*=\s*['\"][^'\"]+"
        "mongodb://"
        "postgres://"
      )

User: "perfect, thanks"
```

---

## Key Principles

1. **Match first, clarify second** - Check if pattern exists before asking
2. **Use templates as starting point** - Adapt, don't reinvent
3. **Ask when ambiguous** - Multiple valid interpretations need clarification
4. **Prefer simple detection** - Regex > AST > Delegated > Hybrid
5. **Reference limitations** - Tell users what the pattern can't catch

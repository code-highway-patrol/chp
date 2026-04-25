# CHP Design Document

## Overview

**CHP** is a static analysis framework for projects that provides guardrails for AI agents (like Claude Code). It validates actions against defined laws before they execute, provides proactive guidance to help agents avoid violations, and prevents "vibe slop" from entering the codebase.

**Key insight**: CHP doesn't just block actions—it guides agents toward success. When a violation is detected, CHP returns a concrete fix suggestion that the agent can apply to proceed.

## Law Structure

Laws are stored as JSON files in `chp/laws/*.json`. Each law defines:

```json
{
  "id": "no-public-s3-buckets",
  "intent": "No resources may expose data publicly",
  "violations": [
    {
      "pattern": "s3Bucket.isPublic()",
      "fix": "setBlockPublicAccess(true)",
      "satisfies": "s3Bucket.isPublic() == false"
    }
  ],
  "reaction": "block"
}
```

**Fields:**
- `id` - Unique identifier for the law
- `intent` - High-level description of what the law protects
- `violations` - Array of violation patterns
  - `pattern` - Condition that triggers a violation
  - `fix` - Atomic action that resolves the violation
  - `satisfies` - Verification that the fix achieves the intent
- `reaction` - How to respond: `"block"`, `"warn"`, `"auto_fix"`

**Key design**: The `satisfies` field bridges the suggestive and verification layers—guaranteeing that suggested fixes actually pass verification.

## Evaluation Flow

When an agent attempts an action, CHP evaluates it against applicable laws:

```
1. INTERCEPT - Hook catches the action (tool call, git operation, file change)
2. MATCH - Find all laws whose violation patterns match the action
3. EVALUATE - Check if the action actually violates any matched patterns
4. REACT - Based on the law's reaction field:
   - "block" → Return error + fix suggestion
   - "warn" → Log warning, allow action to proceed
   - "auto_fix" → Apply fix automatically, continue
5. SUGGEST - If blocking, return the fix field as guidance
```

**Example flow:**
```
Agent: s3.createBucket({ bucket: 'my-data' })
       ↓
CHP: Matched law "no-public-s3-buckets"
     Violation: pattern "s3Bucket.isPublic()" matches
     Reaction: "block"
     Fix: "setBlockPublicAccess(true)"
       ↓
CHP returns: Error + "Set BlockPublicAccess: true in your bucket config"
Agent applies fix and retries
```

## Skills

CHP provides skills for defining, managing, and debugging laws:

**`chp:write-laws`**
- Converts vague intent → concrete law JSON through dialogue
- Clarifies scope, researches best practices, validates fixes
- Writes to `chp/laws/*.json`

**`chp:investigate`**
- Debugs why an action was blocked
- Shows which law was triggered and why
- Explains the fix in detail

**`chp:audit`**
- Scans entire codebase for law violations
- Generates report with violations, suggestions, and priority
- Useful for onboarding and periodic reviews

**`chp:plan-check`**
- Previews what laws would affect a planned change
- Lets agents anticipate guardrails before implementing
- Returns list of applicable laws and their requirements

**`chp:refine-laws`**
- Tunes existing laws based on new requirements
- Helps adjust strictness, add new violation patterns, or modify fixes

**`chp:onboard`**
- Shows all active laws for the project
- Explains what guardrails are in place
- Good for understanding project constraints

## Hook Integration

CHP integrates with the available environment through **environment-aware hook registration**:

**Tool Hooks**
- Registers with Claude Code's pre/post tool hook system
- Intercepts tool calls before execution
- Applies to all tools (file operations, API calls, database operations, etc.)

**Git Hooks**
- If Git is installed, registers pre-commit and pre-push hooks
- Validates staged files against laws before commit
- Prevents violating code from being pushed

**File Watching**
- If available, registers file change listeners
- Validates edits in real-time
- Provides immediate feedback

**Graceful Degradation**
- CHP detects what's available in the environment
- Only registers hooks that are supported
- Works with whatever the harness provides

## Error Handling and Feedback

**When a violation is blocked:**

```json
{
  "blocked": true,
  "law": "no-public-s3-buckets",
  "reason": "s3Bucket.isPublic() matched",
  "fix": "setBlockPublicAccess(true)",
  "suggestion": "Add BlockPublicAccess configuration to your bucket"
}
```

**When a violation is warned:**

```json
{
  "warned": true,
  "law": "long-function",
  "reason": "Function exceeds 100 lines",
  "suggestion": "Consider splitting into smaller functions"
}
```

**When auto-fix is applied:**

```json
{
  "fixed": true,
  "law": "missing-readme",
  "applied": "Generated README from package.json"
}
```

**Feedback to agents:**
- Clear, actionable messages
- Exact fix to apply
- Reference to the specific law
- No ambiguity about what to do next

## Law Examples

**Security Law:**
```json
{
  "id": "no-hardcoded-api-keys",
  "intent": "No API keys may be stored in the codebase",
  "violations": [
    {
      "pattern": "fileContains(/api[_-]?key\\s*[:=]\\s*['\"][^'\"]+['\"]/, file)",
      "fix": "useEnvironmentVariable('API_KEY')",
      "satisfies": "!fileContains(/api[_-]?key\\s*[:=]\\s*['\"][^'\"]+['\"]/, file)"
    }
  ],
  "reaction": "block"
}
```

**Database Law:**
```json
{
  "id": "no-destructive-db-changes-in-prod",
  "intent": "Production database cannot be modified destructively",
  "violations": [
    {
      "pattern": "environment == 'prod' && (query.includes('DROP') || query.includes('DELETE') || query.includes('TRUNCATE'))",
      "fix": "useStagingEnvironment()",
      "satisfies": "environment != 'prod' || !query.includes('DROP')"
    }
  ],
  "reaction": "block"
}
```

**Code Quality Law:**
```json
{
  "id": "require-readme",
  "intent": "Every project must have documentation",
  "violations": [
    {
      "pattern": "!fileExists('README.md')",
      "fix": "generateReadme()",
      "satisfies": "fileExists('README.md')"
    }
  ],
  "reaction": "warn"
}
```

## Implementation Considerations

**Pattern Matching:**
- Laws need a flexible pattern language
- Could use regex, AST matching, or custom DSL
- Must handle code, config, API calls, file operations

**Fix Validation:**
- The `satisfies` field must be testable
- CHP should simulate fixes before suggesting them
- Prove that the fix actually achieves the stated state

**Law Loading:**
- Load all JSON files from `chp/laws/*.json`
- Cache in memory for performance
- Reload on file changes during development

**Performance:**
- Pattern matching should be fast
- Cache compiled patterns
- Lazy evaluation where possible

**Extensibility:**
- Laws can be added/removed without restarting
- New violation patterns can be added to existing laws
- Plugin architecture for custom pattern matchers

## Testing Strategy

**Law Testing:**
- Each law should have test cases proving violations are detected
- Fix suggestions should be tested to verify they satisfy the `satisfies` condition
- Test edge cases and boundary conditions

**Integration Testing:**
- Hook registration works correctly in different environments
- Graceful degradation when hooks aren't available
- Actions flow through the evaluation pipeline correctly

**Skill Testing:**
- `chp:write-laws` generates valid JSON
- `chp:investigate` returns accurate debugging info
- `chp:audit` finds all violations in a test codebase

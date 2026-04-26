# CHP Law Pattern Reference

A comprehensive guide for agents to recognize common code enforcement patterns and implement them as CHP laws. When users describe what they want to enforce, match their language to these patterns and ask "you mean something like this?"

## How to Use This Reference

1. **Listen to user's request** - "no API keys", "enforce readable code", "catch bugs"
2. **Match to category** - Use the pattern descriptions below
3. **Clarify if needed** - Ask "you mean X, Y, or Z?" with specific options
4. **Implement** - Use the provided templates

---

## Detection Method Hierarchy

Choose the simplest method that works:

| Method | When to Use | Complexity | Reliability |
|--------|-------------|------------|-------------|
| **Regex/Shell** | String matches, file checks | Low | Medium |
| **AST Analysis** | Code structure, complexity | Medium | High |
| **Delegated Tools** | Language rules, comprehensive | High | Highest |
| **Hybrid** | Context-aware, multi-condition | High | High |

---

## Section 1: Regex/Shell Patterns

### When to Use
- Simple string matching (secrets, debug statements)
- File existence checks (missing tests, documentation)
- Size/length metrics (file size, line count)
- Git-based checks (commit message format, changed files)

### Decision Tree
```
Can you detect it with grep or file size?
├─ Yes → Use regex/shell
└─ No → Go to Section 2 (AST)
```

### Real-World Patterns

#### Security: Secrets and Credentials

**User says:** "no API keys", "block secrets", "no credentials"

**Clarify:** Which secrets?
- API keys (`sk_`, `AIza`, `AKIA`)
- Tokens (`Bearer`, `JWT`)
- Passwords (`password`, `PASS`)
- Database URLs (`mongodb://`, `postgres://`)

**ESLint equivalent:** `no-secrets` plugin, `secrets` patterns

**CHP Implementation:**
```bash
#!/bin/bash
# docs/chp/laws/no-secrets/verify.sh

# Common secret patterns
PATTERNS=(
  "sk_[a-zA-Z0-9]{20,}"           # Stripe API keys
  "AIza[A-Za-z0-9_-]{35}"         # Google API keys
  "AKIA[0-9A-Z]{16}"              # AWS access keys
  "Bearer eyJ[A-Za-z0-9_-]+\."    # JWT tokens
  "password\s*=\s*['\"][^'\"]+"   # password = "..."
)

# Check staged files
FILES=$(git diff --cached --name-only | grep -E '\.(js|ts|json|env|md)$' || true)
if [ -z "$FILES" ]; then exit 0; fi

for pattern in "${PATTERNS[@]}"; do
  if echo "$FILES" | xargs grep -E "$pattern" 2>/dev/null; then
    echo "Secret pattern detected: $pattern"
    exit 1
  fi
done

exit 0
```

**Limitations:** Can't detect obfuscated secrets, false positives on valid strings

---

#### Debug Artifacts: Console Methods

**User says:** "no console.log", "remove debug statements", "no debugger"

**Clarify:** Which debug methods?
- `console.log`, `console.debug`, `console.info`
- `console.warn`, `console.error` (maybe allow?)
- `debugger` statements
- Commented-out code

**ESLint equivalent:** `no-console`, `no-debugger`

**CHP Implementation:**
```bash
#!/bin/bash
# docs/chp/laws/no-console-log/verify.sh

# Block console methods in production code
PATTERNS=(
  "console\.log"
  "console\.debug"
  "console\.info"
  "debugger"
)

# Exclude test files
FILES=$(git diff --cached --name-only | grep -E '\.(js|ts|tsx)$' | grep -v test || true)

if [ -z "$FILES" ]; then exit 0; fi

for pattern in "${PATTERNS[@]}"; do
  if echo "$FILES" | xargs grep -n "$pattern" 2>/dev/null; then
    echo "Debug statement found: $pattern"
    exit 1
  fi
done

exit 0
```

**Limitations:** Can't distinguish intentional logging from debug logs, false positives in logger wrappers

---

#### File Metrics: Size and Length

**User says:** "no huge files", "limit file size", "max lines"

**Clarify:** What's the threshold?
- Max file size (KB)
- Max line count
- Which file types?

**ESLint equivalent:** `max-lines`, `max-lines-per-function`

**CHP Implementation:**
```bash
#!/bin/bash
# docs/chp/laws/max-file-size/verify.sh

MAX_LINES=500
MAX_SIZE_KB=100

# Check staged files
FILES=$(git diff --cached --name-only | grep -E '\.(ts|js|tsx|jsx)$' || true)
if [ -z "$FILES" ]; then exit 0; fi

for file in $FILES; do
  # Check line count
  LINES=$(wc -l < "$file" 2>/dev/null || echo 0)
  if [ "$LINES" -gt "$MAX_LINES" ]; then
    echo "File too large: $file ($LINES lines, max $MAX_LINES)"
    exit 1
  fi

  # Check file size
  SIZE_KB=$(du -k "$file" | cut -f1)
  if [ "$SIZE_KB" -gt "$MAX_SIZE_KB" ]; then
    echo "File too large: $file (${SIZE_KB}KB, max ${MAX_SIZE_KB}KB)"
    exit 1
  fi
done

exit 0
```

**Limitations:** Doesn't measure complexity, only size

---

#### Missing Files: Tests and Documentation

**User says:** "require tests", "enforce documentation", "missing README"

**Clarify:** What's required?
- Test file alongside source?
- README for modules?
- JSDoc on exports?

**CHP Implementation:**
```bash
#!/bin/bash
# docs/chp/laws/require-tests/verify.sh

# Check that each .ts file has a corresponding .test.ts
FILES=$(git diff --cached --name-only | grep -E '^src/.*\.ts$' || true)
if [ -z "$FILES" ]; then exit 0; fi

for file in $FILES; do
  # Derive test file path
  test_file="${file/src/tests}"
  test_file="${test_file/.ts/.test.ts}"

  if [ ! -f "$test_file" ]; then
    echo "Missing test file: $test_file"
    exit 1
  fi
done

exit 0
```

**Limitations:** Doesn't verify test quality, only existence

---

#### Git Workflow: Commit Messages

**User says:** "enforce commit format", "require ticket number", "conventional commits"

**Clarify:** What format?
- Conventional commits (`feat:`, `fix:`)?
- Ticket number prefix (`ABC-123`)?
- Max length?

**CHP Implementation:**
```bash
#!/bin/bash
# docs/chp/laws/commit-message-format/verify.sh

# Read commit message
MESSAGE=$(cat "$1")

# Check for conventional commit format
if ! echo "$MESSAGE" | head -1 | grep -qE '^(feat|fix|docs|style|refactor|test|chore)(\(.+\))?: '; then
  echo "Commit must follow conventional commit format: type: description"
  echo "Types: feat, fix, docs, style, refactor, test, chore"
  exit 1
fi

# Check max length
FIRST_LINE=$(echo "$MESSAGE" | head -1)
if [ ${#FIRST_LINE} -gt 72 ]; then
  echo "First line too long: ${#FIRST_LINE} chars (max 72)"
  exit 1
fi

exit 0
```

**Limitations:** Can't verify semantic meaning, only format

---

## Section 2: AST-Based Analysis

### When to Use
- Code structure (nesting depth, function length)
- Complexity metrics (cyclomatic complexity)
- Unused variables/imports
- Type safety violations
- Pattern-specific checks (Promise without catch)

### Decision Tree
```
Does it require understanding code structure?
├─ Yes → Use AST analysis
│   ├─ JavaScript/TypeScript → ESLint custom rule or TS Compiler API
│   ├─ Python → Tree-sitter or AST module
│   └─ Other → Tree-sitter or language-specific AST
└─ No → Go to Section 1 (Regex/Shell)
```

### Real-World Patterns

#### Code Complexity: Nesting Depth

**User says:** "reduce nesting", "too deep", "complex callbacks"

**Clarify:** What's the threshold?
- Max nesting depth (default: 4)
- Block if exceeds?
- Which constructs? (if, for, function, try)

**ESLint equivalent:** `max-depth`, `complexity`

**CHP Implementation (ESLint Custom Rule):**
```javascript
// docs/chp/laws/max-nesting-depth/verify.js
const rule = {
  meta: {
    type: 'suggestion',
    docs: { description: 'enforce maximum nesting depth' },
    schema: [{ type: 'integer' }]
  },
  create(context) {
    const maxDepth = context.options[0] || 4;
    const stack = [];

    return {
      FunctionDeclaration() { stack.push(0); },
      'FunctionDeclaration:exit'() { stack.pop(); },

      IfStatement(node) {
        const depth = stack[stack.length - 1] || 0;
        if (depth >= maxDepth) {
          context.report({
            node,
            message: `Nesting depth too deep (${depth + 1}, max ${maxDepth})`
          });
        }
        if (stack.length > 0) stack[stack.length - 1]++;
      }
    };
  }
};

module.exports = rule;
```

**CHP verify.sh wrapper:**
```bash
#!/bin/bash
# docs/chp/laws/max-nesting-depth/verify.sh

# Run ESLint with custom rule
eslint --no-eslintrc --rule 'max-depth: [error, 4]' src/
exit $?
```

**Limitations:** Requires ESLint setup, may need custom rules for specific patterns

---

#### Unused Code: Imports and Variables

**User says:** "no unused imports", "remove dead code", "clean imports"

**Clarify:** Which unused items?
- Imports?
- Variables?
- Functions?
- Type-only?

**ESLint equivalent:** `no-unused-vars`, `no-imports-assign`

**CHP Implementation:**
```bash
#!/bin/bash
# docs/chp/laws/no-unused-imports/verify.sh

# Use TypeScript compiler to find unused
npx tsc --noEmit --noUnusedLocals --noUnusedParameters 2>&1 | grep "unused" && exit 1

# Or use ESLint
eslint --no-ignore src/ 2>&1 | grep "no-unused-vars" && exit 1

exit 0
```

**Limitations:** TypeScript-only, requires build setup

---

#### Async Patterns: Unhandled Promises

**User says:** "catch all promises", "no unhandled async", "await properly"

**Clarify:** What's the issue?
- Missing await?
- Promise without catch?
- Async function without try/catch?

**ESLint equivalent:** `no-floating-promises`, `require-await`

**CHP Implementation (TypeScript Compiler API):**
```typescript
// docs/chp/laws/no-unhandled-promises/verify.ts
import * as ts from 'typescript';

function checkFile(filePath: string): boolean {
  const source = ts.sys.readFile(filePath);
  if (!source) return false;

  const sourceFile = ts.createSourceFile(
    filePath,
    source,
    ts.ScriptTarget.Latest,
    true
  );

  let hasViolation = false;

  function visit(node: ts.Node) {
    // Check for Promise without await
    if (ts.isCallExpression(node)) {
      const type = checker.getTypeAtLocation(node);
      if (type.symbol?.name === 'Promise') {
        // Check if parent is await or return
        if (!ts.isAwaitExpression(node.parent) &&
            !ts.isReturnStatement(node.parent)) {
          console.log(`Unhandled Promise at ${node.getStart(sourceFile)}`);
          hasViolation = true;
        }
      }
    }
    ts.forEachChild(node, visit);
  }

  visit(sourceFile);
  return hasViolation;
}
```

**Limitations:** Complex AST traversal, language-specific

---

## Section 3: Delegated Tools

### When to Use
- Language-specific rules (ESLint, Prettier, Black)
- Comprehensive analysis (SonarQube, CodeQL)
- Security scanning (Semgrep, njsscan)
- Performance analysis (Lighthouse, bundle size)

### Decision Tree
```
Does an existing tool solve this?
├─ Yes → Delegate to that tool
│   ├─ Linter → ESLint, Prettier, Black
│   ├─ Security → Semgrep, CodeQL
│   ├─ Quality → SonarQube, DeepSource
│   └─ Performance → Lighthouse, webpack-bundle-analyzer
└─ No → Go to Section 2 (AST)
```

### Real-World Patterns

#### Code Style: Linting Rules

**User says:** "enforce style", "consistent formatting", "lint errors"

**Clarify:** Which linter?
- ESLint (JS/TS)
- Prettier (formatting)
- Black (Python)
- golangci-lint (Go)

**CHP Implementation:**
```bash
#!/bin/bash
# docs/chp/laws/eslint-rules/verify.sh

# Run ESLint, fail on any warnings
eslint --max-warnings 0 src/
exit $?
```

**Or Prettier:**
```bash
#!/bin/bash
# docs/chp/laws/prettier-format/verify.sh

# Check formatting without modifying
prettier --check "src/**/*.{js,ts,tsx,jsx,json,md}"
exit $?
```

**Limitations:** Requires tool configuration, may be slow on large codebases

---

#### Security: Vulnerability Scanning

**User says:** "find security issues", "scan for vulnerabilities", "no unsafe code"

**Clarify:** What type?
- Dependency vulnerabilities?
- Code patterns (SQL injection, XSS)?
- Secrets?

**Semgrep equivalent:** Security rules, `semgrep --config=auto`

**CHP Implementation:**
```bash
#!/bin/bash
# docs/chp/laws/security-scan/verify.sh

# Run Semgrep with security rules
semgrep --config=auto --error src/
exit $?
```

**Or npm audit:**
```bash
#!/bin/bash
# docs/chp/laws/dependency-audit/verify.sh

# Check for vulnerable dependencies
npm audit --audit-level=moderate
exit $?
```

**Limitations:** False positives, requires rule configuration

---

#### Type Safety: Type Checking

**User says:** "enforce types", "no any types", "strict mode"

**Clarify:** What type checking?
- TypeScript strict mode?
- Disallow `any`?
- Require return types?

**CHP Implementation:**
```bash
#!/bin/bash
# docs/chp/laws/type-check/verify.sh

# Run TypeScript compiler
npx tsc --noEmit
exit $?
```

**With specific checks:**
```bash
#!/bin/bash
# docs/chp/laws/no-any-type/verify.sh

# Use ESLint to find any types
eslint --no-ignore --rule 'no-explicit-any: error' src/
exit $?
```

**Limitations:** TypeScript-only, requires tsconfig

---

## Section 4: Hybrid Patterns

### When to Use
- Context-aware checks (allow console.log in tests)
- Multi-condition rules
- File-type specific behavior
- Environment-specific rules

### Decision Tree
```
Does the rule need context or multiple conditions?
├─ Yes → Use hybrid approach
│   ├─ Combine grep + file path check
│   ├─ Combine AST + git diff
│   └─ Combine tool + custom filter
└─ No → Use simpler section
```

### Real-World Patterns

#### Conditional Enforcement: Context-Aware

**User says:** "no console.log except in tests", "allow TODO with ticket"

**Clarify:** What's the exception?
- File path patterns?
- Comments with specific format?
- Environment variables?

**CHP Implementation:**
```bash
#!/bin/bash
# docs/chp/laws/no-console-log-except-tests/verify.sh

# Find console.log in non-test files
FILES=$(git diff --cached --name-only | grep -E '\.(js|ts)$' || true)
if [ -z "$FILES" ]; then exit 0; fi

for file in $FILES; do
  # Skip test files
  if echo "$file" | grep -qE '\.test\.(js|ts)|spec\.|test/'; then
    continue
  fi

  # Check for console.log
  if grep -q "console\.log" "$file" 2>/dev/null; then
    echo "console.log found in $file (not allowed outside tests)"
    exit 1
  fi
done

exit 0
```

**Limitations:** More complex logic, harder to maintain

---

#### TODO Comments: Require Ticket

**User says:** "TODO must have ticket", "no unresolved TODOs"

**Clarify:** What's required?
- Ticket number format? (ABC-123, #123)
- Link to issue?
- Block commits?

**CHP Implementation:**
```bash
#!/bin/bash
# docs/chp/laws/todo-with-ticket/verify.sh

# Check for TODO without ticket
PATTERNS=(
  "TODO[^:]"           # TODO not followed by colon
  "FIXME[^:]"          # FIXME not followed by colon
  "HACK"               # Any HACK comment
)

FILES=$(git diff --cached --name-only || true)
if [ -z "$FILES" ]; then exit 0; fi

for pattern in "${PATTERNS[@]}"; do
  # Find TODOs without ticket reference
  MATCHES=$(echo "$FILES" | xargs grep -n "$pattern" 2>/dev/null | grep -vE "([A-Z]+-[0-9]+|#\d+)" || true)
  if [ -n "$MATCHES" ]; then
    echo "TODO/FIXME without ticket reference:"
    echo "$MATCHES"
    exit 1
  fi
done

exit 0
```

**Limitations:** Can't verify ticket exists, only format

---

#### Import Structure: Enforce Ordering

**User says:** "organize imports", "import groups", "no absolute imports"

**Clarify:** What order?
- External → Internal → Relative?
- Alphabetical?
- Grouped by type?

**ESLint equivalent:** `import/order`, `no-relative-imports`

**CHP Implementation:**
```bash
#!/bin/bash
# docs/chp/laws/import-order/verify.sh

# Use ESLint import/order rule
eslint --no-ignore --rule 'import/order: [error, {groups: ["builtin", "external", "internal", "parent", "sibling", "index"]}]' src/
exit $?
```

**Or custom check:**
```bash
#!/bin/bash
# docs/chp/laws/no-absolute-imports/verify.sh

# Block absolute imports from src/
FILES=$(git diff --cached --name-only | grep -E '\.(ts|tsx)$' || true)
if [ -z "$FILES" ]; then exit 0; fi

for file in $FILES; do
  # Check for imports from src/ using absolute path
  if grep -q "from ['\"]src/" "$file" 2>/dev/null; then
    echo "Absolute import from src/ found in $file"
    echo "Use relative imports instead: from '../../...'"
    exit 1
  fi
done

exit 0
```

**Limitations:** May conflict with IDE auto-imports, project-specific

---

## Quick Reference: Pattern Matching

| User Request | Section | Detection Method | Example |
|--------------|---------|------------------|---------|
| "no API keys" | 1 | Regex | `sk_\|AIza` |
| "no console.log" | 1 | Regex | `console\.log` |
| "file too big" | 1 | Shell | `wc -l > 500` |
| "missing tests" | 1 | File existence | `test.ts` exists |
| "commit format" | 1 | Regex | Conventional commits |
| "too nested" | 2 | AST | Nesting depth check |
| "unused imports" | 2 | AST | TypeScript compiler |
| "unhandled promise" | 2 | AST | Promise without await |
| "enforce style" | 3 | Delegated | ESLint/Prettier |
| "security scan" | 3 | Delegated | Semgrep |
| "type safety" | 3 | Delegated | `tsc --noEmit` |
| "console in tests only" | 4 | Hybrid | Regex + file path |
| "TODO with ticket" | 4 | Hybrid | Regex with exceptions |
| "import order" | 4 | Hybrid | ESLint + custom |

---

## Implementation Checklist

When implementing a law:

1. **Clarify the requirement** - What exactly should be blocked?
2. **Choose detection method** - Simplest method that works
3. **Write verify.sh** - Use templates above
4. **Write law.json** - Metadata and hooks
5. **Write guidance.md** - Explain what and why
6. **Test the law** - `chp-law test <law-name>`
7. **Deploy** - Install hooks with `chp-hooks install`

---

## Contributing

Found a pattern that should be included? Add it to the appropriate section with:
- User language that triggers it
- Clarifying questions
- CHP implementation template
- Limitations

The goal is to make pattern recognition instant for agents.

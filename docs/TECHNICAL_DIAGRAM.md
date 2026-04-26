# CHP Technical Architecture

## System Overview

**Repository:** github.com/code-highway-patrol/chp  
**Total Size:** ~6,000 lines (185KB Bash, 26KB JS, 187KB Markdown)  
**Active Laws:** 7 | **Hook Types:** 25+ | **Test Suites:** 12

---

## Architecture Layers

### Layer 1: AI Agents (Entry Points)

| Platform | Integration |
|----------|-------------|
| Claude Code | `.claude-plugin/` - Skills + hooks |
| OpenAI Codex | `.codex-plugin/` - Plugin manifest |
| Cursor IDE | `.cursor-plugin/` - Plugin + registry |
| Windsurf | `.windsurf-plugin/` - MCP server |
| Gemini | `gemini-extension.json` |

**Key Feature:** One law definition works across all AI tools.

---

### Layer 2: Hook Interception

```
Git Hooks (15)              Agent Hooks (6)
─────────────               ───────────────
pre-commit                  pre-tool
pre-push                    post-tool
post-commit                 pre-prompt
pre-rebase                  post-prompt
commit-msg                  pre-response
[10 more...]                post-response
```

**Innovation:** Blocks at tool-call layer, not after file save.

---

### Layer 3: Core Engine

| Component | Size | Purpose |
|-----------|------|---------|
| `dispatcher.sh` | 7.2KB | Routes violations to checkers |
| `hook-registry.sh` | 6.7KB | 25+ hook type management |
| `logger.sh` | 2.5KB | JSONL citation logging |
| `law-mutate.sh` | 12.8KB | Atomic law updates |
| `probe.sh` | 11.5KB | Test data generation |
| `tightener.sh` | 1.7KB | Auto-escalation logic |

---

### Layer 4: Atomic Checkers

| Checker | Purpose |
|---------|---------|
| `pattern.sh` | Regex-based matching |
| `threshold.sh` | Metric gating (lines, complexity) |
| `structural.sh` | Cross-file validation |
| `agent.sh` | AI-guided prompt checks |

---

### Layer 5: Law Definitions

**Each law contains:**
- `law.json` - Configuration (checks, severity, hooks)
- `verify.sh` - Delegates to checkers
- `guidance.md` - Human documentation
- `probes.json` (optional) - Test patterns

**Active Laws:**
- `no-api-keys` - Secret detection
- `no-console-log` - Structured logging enforcement
- `migration-safety` - Rollback verification
- `no-todos` - Ticket tracking
- `mandarin-only` - Language enforcement
- `no-alerts` - Alert hygiene
- `test-scope` - Scoped testing

---

### Layer 6: CLI & Skills

**Commands:**
- `chp-law` - Law CRUD + interactive builder
- `chp-status` - System monitoring
- `chp-audit` - Cross-repo reports
- `chp-doctor` - Health diagnostics
- `chp-hooks` - Hook installation

**Skills:**
- `write-laws` - Interactive law creation
- `review-laws` - Consistency validation
- `investigate` - Violation debugging
- `audit` - Codebase scanning
- `status` - Reporting

---

## Data Flow

```
AI Agent → Tool Call → Hook Intercept → Dispatcher → Checkers → Law
                                              ↓
AI Self-Correct ← Fix Suggestion ← Logger/JSONL ← Violation
```

---

## File Statistics

| Category | Count | Size |
|----------|-------|------|
| Bash scripts | 53 | ~185KB |
| JS files | 6 | ~26KB |
| JSON configs | 12 | ~25KB |
| Markdown docs | 28 | ~187KB |
| Test suites | 12 | ~55KB |

---

## Design Principles

1. **Bash-First:** Enforcement at shell layer for speed/portability
2. **Atomic Checks:** Laws decompose into 4 check types
3. **Multi-Platform:** One definition, all AI tools
4. **Pre-Write:** Block at tool-call, not post-save
5. **Structured Logging:** JSONL for audit trails
6. **Auto-Tightening:** Escalate based on violations

# CHP Logging System Design

**Date:** 2026-04-25
**Status:** Approved

## Overview

Single-file logging system using JSONL format at `.chp/logs.jsonl`. Every CHP event (evaluation, violation, hook trigger, law change) is logged as a JSON line with full context. Logging happens automatically in the core shell scripts.

**Key points:**
- Log everything - no configuration needed for now
- JSONL format for easy parsing and analysis
- Located at `.chp/logs.jsonl` (gitignored)
- Shell-only implementation (no TypeScript)
- Minimal performance impact

## Log Entry Schema

Each log entry is a JSON object with these fields:

```typescript
interface LogEntry {
  timestamp: string;           // ISO 8601 timestamp (UTC)
  event_type: string;          // "violation" | "evaluation" | "hook_trigger" | "law_change" | "hook_install"
  law_id?: string;             // ID of the law involved (if applicable)
  action?: string;             // Action being evaluated (tool, command, etc.)
  result?: string;             // "blocked" | "warned" | "fixed" | "passed"
  pattern?: string;            // Pattern that matched (for violations)
  fix?: string;                // Suggested fix (for violations)
  files?: string;             // Comma-separated list of files involved
  hook_type?: string;          // Hook that triggered (pre-commit, pre-tool, etc.)
  details?: string;            // Additional context (JSON string)
}
```

**Example entries:**

```jsonl
{"timestamp":"2026-04-24T23:30:00Z","event_type":"violation","law_id":"no-api-keys","action":"git commit","result":"blocked","pattern":"sk_.*","fix":"use environment variable","files":"src/config.ts","hook_type":"pre-commit"}
{"timestamp":"2026-04-24T23:31:00Z","event_type":"evaluation","law_id":"max-line-length","action":"Edit tool","result":"passed","files":"src/index.ts"}
{"timestamp":"2026-04-24T23:32:00Z","event_type":"law_change","law_id":"new-security-law","details":"{\"action\":\"created\",\"hooks\":[\"pre-commit\",\"pre-push\"]}"}
{"timestamp":"2026-04-24T23:33:00Z","event_type":"hook_install","hook_type":"pre-commit","laws":"no-api-keys,no-console-log"}
```

## Logger Module

**File:** `core/logger.sh`

```bash
#!/bin/bash
# core/logger.sh - CHP Logging System

CHP_LOG_DIR=".chp"
CHP_LOG_FILE="$CHP_LOG_DIR/logs.jsonl"

# Initialize log directory and file
logger_init() {
    mkdir -p "$CHP_LOG_DIR" 2>/dev/null
    touch "$CHP_LOG_FILE" 2>/dev/null
}

# Log an event
# Usage: logger_log "event_type" "key1" "value1" "key2" "value2" ...
logger_log() {
    local event_type="$1"
    shift

    local timestamp=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
    local entry="{\"timestamp\":\"$timestamp\",\"event_type\":\"$event_type\""

    # Parse key-value pairs
    while [[ $# -gt 0 ]]; do
        local key="$1"
        local value="$2"
        # Escape JSON special characters in value
        value=$(echo "$value" | sed 's/"/\\"/g')
        entry="$entry,\"$key\":\"$value\""
        shift 2
    done

    entry="$entry}"
    echo "$entry" >> "$CHP_LOG_FILE" 2>/dev/null
}

# Convenience methods
logger_violation() {
    logger_log "violation" \
        "law_id" "$1" \
        "action" "$2" \
        "result" "$3" \
        "pattern" "$4" \
        "fix" "$5" \
        "files" "$6" \
        "hook_type" "$7"
}

logger_evaluation() {
    logger_log "evaluation" \
        "law_id" "$1" \
        "action" "$2" \
        "result" "$3" \
        "files" "$4"
}

logger_hook_trigger() {
    logger_log "hook_trigger" \
        "hook_type" "$1" \
        "laws" "$2"
}

logger_hook_install() {
    logger_log "hook_install" \
        "hook_type" "$1" \
        "laws" "$2"
}

logger_law_change() {
    logger_log "law_change" \
        "law_id" "$1" \
        "details" "$2"
}
```

## Integration Points

The logger will be integrated into these shell scripts:

### 1. Verifier (`core/verifier.sh`)
- Source `logger.sh` at the top
- Call `logger_init()` on startup
- Log each law verification with result
- Log violations with full details

### 2. Dispatcher (`core/dispatcher.sh`)
- Source `logger.sh` at the top
- Call `logger_init()` on startup
- Log high-level events

### 3. Tightener (`core/tightener.sh`)
- Source `logger.sh` at the top
- Log when laws are tightened

### 4. Installer (`core/installer.sh`)
- Source `logger.sh` at the top
- Log hook installation/uninstallation events

## Usage Example

```bash
#!/bin/bash
# In verifier.sh

# Source the logger
source "$(dirname "$0")/logger.sh"

# Initialize
logger_init

# When checking a law
if grep -q "sk_" "$file"; then
    logger_violation "no-api-keys" "git commit" "blocked" "sk_.*" "use environment variable" "$file" "pre-commit"
    exit 1
else
    logger_evaluation "no-api-keys" "git commit" "passed" "$file"
fi
```

## Error Handling & Edge Cases

**What happens when:**

1. **Log file doesn't exist** - Created by `logger_init()`
2. **`.chp` directory doesn't exist** - Created by `logger_init()`
3. **Write fails** - Silently fail (don't break CHP operations), stderr redirected to /dev/null
4. **Corrupted log line** - Skip it during parsing (JSONL is resilient)
5. **Concurrent writes** - Accept rare race condition (logs are best-effort)
6. **Disk space** - Monitor file size, warn if >10MB (manual check)

**Git Ignore:**
Add `.chp/logs.jsonl` to project `.gitignore` - logs are local, not tracked.

## File Structure

```
chp/
├── core/
│   ├── logger.sh          # New: Logger functions
│   ├── verifier.sh        # Modified: Add logging calls
│   ├── dispatcher.sh      # Modified: Add logging calls
│   ├── tightener.sh       # Modified: Add logging calls
│   └── installer.sh       # Modified: Add logging calls
├── tests/
│   └── logger.test.sh     # New: Logger tests
├── .chp/
│   └── logs.jsonl         # New: Log file (gitignored)
└── .gitignore             # Modified: Add .chp/logs.jsonl
```

## Testing Strategy

**Unit Tests (`tests/logger.test.sh`):**
- Logger creates log file if it doesn't exist
- Logger appends entries correctly
- Log entries parse as valid JSON
- Convenience methods log correct event types
- Special characters are properly escaped

**Integration Tests:**
- Verifier logs violations when blocking
- Verifier logs passes when no violations
- Hook registry logs trigger events
- Multiple sequential writes create valid JSONL

**Manual Testing:**
- Run CHP operations, verify logs appear
- Check log file grows correctly
- Verify gitignore excludes logs.jsonl

## Event Types

| Event Type | Description | Fields |
|------------|-------------|--------|
| `violation` | A law was violated | law_id, action, result, pattern, fix, files, hook_type |
| `evaluation` | An action was evaluated | law_id, action, result, files |
| `hook_trigger` | A hook was triggered | hook_type, laws |
| `hook_install` | A hook was installed/uninstalled | hook_type, laws |
| `law_change` | A law was created/modified/deleted | law_id, details |

## Future Considerations

Out of scope for initial implementation:
- Log rotation (daily files)
- Log size limits and cleanup
- Query/analysis tools
- Remote logging
- Configuration for log levels

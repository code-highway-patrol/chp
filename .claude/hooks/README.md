# CHP Claude Code Hook Integration

This directory contains CHP hooks for Claude Code.

## Setup

Add to your `.claude/settings.json`:

```json
{
  "hooks": {
    "pre-tool": {
      "enabled": true,
      "command": "bash /path/to/chp/.claude/hooks/pre-tool.sh"
    },
    "post-tool": {
      "enabled": true,
      "command": "bash /path/to/chp/.claude/hooks/post-tool.sh"
    }
  }
}
```

## Available Hooks

- `pre-prompt.sh` - Runs before user prompt
- `post-prompt.sh` - Runs after user prompt
- `pre-tool.sh` - Runs before tool execution (can block)
- `post-tool.sh` - Runs after tool execution
- `pre-response.sh` - Runs before agent response
- `post-response.sh` - Runs after agent response

## Installation

Run `bash .claude/hooks/install.sh` to install hooks to this directory.

Or manually copy from `hooks/agent/` to `.claude/hooks/`.

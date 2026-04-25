# Quick Start - Install CHP in Windsurf

## Step 1: Add MCP Server to Windsurf Settings

Open Windsurf Settings → MCP Servers and add:

```json
{
  "mcpServers": {
    "chp": {
      "command": "node",
      "args": ["./lib/mcp-server.js"],
      "env": {
        "CHP_ROOT": "${workspaceFolder}"
      }
    }
  }
}
```

Or add to your project's `.windsurf/settings.json`:

```json
{
  "mcpServers": {
    "chp": {
      "command": "node",
      "args": ["./node_modules/chp/lib/mcp-server.js"],
      "env": {
        "CHP_ROOT": "${workspaceFolder}"
      }
    }
  }
}
```

## Step 2: Restart Windsurf

Restart Windsurf to load the MCP server.

## Step 3: Verify Installation

Ask Cascade:
```
"What CHP tools are available?"
```

You should see:
- chp_analyze
- chp_check
- chp_create_law
- chp_validate

## Step 4: Start Using

```
"Run CHP analysis on my codebase"
"Check for violations in src/"
"Create a new traffic law"
```

## Tips

- The MCP server runs locally - no data leaves your machine
- CHP respects your .gitignore and .chprc configuration
- Use Cascade's native understanding to refine violations

# CHP for Windsurf IDE

The Code Highway Patrol plugin for Windsurf brings automated code quality enforcement to your AI-native development workflow.

## Features

- **🚔 Traffic Law Enforcement** - Automatically detect and prevent code quality violations
- **🤖 Cascade AI Integration** - Leverage Windsurf's AI agent for intelligent code analysis
- **📋 MCP Server** - Full Model Context Protocol support for deep IDE integration
- **🔧 Git Hooks** - Pre-commit and pre-push hooks to catch violations before they're committed
- **⚡ Real-time Validation** - Instant feedback on rule violations

## Installation

### Option 1: Manual Installation

1. Copy the `.windsurf-plugin` directory to your project root:
   ```bash
   cp -r path/to/chp/.windsurf-plugin ./
   ```

2. Add the MCP server to your Windsurf settings (`~/.windsurf/settings.json` or project-level):
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

### Option 2: Windsurf Plugin Store

Once published, you can install directly from Windsurf's Plugin Store:
1. Open Windsurf Settings
2. Navigate to Plugins
3. Search for "CHP - Code Highway Patrol"
4. Click Install

## Usage

### With Cascade AI

Ask Cascade to run CHP analysis:
```
"Run CHP analysis on this file"
"Check for console.log violations"
"Create a new traffic law for API keys"
```

### MCP Tools

The plugin provides these MCP tools that Cascade can use:

- **chp_analyze** - Run full codebase analysis
- **chp_check** - Check specific files or rules
- **chp_create_law** - Create a new traffic law
- **chp_validate** - Validate CHP configuration

### Example Prompts for Cascade

```
"Use chp_analyze to check for any violations in my codebase"
"Run chp_check on src/utils/auth.js for security rules"
"Create a law called no-hardcoded-secrets with pre-commit hook"
```

## Configuration

CHP respects your project's `.chprc` or `chp.config.js` file:

```javascript
module.exports = {
  rules: {
    'no-console': 'error',
    'no-secrets': 'error',
    'max-line-length': ['warn', 120]
  },
  ignore: ['node_modules/**', 'dist/**']
};
```

## Creating Custom Laws

Use the MCP tool or CLI:

```bash
# Via CLI
./commands/chp-law create my-law --hooks=pre-commit

# Via Cascade
"Create a law called enforce-typescript with pre-push hook"
```

## Troubleshooting

### MCP Server Not Starting

1. Ensure Node.js >= 18.0.0 is installed
2. Verify the MCP server path in Windsurf settings
3. Check Windsurf's developer console for errors

### Tools Not Available

1. Restart Windsurf after installing the plugin
2. Verify the MCP server is running in Settings > MCP Servers
3. Check that CHP_ROOT environment variable is set correctly

## Resources

- [CHP Documentation](https://github.com/yourusername/chp)
- [Windsurf Documentation](https://windsurf.ai)
- [MCP Protocol](https://modelcontextprotocol.io)

## License

MIT

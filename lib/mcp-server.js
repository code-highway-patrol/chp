#!/usr/bin/env node

/**
 * CHP MCP Server for Windsurf IDE
 *
 * This MCP server provides CHP (Code Highway Patrol) functionality
 * to Windsurf's Cascade AI through the Model Context Protocol.
 */

const { execSync } = require('child_process');
const path = require('path');
const fs = require('fs');

// Simple MCP server implementation
class CHPMcpServer {
  constructor() {
    this.tools = {
      chp_analyze: this.handleAnalyze.bind(this),
      chp_check: this.handleCheck.bind(this),
      chp_create_law: this.handleCreateLaw.bind(this),
      chp_validate: this.handleValidate.bind(this)
    };
  }

  async handleAnalyze(args = {}) {
    try {
      const rules = args.rules ? args.rules.map(r => `--rule ${r}`).join(' ') : '';
      const severity = args.severity ? `--severity ${args.severity}` : '';

      const cmd = `npm run analyze -- ${rules} ${severity}`;
      const result = execSync(cmd, {
        encoding: 'utf-8',
        cwd: process.env.CHP_ROOT || process.cwd()
      });

      return {
        content: [{
          type: 'text',
          text: result
        }]
      };
    } catch (error) {
      return {
        content: [{
          type: 'text',
          text: `Analysis failed: ${error.message}`
        }],
        isError: true
      };
    }
  }

  async handleCheck(args = {}) {
    try {
      const files = args.files ? args.files.join(' ') : '';
      const rule = args.rule ? `--rule ${args.rule}` : '';

      const cmd = `npm run check -- ${files} ${rule}`;
      const result = execSync(cmd, {
        encoding: 'utf-8',
        cwd: process.env.CHP_ROOT || process.cwd()
      });

      return {
        content: [{
          type: 'text',
          text: result
        }]
      };
    } catch (error) {
      return {
        content: [{
          type: 'text',
          text: `Check failed: ${error.message}`
        }],
        isError: true
      };
    }
  }

  async handleCreateLaw(args) {
    try {
      const { name, description, hooks } = args;
      const hooksStr = Array.isArray(hooks) ? hooks.join(',') : hooks;

      const cmd = `./commands/chp-law create ${name} --hooks="${hooksStr}"`;
      const result = execSync(cmd, {
        encoding: 'utf-8',
        cwd: process.env.CHP_ROOT || process.cwd()
      });

      return {
        content: [{
          type: 'text',
          text: `Law "${name}" created successfully!\n\n${result}`
        }]
      };
    } catch (error) {
      return {
        content: [{
          type: 'text',
          text: `Failed to create law: ${error.message}`
        }],
        isError: true
      };
    }
  }

  async handleValidate(args = {}) {
    try {
      const law = args.law || '';
      const cmd = `npm run validate -- ${law}`;
      const result = execSync(cmd, {
        encoding: 'utf-8',
        cwd: process.env.CHP_ROOT || process.cwd()
      });

      return {
        content: [{
          type: 'text',
          text: result
        }]
      };
    } catch (error) {
      return {
        content: [{
          type: 'text',
          text: `Validation failed: ${error.message}`
        }],
        isError: true
      };
    }
  }

  // MCP protocol handlers
  async handleRequest(message) {
    const { method, params } = message;

    switch (method) {
      case 'tools/list':
        return {
          tools: [
            {
              name: 'chp_analyze',
              description: 'Run full CHP analysis on the codebase',
              inputSchema: {
                type: 'object',
                properties: {
                  rules: { type: 'array', items: { type: 'string' } },
                  severity: { type: 'string', enum: ['error', 'warn', 'info'] }
                }
              }
            },
            {
              name: 'chp_check',
              description: 'Check specific files or rules',
              inputSchema: {
                type: 'object',
                properties: {
                  files: { type: 'array', items: { type: 'string' } },
                  rule: { type: 'string' }
                }
              }
            },
            {
              name: 'chp_create_law',
              description: 'Create a new CHP traffic law',
              inputSchema: {
                type: 'object',
                required: ['name', 'hooks'],
                properties: {
                  name: { type: 'string' },
                  description: { type: 'string' },
                  hooks: { type: 'array', items: { type: 'string' } }
                }
              }
            },
            {
              name: 'chp_validate',
              description: 'Validate CHP configuration',
              inputSchema: {
                type: 'object',
                properties: {
                  law: { type: 'string' }
                }
              }
            }
          ]
        };

      case 'tools/call':
        const tool = this.tools[params.name];
        if (tool) {
          return await tool(params.arguments || {});
        }
        throw new Error(`Unknown tool: ${params.name}`);

      case 'resources/list':
        return {
          resources: [
            {
              uri: `file://${process.env.CHP_ROOT || process.cwd()}/docs/chp`,
              name: 'CHP Documentation',
              description: 'Context files for CHP laws and guidance',
              mimeType: 'text/markdown'
            }
          ]
        };

      default:
        throw new Error(`Unknown method: ${method}`);
    }
  }
}

// Simple stdio server for MCP
if (require.main === module) {
  const server = new CHPMcpServer();

  process.stdin.setEncoding('utf-8');

  let buffer = '';
  process.stdin.on('data', (chunk) => {
    buffer += chunk;

    // Process complete JSON-RPC messages
    while (true) {
      const newlineIndex = buffer.indexOf('\n');
      if (newlineIndex === -1) break;

      const messageStr = buffer.slice(0, newlineIndex);
      buffer = buffer.slice(newlineIndex + 1);

      if (!messageStr.trim()) continue;

      try {
        const message = JSON.parse(messageStr);
        server.handleRequest(message).then(result => {
          process.stdout.write(JSON.stringify({
            jsonrpc: '2.0',
            id: message.id,
            result
          }) + '\n');
        }).catch(error => {
          process.stdout.write(JSON.stringify({
            jsonrpc: '2.0',
            id: message.id,
            error: {
              code: -32000,
              message: error.message
            }
          }) + '\n');
        });
      } catch (error) {
        // Ignore parse errors for partial messages
      }
    }
  });
}

module.exports = CHPMcpServer;

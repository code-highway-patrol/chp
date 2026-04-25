#!/usr/bin/env node

import { program } from 'commander';
import chalk from 'chalk';
import path from 'path';
import { fileURLToPath } from 'url';

const __dirname = path.dirname(fileURLToPath(import.meta.url));

program
  .name('chp')
  .description('Code Highway Patrol - Static analysis framework')
  .version('1.0.0');

program
  .command('ui')
  .description('Launch CHP web UI')
  .option('-p, --port <port>', 'Port to run on', '3000')
  .action(async (options) => {
    const port = parseInt(options.port) || 3000;
    const { startServer } = await import('../server/index.cjs');
    startServer(port);
  });

program
  .command('serve')
  .description('Start CHP MCP server for IDE integration')
  .option('-p, --port <port>', 'Port to run on', '3100')
  .action(async (options) => {
    const port = parseInt(options.port) || 3100;
    const { startMcpServer } = await import('../lib/mcp-server.cjs');
    startMcpServer(port);
  });

program
  .command('analyze')
  .description('Run full codebase analysis')
  .option('--severity <level>', 'Minimum severity level', 'info')
  .option('--scope <scope>', 'Analysis scope', 'all')
  .option('--output <format>', 'Output format', 'text')
  .option('--fix', 'Auto-fix issues', false)
  .action(async (options) => {
    const { analyze } = await import('../scripts/analyze.js');
    await analyze(options);
  });

program
  .command('check')
  .description('Check specific files or rules')
  .argument('[target]', 'File, directory, or pattern')
  .option('--rule <id>', 'Specific rule ID')
  .option('--severity <level>', 'Minimum severity', 'warning')
  .action(async (target, options) => {
    const { check } = await import('../scripts/check.js');
    await check(target, options);
  });

program
  .command('validate')
  .description('Validate CHP configuration')
  .option('--rules', 'Validate rules', true)
  .option('--config', 'Validate config', true)
  .option('--schema', 'Validate schemas', true)
  .action(async (options) => {
    const { validate } = await import('../scripts/validate.js');
    await validate(options);
  });

program
  .command('laws')
  .description('Manage CHP laws')
  .argument('<command>', 'create|list|delete|test|disable|enable')
  .argument('[args...]', 'Arguments for the command')
  .action(async (cmd, args) => {
    const result = await import('../lib/cli-laws.js');
    await result.runLawsCommand(cmd, args);
  });

program.parse();
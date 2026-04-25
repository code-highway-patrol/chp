#!/usr/bin/env node

import { program } from 'commander';
import chalk from 'chalk';

program
  .name('chp')
  .description('Code Highway Patrol - Static analysis framework')
  .version('1.0.0');

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
  .description('List registered CHP laws')
  .action(async () => {
    console.log(chalk.bold.blue('CHP Registered Laws'));
    console.log(chalk.gray('='.repeat(50)));
    // Law listing would be implemented here
    console.log(chalk.gray('Use the Chief agent to manage laws'));
  });

program.parse();

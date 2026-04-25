#!/usr/bin/env node

import { program } from 'commander';
import chalk from 'chalk';
import fastGlob from 'fast-glob';
const { glob } = fastGlob;
import { readFileSync } from 'fs';
import { resolve, join } from 'path';
import yaml from 'js-yaml';

const __dirname = resolve();

function loadRules() {
  const rulesDir = join(__dirname, 'assets', 'rules');
  try {
    const ruleFiles = glob.sync(['**/*.json', '**/*.yaml', '**/*.yml'], {
      cwd: rulesDir,
      absolute: true
    });

    return ruleFiles.map(file => {
      const content = readFileSync(file, 'utf8');
      const ext = file.split('.').pop();
      return ext === 'yaml' || ext === 'yml'
        ? yaml.load(content)
        : JSON.parse(content);
    });
  } catch (error) {
    console.warn(chalk.yellow('Warning: Could not load rules:', error.message));
    return [];
  }
}

function calculateHealthScore(findings) {
  const errorWeight = 10;
  const warningWeight = 3;
  const infoWeight = 1;

  let totalDeductions = 0;
  findings.forEach(f => {
    if (f.severity === 'error') totalDeductions += errorWeight;
    else if (f.severity === 'warning') totalDeductions += warningWeight;
    else totalDeductions += infoWeight;
  });

  return Math.max(0, 100 - totalDeductions);
}

async function analyzeFiles(scope, severity) {
  const patterns = ['**/*.{js,ts,jsx,tsx,py,java,go,rs}'];
  const ignore = ['**/node_modules/**', '**/dist/**', '**/build/**', '**/.git/**'];

  let files;
  if (scope === 'staged') {
    // For staged files, we'd use git commands
    console.log(chalk.yellow('Staged file analysis requires git context'));
    files = glob.sync(patterns, { ignore, cwd: __dirname });
  } else if (scope === 'changed') {
    // For changed files, we'd use git diff
    console.log(chalk.yellow('Changed file analysis requires git context'));
    files = glob.sync(patterns, { ignore, cwd: __dirname });
  } else {
    files = glob.sync(patterns, { ignore, cwd: __dirname });
  }

  const rules = loadRules();
  const findings = [];

  // Simple pattern-based checking
  files.forEach(file => {
    try {
      const content = readFileSync(join(__dirname, file), 'utf8');

      rules.forEach(rule => {
        if (rule.patterns && rule.patterns.checks) {
          rule.patterns.checks.forEach(check => {
            if (check.type === 'pattern' && check.regex) {
              const regex = new RegExp(check.regex, 'g');
              let match;
              let lineNum = 1;
              const lines = content.split('\n');

              lines.forEach((line, idx) => {
                if (regex.test(line)) {
                  findings.push({
                    file,
                    line: idx + 1,
                    rule: rule.id,
                    message: rule.description || check.message || 'Pattern matched',
                    severity: rule.severity || 'warning',
                    code: line.trim()
                  });
                }
              });
            }
          });
        }
      });
    } catch (error) {
      // Skip files that can't be read
    }
  });

  return findings;
}

function severityOrder(s) {
  const order = { error: 0, warning: 1, info: 2 };
  return order[s] ?? 2;
}

export async function analyze(options = {}) {
  const { severity = 'info', scope = 'all', output = 'text', fix = false } = options;

  console.log(chalk.bold.blue('CHP Analysis'));
  console.log(chalk.gray('='.repeat(50)));
  console.log(chalk.gray(`Scope: ${scope} | Severity: ${severity} | Fix: ${fix}`));
  console.log();

  const findings = await analyzeFiles(scope, severity);
  const filtered = findings.filter(f => {
    const order = { error: 0, warning: 1, info: 2 };
    return order[f.severity] <= order[severity];
  });

  const healthScore = calculateHealthScore(filtered);

  if (output === 'json') {
    console.log(JSON.stringify({
      healthScore,
      findings: filtered,
      summary: {
        total: filtered.length,
        bySeverity: {
          error: filtered.filter(f => f.severity === 'error').length,
          warning: filtered.filter(f => f.severity === 'warning').length,
          info: filtered.filter(f => f.severity === 'info').length
        }
      }
    }, null, 2));
  } else {
    // Health score
    const scoreColor = healthScore >= 80 ? 'green' : healthScore >= 50 ? 'yellow' : 'red';
    console.log(chalk.bold(`Health Score: ${chalk[scoreColor](healthScore + '/100')}`));
    console.log();

    // Group by severity
    const bySeverity = { error: [], warning: [], info: [] };
    filtered.forEach(f => bySeverity[f.severity].push(f));

    ['error', 'warning', 'info'].forEach(sev => {
      const items = bySeverity[sev];
      if (items.length > 0) {
        const color = sev === 'error' ? 'red' : sev === 'warning' ? 'yellow' : 'blue';
        console.log(chalk.bold[color](sev.toUpperCase() + ` (${items.length})`));

        items.slice(0, 10).forEach(f => {
          console.log(`  ${chalk.gray(f.file)}:${chalk.gray(f.line)}`);
          console.log(`    ${color(f.message)}`);
          if (f.code) {
            console.log(`    ${chalk.gray('    ' + f.code.substring(0, 60))}`);
          }
        });

        if (items.length > 10) {
          console.log(chalk.gray(`  ... and ${items.length - 10} more`));
        }
        console.log();
      }
    });

    // Summary
    console.log(chalk.bold('Summary:'));
    console.log(`  Total findings: ${filtered.length}`);
    console.log(`  Errors: ${bySeverity.error.length}`);
    console.log(`  Warnings: ${bySeverity.warning.length}`);
    console.log(`  Info: ${bySeverity.info.length}`);
  }

  return filtered.filter(f => f.severity === 'error').length > 0 ? 1 : 0;
}

// CLI interface
program
  .name('chp-analyze')
  .description('Code Highway Patrol - Analyze codebase')
  .option('--severity <level>', 'Minimum severity level', 'info')
  .option('--scope <scope>', 'Analysis scope (all|staged|changed)', 'all')
  .option('--output <format>', 'Output format (json|text|markdown)', 'text')
  .option('--fix', 'Automatically fix issues', false)
  .action(async (options) => {
    const exitCode = await analyze(options);
    process.exit(exitCode);
  });

// Only parse if run directly
if (import.meta.url === `file://${process.argv[1]}` || import.meta.url === `file://${process.argv[1].replace(/\\/g, '/')}`) {
  program.parse();
}

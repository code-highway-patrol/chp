#!/usr/bin/env node

import { program } from 'commander';
import chalk from 'chalk';
import { glob } from 'fast-glob';
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
    return [];
  }
}

function checkFile(file, rules, minSeverity) {
  const findings = [];

  try {
    const content = readFileSync(join(__dirname, file), 'utf8');
    const lines = content.split('\n');

    rules.forEach(rule => {
      if (rule.patterns && rule.patterns.checks) {
        rule.patterns.checks.forEach(check => {
          if (check.type === 'pattern' && check.regex) {
            const regex = new RegExp(check.regex);

            lines.forEach((line, idx) => {
              if (regex.test(line)) {
                const severity = rule.severity || 'warning';
                const order = { error: 0, warning: 1, info: 2 };
                if (order[severity] <= order[minSeverity]) {
                  findings.push({
                    file,
                    line: idx + 1,
                    rule: rule.id,
                    name: rule.name,
                    message: rule.description || check.message || 'Pattern matched',
                    severity,
                    code: line.trim()
                  });
                }
              }
            });
          }
        });
      }
    });
  } catch (error) {
    // Skip files that can't be read
  }

  return findings;
}

program
  .name('chp-check')
  .description('Code Highway Patrol - Check specific files or rules')
  .argument('[target]', 'File, directory, or pattern to check')
  .option('--rule <id>', 'Specific rule ID to check')
  .option('--severity <level>', 'Minimum severity level', 'warning')
  .action(async (target, options) => {
    const { rule: ruleId, severity } = options;

    console.log(chalk.bold.blue('CHP Check'));
    console.log(chalk.gray('='.repeat(50)));
    console.log();

    const allRules = loadRules();
    let rules = allRules;

    if (ruleId) {
      rules = allRules.filter(r => r.id === ruleId);
      if (rules.length === 0) {
        console.error(chalk.red(`Rule not found: ${ruleId}`));
        process.exit(1);
      }
      console.log(chalk.gray(`Checking rule: ${ruleId}`));
    } else {
      console.log(chalk.gray(`Checking all rules (severity: ${severity}+)`));
    }
    console.log();

    let files = [];
    if (target) {
      // Check if it's a directory or pattern
      const targetPath = join(__dirname, target);
      files = glob.sync(target, { cwd: __dirname });
      if (files.length === 0) {
        // Try as a direct file
        files = [target];
      }
    } else {
      files = glob.sync(['**/*.{js,ts,jsx,tsx,py,java,go,rs}'], {
        cwd: __dirname,
        ignore: ['**/node_modules/**', '**/dist/**', '**/build/**']
      });
    }

    console.log(chalk.gray(`Checking ${files.length} file(s)...`));
    console.log();

    const allFindings = [];
    files.forEach(file => {
      const findings = checkFile(file, rules, severity);
      allFindings.push(...findings);
    });

    // Group by file
    const byFile = {};
    allFindings.forEach(f => {
      if (!byFile[f.file]) byFile[f.file] = [];
      byFile[f.file].push(f);
    });

    // Display results
    Object.entries(byFile).forEach(([file, findings]) => {
      const hasErrors = findings.some(f => f.severity === 'error');
      const icon = hasErrors ? chalk.red('✗') : chalk.yellow('⚠');
      console.log(`${icon} ${file} (${findings.length} issue${findings.length !== 1 ? 's' : ''})`);

      findings.forEach(f => {
        const color = f.severity === 'error' ? 'red' : 'yellow';
        console.log(`  ${chalk.gray(f.line)}: ${chalk[color](f.severity)} - ${f.message}`);
        if (f.code) {
          console.log(`    ${chalk.gray(f.code.substring(0, 50))}`);
        }
      });
      console.log();
    });

    const errorCount = allFindings.filter(f => f.severity === 'error').length;
    console.log(chalk.bold(`Total: ${allFindings.length} findings (${errorCount} errors)`));

    process.exit(errorCount > 0 ? 1 : 0);
  });

program.parse();

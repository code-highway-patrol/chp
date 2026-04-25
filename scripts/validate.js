#!/usr/bin/env node

import { program } from 'commander';
import chalk from 'chalk';
import { glob } from 'fast-glob';
import { readFileSync, existsSync } from 'fs';
import { resolve, join } from 'path';
import yaml from 'js-yaml';
import { Validator } from 'jsonschema';

const __dirname = resolve();
const validator = new Validator();

let errorCount = 0;
let warningCount = 0;

function logError(msg) {
  console.error(chalk.red(`✗ ${msg}`));
  errorCount++;
}

function logWarning(msg) {
  console.warn(chalk.yellow(`⚠ ${msg}`));
  warningCount++;
}

function logSuccess(msg) {
  console.log(chalk.green(`✓ ${msg}`));
}

function validateRules() {
  console.log(chalk.bold('Validating Rules...'));
  const rulesDir = join(__dirname, 'assets', 'rules');

  if (!existsSync(rulesDir)) {
    logWarning('Rules directory does not exist');
    return;
  }

  const ruleFiles = glob.sync(['**/*.json', '**/*.yaml', '**/*.yml'], {
    cwd: rulesDir,
    absolute: true
  });

  if (ruleFiles.length === 0) {
    logWarning('No rule files found');
    return;
  }

  console.log(chalk.gray(`Found ${ruleFiles.length} rule file(s)`));

  const ruleIds = new Set();

  ruleFiles.forEach(file => {
    try {
      const content = readFileSync(file, 'utf8');
      const ext = file.split('.').pop();
      const rule = ext === 'yaml' || ext === 'yml'
        ? yaml.load(content)
        : JSON.parse(content);

      // Check required fields
      if (!rule.id) {
        logError(`${file}: Missing required field "id"`);
      } else {
        if (ruleIds.has(rule.id)) {
          logError(`${file}: Duplicate rule ID "${rule.id}"`);
        } else {
          ruleIds.add(rule.id);
        }
      }

      if (!rule.name) {
        logWarning(`${file}: Missing recommended field "name"`);
      }

      if (!rule.description) {
        logWarning(`${file}: Missing recommended field "description"`);
      }

      if (!rule.severity || !['error', 'warning', 'info'].includes(rule.severity)) {
        logWarning(`${file}: Invalid or missing severity (should be error|warning|info)`);
      }

      // Validate patterns
      if (rule.patterns) {
        if (!rule.patterns.include && !rule.patterns.exclude) {
          logWarning(`${file}: patterns should include include/exclude patterns`);
        }

        if (rule.patterns.checks) {
          rule.patterns.checks.forEach((check, idx) => {
            if (!check.type) {
              logError(`${file}: Check ${idx} missing type`);
            }
            if (check.type === 'pattern' && !check.regex) {
              logError(`${file}: Pattern check ${idx} missing regex`);
            }
          });
        }
      }

      logSuccess(`${file}: Valid`);
    } catch (error) {
      logError(`${file}: ${error.message}`);
    }
  });

  console.log();
}

function validateConfig() {
  console.log(chalk.bold('Validating Plugin Configuration...'));

  const pluginDirs = [
    '.claude-plugin',
    '.codex-plugin',
    '.cursor-plugin'
  ];

  pluginDirs.forEach(dir => {
    const configPath = join(__dirname, dir, 'plugin.json');

    if (!existsSync(configPath)) {
      logWarning(`${dir}/plugin.json not found`);
      return;
    }

    try {
      const content = readFileSync(configPath, 'utf8');
      const config = JSON.parse(content);

      // Check required fields
      const required = ['name', 'displayName', 'description', 'version', 'publisher'];
      required.forEach(field => {
        if (!config[field]) {
          logError(`${dir}/plugin.json: Missing required field "${field}"`);
        }
      });

      // Check engines
      if (!config.engines) {
        logWarning(`${dir}/plugin.json: Missing engines field`);
      }

      // Check capabilities
      if (!config.capabilities) {
        logWarning(`${dir}/plugin.json: Missing capabilities field`);
      }

      // Check components
      if (config.components) {
        Object.entries(config.components).forEach(([type, component]) => {
          const dirPath = join(__dirname, component.directory);
          if (!existsSync(dirPath)) {
            logWarning(`${dir}/plugin.json: Component directory "${component.directory}" does not exist`);
          }
        });
      }

      logSuccess(`${dir}/plugin.json: Valid`);
    } catch (error) {
      logError(`${dir}/plugin.json: ${error.message}`);
    }
  });

  // Validate gemini-extension.json
  const geminiPath = join(__dirname, 'gemini-extension.json');
  if (existsSync(geminiPath)) {
    try {
      const content = readFileSync(geminiPath, 'utf8');
      const config = JSON.parse(content);

      if (!config.name || !config.version) {
        logError('gemini-extension.json: Missing required fields');
      } else {
        logSuccess('gemini-extension.json: Valid');
      }
    } catch (error) {
      logError(`gemini-extension.json: ${error.message}`);
    }
  }

  console.log();
}

function validateSchemas() {
  console.log(chalk.bold('Validating Schemas...'));
  const schemasDir = join(__dirname, 'assets', 'schemas');

  if (!existsSync(schemasDir)) {
    logWarning('Schemas directory does not exist');
    return;
  }

  const schemaFiles = glob.sync('**/*.json', {
    cwd: schemasDir,
    absolute: true
  });

  if (schemaFiles.length === 0) {
    logWarning('No schema files found');
    return;
  }

  console.log(chalk.gray(`Found ${schemaFiles.length} schema file(s)`));

  schemaFiles.forEach(file => {
    try {
      const content = readFileSync(file, 'utf8');
      const schema = JSON.parse(content);

      // Basic JSON Schema validation
      if (!schema.$schema && !schema.title) {
        logWarning(`${file}: Schema missing $schema or title`);
      }

      if (!schema.type && !schema.properties) {
        logWarning(`${file}: Schema missing type or properties`);
      }

      logSuccess(`${file}: Valid`);
    } catch (error) {
      logError(`${file}: ${error.message}`);
    }
  });

  console.log();
}

program
  .name('chp-validate')
  .description('Code Highway Patrol - Validate configuration and rules')
  .option('--rules', 'Validate rule definitions', true)
  .option('--config', 'Validate plugin configuration', true)
  .option('--schema', 'Validate schemas', true)
  .action((options) => {
    console.log(chalk.bold.blue('CHP Validation'));
    console.log(chalk.gray('='.repeat(50)));
    console.log();

    if (options.rules) validateRules();
    if (options.config) validateConfig();
    if (options.schema) validateSchemas();

    console.log(chalk.bold('Summary:'));
    console.log(`  Errors: ${errorCount}`);
    console.log(`  Warnings: ${warningCount}`);

    if (errorCount === 0 && warningCount === 0) {
      console.log(chalk.green('\nAll validations passed!'));
      process.exit(0);
    } else if (errorCount === 0) {
      console.log(chalk.yellow('\nValidation passed with warnings'));
      process.exit(0);
    } else {
      console.log(chalk.red('\nValidation failed'));
      process.exit(1);
    }
  });

program.parse();

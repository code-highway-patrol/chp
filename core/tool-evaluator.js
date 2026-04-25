#!/usr/bin/env node
// Node.js wrapper for evaluating tool actions against CHP laws
// Called from hooks/agent/pre-tool.sh

const { evaluateAction } = require('./core/evaluator');
const { loadLaws } = require('./core/law-loader');

// Parse arguments: TOOL_NAME, FILE_PATH, etc.
const toolName = process.env.TOOL_NAME || '';
const filePath = process.env.FILE_PATH || '';
const toolArgs = process.argv.slice(2);

// Build action object
const action = {
  type: 'tool',
  payload: {
    name: toolName,
    args: toolArgs,
    filePath: filePath
  },
  context: {
    hook: 'pre-tool',
    timestamp: new Date().toISOString()
  }
};

// Load laws registered for pre-tool hook
const lawsDir = './docs/chp/laws';
const allLaws = loadLaws(lawsDir);

// Filter to only pre-tool laws
const preToolLaws = allLaws.filter(law => {
  const lawJsonPath = `${lawsDir}/${law.id}/law.json`;
  try {
    const fs = require('fs');
    const lawData = JSON.parse(fs.readFileSync(lawJsonPath, 'utf-8'));
    return lawData.hooks && lawData.hooks.includes('pre-tool');
  } catch {
    return false;
  }
});

if (preToolLaws.length === 0) {
  console.log('[CHP] No pre-tool laws registered, allowing tool');
  process.exit(0);
}

// Evaluate action against laws
const result = evaluateAction(action, preToolLaws);

if (result.blocked) {
  console.error(`[CHP BLOCKED] ${result.law}: ${result.reason}`);
  console.error(`[CHP] Suggestion: ${result.suggestion}`);
  if (result.fix) {
    console.error(`[CHP] Fix: ${result.fix}`);
  }
  process.exit(1);
}

if (result.warned) {
  console.warn(`[CHP WARN] ${result.law}: ${result.reason}`);
  console.warn(`[CHP] Suggestion: ${result.suggestion}`);
}

console.log('[CHP] Tool allowed');
process.exit(0);
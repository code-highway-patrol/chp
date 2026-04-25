const { execSync } = require('child_process');
const path = require('path');

const CHP_ROOT = process.env.CHP_ROOT || process.cwd();

function exec(command, options = {}) {
  try {
    const result = execSync(command, {
      encoding: 'utf-8',
      cwd: CHP_ROOT,
      stdio: 'pipe',
      ...options
    });
    return { success: true, output: result };
  } catch (error) {
    return { success: false, output: error.stdout || error.message, code: error.status };
  }
}

function execLaw(command, ...args) {
  return exec(`./commands/chp-law ${command} ${args.join(' ')}`);
}

function execScan(command) {
  return exec(`./commands/chp-scan ${command || ''}`);
}

module.exports = { exec, execLaw, execScan };
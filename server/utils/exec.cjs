const { execSync } = require('child_process');
const path = require('path');

const CHP_ROOT = process.env.CHP_ROOT || process.cwd();
const IS_WIN = process.platform === 'win32';

function exec(command, options = {}) {
  try {
    const result = execSync(command, {
      encoding: 'utf-8',
      cwd: CHP_ROOT,
      stdio: 'pipe',
      shell: IS_WIN ? 'cmd.exe' : '/bin/bash',
      ...options
    });
    return { success: true, output: result };
  } catch (error) {
    return { success: false, output: error.stdout || error.message, code: error.status };
  }
}

function execLaw(command, ...args) {
  const cmd = IS_WIN
    ? `bash ./commands/chp-law ${command} ${args.join(' ')}`
    : `./commands/chp-law ${command} ${args.join(' ')}`;
  return exec(cmd);
}

function execScan(command) {
  const cmd = IS_WIN
    ? `bash ./commands/chp-scan ${command || ''}`
    : `./commands/chp-scan ${command || ''}`;
  return exec(cmd);
}

module.exports = { exec, execLaw, execScan };
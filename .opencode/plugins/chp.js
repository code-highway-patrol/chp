/**
 * CHP plugin for OpenCode.ai
 *
 * - Registers shared CHP skills via the `config` hook (no symlinks).
 * - Gates tool calls through core/dispatcher.sh pre-tool. Non-zero exit aborts.
 * - Fires post-tool after each tool so post-tool laws can record violations.
 */

import path from 'path';
import fs from 'fs';
import { spawnSync } from 'child_process';
import { fileURLToPath } from 'url';

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const REPO_ROOT = path.resolve(__dirname, '../..');
const DISPATCHER = path.join(REPO_ROOT, 'core', 'dispatcher.sh');
const SKILLS_DIR = path.join(REPO_ROOT, '.claude-plugin', 'plugins', 'chp', 'skills');

const gateEnabled = () => process.env.CHP_OPENCODE_GATE !== 'off';

const runDispatcher = (event, env, cwd) => {
  if (!fs.existsSync(DISPATCHER)) return { skipped: true };
  const res = spawnSync('bash', [DISPATCHER, event], {
    cwd,
    env: { ...process.env, ...env },
    encoding: 'utf8',
    timeout: 30_000,
  });
  return {
    skipped: false,
    code: res.status ?? 0,
    stdout: (res.stdout || '').trim(),
    stderr: (res.stderr || '').trim(),
  };
};

export const ChpPlugin = async ({ directory }) => {
  return {
    config: async (config) => {
      if (!fs.existsSync(SKILLS_DIR)) return;
      config.skills = config.skills || {};
      config.skills.paths = config.skills.paths || [];
      if (!config.skills.paths.includes(SKILLS_DIR)) {
        config.skills.paths.push(SKILLS_DIR);
      }
    },

    'tool.execute.before': async (input, output) => {
      if (!gateEnabled()) return;
      const res = runDispatcher('pre-tool', {
        CHP_TOOL_NAME: input.tool || '',
        CHP_TOOL_INPUT: JSON.stringify(output.args ?? {}),
      }, directory);
      if (res.skipped) return;
      if (res.code !== 0) {
        const reason = res.stdout || res.stderr || 'CHP law violation detected';
        throw new Error(reason);
      }
    },

    'tool.execute.after': async (input) => {
      if (!gateEnabled()) return;
      runDispatcher('post-tool', {
        CHP_TOOL_NAME: input.tool || '',
        CHP_TOOL_INPUT: JSON.stringify(input.args ?? {}),
      }, directory);
    },
  };
};

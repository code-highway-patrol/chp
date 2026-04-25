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
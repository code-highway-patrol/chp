#!/usr/bin/env node

import { program } from 'commander';
import chalk from 'chalk';
import fs from 'fs/promises';
import path from 'path';
import { fileURLToPath } from 'url';

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const MARKETPLACE_API = 'https://chp-web.vercel.app/api';

const marketplace = program
  .name('chp marketplace')
  .description('Install skills from the CHP marketplace');

async function ensureChprcDir() {
  const chprcDir = path.join(process.cwd(), '.chprc');
  try {
    await fs.access(chprcDir);
  } catch {
    await fs.mkdir(chprcDir, { recursive: true });
    console.log(chalk.gray('Created .chprc directory'));
  }
  return chprcDir;
}

async function installStatue(slug, chprcDir) {
  console.log(chalk.blue(`Fetching statue: ${slug}...`));

  try {
    const response = await fetch(`${MARKETPLACE_API}/statues/${slug}`);
    if (!response.ok) {
      if (response.status === 404) {
        console.error(chalk.red(`Statue not found: ${slug}`));
        return false;
      }
      throw new Error(`HTTP ${response.status}`);
    }

    const statue = await response.json();

    if (statue.type === 'collection') {
      console.log(chalk.yellow(`Installing collection "${statue.title}" with ${statue.contents?.length || 0} skills...`));

      if (statue.contents && statue.contents.length > 0) {
        const collectionDir = path.join(chprcDir, statue.slug);
        await fs.mkdir(collectionDir, { recursive: true });

        for (const item of statue.contents) {
          const itemPath = path.join(collectionDir, `${item.slug}.md`);
          await fs.writeFile(itemPath, item.body, 'utf-8');
          console.log(chalk.green(`  ✓ Installed: ${item.title}`));
        }

        console.log(chalk.green(`Collection installed to .chprc/${statue.slug}/`));
      }
    } else {
      const filePath = path.join(chprcDir, `${statue.slug}.md`);
      await fs.writeFile(filePath, statue.body, 'utf-8');
      console.log(chalk.green(`✓ Installed: ${statue.title}`));
      console.log(chalk.gray(`  Saved to: .chprc/${statue.slug}.md`));
    }

    return true;
  } catch (error) {
    console.error(chalk.red(`Failed to install statue: ${error.message}`));
    return false;
  }
}

marketplace
  .command('install <slug...>')
  .description('Install one or more statues from the marketplace')
  .option('-v, --verbose', 'Show detailed output')
  .action(async (slugs, options) => {
    const chprcDir = await ensureChprcDir();

    console.log(chalk.bold.blue('CHP Marketplace Install'));
    console.log(chalk.gray('='.repeat(40)));

    let successCount = 0;
    let failCount = 0;

    for (const slug of slugs) {
      const success = await installStatue(slug, chprcDir);
      if (success) {
        successCount++;
      } else {
        failCount++;
      }
      console.log();
    }

    console.log(chalk.gray('='.repeat(40)));
    console.log(chalk.bold(`Installed: ${successCount} | Failed: ${failCount}`));

    if (successCount > 0) {
      console.log(chalk.gray('\nSkills are now available in your .chprc directory.'));
    }
  });

marketplace
  .command('search [query]')
  .description('Search the marketplace for statues')
  .option('-l, --limit <n>', 'Number of results', '12')
  .action(async (query = '', options) => {
    console.log(chalk.bold.blue('CHP Marketplace Search'));
    console.log(chalk.gray('='.repeat(40)));

    try {
      const limit = parseInt(options.limit, 10);
      let url = `${MARKETPLACE_API}/statues?limit=${limit}`;
      let method = 'GET';

      if (query.trim()) {
        url = `${MARKETPLACE_API}/statues/search`;
        method = 'POST';
      }

      const response = await fetch(url, {
        method,
        ...(method === 'POST' && {
          headers: { 'Content-Type': 'application/json' },
          body: JSON.stringify({ query: query.trim() })
        })
      });

      if (!response.ok) {
        throw new Error(`HTTP ${response.status}`);
      }

      const data = await response.json();
      const items = data.items || [];

      if (items.length === 0) {
        console.log(chalk.yellow('No results found.'));
        return;
      }

      console.log(chalk.gray(`Found ${items.length} result${items.length === 1 ? '' : 's'}:\n`));

      items.forEach((item, idx) => {
        const isCollection = item.type === 'collection';
        const icon = isCollection ? '📁' : '📄';
        const typeLabel = isCollection ? chalk.yellow('collection') : chalk.gray('single');

        console.log(`${chalk.gray(`${idx + 1}.`)} ${icon} ${chalk.bold(item.title)} ${typeLabel}`);
        console.log(`   ${chalk.gray('Slug:')} ${chalk.cyan(item.slug)}`);
        console.log(`   ${chalk.gray('Stars:')} ${chalk.yellow('★ ' + item.stars)}`);

        if (item.description) {
          const desc = item.description.length > 60
            ? item.description.slice(0, 60) + '...'
            : item.description;
          console.log(`   ${chalk.gray(desc)}`);
        }

        if (item.tags && item.tags.length > 0) {
          console.log(`   ${chalk.dim(item.tags.slice(0, 3).join(', '))}`);
        }

        console.log();
      });

      console.log(chalk.gray('Install with: chp marketplace install <slug>'));

    } catch (error) {
      console.error(chalk.red(`Search failed: ${error.message}`));
    }
  });

marketplace
  .command('list')
  .description('List all available statues in the marketplace')
  .option('-l, --limit <n>', 'Number of results', '24')
  .action(async (options) => {
    console.log(chalk.bold.blue('CHP Marketplace'));
    console.log(chalk.gray('='.repeat(40)));

    try {
      const limit = parseInt(options.limit, 10);
      const response = await fetch(`${MARKETPLACE_API}/statues?limit=${limit}`);

      if (!response.ok) {
        throw new Error(`HTTP ${response.status}`);
      }

      const data = await response.json();
      const items = data.items || [];

      if (items.length === 0) {
        console.log(chalk.yellow('No statues available.'));
        return;
      }

      console.log(chalk.gray(`Available statues (${items.length}):\n`));

      items.forEach((item, idx) => {
        const isCollection = item.type === 'collection';
        const icon = isCollection ? '📁' : '📄';

        console.log(`${chalk.gray(`${idx + 1}.`)} ${icon} ${chalk.bold(item.title)}`);
        console.log(`   ${chalk.gray('Slug:')} ${chalk.cyan(item.slug)} ${chalk.gray('|')} ${chalk.yellow('★ ' + item.stars)}`);

        if (item.tags && item.tags.length > 0) {
          console.log(`   ${chalk.dim(item.tags.slice(0, 3).join(', '))}`);
        }

        console.log();
      });

      if (data.hasMore) {
        console.log(chalk.gray(`(showing ${limit} of many - use search to find specific skills)`));
      }

      console.log(chalk.gray('Install with: chp marketplace install <slug>'));

    } catch (error) {
      console.error(chalk.red(`Failed to fetch marketplace: ${error.message}`));
    }
  });

// Handle both direct execution and import
if (import.meta.url === `file://${process.argv[1]}` || import.meta.url === `file:///${process.argv[1].replace(/\\/g, '/')}`) {
  marketplace.parseAsync(process.argv.slice(2));
}

export { marketplace };

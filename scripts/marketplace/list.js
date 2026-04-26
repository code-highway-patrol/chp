import chalk from 'chalk';

const MARKETPLACE_API = 'https://pinkdonut.work/api';

export async function list(options) {
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

    if (data.hasMore) {
      console.log(chalk.gray(`(showing ${limit} of many - use search to find specific skills)`));
    }

    console.log(chalk.gray('Install with: chp marketplace install <slug>'));

  } catch (error) {
    console.error(chalk.red(`Failed to fetch marketplace: ${error.message}`));
  }
}

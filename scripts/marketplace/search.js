import chalk from 'chalk';

const MARKETPLACE_API = 'https://pinkdonut.work/api';

export async function search(query = '', options) {
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
}

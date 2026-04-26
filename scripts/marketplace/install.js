import chalk from 'chalk';
import fs from 'fs/promises';
import path from 'path';

const MARKETPLACE_API = 'https://chp-web.vercel.app/api';

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

export async function install(slugs, options) {
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
}

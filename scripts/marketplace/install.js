import chalk from 'chalk';
import fs from 'fs/promises';
import path from 'path';

const MARKETPLACE_API = 'https://pinkdonut.work/api';

async function ensureLawsDir() {
  const lawsDir = path.join(process.cwd(), 'docs', 'chp', 'laws');
  try {
    await fs.access(lawsDir);
  } catch {
    await fs.mkdir(lawsDir, { recursive: true });
    console.log(chalk.gray('Created docs/chp/laws directory'));
  }
  return lawsDir;
}

async function installStatue(slug, lawsDir) {
  console.log(chalk.blue(`Fetching law: ${slug}...`));

  try {
    const response = await fetch(`${MARKETPLACE_API}/statues/${slug}`);
    if (!response.ok) {
      if (response.status === 404) {
        console.error(chalk.red(`Law not found: ${slug}`));
        return false;
      }
      throw new Error(`HTTP ${response.status}`);
    }

    const statue = await response.json();

    // Handle law packs (statues with files array)
    if (statue.files && statue.files.length > 0) {
      console.log(chalk.yellow(`Installing law pack "${statue.title}" with ${statue.laws?.length || 0} laws...`));

      // Group files by law name (first directory in path)
      const lawGroups = {};
      for (const file of statue.files) {
        const parts = file.path.split('/');
        const lawName = parts[0];
        if (!lawGroups[lawName]) {
          lawGroups[lawName] = [];
        }
        lawGroups[lawName].push(file);
      }

      // Install each law
      for (const [lawName, files] of Object.entries(lawGroups)) {
        await installLawPack(lawName, files, lawsDir);
      }

      console.log(chalk.green(`Law pack installed to docs/chp/laws/`));
      return true;
    }

    // Handle single law or old collection format
    if (statue.type === 'collection' && statue.contents && statue.contents.length > 0) {
      console.log(chalk.yellow(`Installing collection "${statue.title}" with ${statue.contents.length} laws...`));
      for (const item of statue.contents) {
        await installLaw(item, lawsDir);
      }
      console.log(chalk.green(`Collection installed to docs/chp/laws/`));
      return true;
    }

    // Single law
    await installLaw(statue, lawsDir);
    return true;
  } catch (error) {
    console.error(chalk.red(`Failed to install law: ${error.message}`));
    return false;
  }
}

async function installLawPack(lawName, files, lawsDir) {
  const lawDir = path.join(lawsDir, lawName);
  await fs.mkdir(lawDir, { recursive: true });

  for (const file of files) {
    const parts = file.path.split('/');
    const fileName = parts.slice(1).join('/'); // Remove law name prefix

    if (!fileName) continue; // Skip empty paths

    const filePath = path.join(lawDir, fileName);
    const fileDir = path.dirname(filePath);

    await fs.mkdir(fileDir, { recursive: true });
    await fs.writeFile(filePath, file.content, 'utf-8');
  }

  console.log(chalk.green(`  ✓ Installed: ${lawName}`));
}

async function installLaw(law, lawsDir) {
  const lawDir = path.join(lawsDir, law.slug);
  await fs.mkdir(lawDir, { recursive: true });

  let lawJson;
  if (law.lawJson) {
    if (typeof law.lawJson === 'string') {
      lawJson = JSON.parse(law.lawJson);
    } else {
      lawJson = law.lawJson;
    }
  } else {
    lawJson = {
      name: law.slug,
      severity: 'error',
      hooks: ['pre-commit'],
      enabled: true,
      intent: law.description || law.title,
      autoFix: 'never',
      checks: [],
      include: ['**/*'],
      exclude: ['**/node_modules/**'],
      created: new Date().toISOString(),
      failures: 0,
      tightening_level: 0
    };
  }

  await fs.writeFile(path.join(lawDir, 'law.json'), JSON.stringify(lawJson, null, 2), 'utf-8');

  if (law.body) {
    await fs.writeFile(path.join(lawDir, 'guidance.md'), law.body, 'utf-8');
  }

  console.log(chalk.green(`  ✓ Installed: ${law.title}`));
}

export async function install(slugs, options) {
  const lawsDir = await ensureLawsDir();

  console.log(chalk.bold.blue('CHP Marketplace Install'));
  console.log(chalk.gray('='.repeat(40)));

  let successCount = 0;
  let failCount = 0;

  for (const slug of slugs) {
    const success = await installStatue(slug, lawsDir);
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
    console.log(chalk.gray('\nLaws are now available in docs/chp/laws/'));
  }
}

import chalk from 'chalk';
import fs from 'fs/promises';
import path from 'path';
import { spawn } from 'child_process';

const MARKETPLACE_API = process.env.CHP_MARKETPLACE_API || 'https://www.pinkdonut.work/api';
const LAWS_DIR = path.join('docs', 'chp', 'laws');
const REGISTRY_PATH = path.join('.chp', 'hook-registry.json');

const LAW_FILES = new Set(['law.json', 'verify.sh', 'guidance.md']);

// What to do with a file in statue.files[]:
//   accept   → write to docs/chp/laws/<path>
//   info     → skip (informational, e.g. README.md)
//   reject   → skip with a warning (unexpected path shape)
function classifyPath(p) {
  const segs = p.split('/').filter(Boolean);
  const base = segs[segs.length - 1];
  if (base === 'README.md' || base === 'readme.md') return 'info';
  if (segs.length !== 2) return 'reject';
  if (!LAW_FILES.has(base)) return 'reject';
  return 'accept';
}

// Legacy single-law statues (body + lawJson, no files[]) get the same on-disk
// shape the marketplace UI synthesizes: <slug>/guidance.md and <slug>/law.json.
function synthesizeFiles(statue) {
  const out = [];
  if (statue.body && statue.body.trim()) {
    out.push({ path: `${statue.slug}/guidance.md`, content: statue.body });
  }
  if (statue.lawJson != null && statue.lawJson !== '') {
    const content =
      typeof statue.lawJson === 'string'
        ? statue.lawJson
        : JSON.stringify(statue.lawJson, null, 2);
    out.push({ path: `${statue.slug}/law.json`, content });
  }
  return out;
}

async function fetchStatue(slug) {
  const url = `${MARKETPLACE_API}/statues/${encodeURIComponent(slug)}`;
  const res = await fetch(url);
  if (res.status === 404) return null;
  if (!res.ok) throw new Error(`HTTP ${res.status} fetching ${url}`);
  return res.json();
}

async function writeFileEnsuringDir(dest, content, mode) {
  await fs.mkdir(path.dirname(dest), { recursive: true });
  await fs.writeFile(dest, content, 'utf-8');
  if (mode != null) await fs.chmod(dest, mode);
}

// Update .chp/hook-registry.json: add each law to the hook arrays declared in
// its law.json.hooks. Idempotent.
async function registerLaws(lawNames) {
  let registry = { hooks: {} };
  try {
    registry = JSON.parse(await fs.readFile(REGISTRY_PATH, 'utf-8'));
    if (!registry.hooks) registry.hooks = {};
  } catch (err) {
    if (err.code !== 'ENOENT') throw err;
    await fs.mkdir(path.dirname(REGISTRY_PATH), { recursive: true });
  }

  for (const name of lawNames) {
    const lawJsonPath = path.join(LAWS_DIR, name, 'law.json');
    let parsed;
    try {
      parsed = JSON.parse(await fs.readFile(lawJsonPath, 'utf-8'));
    } catch {
      console.log(chalk.yellow(`  · skipping registry update for ${name} (law.json not readable)`));
      continue;
    }
    const hooks = Array.isArray(parsed.hooks) ? parsed.hooks : [];
    for (const hook of hooks) {
      if (!registry.hooks[hook]) {
        registry.hooks[hook] = { laws: [], enabled: true, blocking: true };
      }
      const laws = registry.hooks[hook].laws ?? [];
      if (!laws.includes(name)) laws.push(name);
      registry.hooks[hook].laws = laws;
    }
  }

  await fs.writeFile(REGISTRY_PATH, JSON.stringify(registry, null, 2) + '\n', 'utf-8');
}

// Best-effort: ensure hook templates are installed by calling the installer
// directly. Skip the chp-hooks subprocess overhead - source installer.sh and
// call ensure_hooks_installed directly.
function ensureHookTemplates() {
  return new Promise((resolve) => {
    const proc = spawn('bash', ['-c', `
      source "$(pwd)/core/common.sh"
      source "$(pwd)/core/hook-registry.sh"
      source "$(pwd)/core/detector.sh"
      source "$(pwd)/core/installer.sh"
      ensure_hooks_installed 2>&1
    `], { stdio: 'pipe' });
    let stderr = '';
    let stdout = '';
    proc.stderr.on('data', (d) => (stderr += d.toString()));
    proc.stdout.on('data', (d) => (stdout += d.toString()));
    proc.on('error', () => {
      console.log(chalk.gray('  · Could not run hook template install — run `bash scripts/setup.sh` manually'));
      resolve();
    });
    proc.on('exit', (code) => {
      if (code !== 0) {
        console.log(chalk.yellow(`  · Hook template install exited ${code}`));
      }
      // Show any useful output
      if (stdout) console.log(chalk.gray(stdout.trim()));
      resolve();
    });
  });
}

async function installStatue(slug) {
  console.log(chalk.blue(`Fetching ${slug}…`));
  const statue = await fetchStatue(slug);
  if (!statue) {
    console.error(chalk.red(`  ✗ not found: ${slug}`));
    return { success: false, lawNames: [] };
  }

  const fileList =
    Array.isArray(statue.files) && statue.files.length > 0
      ? statue.files
      : synthesizeFiles(statue);

  if (fileList.length === 0) {
    console.error(chalk.red(`  ✗ ${slug} has no installable content`));
    return { success: false, lawNames: [] };
  }

  const lawNames = new Set();
  let written = 0;
  let skipped = 0;

  for (const f of fileList) {
    const verdict = classifyPath(f.path);
    if (verdict === 'info') {
      skipped++;
      continue;
    }
    if (verdict === 'reject') {
      console.log(chalk.yellow(`  · ignoring unexpected path: ${f.path}`));
      skipped++;
      continue;
    }
    const dest = path.join(LAWS_DIR, f.path);
    const mode = f.path.endsWith('.sh') ? 0o755 : undefined;
    await writeFileEnsuringDir(dest, f.content, mode);
    lawNames.add(f.path.split('/')[0]);
    written++;
  }

  if (written === 0) {
    console.error(chalk.red(`  ✗ ${slug} produced no usable law files`));
    return { success: false, lawNames: [] };
  }

  const lawList = Array.from(lawNames).sort();
  console.log(chalk.green(`  ✓ wrote ${written} files (${skipped} skipped)`));
  console.log(chalk.green(`  ✓ ${lawList.length} law(s): ${lawList.join(', ')}`));
  return { success: true, lawNames: lawList };
}

export async function install(slugs, _options) {
  console.log(chalk.bold.blue('CHP Marketplace Install'));
  console.log(chalk.gray('='.repeat(40)));

  // Install all laws in parallel for significant speedup
  const results = await Promise.allSettled(
    slugs.map((slug) => installStatue(slug))
  );

  // Collect all law names from successful installs
  const allLawNames = new Set();
  let ok = 0;
  let bad = 0;

  for (const result of results) {
    if (result.status === 'fulfilled' && result.value.success) {
      ok++;
      result.value.lawNames.forEach(name => allLawNames.add(name));
    } else {
      bad++;
    }
    console.log();
  }

  // Single batch registry update for all laws
  if (allLawNames.size > 0) {
    console.log(chalk.gray(`Updating registry with ${allLawNames.size} law(s)...`));
    await registerLaws(Array.from(allLawNames));
    await ensureHookTemplates();
  }

  console.log(chalk.gray('='.repeat(40)));
  console.log(chalk.bold(`Installed: ${ok} | Failed: ${bad}`));
  if (ok > 0) {
    console.log(
      chalk.gray('Laws now live under docs/chp/laws/ and are wired into .chp/hook-registry.json.'),
    );
  }
  if (bad > 0) process.exitCode = 1;
}

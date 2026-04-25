import { exec } from 'child_process';
import { promisify } from 'util';
import { promises as fs } from 'fs';
import { join } from 'path';

const execAsync = promisify(exec);

export interface Environment {
  git: boolean;
  toolHooks: boolean;
  fileWatching: boolean;
}

export interface HookRegistrationResult {
  success: boolean;
  hooksRegistered: string[];
  error?: string;
}

/**
 * Detects the available capabilities of the current environment
 */
export async function detectEnvironment(): Promise<Environment> {
  const [git, toolHooks, fileWatching] = await Promise.all([
    isGitAvailable(),
    areToolHooksAvailable(),
    isFileWatchingAvailable(),
  ]);

  return {
    git,
    toolHooks,
    fileWatching,
  };
}

/**
 * Checks if git is available in the current environment
 */
export async function isGitAvailable(): Promise<boolean> {
  try {
    await execAsync('git --version');
    return true;
  } catch {
    return false;
  }
}

/**
 * Checks if tool hooks (pre-commit hooks for tools) are available
 */
export async function areToolHooksAvailable(): Promise<boolean> {
  try {
    // Check if we're in a git repository with hooks directory
    await execAsync('git rev-parse --git-dir');
    return true;
  } catch {
    return false;
  }
}

/**
 * Checks if file watching capabilities are available
 */
export async function isFileWatchingAvailable(): Promise<boolean> {
  try {
    // Check if fs.watch is available (always true in Node.js)
    return typeof process !== 'undefined';
  } catch {
    return false;
  }
}

/**
 * Registers hooks based on the detected environment capabilities
 */
export async function registerHooks(
  environment: Environment
): Promise<HookRegistrationResult> {
  const hooksRegistered: string[] = [];

  try {
    // Register git hooks if git is available
    if (environment.git) {
      const gitResult = await registerGitHooks();
      if (gitResult.success) {
        hooksRegistered.push('git');
      } else {
        return {
          success: false,
          hooksRegistered,
          error: `Failed to register git hooks: ${gitResult.error}`,
        };
      }
    }

    // Register tool hooks if available
    if (environment.toolHooks) {
      hooksRegistered.push('tool');
    }

    return {
      success: true,
      hooksRegistered,
    };
  } catch (error) {
    return {
      success: false,
      hooksRegistered,
      error: error instanceof Error ? error.message : 'Unknown error',
    };
  }
}

/**
 * Registers git hooks for the repository
 */
async function registerGitHooks(): Promise<{ success: boolean; error?: string }> {
  try {
    const { stdout: gitDir } = await execAsync('git rev-parse --git-dir');
    const hooksDir = join(gitDir.trim(), 'hooks');

    // Ensure hooks directory exists
    await fs.mkdir(hooksDir, { recursive: true });

    // Create pre-commit hook
    const preCommitHook = join(hooksDir, 'pre-commit');
    const hookContent = `#!/bin/sh
# CHP pre-commit hook
npx chp run --pre-commit
`;

    await fs.writeFile(preCommitHook, hookContent, { mode: 0o755 });

    return { success: true };
  } catch (error) {
    return {
      success: false,
      error: error instanceof Error ? error.message : 'Unknown error',
    };
  }
}

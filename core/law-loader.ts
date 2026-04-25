// core/law-loader.ts

import * as fs from 'fs';
import * as path from 'path';
import { Law } from './types';

/**
 * Validation schema for Law objects
 */
const LAW_REQUIRED_FIELDS = ['id', 'intent', 'violations', 'reaction'];

/**
 * Validate that an object conforms to Law interface
 */
function validateLaw(obj: unknown): obj is Law {
  if (typeof obj !== 'object' || obj === null) {
    return false;
  }

  const law = obj as Record<string, unknown>;

  // Check required fields
  for (const field of LAW_REQUIRED_FIELDS) {
    if (!(field in law)) {
      throw new Error(`Law missing required field: ${field}`);
    }
  }

  // Validate types
  if (typeof law.id !== 'string') {
    throw new Error('Law.id must be a string');
  }

  if (typeof law.intent !== 'string') {
    throw new Error('Law.intent must be a string');
  }

  if (!Array.isArray(law.violations)) {
    throw new Error('Law.violations must be an array');
  }

  // Validate each violation
  for (let i = 0; i < law.violations.length; i++) {
    const violation = law.violations[i] as Record<string, unknown>;
    if (typeof violation.pattern !== 'string') {
      throw new Error(`Law.violations[${i}].pattern must be a string`);
    }
    if (typeof violation.fix !== 'string') {
      throw new Error(`Law.violations[${i}].fix must be a string`);
    }
    if (typeof violation.satisfies !== 'string') {
      throw new Error(`Law.violations[${i}].satisfies must be a string`);
    }
  }

  if (!['block', 'warn', 'auto_fix'].includes(law.reaction as string)) {
    throw new Error('Law.reaction must be one of: block, warn, auto_fix');
  }

  return true;
}

/**
 * Load a single law from a JSON file
 * @param lawPath - Path to the law JSON file
 * @returns Parsed Law object
 * @throws Error if file doesn't exist or JSON is invalid
 */
export function loadLaw(lawPath: string): Law {
  if (!fs.existsSync(lawPath)) {
    throw new Error(`Law file not found: ${lawPath}`);
  }

  const content = fs.readFileSync(lawPath, 'utf-8');
  let parsed: unknown;

  try {
    parsed = JSON.parse(content);
  } catch (err) {
    throw new Error(`Failed to parse law JSON: ${lawPath}`);
  }

  if (validateLaw(parsed)) {
    return parsed;
  }

  throw new Error(`Invalid law format: ${lawPath}`);
}

/**
 * Load all laws from a directory
 * @param lawsDir - Path to directory containing law JSON files
 * @returns Array of Law objects
 */
export function loadLaws(lawsDir: string): Law[] {
  if (!fs.existsSync(lawsDir)) {
    return [];
  }

  const laws: Law[] = [];
  const files = fs.readdirSync(lawsDir);

  for (const file of files) {
    if (!file.endsWith('.json')) {
      continue;
    }

    const lawPath = path.join(lawsDir, file);
    try {
      const law = loadLaw(lawPath);
      laws.push(law);
    } catch (err) {
      // Log error but continue loading other laws
      console.warn(`Failed to load law ${file}:`, err);
    }
  }

  return laws;
}

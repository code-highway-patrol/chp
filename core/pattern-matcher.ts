// core/pattern-matcher.ts

import { ViolationPattern, Action } from './types';

/**
 * Built-in functions available in pattern expressions
 */
interface PatternContext {
  [key: string]: unknown;
}

/**
 * Evaluate a pattern against a context
 * @param pattern - Pattern expression to evaluate
 * @param context - Context containing variables and functions
 * @returns True if pattern matches, false otherwise
 */
export function matchPattern(pattern: string, context: PatternContext = {}): boolean {
  // Handle negation
  if (pattern.startsWith('!')) {
    const innerPattern = pattern.slice(1).trim();
    return !matchPattern(innerPattern, context);
  }

  // Handle compound expressions with &&
  if (pattern.includes(' && ')) {
    const parts = pattern.split(' && ');
    return parts.every(part => matchPattern(part.trim(), context));
  }

  // Handle compound expressions with ||
  if (pattern.includes(' || ')) {
    const parts = pattern.split(' || ');
    return parts.some(part => matchPattern(part.trim(), context));
  }

  // Handle fileContains(pattern, content)
  const fileContainsMatch = pattern.match(/fileContains\(([^,]+),\s*(\w+)\)/);
  if (fileContainsMatch) {
    const [, searchPattern, contentVar] = fileContainsMatch;
    const content = context[contentVar] as string;

    if (typeof content !== 'string') {
      return false;
    }

    // Check if searchPattern is regex (enclosed in /)
    if (searchPattern.startsWith('/') && searchPattern.endsWith('/')) {
      const regexPattern = searchPattern.slice(1, -1);
      const regex = new RegExp(regexPattern);
      return regex.test(content);
    }

    // Simple string search (remove quotes)
    const searchString = searchPattern.replace(/['"]/g, '');
    return content.includes(searchString);
  }

  // Handle fileExists(path)
  const fileExistsMatch = pattern.match(/fileExists\(([^)]+)\)/);
  if (fileExistsMatch) {
    const [, path] = fileExistsMatch;
    const pathStr = path.replace(/['"]/g, '');
    const fileExistsFn = context.fileExists as (path: string) => boolean;
    return typeof fileExistsFn === 'function' ? fileExistsFn(pathStr) : false;
  }

  // Handle equality comparisons
  const equalityMatch = pattern.match(/^(\w+)\s*==\s*["']([^"']+)["']$/);
  if (equalityMatch) {
    const [, varName, expectedValue] = equalityMatch;
    return context[varName] === expectedValue;
  }

  // Handle function calls like query.includes("DROP")
  const includesMatch = pattern.match(/^(\w+)\.includes\(["']([^"']+)["']\)$/);
  if (includesMatch) {
    const [, varName, searchValue] = includesMatch;
    const variable = context[varName] as string;
    return typeof variable === 'string' ? variable.includes(searchValue) : false;
  }

  // Handle function calls like s3Bucket.isPublic()
  const methodMatch = pattern.match(/^(\w+)\.(\w+)\(\)$/);
  if (methodMatch) {
    const [, objName, methodName] = methodMatch;
    const obj = context[objName] as Record<string, () => boolean>;
    return typeof obj === 'object' && typeof obj[methodName] === 'function'
      ? obj[methodName]()
      : false;
  }

  // Default: try to evaluate as a boolean expression
  try {
    // Create a function with the context variables
    const contextKeys = Object.keys(context);
    const contextValues = Object.values(context);
    const evalFn = new Function(...contextKeys, `return ${pattern};`);
    return evalFn(...contextValues) === true;
  } catch {
    // If evaluation fails, return false
    return false;
  }
}

/**
 * Match an action against a list of violation patterns
 * @param action - The action to evaluate
 * @param violations - List of violation patterns to check
 * @returns Array of matching violation patterns
 */
export function matchActionAgainstViolations(
  action: Action,
  violations: ViolationPattern[]
): ViolationPattern[] {
  const matches: ViolationPattern[] = [];

  // Build context from action
  const context: PatternContext = {
    ...action.context,
    type: action.type,
    payload: action.payload
  };

  // Extract common context values
  if (action.type === 'file-write' || action.type === 'file-read') {
    const payload = action.payload as Record<string, unknown>;
    if (payload.content) {
      context.content = payload.content;
    }
    if (payload.file) {
      context.file = payload.file;
    }
  }

  for (const violation of violations) {
    if (matchPattern(violation.pattern, context)) {
      matches.push(violation);
    }
  }

  return matches;
}

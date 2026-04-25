// core/evaluator.ts

import { Law, Action, EvaluationResult, ReactionType } from './types';
import { matchActionAgainstViolations } from './pattern-matcher';

/**
 * Evaluate an action against a list of laws
 * @param action - The action to evaluate
 * @param laws - List of laws to check against
 * @returns Evaluation result indicating if action was blocked/warned/fixed
 */
export function evaluateAction(action: Action, laws: Law[]): EvaluationResult {
  // Check each law in order
  for (const law of laws) {
    const matchingViolations = matchActionAgainstViolations(action, law.violations);

    if (matchingViolations.length > 0) {
      const violation = matchingViolations[0]; // Use first matching violation
      return createEvaluationResult(law, violation, action);
    }
  }

  // No violations found
  return {};
}

/**
 * Create an evaluation result based on law reaction type
 */
function createEvaluationResult(law: Law, violation: { pattern: string; fix: string; satisfies: string }, action: Action): EvaluationResult {
  const result: EvaluationResult = {
    law: law.id,
    reason: `Violation: ${violation.pattern}`
  };

  switch (law.reaction) {
    case 'block':
      result.blocked = true;
      result.fix = violation.fix;
      result.suggestion = generateSuggestion(law, violation);
      break;

    case 'warn':
      result.warned = true;
      result.suggestion = generateSuggestion(law, violation);
      break;

    case 'auto_fix':
      result.fixed = true;
      result.applied = violation.fix;
      result.suggestion = `Automatically applied: ${violation.fix}`;
      break;
  }

  return result;
}

/**
 * Generate a human-readable suggestion for fixing a violation
 */
function generateSuggestion(law: Law, violation: { pattern: string; fix: string; satisfies: string }): string {
  return `[${law.id}] ${law.intent}\nFix: ${violation.fix}`;
}

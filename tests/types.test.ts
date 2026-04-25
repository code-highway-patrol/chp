// tests/types.test.ts

import { Law, ViolationPattern, ReactionType, Action, EvaluationResult } from '../core/types';

describe('Core Types', () => {
  describe('ViolationPattern', () => {
    it('should create a valid violation pattern', () => {
      const pattern: ViolationPattern = {
        pattern: 'fileContains(/api[_-]?key/, file)',
        fix: 'useEnvironmentVariable("API_KEY")',
        satisfies: '!fileContains(/api[_-]?key/, file)'
      };

      expect(pattern.pattern).toBeDefined();
      expect(pattern.fix).toBeDefined();
      expect(pattern.satisfies).toBeDefined();
    });
  });

  describe('Law', () => {
    it('should create a valid law', () => {
      const law: Law = {
        id: 'no-api-keys',
        intent: 'No API keys in codebase',
        violations: [{
          pattern: 'fileContains(/api[_-]?key/, file)',
          fix: 'useEnvironmentVariable("API_KEY")',
          satisfies: '!fileContains(/api[_-]?key/, file)'
        }],
        reaction: 'block'
      };

      expect(law.id).toBe('no-api-keys');
      expect(law.violations).toHaveLength(1);
      expect(law.reaction).toBe('block');
    });
  });

  describe('ReactionType', () => {
    it('should accept valid reaction types', () => {
      const validReactions: ReactionType[] = ['block', 'warn', 'auto_fix'];
      validReactions.forEach(reaction => {
        expect(['block', 'warn', 'auto_fix']).toContain(reaction);
      });
    });
  });

  describe('EvaluationResult', () => {
    it('should create a blocked result', () => {
      const result: EvaluationResult = {
        blocked: true,
        law: 'no-api-keys',
        reason: 'API key detected',
        fix: 'useEnvironmentVariable("API_KEY")',
        suggestion: 'Replace hardcoded API key with environment variable'
      };

      expect(result.blocked).toBe(true);
      expect(result.law).toBe('no-api-keys');
    });

    it('should create a warned result', () => {
      const result: EvaluationResult = {
        warned: true,
        law: 'long-function',
        reason: 'Function exceeds 100 lines',
        suggestion: 'Consider splitting into smaller functions'
      };

      expect(result.warned).toBe(true);
      expect(result.blocked).toBeUndefined();
    });
  });
});

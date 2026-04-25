// tests/evaluator.test.ts

import { evaluateAction } from '../core/evaluator';
import { Law, Action } from '../core/types';

describe('Evaluator', () => {
  const mockLaws: Law[] = [
    {
      id: 'no-api-keys',
      intent: 'No API keys in codebase',
      violations: [{
        pattern: 'fileContains("api_key", content)',
        fix: 'useEnvironmentVariable("API_KEY")',
        satisfies: '!fileContains("api_key", content)'
      }],
      reaction: 'block'
    },
    {
      id: 'long-function',
      intent: 'Functions should be short',
      violations: [{
        pattern: 'lineCount > 100',
        fix: 'splitFunction()',
        satisfies: 'lineCount <= 100'
      }],
      reaction: 'warn'
    },
    {
      id: 'missing-readme',
      intent: 'Every project needs a README',
      violations: [{
        pattern: '!fileExists("README.md")',
        fix: 'generateReadme()',
        satisfies: 'fileExists("README.md")'
      }],
      reaction: 'auto_fix'
    }
  ];

  describe('evaluateAction with block reaction', () => {
    it('should return blocked result for violating action', () => {
      const action: Action = {
        type: 'file-write',
        payload: { content: 'const api_key = "xyz"' },
        context: { file: 'config.js' }
      };

      const result = evaluateAction(action, mockLaws);

      expect(result.blocked).toBe(true);
      expect(result.law).toBe('no-api-keys');
      expect(result.fix).toContain('useEnvironmentVariable');
      expect(result.suggestion).toBeDefined();
    });

    it('should return empty result for non-violating action', () => {
      const action: Action = {
        type: 'file-write',
        payload: { content: 'const config = {}' },
        context: { file: 'config.js' }
      };

      const result = evaluateAction(action, mockLaws);

      expect(result.blocked).toBeUndefined();
      expect(result.warned).toBeUndefined();
    });
  });

  describe('evaluateAction with warn reaction', () => {
    it('should return warned result', () => {
      const action: Action = {
        type: 'file-write',
        payload: { content: 'x'.repeat(101) },
        context: { lineCount: 150 }
      };

      const result = evaluateAction(action, mockLaws);

      expect(result.warned).toBe(true);
      expect(result.law).toBe('long-function');
      expect(result.suggestion).toBeDefined();
    });
  });

  describe('evaluateAction with auto_fix reaction', () => {
    it('should return fixed result with applied fix', () => {
      const action: Action = {
        type: 'check-readme',
        payload: {},
        context: {
          fileExists: (f: string) => f !== 'README.md'
        }
      };

      const result = evaluateAction(action, mockLaws);

      expect(result.fixed).toBe(true);
      expect(result.law).toBe('missing-readme');
      expect(result.applied).toContain('generateReadme');
    });
  });

  describe('evaluateAction with multiple violations', () => {
    it('should return result for first matching violation', () => {
      const action: Action = {
        type: 'file-write',
        payload: { content: 'const api_key = "xyz"' },
        context: { file: 'config.js', lineCount: 150 }
      };

      const result = evaluateAction(action, mockLaws);

      // Should return the first matching violation
      expect(result.blocked).toBe(true);
      expect(result.law).toBe('no-api-keys');
    });
  });
});

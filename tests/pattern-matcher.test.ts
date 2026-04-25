// tests/pattern-matcher.test.ts

import { matchPattern, matchActionAgainstViolations } from '../core/pattern-matcher';
import { ViolationPattern, Action } from '../core/types';

describe('Pattern Matcher', () => {
  describe('matchPattern', () => {
    it('should match simple string patterns', () => {
      const pattern = 'fileContains("api_key", content)';
      const context = { content: 'const api_key = "xyz"' };

      const result = matchPattern(pattern, context);

      expect(result).toBe(true);
    });

    it('should not match non-matching patterns', () => {
      const pattern = 'fileContains("api_key", content)';
      const context = { content: 'const apiKey = "xyz"' };

      const result = matchPattern(pattern, context);

      expect(result).toBe(false);
    });

    it('should match regex patterns', () => {
      const pattern = 'fileContains(/api[_-]?key/, content)';
      const context = { content: 'const api_key = "xyz"' };

      const result = matchPattern(pattern, context);

      expect(result).toBe(true);
    });

    it('should match equality patterns', () => {
      const pattern = 'environment == "prod"';
      const context = { environment: 'prod' };

      const result = matchPattern(pattern, context);

      expect(result).toBe(true);
    });

    it('should match negation patterns', () => {
      const pattern = '!fileExists("README.md")';
      const context = { fileExists: (f: string) => f !== 'README.md' };

      const result = matchPattern(pattern, context);

      expect(result).toBe(true);
    });

    it('should match compound patterns with &&', () => {
      const pattern = 'environment == "prod" && query.includes("DROP")';
      const context = { environment: 'prod', query: 'DROP TABLE users' };

      const result = matchPattern(pattern, context);

      expect(result).toBe(true);
    });

    it('should match compound patterns with ||', () => {
      const pattern = 'environment == "prod" || environment == "staging"';
      const context = { environment: 'staging' };

      const result = matchPattern(pattern, context);

      expect(result).toBe(true);
    });
  });

  describe('matchActionAgainstViolations', () => {
    const violations: ViolationPattern[] = [
      {
        pattern: 'fileContains("api_key", content)',
        fix: 'useEnvironmentVariable("API_KEY")',
        satisfies: '!fileContains("api_key", content)'
      },
      {
        pattern: 'fileContains("AKIA", content)',
        fix: 'useSecretsManagement()',
        satisfies: '!fileContains("AKIA", content)'
      }
    ];

    it('should return matching violations', () => {
      const action: Action = {
        type: 'file-write',
        payload: { content: 'const api_key = "xyz"' },
        context: { file: 'config.js' }
      };

      const matches = matchActionAgainstViolations(action, violations);

      expect(matches).toHaveLength(1);
      expect(matches[0].pattern).toContain('api_key');
    });

    it('should return empty array when no violations match', () => {
      const action: Action = {
        type: 'file-write',
        payload: { content: 'const config = {}' },
        context: { file: 'config.js' }
      };

      const matches = matchActionAgainstViolations(action, violations);

      expect(matches).toHaveLength(0);
    });
  });
});

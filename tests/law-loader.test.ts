// tests/law-loader.test.ts

import { Law } from '../core/types';
import { loadLaws, loadLaw } from '../core/law-loader';

describe('Law Loader', () => {
  const testLawsDir = './test-laws';

  beforeEach(() => {
    // Setup test laws directory
    const fs = require('fs');
    if (!fs.existsSync(testLawsDir)) {
      fs.mkdirSync(testLawsDir, { recursive: true });
    }
  });

  afterEach(() => {
    // Cleanup test laws directory
    const fs = require('fs');
    if (fs.existsSync(testLawsDir)) {
      fs.rmSync(testLawsDir, { recursive: true, force: true });
    }
  });

  describe('loadLaw', () => {
    it('should load a single law from JSON file', () => {
      const fs = require('fs');
      const lawPath = `${testLawsDir}/test-law.json`;
      const lawData = {
        id: 'test-law',
        intent: 'Test law',
        violations: [{
          pattern: 'true',
          fix: 'false',
          satisfies: '!true'
        }],
        reaction: 'block'
      };
      fs.writeFileSync(lawPath, JSON.stringify(lawData, null, 2));

      const law = loadLaw(lawPath);

      expect(law).toBeDefined();
      expect(law.id).toBe('test-law');
      expect(law.intent).toBe('Test law');
    });

    it('should throw error for invalid JSON', () => {
      const fs = require('fs');
      const lawPath = `${testLawsDir}/invalid-law.json`;
      fs.writeFileSync(lawPath, '{ invalid json }');

      expect(() => loadLaw(lawPath)).toThrow();
    });

    it('should throw error for missing required fields', () => {
      const fs = require('fs');
      const lawPath = `${testLawsDir}/incomplete-law.json`;
      fs.writeFileSync(lawPath, JSON.stringify({ id: 'test' }));

      expect(() => loadLaw(lawPath)).toThrow();
    });
  });

  describe('loadLaws', () => {
    it('should load all laws from directory', () => {
      const fs = require('fs');
      const law1 = { id: 'law1', intent: 'Law 1', violations: [], reaction: 'block' };
      const law2 = { id: 'law2', intent: 'Law 2', violations: [], reaction: 'warn' };

      fs.writeFileSync(`${testLawsDir}/law1.json`, JSON.stringify(law1));
      fs.writeFileSync(`${testLawsDir}/law2.json`, JSON.stringify(law2));

      const laws = loadLaws(testLawsDir);

      expect(laws).toHaveLength(2);
      expect(laws.find(l => l.id === 'law1')).toBeDefined();
      expect(laws.find(l => l.id === 'law2')).toBeDefined();
    });

    it('should return empty array for non-existent directory', () => {
      const laws = loadLaws('./non-existent-dir');
      expect(laws).toEqual([]);
    });

    it('should skip non-JSON files', () => {
      const fs = require('fs');
      const law1 = { id: 'law1', intent: 'Law 1', violations: [], reaction: 'block' };
      fs.writeFileSync(`${testLawsDir}/law1.json`, JSON.stringify(law1));
      fs.writeFileSync(`${testLawsDir}/readme.txt`, 'not a law');

      const laws = loadLaws(testLawsDir);

      expect(laws).toHaveLength(1);
    });
  });
});

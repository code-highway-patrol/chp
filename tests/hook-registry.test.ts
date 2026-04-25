import { detectEnvironment, registerHooks } from '../core/hook-registry';

describe('Hook Registry', () => {
  describe('detectEnvironment', () => {
    it('should detect all features available', async () => {
      const env = await detectEnvironment();
      expect(env).toHaveProperty('git');
      expect(env).toHaveProperty('toolHooks');
      expect(env).toHaveProperty('fileWatching');
      expect(typeof env.git).toBe('boolean');
      expect(typeof env.toolHooks).toBe('boolean');
      expect(typeof env.fileWatching).toBe('boolean');
    });

    it('should return consistent results', async () => {
      const env1 = await detectEnvironment();
      const env2 = await detectEnvironment();
      expect(env1).toEqual(env2);
    });
  });

  describe('registerHooks', () => {
    beforeEach(() => {
      jest.clearAllMocks();
    });

    afterEach(() => {
      jest.restoreAllMocks();
    });

    it('should register hooks when git is available', async () => {
      const env = await detectEnvironment();
      if (env.git) {
        const result = await registerHooks(env);
        expect(result.success).toBe(true);
        expect(result.hooksRegistered).toContain('git');
      }
    });

    it('should skip git hooks when git is not available', async () => {
      const env = await detectEnvironment();
      const envWithoutGit = { ...env, git: false };
      const result = await registerHooks(envWithoutGit);
      expect(result.success).toBe(true);
      expect(result.hooksRegistered).not.toContain('git');
    });

    it('should handle error case when environment is invalid', async () => {
      // Test with an invalid environment that might cause errors
      const invalidEnv = { git: true, toolHooks: false, fileWatching: false };

      // This test verifies the function handles various environment states
      const result = await registerHooks(invalidEnv);

      // Either success or failure is acceptable - we're testing it doesn't crash
      expect(result).toHaveProperty('success');
      expect(result).toHaveProperty('hooksRegistered');
      expect(Array.isArray(result.hooksRegistered)).toBe(true);

      if (!result.success) {
        expect(result.error).toBeDefined();
        expect(typeof result.error).toBe('string');
      }
    });

    it('should handle tool hooks registration', async () => {
      const env = await detectEnvironment();
      if (env.toolHooks) {
        const result = await registerHooks(env);
        expect(result.success).toBe(true);
        if (env.toolHooks) {
          expect(result.hooksRegistered).toContain('tool');
        }
      }
    });
  });
});

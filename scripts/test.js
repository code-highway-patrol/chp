#!/usr/bin/env node

const { execSync } = require('child_process');
const path = require('path');

console.log('Running tests...\n');

try {
  // Run Jest with ts-jest preset
  execSync(
    'npx jest --passWithNoTests',
    {
      stdio: 'inherit',
      cwd: path.resolve(__dirname, '..')
    }
  );
  console.log('\n✓ Tests passed!');
} catch (error) {
  console.error('\n✗ Tests failed!');
  process.exit(1);
}

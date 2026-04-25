#!/usr/bin/env node

const { execSync } = require('child_process');
const path = require('path');
const fs = require('fs');

class CHPMcpServer {
  constructor() {
    this.tools = {
      chp_analyze: this.handleAnalyze.bind(this),
      chp_check: this.handleCheck.bind(this),
      chp_create_law: this.handleCreateLaw.bind(this),
      chp_validate: this.handleValidate.bind(this),
      chp_scan: this.handleScan.bind(this),
      chp_list_laws: this.handleListLaws.bind(this)
    };
  }

  handleAnalyze(args = {}) {
    try {
      const rules = args.rules ? args.rules.map(r => `--rule ${r}`).join(' ') : '';
      const severity = args.severity ? `--severity ${args.severity}` : '';
      const cmd = `npx chp analyze ${rules} ${severity}`;
      const result = execSync(cmd, { encoding: 'utf-8', cwd: process.cwd(), shell: 'bash' });
      return { content: [{ type: 'text', text: result }] };
    } catch (error) {
      return { content: [{ type: 'text', text: `Analysis failed: ${error.message}` }], isError: true };
    }
  }

  handleCheck(args = {}) {
    try {
      const files = args.files ? args.files.join(' ') : '';
      const rule = args.rule ? `--rule ${args.rule}` : '';
      const cmd = `npx chp check ${files} ${rule}`;
      const result = execSync(cmd, { encoding: 'utf-8', cwd: process.cwd(), shell: 'bash' });
      return { content: [{ type: 'text', text: result }] };
    } catch (error) {
      return { content: [{ type: 'text', text: `Check failed: ${error.message}` }], isError: true };
    }
  }

  handleCreateLaw(args) {
    try {
      const { name, description, pattern, severity, hooks } = args;
      if (!name) return { content: [{ type: 'text', text: 'Law name is required' }], isError: true };

      const lawsDir = path.join(process.cwd(), 'docs/chp/laws');
      const lawDir = path.join(lawsDir, name);
      fs.mkdirSync(lawDir, { recursive: true });

      const lawJson = {
        name,
        created: new Date().toISOString(),
        severity: severity || 'error',
        failures: 0,
        tightening_level: 0,
        hooks: hooks || [],
        enabled: true,
        description: description || '',
        pattern: pattern || ''
      };
      fs.writeFileSync(path.join(lawDir, 'law.json'), JSON.stringify(lawJson, null, 2));

      const verifyScript = `#!/bin/bash
LAW_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CHP_BASE="$(cd "$LAW_DIR/../../../../" && pwd)"
source "$CHP_BASE/core/common.sh"

verify_law() {
    local law_name="${name}"
    log_info "Verifying law: $law_name"
    local staged_files=$(git diff --cached --name-only --diff-filter=ACM)
    if [ -z "$staged_files" ]; then
        log_info "No staged files to check"
        return 0
    fi
    local skip_pattern='\\.(md|json|txt|sh|yml|yaml|lock|gitignore)$'
    local violations=0
    local violating_files=()
    while IFS= read -r file; do
        if echo "$file" | grep -qE "$skip_pattern"; then continue; fi
        if [ ! -f "$file" ]; then continue; fi
        if git diff --cached "$file" | grep -qE '${pattern || '.'}'; then
            violations=$((violations + 1))
            violating_files+=("$file")
        fi
    done <<< "$staged_files"
    if [ $violations -gt 0 ]; then
        log_error "Law violation detected in $violations file(s): ${description || name}"
        for file in "\${violating_files[@]}"; do
            log_error "  - $file"
        done
        return 1
    fi
    log_info "Law verification passed: $law_name"
    return 0
}

verify_law
exit $?
`;
      fs.writeFileSync(path.join(lawDir, 'verify.sh'), verifyScript);

      const guidance = `# Law: ${name}

**Severity:** ${severity || 'error'}
**Created:** ${lawJson.created}

## Purpose

${description || 'Enforces code quality standards.'}

## Violation Pattern

\`\`\`
${pattern || '.*'}
\`\`\`

## Guidance

Describe what this law checks for and how to comply.

### Examples

#### Good Practice
\`\`\`
// Compliant code
\`\`\`

#### Bad Practice
\`\`\`
// Non-compliant code
\`\`\`
`;
      fs.writeFileSync(path.join(lawDir, 'guidance.md'), guidance);

      return { content: [{ type: 'text', text: `Law "${name}" created successfully!` }] };
    } catch (error) {
      return { content: [{ type: 'text', text: `Failed to create law: ${error.message}` }], isError: true };
    }
  }

  handleValidate(args = {}) {
    try {
      const cmd = `npx chp validate`;
      const result = execSync(cmd, { encoding: 'utf-8', cwd: process.cwd(), shell: 'bash' });
      return { content: [{ type: 'text', text: result }] };
    } catch (error) {
      return { content: [{ type: 'text', text: `Validation failed: ${error.message}` }], isError: true };
    }
  }

  handleScan(args = {}) {
    try {
      const lawsDir = path.join(process.cwd(), 'docs/chp/laws');
      const reportPath = path.join(process.cwd(), '.chp/report.json');

      const laws = fs.existsSync(lawsDir)
        ? fs.readdirSync(lawsDir).filter(f => fs.statSync(path.join(lawsDir, f)).isDirectory())
        : [];

      const violations = [];
      for (const lawName of laws) {
        const lawJsonPath = path.join(lawsDir, lawName, 'law.json');
        if (!fs.existsSync(lawJsonPath)) continue;
        const lawData = JSON.parse(fs.readFileSync(lawJsonPath, 'utf-8'));
        if (!lawData.enabled) continue;
        if (!lawData.pattern) continue;

        const allFiles = execSync('git ls-files', { encoding: 'utf-8', shell: 'bash' });
        const skipPattern = /\.(md|json|txt|sh|yml|yaml|lock|gitignore)$/;

        for (const file of allFiles.split('\n').filter(f => f && !skipPattern.test(f))) {
          if (!fs.existsSync(file)) continue;
          const content = fs.readFileSync(file, 'utf-8');
          const regex = new RegExp(lawData.pattern);
          if (regex.test(content)) {
            const lines = content.split('\n');
            const matchLine = lines.findIndex(l => regex.test(l)) + 1;
            violations.push({
              law: lawName,
              file,
              line: matchLine,
              snippet: lines[matchLine - 1]?.substring(0, 100),
              reaction: lawData.severity === 'error' ? 'block' : 'warn'
            });
          }
        }
      }

      const report = {
        timestamp: new Date().toISOString(),
        files_checked: execSync('git ls-files', { encoding: 'utf-8', shell: 'bash' }).split('\n').filter(f => f).length,
        total_violations: violations.length,
        total_block: violations.filter(v => v.reaction === 'block').length,
        total_warn: violations.filter(v => v.reaction === 'warn').length,
        violations
      };

      fs.mkdirSync(path.dirname(reportPath), { recursive: true });
      fs.writeFileSync(reportPath, JSON.stringify(report, null, 2));

      return { content: [{ type: 'text', text: `Scan complete. ${violations.length} violations found.` }] };
    } catch (error) {
      return { content: [{ type: 'text', text: `Scan failed: ${error.message}` }], isError: true };
    }
  }

  handleListLaws(args = {}) {
    try {
      const lawsDir = path.join(process.cwd(), 'docs/chp/laws');
      if (!fs.existsSync(lawsDir)) {
        return { content: [{ type: 'text', text: 'No laws found.' }] };
      }
      const dirs = fs.readdirSync(lawsDir).filter(f => fs.statSync(path.join(lawsDir, f)).isDirectory());
      const lawList = dirs.map(d => {
        const lawJsonPath = path.join(lawsDir, d, 'law.json');
        if (!fs.existsSync(lawJsonPath)) return null;
        const data = JSON.parse(fs.readFileSync(lawJsonPath, 'utf-8'));
        return `- ${d} (${data.severity}) - ${data.enabled ? 'enabled' : 'disabled'}`;
      }).filter(Boolean);
      return { content: [{ type: 'text', text: lawList.join('\n') || 'No laws found.' }] };
    } catch (error) {
      return { content: [{ type: 'text', text: `Failed to list laws: ${error.message}` }], isError: true };
    }
  }

  handleRequest(message) {
    const { method, params } = message;

    switch (method) {
      case 'tools/list':
        return {
          tools: [
            { name: 'chp_analyze', description: 'Run full CHP analysis', inputSchema: { type: 'object', properties: { rules: { type: 'array', items: { type: 'string' } }, severity: { type: 'string' } } } },
            { name: 'chp_check', description: 'Check specific files', inputSchema: { type: 'object', properties: { files: { type: 'array', items: { type: 'string' } }, rule: { type: 'string' } } } },
            { name: 'chp_create_law', description: 'Create a new law', inputSchema: { type: 'object', required: ['name'], properties: { name: { type: 'string' }, description: { type: 'string' }, pattern: { type: 'string' }, severity: { type: 'string' }, hooks: { type: 'array', items: { type: 'string' } } } },
            { name: 'chp_validate', description: 'Validate CHP config', inputSchema: { type: 'object' } },
            { name: 'chp_scan', description: 'Scan codebase for violations', inputSchema: { type: 'object' } },
            { name: 'chp_list_laws', description: 'List all laws', inputSchema: { type: 'object' } }
          ]
        };
      case 'tools/call':
        const tool = this.tools[params.name];
        if (tool) return tool(params.arguments || {});
        throw new Error(`Unknown tool: ${params.name}`);
      case 'resources/list':
        return { resources: [{ uri: `file://${process.cwd()}/docs/chp`, name: 'CHP Documentation', mimeType: 'text/markdown' }] };
      default:
        throw new Error(`Unknown method: ${method}`);
    }
  }

  run() {
    process.stdin.setEncoding('utf-8');
    let buffer = '';
    process.stdin.on('data', (chunk) => {
      buffer += chunk;
      while (true) {
        const newlineIndex = buffer.indexOf('\n');
        if (newlineIndex === -1) break;
        const messageStr = buffer.slice(0, newlineIndex);
        buffer = buffer.slice(newlineIndex + 1);
        if (!messageStr.trim()) continue;
        try {
          const message = JSON.parse(messageStr);
          this.handleRequest(message).then(result => {
            process.stdout.write(JSON.stringify({ jsonrpc: '2.0', id: message.id, result }) + '\n');
          }).catch(error => {
            process.stdout.write(JSON.stringify({ jsonrpc: '2.0', id: message.id, error: { code: -32000, message: error.message } }) + '\n');
          });
        } catch {}
      }
    });
  }
}

function startMcpServer(port = 3100) {
  console.log(`CHP MCP server running on port ${port} (stdio)`);
  const server = new CHPMcpServer();
  server.run();
}

module.exports = { startMcpServer, CHPMcpServer };

if (require.main === module) {
  startMcpServer();
}
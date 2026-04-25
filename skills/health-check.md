---
name: health-check
description: Analyze codebase health and identify potential issues across multiple dimensions
---

# CHP Health Check

Run a comprehensive health analysis of the codebase using Code Highway Patrol.

## Usage

Invoke this skill when:
- User asks to check code health or quality
- User wants to identify potential issues
- User requests a codebase audit or review

## Analysis Dimensions

The health check analyzes:

1. **Code Complexity**: Cyclomatic complexity, nesting depth, function length
2. **Security Patterns**: Potential vulnerabilities, sensitive data exposure
3. **Maintainability**: Code duplication, naming conventions, documentation
4. **Performance**: Inefficient patterns, resource usage
5. **Traffic Law Compliance**: Adherence to defined CHP traffic laws

## Process

1. Scan the codebase using configured CHP traffic laws
2. Check each file against registered rules
3. Aggregate findings by severity and category
4. Generate actionable report with recommendations

## Output

Returns a structured report with:
- Overall health score (0-100)
- Findings grouped by category and severity
- Specific file and line references
- Recommended actions for each issue

# CHP Example Use Cases

Real-world scenarios where CHP prevents problems and enforces standards.

---

## Use Case 1: Preventing API Key Leaks

**Scenario:** Developer accidentally commits API key to repository.

**Without CHP:**
```bash
$ git add src/config.js
$ git commit -m "add config"
$ git push origin main
# API key is now in git history, exposed publicly
# Must rotate credentials, audit access logs, purge history
```

**With CHP:**
```bash
$ git add src/config.js
$ git commit -m "add config"

❌ CHP law 'no-api-keys' violated
   Found: sk_live_51H7... in src/config.js:15
   
   Fix: Move API key to environment variable
   
   # .env
   STRIPE_KEY=sk_live_51H7...
   
   # src/config.js
   const stripeKey = process.env.STRIPE_KEY;

Commit blocked. Fix and retry.
```

**Value:** Prevents costly security incident, credential rotation, and potential data breach.

---

## Use Case 2: Enforcing Test Coverage on Critical Code

**Scenario:** Developer adds payment processing logic without tests.

**Without CHP:**
```javascript
// src/payments/process.js - 200 lines, zero tests
// Merges to main, deployed to production
// Bug discovered when customer charged 10x
```

**With CHP:**
```bash
$ git add src/payments/process.js
$ git commit -m "add payment processor"

⚠️  CHP law 'require-tests-for-payment-code' warning
   New file: src/payments/process.js
   Missing: src/payments/process.test.js
   
   Critical paths require tests:
   - Charge calculation logic
   - Error handling paths
   - Idempotency checks

Continue anyway? (y/n): n

$ # Developer adds tests
$ git add src/payments/process.js src/payments/process.test.js
$ git commit -m "add payment processor with tests"
✅ All checks passed
```

**Value:** Prevents untested critical code from reaching production.

---

## Use Case 3: Blocking Console.log in Production Builds

**Scenario:** Debug statements left in code, cluttering production logs.

**Without CHP:**
```javascript
// Production logs filled with:
[2024-01-15T10:23:01Z] "user logged in"
[2024-01-15T10:23:01Z] { id: 123, name: "John" }
[2024-01-15T10:23:01Z] "fetching data"
[2024-01-15T10:23:02Z] { results: [...], count: 150 }
// Real error messages buried in noise
```

**With CHP:**
```bash
$ git add src/auth/login.js
$ git commit -m "fix login flow"

❌ CHP law 'no-console-log' violated
   Found: console.log in src/auth/login.js:45
   
   Fix: Use proper logger
   
   // Bad
   console.log('User logged in', user);
   
   // Good
   logger.info('User login successful', { userId: user.id });

Commit blocked.
```

**Value:** Clean, actionable production logs; no performance impact from I/O.

---

## Use Case 4: Enforcing Terraform Security Before Apply

**Scenario:** Developer creates public S3 bucket for "quick testing."

**Without CHP:**
```hcl
resource "aws_s3_bucket" "data" {
  bucket = "company-data-bucket"
  # No public access block
}
# terraform apply succeeds
# Data exposed to internet
# Security incident declared
```

**With CHP:**
```bash
$ terraform plan

❌ CHP law 'no-public-s3-buckets' violated
   Resource: aws_s3_bucket.data
   Issue: Missing aws_s3_bucket_public_access_block
   
   Fix: Add public access block
   
   resource "aws_s3_bucket_public_access_block" "data" {
     bucket = aws_s3_bucket.data.id
     block_public_acls       = true
     block_public_policy     = true
     ignore_public_acls      = true
     restrict_public_buckets = true
   }

Apply blocked. Fix and retry.
```

**Value:** Prevents data exposure before it reaches AWS.

---

## Use Case 5: Preventing Database Migrations Without Rollback

**Scenario:** Developer adds migration that drops column, no rollback plan.

**Without CHP:**
```bash
$ npm run migrate
# Production database altered
# Service degradation detected
# No rollback script, 2-hour outage
```

**With CHP:**
```bash
$ git add migrations/20240115_drop_legacy_column.js
$ git commit -m "clean up legacy data"

❌ CHP law 'migration-requires-rollback' violated
   Migration: 20240115_drop_legacy_column.js
   Missing: Rollback function or script
   
   Fix: Add down() migration
   
   exports.down = async (knex) => {
     await knex.schema.table('users', t => {
       t.string('legacy_column');
     });
   };

Commit blocked.
```

**Value:** Every migration has an escape hatch, reducing outage risk.

---

## Use Case 6: Enforcing Documentation for API Changes

**Scenario:** Developer changes API response format, docs stay outdated.

**Without CHP:**
```javascript
// API now returns { user: { id, email, profile } }
// Docs still show: { user: { id, name } }
// Mobile app breaks on deploy
// Customer complaints, rollback required
```

**With CHP:**
```bash
$ git add src/api/users.js  # Modified response format
$ git commit -m "add user profile to response"

⚠️  CHP law 'openapi-docs-in-sync' warning
   Modified: src/api/users.js (API handler)
   Not modified: docs/openapi.yml
   
   API changes require OpenAPI spec updates
   
   Checklist:
   - [ ] Response schema updated
   - [ ] Example payload updated
   - [ ] Version bumped if breaking

Continue? (y/n): n

$ # Developer updates docs
$ git add src/api/users.js docs/openapi.yml
$ git commit -m "add user profile to response, update docs"
```

**Value:** API consumers always have accurate documentation.

---

## Use Case 7: Blocking Direct Main Branch Commits

**Scenario:** Developer pushes directly to main, bypassing code review.

**Without CHP:**
```bash
$ git push origin main
# Code lands without review
# Bug introduced, tests fail on CI
# Main branch broken for all developers
```

**With CHP:**
```bash
$ git push origin main

❌ CHP law 'require-pull-request' violated
   Direct pushes to main are blocked
   
   Fix: Use pull request workflow
   
   git checkout -b feature/my-change
   git push origin feature/my-change
   # Open PR, get review, merge via GitHub

Push rejected.
```

**Value:** All code reviewed before reaching main branch.

---

## Use Case 8: Enforcing Structured Logging

**Scenario:** Developer uses string concatenation in logs.

**Without CHP:**
```javascript
logger.info('User ' + userId + ' failed login from ' + ip);
// Output: "User 12345 failed login from 192.168.1.1"
// Cannot query by userId or IP in log aggregator
```

**With CHP:**
```bash
$ git add src/auth/login.js
$ git commit -m "improve error handling"

⚠️  CHP law 'structured-logging-only' warning
   Found: String concatenation in log statement
   
   Fix: Use structured fields
   
   // Bad
   logger.info('User ' + userId + ' failed login from ' + ip);
   
   // Good
   logger.info('Login failed', { 
     userId, 
     ip, 
     timestamp: new Date().toISOString() 
   });

Searchable fields: userId, ip, timestamp
```

**Value:** Logs are queryable, filterable, and machine-parseable.

---

## Use Case 9: Preventing Large File Commits

**Scenario:** Developer accidentally commits 500MB video file.

**Without CHP:**
```bash
$ git add assets/promo-video.mp4  # 500MB
$ git commit -m "add promo"
$ git push
# Repository bloats permanently
# Clone times increase
# Git history forever contains 500MB blob
```

**With CHP:**
```bash
$ git add assets/promo-video.mp4
$ git commit -m "add promo"

❌ CHP law 'max-file-size' violated
   File: assets/promo-video.mp4 (512MB)
   Limit: 10MB
   
   Fix: Use Git LFS or external storage
   
   git lfs track "*.mp4"
   git add .gitattributes assets/promo-video.mp4

Commit blocked.
```

**Value:** Repository stays lean, clone times fast, history clean.

---

## Use Case 10: Enforcing Conventional Commit Messages

**Scenario:** Inconsistent commit messages make changelog generation impossible.

**Without CHP:**
```
fix bug
updated stuff
WIP
cleanup
final final version
# Cannot auto-generate changelog
# Release notes manual and error-prone
```

**With CHP:**
```bash
$ git commit -m "fix bug"

❌ CHP law 'conventional-commits' violated
   Message: "fix bug"
   Format: type(scope): description
   
   Examples:
   feat(auth): add OAuth2 login
   fix(api): handle null response
   docs(readme): update install steps
   test(payments): add charge tests

Commit rejected. Fix message and retry.

$ git commit -m "fix(auth): handle expired token edge case"
✅ Commit accepted
```

**Value:** Auto-generated changelogs, semantic versioning, clear history.

---

## Use Case 11: AI Agent Prevented From Deleting Production Database

**Scenario:** AI agent suggests destructive operation.

**Without CHP:**
```
User: "Clean up old data"
Agent: "I'll run DELETE FROM users WHERE created_at < '2023-01-01'"
# Deletes 50,000 user records
# No backup, no confirmation
# Irreversible data loss
```

**With CHP:**
```
User: "Clean up old data"
Agent: "I'll help you archive old data safely"

⚠️  CHP law 'no-destructive-db-ops' triggered
   Operation: DELETE FROM users WHERE ...
   Environment: production
   
   Blocked in production. Suggested alternatives:
   1. Export data to archive table first
   2. Use soft delete (set deleted_at)
   3. Run on staging to preview impact

Safe approach:
-- Create archive table
CREATE TABLE users_archive AS 
SELECT * FROM users WHERE created_at < '2023-01-01';

-- Verify archive, then soft delete
UPDATE users 
SET deleted_at = NOW() 
WHERE created_at < '2023-01-01';
```

**Value:** AI agents guided away from destructive actions in production.

---

## Use Case 12: Onboarding New Developer

**Scenario:** New team member doesn't know project standards.

**Without CHP:**
```bash
$ git clone repo
$ # Developer learns standards through PR rejections
$ # Multiple round-trips, frustration, delays
```

**With CHP:**
```bash
$ git clone repo
$ ./commands/chp-onboard

CHP Code Health Protocol
━━━━━━━━━━━━━━━━━━━━━━━

Active Laws: 12

Security (3):
  ✓ no-api-keys        - Prevents credential leaks
  ✓ no-secrets-in-code - Blocks hardcoded passwords
  ✓ require-https      - Enforces TLS in production

Quality (4):
  ✓ no-console-log     - Use structured logging
  ✓ max-file-size      - 10MB limit, use Git LFS
  ✓ require-tests      - Critical paths need coverage
  ✓ no-todos-in-code   - Track in issues instead

Infrastructure (3):
  ✓ terraform-plan     - Require plan before apply
  ✓ no-public-s3       - Block public bucket exposure
  ✓ k8s-resource-limits - Prevent OOM crashes

Process (2):
  ✓ conventional-commits - For changelog generation
  ✓ require-pr         - No direct main pushes

Quick Commands:
  chp-law list         - See all laws
  chp-law test <name>  - Test a specific law
  chp-audit            - Scan codebase for violations

Read docs/chp/laws/*/guidance.md for details.
```

**Value:** New developers understand constraints immediately, faster onboarding.

---

## Summary

| Use Case | Prevents | Enforces |
|----------|----------|----------|
| API key leaks | Security incidents | Secrets in environment |
| Missing tests | Production bugs | Coverage on critical paths |
| Console.log noise | Log pollution | Structured logging |
| Public S3 buckets | Data exposure | Private-by-default |
| Migrations without rollback | Extended outages | Rollback plans |
| Outdated API docs | Integration failures | Doc/code sync |
| Direct main pushes | Unreviewed code | PR workflow |
| String logging | Unqueryable logs | JSON structured logs |
| Large files | Repo bloat | Git LFS usage |
| Bad commit messages | Manual changelog work | Conventional commits |
| AI destructive ops | Data loss | Safe alternatives |
| New dev confusion | Repeated rejections | Self-documented standards |

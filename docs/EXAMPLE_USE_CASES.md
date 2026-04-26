# CHP Use Cases

Some shit that actually happens and how CHP catches it.

---

## The API Key You Forgot About

You're hacking on Stripe integration, hardcode the key to test quickly.

```bash
git add .
git commit -m "stripe stuff"
```

**Normally:** Key's in git history now. Good luck scrubbing that. Hope no one scrapes your repo.

**With CHP:**
```
❌ no-api-keys: Found sk_live_ in src/config.js:15

Move it to .env dumbass. Commit blocked.
```

---

## Console.log Everywhere

You're debugging. Console.log here, console.log there. Works, ship it.

**Normally:** Production logs are 90% your debug garbage. Good luck finding actual errors.

**With CHP:**
```
❌ no-console-log: 3 console.log statements staged

Use a real logger or remove them. Commit blocked.
```

---

## "Quick" S3 Bucket

Need to share a file with the team, make a bucket, forget the permissions.

```hcl
resource "aws_s3_bucket" "temp" {
  bucket = "company-data-temp"
}
```

**Normally:** Your bucket is public. Data exposed. Security incident ticket #4472.

**With CHP:**
```
❌ no-public-s3-buckets: Missing public_access_block

Add the block or explain why this needs to be public. terraform apply blocked.
```

---

## The Migration You Can't Undo

New feature needs schema change. Write migration, deploy, realize it's wrong.

**Normally:** No rollback. 2am outage. Hotfix migration written while tired.

**With CHP:**
```
❌ migration-requires-rollback: migrations/20240115_alter_users.js has no down()

How are you gonna unfuck this when it breaks? Commit blocked.
```

---

## Direct Push to Main

Small fix, just push it. It's fine.

```bash
git push origin main
```

**Normally:** CI breaks for everyone. 12 slack DMs. Revert PR.

**With CHP:**
```
❌ require-pull-request: Direct pushes to main blocked

Open a PR like everyone else. Push rejected.
```

---

## "I'll Write Tests Later"

Payment logic done. Works on your machine. Tests later.

**Normally:** "Later" never comes. Bug found in prod when customer's charged 10x.

**With CHP:**
```
⚠️ require-tests: src/payments/process.js has no test file

Critical code needs tests. Commit anyway? n
```

---

## Random File Addition

Drag and drop 500MB video into assets/. Commit.

**Normally:** Repo is now 500MB heavier forever. Clone takes ages. History polluted.

**With CHP:**
```
❌ max-file-size: assets/promo.mp4 is 512MB (limit: 10MB)

Use Git LFS or external hosting. Commit blocked.
```

---

## Commit Message Garbage

```
fix stuff
WIP
final version
actually final
```

**Normally:** Changelog is manual. Release notes are guesswork.

**With CHP:**
```
❌ conventional-commits: "fix stuff" doesn't match required format

Try: fix(auth): handle null token in refresh flow
```

---

## AI Agent About to Delete Prod

Claude: "I'll clean up those old records for you"

**Normally:** DELETE FROM users WHERE ... runs on production. Oops.

**With CHP:**
```
⚠️ no-destructive-db-ops: DELETE in production blocked

Export first. Soft delete. Test on staging. Suggesting safer approach...
```

---

## String Logs You Can't Query

```javascript
logger.info('User ' + id + ' from ' + ip + ' failed login')
```

**Normally:** Want to find all failures for user 123? Good luck grepping.

**With CHP:**
```
⚠️ structured-logging: String concatenation detected

Use: logger.info('Login failed', { userId: id, ip })
```

---

## New Dev Has No Idea

First day. Git clone. Make change. Push.

**Normally:** PR rejected 3 times. "We don't do that here." Frustrating.

**With CHP:**
```bash
$ ./commands/chp-status

Active rules: 12
- no-api-keys: Don't commit secrets
- require-pr: Use branches, not main
- conventional-commits: fix/feat/docs format

Read docs/chp/laws/*/guidance.md for the full list.
```

---

That's it. CHP just stops you from doing dumb shit that costs time later.

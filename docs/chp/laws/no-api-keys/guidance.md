# Law: no-api-keys

**Severity:** error
**Created:** 2026-04-25T05:02:04Z

## Purpose

Prevent API keys, tokens, and secrets from being committed to the repository. Leaked credentials in source code are a leading cause of security breaches.

## What this law checks

Scans files for common API key patterns:
- `sk-` (Stripe secret keys)
- `AIza` (Google API keys)
- `AKIA` (AWS access key IDs)
- `ghp_`, `gho_`, `ghu_`, `ghs_`, `ghr_` (GitHub tokens)
- `xoxb-`, `xoxp-` (Slack tokens)

## How to comply

- Use environment variables (`process.env.API_KEY`, `os.environ.get("API_KEY")`)
- Use `.env` files (ensure `.env` is in `.gitignore`)
- Use secret management services (AWS Secrets Manager, HashiCorp Vault, etc.)
- Pass secrets via CI/CD environment settings, not code

### Good Practice

```js
const apiKey = process.env.STRIPE_API_KEY;
```

```python
api_key = os.environ.get("STRIPE_API_KEY")
```

### Bad Practice (will fail verification)

```js
const apiKey = "sk_live_abc123...";
```

```python
api_key = "sk_live_abc123..."
```

## Remediation

If this law fails:
1. Identify the file with the leaked key
2. Move the secret to an environment variable or secret manager
3. Rotate the compromised key immediately
4. Re-run the verification

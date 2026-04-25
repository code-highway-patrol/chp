---
name: security-best-practices
created: 2026-04-25T00:00:00Z
category: Security
severity: error
enabled: True
references:
  - https://owasp.org/Top10/
  - https://cheatsheetseries.owasp.org/
  - https://datatracker.ietf.org/doc/html/draft-ietf-oauth-security-topics
  - https://tools.ietf.org/html/rfc8725
  - https://developer.hashicorp.com/vault/tutorials/getting-started/getting-started-intro
  - https://12factor.net/config
---

# Law: security-best-practices

**Severity:** error  
**Created:** 2026-04-25T00:00:00Z  
**Category:** Security

## Purpose

Enforces security best practices based on OWASP and industry standards.

## Reference Materials

### Primary Sources

1. **OWASP Top 10 (2021)**  
   https://owasp.org/Top10/  
   The definitive list of critical web application security risks. Updated every 3-4 years by security experts worldwide.

2. **OWASP Cheat Sheet Series**  
   https://cheatsheetseries.owasp.org/  
   Practical secure coding quick references for authentication, session management, cryptography, and more.

3. **IETF - OAuth 2.0 Security Best Current Practice**  
   https://datatracker.ietf.org/doc/html/draft-ietf-oauth-security-topics  
   Official security recommendations for OAuth 2.0 implementations from the Internet Engineering Task Force.

4. **RFC 8725 - JSON Web Token Best Current Practices**  
   https://tools.ietf.org/html/rfc8725  
   IETF standards for secure JWT usage, including signing algorithms and validation requirements.

5. **HashiCorp Vault - Secrets Management**  
   https://developer.hashicorp.com/vault/tutorials/getting-started/getting-started-intro  
   Enterprise patterns for secret storage, dynamic credentials, and encryption as a service.

6. **12-Factor App - Config**  
   https://12factor.net/config  
   Heroku's methodology for storing config in environment, never committing secrets to code.

## Patterns Checked

### 1. No Hardcoded Secrets
From [OWASP Cheat Sheet - Secrets Management](https://cheatsheetseries.owasp.org/cheatsheets/Secrets_Management_Cheat_Sheet.html):
> "Secrets must never be stored in source code or version control. Use environment variables or dedicated secret managers."

```javascript
// Bad: Secret in code
const API_KEY = "sk-1234567890abcdef";

// Good: Environment variable
const API_KEY = process.env.API_KEY;
```

### 2. No SQL String Concatenation
From [OWASP Top 10 - A03:2021 Injection](https://owasp.org/Top10/A03_2021-Injection/):
> "Injection flaws occur when untrusted data is sent to an interpreter. Use parameterized queries."

```javascript
// Bad: String concatenation
const query = `SELECT * FROM users WHERE id = ${userId}`;

// Good: Parameterized query
const query = 'SELECT * FROM users WHERE id = ?';
db.query(query, [userId]);
```

### 3. No Eval or Dangerous Functions
From [OWASP Cheat Sheet - XSS Prevention](https://cheatsheetseries.owasp.org/cheatsheets/Cross_Site_Scripting_Prevention_Cheat_Sheet.html):
> "Avoid eval(), new Function(), and document.write() which can execute arbitrary code."

```javascript
// Bad: Code injection risk
eval(userInput);
new Function(userInput)();
document.write(userInput);
```

### 4. Validate All Inputs
From [OWASP Top 10 - A03:2021 Injection](https://owasp.org/Top10/A03_2021-Injection/):
> "Validate, filter, or sanitize all data from untrusted sources."

```javascript
// Bad: Direct use of user input
app.post('/users', (req, res) => {
    db.createUser(req.body);
});

// Good: Schema validation
const schema = z.object({
    email: z.string().email(),
    age: z.number().min(0).max(150)
});
const data = schema.parse(req.body);
```

### 5. HTTPS Only
From [OWASP Cheat Sheet - Transport Layer Protection](https://cheatsheetseries.owasp.org/cheatsheets/Transport_Layer_Protection_Cheat_Sheet.html):
> "Use HTTPS for all authenticated and sensitive communications. Redirect HTTP to HTTPS."

```javascript
// Bad: HTTP allowed
app.listen(80);

// Good: HTTPS enforced
app.use((req, res, next) => {
    if (!req.secure) return res.redirect(301, `https://${req.headers.host}${req.url}`);
    next();
});
```

### 6. Secure Headers
From [OWASP Cheat Sheet - HTTP Headers](https://cheatsheetseries.owasp.org/cheatsheets/HTTP_Headers_Cheat_Sheet.html):

| Header | Purpose |
|--------|---------|
| Content-Security-Policy | Prevents XSS by controlling resource loading |
| X-Content-Type-Options | Prevents MIME type sniffing |
| X-Frame-Options | Prevents clickjacking |
| Strict-Transport-Security | Enforces HTTPS |
| X-XSS-Protection | Legacy XSS protection |

### 7. No Insecure Dependencies
From [OWASP Top 10 - A06:2021 Vulnerable Components](https://owasp.org/Top10/A06_2021-Vulnerable_and_Outdated_Components/):
> "Regularly scan dependencies for known vulnerabilities. Fail CI/CD on high/critical findings."

```bash
# Required commands:
npm audit
# CI/CD must fail on high/critical
```

### 8. Authentication Best Practices
From [OWASP Cheat Sheet - Authentication](https://cheatsheetseries.owasp.org/cheatsheets/Authentication_Cheat_Sheet.html):

- **Passwords**: Min 12 chars, use bcrypt/argon2 (not MD5/SHA1)
- **Sessions**: HttpOnly, Secure, SameSite=Strict cookies
- **JWT**: Short expiry (15min), use refresh tokens, never in localStorage
- **MFA**: Required for admin/sensitive operations

### 9. Authorization Checks
From [OWASP Top 10 - A01:2021 Broken Access Control](https://owasp.org/Top10/A01_2021-Broken_Access_Control/):
> "Deny by default. Implement once, reuse across application."

```javascript
// Bad: Missing authorization
app.get('/admin/users', async (req, res) => {
    const users = await db.getAllUsers();
    res.json(users);
});

// Good: Explicit authorization
app.get('/admin/users', requireAdmin, async (req, res) => {
    const users = await db.getAllUsers();
    res.json(users);
});
```

### 10. No Sensitive Data in Logs
From [OWASP Cheat Sheet - Logging](https://cheatsheetseries.owasp.org/cheatsheets/Logging_Cheat_Sheet.html):
> "Never log sensitive data including passwords, tokens, credit cards, or PII."

```javascript
// Bad: Logging sensitive data
logger.info('Login attempt', { password: req.body.password });

// Good: Redact sensitive fields
logger.info('Login attempt', { userId: req.user.id });
```

## Remediation

Security violations must be fixed immediately. Refer to OWASP Cheat Sheets for detailed remediation guidance.

---

*Guidance synthesized from OWASP Top 10 and official security standards.*

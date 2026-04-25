---
name: observability-best-practices
created: 2026-04-25T00:00:00Z
category: Observability
severity: warn
enabled: True
references:
  - https://cloud.google.com/logging/docs/best-practices
  - https://prometheus.io/docs/practices/
  - https://opentelemetry.io/docs/concepts/signals/traces/
  - https://www.honeycomb.io/blog/what-observability-why-should-i-care/
  - https://www.oreilly.com/library/view/structured-logging-for/9781492030003/
---

# Law: observability-best-practices

**Severity:** warn  
**Created:** 2026-04-25T00:00:00Z  
**Category:** Observability

## Purpose

Enforces observability best practices for logging, metrics, and tracing.

## Reference Materials

### Primary Sources

1. **Google Cloud - Logging Best Practices**  
   https://cloud.google.com/logging/docs/best-practices  
   Google's guide on structured logging, correlation IDs, and log severity levels.

2. **Prometheus - Best Practices**  
   https://prometheus.io/docs/practices/  
   Official guidance on metric naming, instrumentation, histograms, and alerting.

3. **OpenTelemetry - Tracing Concepts**  
   https://opentelemetry.io/docs/concepts/signals/traces/  
   Industry standard for distributed tracing, sampling, and span attributes.

4. **Charity Majors (Honeycomb) - What is Observability?**  
   https://www.honeycomb.io/blog/what-observability-why-should-i-care/  
   The modern definition: unknown-unknowns, high-cardinality data, debugging production.

5. **O'Reilly - Structured Logging Guide**  
   https://www.oreilly.com/library/view/structured-logging-for/9781492030003/  
   Best practices for JSON logging, correlation IDs, and log aggregation.

## Patterns Checked

### 1. Structured Logging Only
From [Google Cloud Logging Best Practices](https://cloud.google.com/logging/docs/best-practices):
> "Structured logs enable filtering, aggregation, and analysis. Avoid string concatenation."

```javascript
// Bad: String concatenation
logger.info('User ' + userId + ' logged in from ' + ip);

// Good: Structured JSON
logger.info('User logged in', {
  userId: userId,
  ip: ip,
  userAgent: req.headers['user-agent'],
  timestamp: new Date().toISOString()
});
```

### 2. Log Levels Used Correctly
From [Google Cloud Logging](https://cloud.google.com/logging/docs/best-practices):

| Level | Use Case | Example |
|-------|----------|---------|
| DEBUG | Development troubleshooting | Variable values |
| INFO | Normal operation events | Request completed |
| WARN | Unexpected but handled | Failed login attempt |
| ERROR | Failed operations | Database connection lost |
| FATAL | System unusable | Cannot start server |

### 3. Correlation IDs Required
From [Google Cloud Logging](https://cloud.google.com/logging/docs/best-practices):
> "Include correlation IDs to trace requests across distributed services."

```javascript
// Bad: No request tracking
app.get('/api/users', async (req, res) => {
  const users = await db.getUsers();
  res.json(users);
});

// Good: Correlation ID propagated
app.get('/api/users', async (req, res) => {
  const correlationId = req.headers['x-request-id'] || generateId();
  logger.info('Processing request', { correlationId });
  
  const users = await db.getUsers({ correlationId });
  res.set('X-Request-ID', correlationId).json(users);
});
```

### 4. No Sensitive Data in Logs
From [OWASP Logging Cheat Sheet](https://cheatsheetseries.owasp.org/cheatsheets/Logging_Cheat_Sheet.html):
> "Never log PII, passwords, tokens, or credit card numbers."

```javascript
// Bad: Leaks PII
logger.info('Login attempt', {
  email: 'user@example.com',
  password: 'secret123',
  ssn: '123-45-6789'
});

// Good: Sanitized
logger.info('Login attempt', {
  userId: 'usr_123',
  email: maskEmail('user@example.com'),
  success: false
});
```

### 5. Metrics Naming Convention
From [Prometheus Naming Best Practices](https://prometheus.io/docs/practices/naming/):
> "Use snake_case. Include unit suffix (_seconds, _bytes, _total)."

```
# Bad: Inconsistent naming
request_count
http.requests.total
apiLatency

# Good: Prometheus naming
http_requests_total{method="GET",status="200"}
http_request_duration_seconds_bucket{le="0.1"}
database_connections_active
cache_hit_ratio
```

### 6. RED Method Metrics
From [Tom Wilkie - RED Method](https://grafana.com/blog/2018/08/02/the-red-method-how-to-instrument-your-services/):

| Metric | Description | Why |
|--------|-------------|-----|
| Rate | Requests per second | Traffic load |
| Errors | Failed requests | Reliability |
| Duration | Request latency | Performance |

### 7. USE Method Metrics (Resources)
From [Brendan Gregg - USE Method](http://www.brendangregg.com/usemethod.html):

| Metric | Description | Why |
|--------|-------------|-----|
| Utilization | % time busy | Capacity planning |
| Saturation | % work queued | Bottlenecks |
| Errors | Error count | Reliability |

### 8. Distributed Tracing Required
From [OpenTelemetry Tracing](https://opentelemetry.io/docs/concepts/signals/traces/):
> "Spans track request flow across services. Attributes add context. Events mark points in time."

```javascript
// Bad: No visibility into request flow
async function processOrder(order) {
  await validateOrder(order);
  await chargePayment(order);
  await fulfillOrder(order);
}

// Good: Spans for each operation
async function processOrder(order) {
  const span = tracer.startSpan('processOrder');
  
  try {
    await tracer.trace('validateOrder', () => validateOrder(order));
    await tracer.trace('chargePayment', () => chargePayment(order));
    await tracer.trace('fulfillOrder', () => fulfillOrder(order));
    
    span.setStatus({ code: SpanStatusCode.OK });
  } catch (err) {
    span.recordException(err);
    span.setStatus({ code: SpanStatusCode.ERROR });
    throw err;
  } finally {
    span.end();
  }
}
```

### 9. Alert on Symptoms, Not Causes
From [Google SRE Book - Alerting](https://sre.google/sre-book/monitoring-distributed-systems/):
> "Alert on user-visible symptoms (slow responses, errors), not causes (high CPU)."

```yaml
# Bad: Alert on cause
- alert: HighCPUUsage
  expr: cpu_usage > 80%
  
# Good: Alert on symptom
- alert: SlowAPIResponses
  expr: histogram_quantile(0.99, rate(http_request_duration_seconds_bucket[5m])) > 1
```

### 10. Health Check Endpoints
From [K8s Probes](https://kubernetes.io/docs/concepts/workloads/pods/pod-lifecycle/#container-probes):

```javascript
// Required endpoints
GET /health/live    // Liveness - is the process running?
GET /health/ready   // Readiness - can it serve traffic?
GET /health/metrics // Prometheus metrics

// Good implementation
app.get('/health/ready', async (req, res) => {
  const checks = await Promise.all([
    db.ping(),
    cache.ping(),
    externalService.check()
  ]);
  
  if (checks.every(c => c.ok)) {
    res.status(200).json({ status: 'ready' });
  } else {
    res.status(503).json({ 
      status: 'not ready',
      failed: checks.filter(c => !c.ok).map(c => c.name)
    });
  }
});
```

## Remediation

Observability gaps make debugging impossible in production. Review against patterns above for operational readiness.

---

*Guidance synthesized from Google, Prometheus, and OpenTelemetry best practices.*

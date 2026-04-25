---
name: microservices-best-practices
created: 2026-04-25T00:00:00Z
category: Microservices
severity: warn
enabled: True
references:
  - https://microservices.io/patterns/
  - https://docs.aws.amazon.com/whitepapers/latest/microservices-on-aws/microservices-communication-patterns.html
  - https://www.oreilly.com/library/view/designing-data-intensive-applications/9781491903063/
  - https://grpc.io/docs/guides/
  - https://pragprog.com/titles/mnee2/
---

# Law: microservices-best-practices

**Severity:** warn  
**Created:** 2026-04-25T00:00:00Z  
**Category:** Microservices

## Purpose

Enforces microservices architecture best practices for service boundaries, communication, and data management.

## Reference Materials

### Primary Sources

1. **Chris Richardson - Microservices Patterns**  
   https://microservices.io/patterns/  
   The comprehensive pattern catalog for microservices. Includes decomposition, communication, data management, and deployment patterns.

2. **AWS - Microservices on AWS Whitepaper**  
   https://docs.aws.amazon.com/whitepapers/latest/microservices-on-aws/microservices-communication-patterns.html  
   AWS best practices for sync/async communication, choreography vs orchestration, and service discovery.

3. **Martin Kleppmann - Designing Data-Intensive Applications (O'Reilly)**  
   https://www.oreilly.com/library/view/designing-data-intensive-applications/9781491903063/  
   Chapters 5 (replication) and 8 (distributed system challenges) essential for microservices data design.

4. **gRPC Documentation - Guides**  
   https://grpc.io/docs/guides/  
   Modern RPC framework best practices for service-to-service communication.

5. **Michael Nygard - Release It! (Pragmatic Bookshelf)**  
   The definitive book on stability patterns: circuit breakers, bulkheads, timeouts.

## Patterns Checked

### 1. Database Per Service
From [Chris Richardson - Database Per Service Pattern](https://microservices.io/patterns/data/database-per-service.html):
> "Each microservice should own its data. No shared databases. Enforce loose coupling at data layer."

```
# Bad: Shared database
Orders Service ──▶ Shared DB ◀── Users Service

# Good: Database per service
Orders Service ──▶ Orders DB
Users Service  ──▶ Users DB
```

### 2. API Gateway Pattern
From [Richardson - API Gateway Pattern](https://microservices.io/patterns/apigateway.html):
> "Single entry point for clients. Handles routing, composition, and protocol translation."

```
# Bad: Clients call multiple services
Mobile App ──▶ Orders Service
           ──▶ Users Service
           ──▶ Inventory Service

# Good: Single entry point
Mobile App ──▶ API Gateway ──▶ Orders Service
                          ──▶ Users Service
                          ──▶ Inventory Service
```

### 3. Async Messaging for Loose Coupling
From [Richardson - Messaging Pattern](https://microservices.io/patterns/communication/messaging.html):
> "Asynchronous messaging improves availability and enables temporal decoupling."

```javascript
// Bad: Synchronous chain
createOrder() {
  await inventoryService.reserve();  // Blocks
  await paymentService.charge();      // Blocks
  await shippingService.schedule();     // Blocks
}

// Good: Event-driven async
// Order Service
publishEvent('OrderCreated', order);

// Inventory Service (subscriber)
onEvent('OrderCreated', async (order) => {
  await reserveInventory(order);
  publishEvent('InventoryReserved', order);
});

// Payment Service (subscriber)
onEvent('InventoryReserved', async (order) => {
  await chargePayment(order);
  publishEvent('PaymentCompleted', order);
});
```

### 4. Circuit Breaker Pattern
From [Nygard - Release It! - Circuit Breaker](https://pragprog.com/titles/mnee2/):
> "Fail fast when downstream is failing. Prevent cascade failures."

```javascript
class CircuitBreaker {
  constructor(threshold = 5, timeout = 60000) {
    this.failureCount = 0;
    this.threshold = threshold;
    this.timeout = timeout;
    this.state = 'CLOSED'; // CLOSED, OPEN, HALF_OPEN
  }
  
  async call(fn) {
    if (this.state === 'OPEN') {
      if (Date.now() - this.lastFailure > this.timeout) {
        this.state = 'HALF_OPEN';
      } else {
        throw new Error('Circuit breaker is OPEN');
      }
    }
    
    try {
      const result = await fn();
      this.onSuccess();
      return result;
    } catch (err) {
      this.onFailure();
      throw err;
    }
  }
}
```

### 5. Saga Pattern for Distributed Transactions
From [Richardson - Saga Pattern](https://microservices.io/patterns/data/saga.html):
> "Manage transactions across multiple services using compensating transactions."

```javascript
// Good: Compensating transactions
class OrderSaga {
  async execute(order) {
    const steps = [
      { service: 'inventory', action: 'reserve', compensate: 'release' },
      { service: 'payment', action: 'charge', compensate: 'refund' },
      { service: 'shipping', action: 'schedule', compensate: 'cancel' }
    ];
    
    const completed = [];
    
    for (const step of steps) {
      try {
        await step.service[step.action](order);
        completed.push(step);
      } catch (err) {
        // Compensate completed steps
        for (const completedStep of completed.reverse()) {
          await completedStep.service[completedStep.compensate](order);
        }
        throw err;
      }
    }
  }
}
```

### 6. Service Discovery
From [AWS Microservices Whitepaper](https://docs.aws.amazon.com/whitepapers/latest/microservices-on-aws/microservices-communication-patterns.html):
> "Services should discover each other dynamically, not use hardcoded URLs."

```yaml
# Bad: Hardcoded URLs
services:
  orders: http://orders-service.internal:8080

# Good: Service registry (DNS-based)
services:
  orders: http://orders.service.consul

# Or Kubernetes native:
services:
  orders: http://orders.default.svc.cluster.local
```

### 7. Backwards Compatibility for APIs
From [Richardson - API Gateway Pattern](https://microservices.io/patterns/apigateway.html):
> "Never remove fields. Deprecate instead. Maintain multiple versions if needed."

```protobuf
// Good: Never remove fields, only deprecate
message GetUserResponse {
  string id = 1;
  string name = 2;
  string email = 3;
  
  // Deprecated - use fullName instead
  string first_name = 4 [deprecated = true];
  string last_name = 5 [deprecated = true];
  
  // New field added
  string full_name = 6;
}
```

### 8. Timeout and Retry Policies
From [AWS - Timeout and Retry Best Practices](https://docs.aws.amazon.com/whitepapers/latest/microservices-on-aws/microservices-communication-patterns.html):
> "Always use timeouts. Retry with exponential backoff. Use circuit breakers."

```javascript
const client = new ServiceClient({
  baseURL: 'http://inventory-service',
  timeout: 5000,  // 5 seconds max
  retry: {
    max: 3,
    backoff: 'exponential',  // 100ms, 200ms, 400ms
    retryableErrors: ['ETIMEDOUT', 'ECONNREFUSED']
  }
});
```

### 9. Health Check Endpoints
From [K8s Health Checks](https://kubernetes.io/docs/concepts/workloads/pods/pod-lifecycle/#container-probes):
> "Liveness checks restart unhealthy pods. Readiness controls traffic routing."

```yaml
livenessProbe:
  httpGet:
    path: /health/live
    port: 8080
  initialDelaySeconds: 10
  periodSeconds: 10

readinessProbe:
  httpGet:
    path: /health/ready
    port: 8080
  initialDelaySeconds: 5
  periodSeconds: 5
```

### 10. Bulkhead Pattern (Isolation)
From [Nygard - Release It! - Bulkheads](https://pragprog.com/titles/mnee2/):
> "Isolate failures. Don't let one slow endpoint consume all resources."

```javascript
// Bad: Shared thread pool can exhaust all capacity
app.get('/api/heavy', heavyHandler);
app.get('/api/light', lightHandler);   // Starves when heavy is loaded

// Good: Separate resource pools
const heavyPool = new WorkerPool(4, 'heavy-ops');
const lightPool = new WorkerPool(20, 'light-ops');

app.get('/api/heavy', (req, res) => {
  heavyPool.execute(heavyHandler, req, res);
});

app.get('/api/light', (req, res) => {
  lightPool.execute(lightHandler, req, res);
});
```

## Remediation

Microservices add operational complexity. Review against patterns above to avoid common pitfalls.

---

*Guidance synthesized from Chris Richardson's patterns and AWS microservices best practices.*

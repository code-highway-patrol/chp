# Best Practices Reference

A curated collection of authoritative best practice guides across software engineering domains.

## Database & Storage

| Resource | URL | Why It Matters |
|----------|-----|----------------|
| PostgreSQL Wiki - Don't Do This | https://wiki.postgresql.org/wiki/Don't_Do_This | Anti-patterns that cause performance issues |
| Designing Data-Intensive Applications (Kleppmann) | https://www.oreilly.com/library/view/designing-data-intensive-applications/9781491903063/ | The database design bible |
| Martin Fowler - Evolutionary Database Design | https://martinfowler.com/articles/evodb.html | Schema migration strategies |
| Flyway Migration Concepts | https://flywaydb.org/documentation/concepts/migrations.html | Version-controlled schema changes |
| DynamoDB Best Practices | https://docs.aws.amazon.com/amazondynamodb/latest/developerguide/bp-general.html | Single-table design patterns |
| MySQL Performance Guide | https://dev.mysql.com/doc/refman/8.0/en/optimization.html | Indexing and query optimization |

## API Design

| Resource | URL | Why It Matters |
|----------|-----|----------------|
| Google API Design Guide | https://cloud.google.com/apis/design | Industry standard REST conventions |
| Microsoft REST API Guidelines | https://github.com/microsoft/api-guidelines | Enterprise API patterns |
| Richardson Maturity Model | https://martinfowler.com/articles/richardsonMaturityModel.html | What makes APIs truly RESTful |
| GraphQL Best Practices | https://graphql.org/learn/thinking-in-graphs/ | Schema design principles |
| Apollo Server Schema Design | https://www.apollographql.com/docs/apollo-server/schema/schema/ | Production GraphQL patterns |
| Swagger/OpenAPI Best Practices | https://swagger.io/resources/articles/best-practices-in-api-documentation/ | API documentation standards |
| API Versioning Guide | https://www.troyhunt.com/your-api-versioning-is-wrong-which-is/ | Versioning strategies comparison |

## Security

| Resource | URL | Why It Matters |
|----------|-----|----------------|
| OWASP Top 10 | https://owasp.org/Top10/ | Critical web security risks |
| OWASP Cheat Sheets | https://cheatsheetseries.owasp.org/ | Secure coding quick reference |
| OAuth 2.0 Security BCP | https://datatracker.ietf.org/doc/html/draft-ietf-oauth-security-topics | IETF security standards |
| JWT Best Practices (RFC 8725) | https://tools.ietf.org/html/rfc8725 | Token security requirements |
| HashiCorp Vault Guides | https://developer.hashicorp.com/vault/tutorials | Secrets management patterns |
| 12-Factor App - Config | https://12factor.net/config | Environment-based configuration |
| CWE Top 25 | https://cwe.mitre.org/top25/ | Software weaknesses archive |
| Mozilla Web Security | https://infosec.mozilla.org/guidelines/web_security.html | Security headers and policies |

## Infrastructure & DevOps

| Resource | URL | Why It Matters |
|----------|-----|----------------|
| Terraform Best Practices | https://www.terraform.io/docs/cloud-docs/recommended-practices/index.html | Team workflows and state management |
| CNCF K8s Best Practices | https://www.cncf.io/wp-content/uploads/2020/08/CNCF-Best-Practices-for-Kubernetes-Workloads.pdf | Production K8s deployment |
| Kief Morris - Infrastructure as Code | https://www.oreilly.com/library/view/infrastructure-as-code/9781098121620/ | IaC patterns and anti-patterns |
| Kubernetes Configuration | https://kubernetes.io/docs/concepts/configuration/overview/ | Official K8s best practices |
| 12-Factor App | https://12factor.net/ | Cloud-native methodology |
| AWS Well-Architected Framework | https://docs.aws.amazon.com/wellarchitected/latest/framework/welcome.html | Cloud architecture pillars |
| Google Cloud Architecture Center | https://cloud.google.com/architecture | Cloud design patterns |
| Azure Architecture Center | https://docs.microsoft.com/en-us/azure/architecture/ | Azure-specific patterns |

## Code Quality & Architecture

| Resource | URL | Why It Matters |
|----------|-----|----------------|
| Clean Architecture (Uncle Bob) | https://blog.cleancoder.com/uncle-bob/2012/08/13/the-clean-architecture.html | Layered architecture pattern |
| Domain-Driven Design (Fowler) | https://martinfowler.com/bliki/DomainDrivenDesign.html | Strategic design patterns |
| Monorepo.tools | https://monorepo.tools/ | Monorepo architecture guide |
| NX Mental Model | https://nx.dev/concepts/mental-model | Monorepo task graph |
| Software Architecture Patterns (O'Reilly) | https://www.oreilly.com/library/view/software-architecture-patterns/9781491971437/ | Architecture pattern catalog |
| Refactoring (Fowler) | https://refactoring.com/catalog/ | Code smell catalog |
| Clean Code | https://www.oreilly.com/library/view/clean-code/9780136083238/ | Code readability standards |
| Google Style Guides | https://google.github.io/styleguide/ | Language-specific conventions |

## Testing

| Resource | URL | Why It Matters |
|----------|-----|----------------|
| Test Pyramid (Fowler) | https://martinfowler.com/articles/practical-test-pyramid.html | Optimal test distribution |
| Google - No More E2E Tests | https://testing.googleblog.com/2015/04/just-say-no-to-more-end-to-end-tests.html | Why E2E tests are problematic |
| Kent C. Dodds Testing Trophy | https://kentcdodds.com/blog/write-tests | Static > Unit > Integration > E2E |
| Given-When-Then (Fowler) | https://martinfowler.com/bliki/GivenWhenThen.html | BDD test structure |
| TDD by Example (Beck) | https://www.oreilly.com/library/view/test-driven-development/0321146530/ | Test-first methodology |
| Arrange-Act-Assert | https://xp123.com/articles/3a-arrange-act-assert/ | Test structure pattern |
| Mutation Testing | https://mutation-testing.org/ | Test quality verification |

## Observability

| Resource | URL | Why It Matters |
|----------|-----|----------------|
| Google Cloud Logging Best Practices | https://cloud.google.com/logging/docs/best-practices | Structured logging guide |
| Prometheus Best Practices | https://prometheus.io/docs/practices/ | Metric naming and instrumentation |
| OpenTelemetry Concepts | https://opentelemetry.io/docs/concepts/signals/traces/ | Distributed tracing standards |
| Charity Majors - What is Observability | https://www.honeycomb.io/blog/what-observability-why-should-i-care/ | Modern observability definition |
| Structured Logging (O'Reilly) | https://www.oreilly.com/library/view/structured-logging-for/9781492030003/ | Correlation IDs and aggregation |
| USE Method (Gregg) | http://www.brendangregg.com/usemethod.html | Resource performance analysis |
| RED Method (Wilkie) | https://grafana.com/blog/2018/08/02/the-red-method-how-to-instrument-your-services/ | Request-based metrics |
| Google SRE Book - Monitoring | https://sre.google/sre-book/monitoring-distributed-systems/ | SRE monitoring philosophy |

## Documentation

| Resource | URL | Why It Matters |
|----------|-----|----------------|
| ADR GitHub Org | https://adr.github.io/ | Architecture Decision Records |
| Michael Nygard - ADRs | https://cognitect.com/blog/2011/11/15/documenting-architecture-decisions | Original ADR article |
| Keep a Changelog | https://keepachangelog.com/en/1.0.0/ | Changelog format standard |
| PagerDuty Runbooks | https://www.pagerduty.com/resources/learn/incident-response-runbook/ | Operational documentation |
| GitLab Docs Guide | https://docs.gitlab.com/ee/development/documentation/ | Technical writing standards |
| Write the Docs Guide | https://www.writethedocs.org/guide/ | Documentation community guide |
| Mermaid Diagrams | https://mermaid.js.org/ | Diagrams as code |
| Diátaxis Framework | https://diataxis.fr/ | Documentation structure pattern |

## Microservices & Distributed Systems

| Resource | URL | Why It Matters |
|----------|-----|----------------|
| Chris Richardson Patterns | https://microservices.io/patterns/ | Comprehensive pattern catalog |
| AWS Microservices Whitepaper | https://docs.aws.amazon.com/whitepapers/latest/microservices-on-aws/microservices-communication-patterns.html | Sync/async communication |
| Designing Data-Intensive Apps | https://www.oreilly.com/library/view/designing-data-intensive-applications/9781491903063/ | Distributed systems fundamentals |
| gRPC Guides | https://grpc.io/docs/guides/ | Modern RPC framework |
| Release It! (Nygard) | https://pragprog.com/titles/mnee2/ | Stability patterns |
| Fallacies of Distributed Computing | https://en.wikipedia.org/wiki/Fallacies_of_distributed_computing | Common misconceptions |
| CAP Theorem | https://www.infoq.com/articles/cap-twelve-years-later-how-the-rules-have-changed/ | Trade-offs in distributed systems |
| SAGA Pattern | https://microservices.io/patterns/data/saga.html | Distributed transactions |

## CI/CD & Delivery

| Resource | URL | Why It Matters |
|----------|-----|----------------|
| Continuous Integration (Fowler) | https://martinfowler.com/articles/continuousIntegration.html | CI fundamentals |
| Continuous Delivery (Humble/Farley) | https://www.oreilly.com/library/view/continuous-delivery-reliable/9780321670117/ | Delivery pipeline design |
| GitLab CI/CD Architecture | https://docs.gitlab.com/ee/ci/pipelines/pipeline_architectures.html | Pipeline structure patterns |
| GitHub Actions Workflow | https://docs.github.com/en/actions/using-workflows/workflow-syntax-for-github-actions | Actions best practices |
| Trunk-Based Development | https://trunkbaseddevelopment.com/ | Branching strategy |
| Feature Flags | https://martinfowler.com/articles/feature-toggles.html | Decoupling deploy from release |

## Performance & Scalability

| Resource | URL | Why It Matters |
|----------|-----|----------------|
| Web Performance (Google) | https://web.dev/performance-scoring/ | Core Web Vitals |
| High Performance Browser Networking | https://hpbn.co/ | Network optimization |
| Systems Performance (Gregg) | http://www.brendangregg.com/systems-performance-2nd-edition-book.html | Systems-level analysis |
| Designing for Scale | https://www.scaledagileframework.com/ | Enterprise scalability |
| Capacity Planning | https://aws.amazon.com/blogs/architecture/capacity-planning-for-elasticity-and-availability/ | Cloud capacity strategies |
| Latency Numbers | https://colin-scott.github.io/personal_website/research/interactive_latency.html | Hardware latency reference |

## Code Review & Collaboration

| Resource | URL | Why It Matters |
|----------|-----|----------------|
| Google Code Review Guide | https://google.github.io/eng-practices/review/ | Code review standards |
| Conventional Commits | https://www.conventionalcommits.org/ | Commit message format |
| Semantic Versioning | https://semver.org/ | Version numbering standard |
| GitHub Flow | https://docs.github.com/en/get-started/quickstart/github-flow | Lightweight branch workflow |
| GitLab Flow | https://docs.gitlab.com/ee/topics/gitlab_flow.html | Extended branch workflow |
| Pull Request Best Practices | https://www.atlassian.com/blog/git/written-unwritten-guide-pull-requests | PR etiquette |

## Accessibility

| Resource | URL | Why It Matters |
|----------|-----|----------------|
| WCAG Guidelines | https://www.w3.org/WAI/WCAG21/quickref/ | Web accessibility standards |
| A11y Project Checklist | https://www.a11yproject.com/checklist/ | Accessibility testing |
| Inclusive Design Principles | https://inclusivedesignprinciples.org/ | Design for all users |
| axe-core Rules | https://dequeuniversity.com/rules/axe/html/4.4 | Automated accessibility testing |

## Mobile Development

| Resource | URL | Why It Matters |
|----------|-----|----------------|
| Apple Human Interface Guidelines | https://developer.apple.com/design/human-interface-guidelines/ | iOS design patterns |
| Material Design | https://material.io/design | Android design system |
| Mobile App Performance | https://developer.android.com/topic/performance | Mobile optimization |
| React Native Best Practices | https://reactnative.dev/docs/performance | Cross-platform patterns |

## AI/ML Engineering

| Resource | URL | Why It Matters |
|----------|-----|----------------|
| ML System Design (Chip Huyen) | https://www.oreilly.com/library/view/designing-machine-learning/9781098107952/ | ML systems architecture |
| MLOps Principles | https://ml-ops.org/content/mlops-principles.html | ML operations |
| Feature Stores | https://www.featurestore.org/ | ML feature management |
| Model Cards | https://modelcards.withgoogle.com/about | Model documentation |
| Responsible AI | https://ai.google/responsibilities/responsible-ai-practices/ | AI ethics guidelines |

## Incident Response

| Resource | URL | Why It Matters |
|----------|-----|----------------|
| PagerDuty Incident Response | https://response.pagerduty.com/ | Incident response guide |
| Google SRE - Incident Management | https://sre.google/sre-book/managing-incidents/ | SRE incident handling |
| Etsy - Failure Friday | https://www.etsy.com/codeascraft/failure-friday | Intentional failure testing |
| Chaos Engineering | https://principlesofchaos.org/ | Controlled failure injection |
| Post-Mortem Templates | https://postmortems.papersdb.io/ | Incident analysis format |

---

*This reference is a living document. Add resources as you discover them.*

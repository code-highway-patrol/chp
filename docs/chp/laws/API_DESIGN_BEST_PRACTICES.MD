---
name: api-design-best-practices
created: 2026-04-25T00:00:00Z
category: API Design
severity: warn
enabled: True
references:
  - https://cloud.google.com/apis/design
  - https://github.com/microsoft/api-guidelines
  - https://martinfowler.com/articles/richardsonMaturityModel.html
  - https://graphql.org/learn/thinking-in-graphs/
  - https://www.apollographql.com/docs/apollo-server/schema/schema/
---

# Law: api-design-best-practices

**Severity:** warn  
**Created:** 2026-04-25T00:00:00Z  
**Category:** API Design

## Purpose

Enforces REST/GraphQL API design best practices based on industry standards.

## Reference Materials

### Primary Sources

1. **Google API Design Guide**  
   https://cloud.google.com/apis/design  
   The industry standard for REST API design. Covers resource naming, standard methods, custom methods, and error handling. Used by Google Cloud APIs and widely adopted.

2. **Microsoft REST API Guidelines**  
   https://github.com/microsoft/api-guidelines  
   Comprehensive guidelines covering URL structure, HTTP methods, versioning, pagination, and $filter/$select/$expand query options.

3. **Martin Fowler - Richardson Maturity Model**  
   https://martinfowler.com/articles/richardsonMaturityModel.html  
   The definitive article on REST maturity levels (Level 0-3), explaining what makes an API truly RESTful.

4. **GraphQL - Thinking in Graphs**  
   https://graphql.org/learn/thinking-in-graphs/  
   Official GraphQL documentation on schema design principles and graph-based thinking.

5. **Apollo Server - Schema Design**  
   https://www.apollographql.com/docs/apollo-server/schema/schema/  
   Production-ready patterns for GraphQL schema design, type naming, and resolver organization.

## Patterns Checked

### 1. REST Resource Naming
From [Google API Design Guide](https://cloud.google.com/apis/design):
> "Use plural nouns and concrete names. Methods should not be in the URL."

```http
# Bad: Verb-based, mixed case
GET /getUsers
GET /getUserData

# Good: Resource-based, plural
GET /users
GET /users/{id}
GET /users/{id}/orders
```

### 2. HTTP Methods Match Semantics
From [Google API Design Guide - Standard Methods](https://cloud.google.com/apis/design/standard_methods):
> "Use GET for retrieval, POST for creation, PUT for full update, PATCH for partial update, DELETE for removal."

```http
# Bad: POST for everything
POST /deleteUser
POST /getOrders

# Good: Proper method usage
DELETE /users/{id}
GET /users/{id}/orders
POST /users/{id}/orders
PUT /users/{id}
PATCH /users/{id}
```

### 3. Status Code Usage
From [Microsoft REST API Guidelines](https://github.com/microsoft/api-guidelines):

| Status | Use |
|--------|-----|
| 200 | GET success, PUT success |
| 201 | POST success (created) |
| 204 | DELETE success |
| 400 | Client error (bad request) |
| 401 | Authentication required |
| 403 | Permission denied |
| 404 | Resource not found |
| 409 | Conflict (business logic) |
| 422 | Validation failed |
| 500 | Server error |

### 4. Version in URL Path
From [Microsoft API Guidelines - Versioning](https://github.com/microsoft/api-guidelines/blob/master/Guidelines.md#versioning):
> "Version should be in the path: /api/v1/resource. Headers are not discoverable."

```http
# Good: Version in path
/api/v1/users
/api/v2/users

# Bad: Version in header only
/users  (with Accept-Version: v1)
```

### 5. Consistent Response Format
From [Google API Design - Standard Response](https://cloud.google.com/apis/design/standard_messages):

```json
// Success envelope
{
  "data": { ... },
  "meta": { "page": 1, "total": 100 }
}

// Error envelope
{
  "error": {
    "code": "INVALID_INPUT",
    "message": "Email is required",
    "field": "email"
  }
}
```

### 6. GraphQL Schema Patterns
From [Apollo Server Schema Design](https://www.apollographql.com/docs/apollo-server/schema/schema/):
> "Types are PascalCase. Fields are camelCase. Lists should be non-null with non-null items."

```graphql
# Good: Type naming
type User { ... }           # PascalCase
user(id: ID!): User         # camelCase field
users(page: Int): [User!]! # Non-null list, non-null items

# Bad
type user { ... }           # lowercase type
User(id: ID): User          # PascalCase field, nullable arg
users: [User]               # nullable list/items
```

### 7. No N+1 Query Risk
From [GraphQL Best Practices](https://graphql.org/learn/thinking-in-graphs/):
> "Resolvers should batch or use DataLoader pattern to avoid N+1 database queries."

### 8. Pagination Required
From [Google API Design - List Pagination](https://cloud.google.com/apis/design/design_patterns#list_pagination):
> "All list operations must support pagination."

```http
# Bad: No limit specified
GET /users

# Good: Pagination enforced
GET /users?page=1&per_page=100
GET /users?cursor=abc123&limit=100
```

## Remediation

Review API design against patterns above and refactor endpoints to match industry standards.

---

*Guidance synthesized from Google API Design Guide, Microsoft REST Guidelines, and GraphQL official docs.*

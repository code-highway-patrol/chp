---
name: database-schema-best-practices
created: 2026-04-25T00:00:00Z
category: Database Design
severity: warn
enabled: True
references:
  - https://wiki.postgresql.org/wiki/Don't_Do_This
  - https://www.oreilly.com/library/view/designing-data-intensive-applications/9781491903063/
  - https://martinfowler.com/articles/evodb.html
  - https://flywaydb.org/documentation/concepts/migrations.html
---

# Law: database-schema-best-practices

**Severity:** warn  
**Created:** 2026-04-25T00:00:00Z  
**Category:** Database Design

## Purpose

Enforces best practices for database schema design based on established patterns from industry resources.

## Reference Materials

### Primary Sources

1. **PostgreSQL Wiki - Don't Do This**  
   https://wiki.postgresql.org/wiki/Don't_Do_This  
   Community-curated list of PostgreSQL anti-patterns, including reserved keywords, bad data types, and design mistakes that cause performance or maintenance issues.

2. **PostgreSQL Documentation - DDL**  
   https://www.postgresql.org/docs/current/ddl-depend.html  
   Official docs on data definition, constraints, dependencies, and best practices for table design.

3. **Martin Kleppmann - Designing Data-Intensive Applications (O'Reilly)**  
   https://www.oreilly.com/library/view/designing-data-intensive-applications/9781491903063/  
   The definitive book on database design, covering relational vs. document models, normalization, indexing, and query languages. Chapter 2 on data models is essential reading.

4. **Martin Fowler - Evolutionary Database Design**  
   https://martinfowler.com/articles/evodb.html  
   Article on iterative schema changes, migration strategies, and maintaining database evolution alongside application code.

5. **Flyway - Database Migration Concepts**  
   https://flywaydb.org/documentation/concepts/migrations.html  
   Industry-standard approach to version-controlled database migrations.

## Patterns Checked

### 1. No Reserved Keywords as Identifiers
From [PostgreSQL Wiki - Don't Do This](https://wiki.postgresql.org/wiki/Don't_Do_This):
> "Using reserved words as table or column names causes issues with tools, queries, and portability."

```sql
-- Bad: "user", "order", "group" are reserved
CREATE TABLE user (...);  

-- Good: Use domain-specific names
CREATE TABLE app_user (...);
```

### 2. Foreign Key Constraints Required
From [Kleppmann - Designing Data-Intensive Applications](https://www.oreilly.com/library/view/designing-data-intensive-applications/9781491903063/), Chapter 2:
> "Foreign keys ensure referential integrity at the database level rather than relying on application code."

```sql
-- Bad: Implicit relationship
CREATE TABLE orders (
    customer_id INT  -- No FK constraint
);

-- Good: Explicit constraint
CREATE TABLE orders (
    customer_id INT REFERENCES customers(id) ON DELETE CASCADE
);
```

### 3. Index on Foreign Keys
From PostgreSQL Wiki:
> "Foreign key columns should almost always be indexed for JOIN performance."

```sql
-- Bad: No index on FK
CREATE TABLE order_items (
    order_id INT REFERENCES orders(id)  -- No index
);

-- Good: Index present
CREATE TABLE order_items (
    order_id INT REFERENCES orders(id)
);
CREATE INDEX idx_order_items_order_id ON order_items(order_id);
```

### 4. Timestamps Required
From [Fowler - Evolutionary Database Design](https://martinfowler.com/articles/evodb.html):
> "Audit columns (created_at, updated_at) are essential for debugging, compliance, and data recovery."

```sql
-- Good practice
CREATE TABLE products (
    id SERIAL PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
```

### 5. No Char(n) for Variable Length
From [PostgreSQL Wiki - Don't Do This](https://wiki.postgresql.org/wiki/Don't_Do_This):
> "char(n) pads with spaces. Use varchar(n) or text instead."

```sql
-- Bad: CHAR pads with spaces
CREATE TABLE users (name CHAR(100));

-- Good: VARCHAR for variable length
CREATE TABLE users (name VARCHAR(100));
```

### 6. No Nullable Boolean Columns
From PostgreSQL Wiki:
> "Three-state booleans (NULL/true/false) cause confusion. Define defaults or make non-nullable."

```sql
-- Bad: Three-state boolean
is_active BOOLEAN;  -- NULL, true, or false

-- Good: Default value
is_active BOOLEAN NOT NULL DEFAULT false;
```

## Remediation

When violations are detected:
1. Check schema against patterns above
2. Apply missing constraints/indexes
3. Re-run verification

---

*Guidance synthesized from PostgreSQL community resources and Kleppmann's "Designing Data-Intensive Applications"*

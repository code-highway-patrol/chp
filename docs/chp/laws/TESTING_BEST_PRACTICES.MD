---
name: testing-best-practices
created: 2026-04-25T00:00:00Z
category: Testing
severity: warn
enabled: True
references:
  - https://martinfowler.com/articles/practical-test-pyramid.html
  - https://testing.googleblog.com/2015/04/just-say-no-to-more-end-to-end-tests.html
  - https://kentcdodds.com/blog/write-tests
  - https://martinfowler.com/bliki/GivenWhenThen.html
---

# Law: testing-best-practices

**Severity:** warn  
**Created:** 2026-04-25T00:00:00Z  
**Category:** Testing

## Purpose

Enforces testing best practices based on the Test Pyramid and industry standards.

## Reference Materials

### Primary Sources

1. **Martin Fowler - Practical Test Pyramid**  
   https://martinfowler.com/articles/practical-test-pyramid.html  
   The definitive article on test pyramid structure: unit tests (many), integration tests (some), E2E tests (few).

2. **Google Testing Blog - Just Say No to More End-to-End Tests**  
   https://testing.googleblog.com/2015/04/just-say-no-to-more-end-to-end-tests.html  
   Google's experience: E2E tests are slow, flaky, and expensive. Prefer unit and integration tests.

3. **Kent C. Dodds - Testing Trophy**  
   https://kentcdodds.com/blog/write-tests  
   Static testing > Unit > Integration > E2E. Integration tests provide the best ROI.

4. **Kent Beck - Test Driven Development: By Example (Book)**  
   The foundational book on TDD methodology and test-first development.

5. **Martin Fowler - Given-When-Then**  
   https://martinfowler.com/bliki/GivenWhenThen.html  
   The BDD pattern for writing clear, behavior-focused test descriptions.

## Patterns Checked

### 1. Test File Co-location
From [Kent C. Dodds - Testing Trophy](https://kentcdodds.com/blog/write-tests):
> "Tests should be close to the code they test. Easier to find, easier to maintain."

```
# Bad: Separate test directory
src/
  users.ts
tests/
  users.test.ts  # Far from source

# Good: Co-located
src/
  users.ts
  users.test.ts  # Next to source
```

### 2. Test Naming Convention
From [Google Testing Blog](https://testing.googleblog.com/2015/04/just-say-no-to-more-end-to-end-tests.html):
> "Test names should describe behavior, not implementation."

```javascript
// Bad: Vague test names
it('works', () => {});
it('test1', () => {});

// Good: Descriptive
it('should return user by ID', () => {});
it('should throw 404 when user not found', () => {});
```

### 3. AAA Pattern (Arrange-Act-Assert)
From [Fowler - Test Pyramid](https://martinfowler.com/articles/practical-test-pyramid.html):
> "Structure tests with clear setup, action, and verification phases."

```javascript
test('calculates total price', () => {
  // Arrange
  const cart = new Cart();
  cart.add({ price: 10 });
  cart.add({ price: 20 });
  
  // Act
  const total = cart.getTotal();
  
  // Assert
  expect(total).toBe(30);
});
```

### 4. No Logic in Tests
From [Google Testing Best Practices](https://testing.googleblog.com/):
> "Tests should be linear. No conditionals, loops, or dynamic assertions."

```javascript
// Bad: Conditional logic
if (condition) {
  expect(result).toBe(expected);
}

// Good: Explicit assertions
expect(result1).toBe(expected1);
expect(result2).toBe(expected2);
```

### 5. One Concept Per Test
From [Fowler - Test Pyramid](https://martinfowler.com/articles/practical-test-pyramid.html):
> "Each test should verify one concept. Multiple assertions should test the same concept."

```javascript
// Bad: Multiple concepts
test('user service', () => {
  // tests create, update, delete, list all in one
});

// Good: Single concept per test
test('should create new user', () => {});
test('should update existing user', () => {});
test('should delete user by ID', () => {});
```

### 6. Test Coverage Minimums
From [Google Testing Blog](https://testing.googleblog.com/2015/04/just-say-no-to-more-end-to-end-tests.html):

| Type | Target | Enforcement |
|------|--------|-------------|
| Statements | 80% | warn |
| Branches | 70% | warn |
| Functions | 80% | warn |
| Lines | 80% | warn |

### 7. Mock External Dependencies
From [Kent C. Dodds - Testing Trophy](https://kentcdodds.com/blog/write-tests):
> "Unit tests should mock I/O. Integration tests verify real interactions."

```javascript
// Bad: Real API call
test('fetches users', async () => {
  const users = await fetchUsers(); // Hits real API
});

// Good: Mocked
test('fetches users', async () => {
  fetchMock.get('/api/users', mockUsers);
  const users = await fetchUsers();
  expect(users).toEqual(mockUsers);
});
```

### 8. No Random Data in Assertions
From [Google Testing Blog](https://testing.googleblog.com/):
> "Tests must be deterministic. Same input, same output, every time."

```javascript
// Bad: Non-deterministic
test('creates user', () => {
  const user = createUser();
  expect(user.id).toBeDefined(); // Random UUID
});

// Good: Deterministic assertions
test('creates user', () => {
  const user = createUser({ name: 'John' });
  expect(user.name).toBe('John');
  expect(user.id).toMatch(/^user_[a-z0-9]+$/);
});
```

### 9. Test Independence
From [Fowler - Test Pyramid](https://martinfowler.com/articles/practical-test-pyramid.html):
> "Tests must not depend on order or shared state. Each test creates its own data."

```javascript
// Bad: Shared state
let counter = 0;

test('increments', () => {
  counter++;
  expect(counter).toBe(1);
});

test('increments again', () => {
  counter++;
  expect(counter).toBe(1); // Fails if run alone!
});

// Good: Isolated
test('increments', () => {
  const counter = createCounter();
  counter.increment();
  expect(counter.value).toBe(1);
});
```

### 10. Test the Behavior, Not Implementation
From [Kent C. Dodds - Testing Trophy](https://kentcdodds.com/blog/write-tests):
> "Tests should not break when refactoring. Test outputs and side effects, not internal code."

```javascript
// Bad: Tests implementation details
test('uses correct regex', () => {
  expect(validator.pattern).toBe(/^[a-z]+$/);
});

// Good: Tests behavior
test('validates lowercase strings', () => {
  expect(validate('abc')).toBe(true);
  expect(validate('ABC')).toBe(false);
});
```

## Remediation

Tests are production code. Review against patterns above for maintainability and reliability.

---

*Guidance synthesized from Martin Fowler's Test Pyramid and Google testing practices.*

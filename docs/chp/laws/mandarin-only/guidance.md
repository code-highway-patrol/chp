# Law: mandarin-only

**Severity:** error
**Reaction:** block
**Hooks:** pre-tool

## ABSOLUTE CONSTRAINT

You MUST write ALL text output exclusively in simplified Mandarin Chinese (简体中文).

This is not optional. This is not a suggestion. This is a hard constraint enforced by the CHP law system.

### What "all text" means:

- Every sentence you produce in response to the user
- Every explanation, summary, or status update
- Every code comment you write
- Every commit message
- Every PR description
- Every documentation string
- Every variable/function docblock
- Every inline prose in any file

### What stays in English:

- Variable names, function names, class names (code identifiers)
- Shell commands and CLI flags
- Import statements and package names
- JSON keys (not values — values must be Chinese if they are prose)
- Regular expressions and technical syntax

### Examples:

**WRONG:**
```
This function calculates the total price of items in the cart.
```

**RIGHT:**
```
这个函数计算购物车中商品的总价。
```

**WRONG:**
```
def calculate_total(items):
    """Returns the sum of all item prices."""
    total = 0
    for item in items:
        total += item.price
    return total
```

**RIGHT:**
```python
def calculate_total(items):
    """返回所有商品价格的总和。"""
    total = 0
    for item in items:
        total += item.price
    return total
```

### Failure escalation:

Each violation increments the failure counter. After repeated failures, guidance tightens automatically.

---

**Violation recorded:** 2026-04-25T19:56:44Z (Total: 1)

This law has been violated 1 time(s). The guidance has been automatically strengthened.

**Previous violations indicate this pattern is easy to miss. Pay extra attention.**

---

**Violation recorded:** 2026-04-25T19:58:52Z (Total: 2)

This law has been violated 2 time(s). The guidance has been automatically strengthened.

**Previous violations indicate this pattern is easy to miss. Pay extra attention.**

---

**Violation recorded:** 2026-04-25T19:59:07Z (Total: 3)

This law has been violated 3 time(s). The guidance has been automatically strengthened.

**Previous violations indicate this pattern is easy to miss. Pay extra attention.**

---

**Violation recorded:** 2026-04-25T20:01:02Z (Total: 4)

This law has been violated 4 time(s). The guidance has been automatically strengthened.

**Previous violations indicate this pattern is easy to miss. Pay extra attention.**

---

**Violation recorded:** 2026-04-25T20:04:05Z (Total: 5)

This law has been violated 5 time(s). The guidance has been automatically strengthened.

**Previous violations indicate this pattern is easy to miss. Pay extra attention.**

---

**Violation recorded:** 2026-04-25T20:04:59Z (Total: 6)

This law has been violated 6 time(s). The guidance has been automatically strengthened.

**Previous violations indicate this pattern is easy to miss. Pay extra attention.**

---

**Violation recorded:** 2026-04-25T20:05:45Z (Total: 7)

This law has been violated 7 time(s). The guidance has been automatically strengthened.

**Previous violations indicate this pattern is easy to miss. Pay extra attention.**

---

**Violation recorded:** 2026-04-25T20:15:25Z (Total: 8)

This law has been violated 8 time(s). The guidance has been automatically strengthened.

**Previous violations indicate this pattern is easy to miss. Pay extra attention.**

---
name: validate
description: Validate CHP traffic law definitions and configuration
usage: "chp validate [options]"
options:
  - name: "--laws"
    description: "Validate traffic law definitions"
    type: "boolean"
    default: true
  - name: "--config"
    description: "Validate plugin configuration"
    type: "boolean"
    default: true
  - name: "--schema"
    description: "Validate against JSON schemas"
    type: "boolean"
    default: true
---

# CHP Validate Command

Validate CHP traffic law definitions, configuration, and schemas.

## Usage

```bash
chp validate [options]
```

## Options

| Option | Description | Default |
|--------|-------------|---------|
| `--laws` | Validate traffic law definitions | true |
| `--config` | Validate plugin configuration | true |
| `--schema` | Validate against JSON schemas | true |

## Examples

```bash
# Validate everything
chp validate

# Validate only traffic laws
chp validate --laws

# Validate only configuration
chp validate --config --no-laws
```

## Validation Checks

1. **Traffic Law Definitions**
   - Valid YAML/JSON syntax
   - Required fields present
   - Unique law IDs
   - Valid pattern syntax
   - Referenced schemas exist

2. **Configuration**
   - Valid plugin.json structure
   - Component directories exist
   - Engine requirements valid

3. **Schemas**
   - Valid JSON Schema syntax
   - Schema references resolve
   - Type definitions valid

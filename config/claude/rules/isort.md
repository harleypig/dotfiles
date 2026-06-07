---
paths:
  - "**/*.py"
  - "**/*.pyi"
---

# isort Rules

**Version:** v1.0.0

## Flags

```bash
isort <file>             # fix in place (default)
isort --check <file>     # check only, non-zero exit on changes
isort --diff <file>      # show diff without writing
```

## Configuration

isort settings live in `pyproject.toml` under `[tool.isort]`. When paired
with black, use the black-compatible profile:

```toml
[tool.isort]
profile = "black"
line_length = 88
```

For yapf-using repos, set `profile = "google"` or tune `line_length` to
match yapf's `column_limit`.

## Ordering with the Formatter

- **black:** isort first, then black. black normalizes whatever isort
  produces.
- **yapf:** isort first, then yapf. Same reason.

Never run the formatter before isort — the import block will be
re-ordered after formatting and create churn.

## Agent Behavior

- After creating or modifying any Python file matched by the paths above:
  1. Run `isort <file>` to sort imports.
  2. Run the repo's formatter (`black` or `yapf`).
  3. Run `flake8 <file>`.
- **Prefer pre-commit** when the repo has it (see `pre-commit.md`):
  `pre-commit run --files <file>` to check, and `pre-commit run --config
  .pre-commit-config-fix.yaml --files <file>` to fix. Fall back to the direct
  invocation above only when pre-commit isn't configured or doesn't cover the
  file.

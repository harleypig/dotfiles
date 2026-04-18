---
paths:
  - "**/*.py"
  - "**/*.pyi"
---

# Python Style

- Format with `black`.
- Sort imports with `isort` (run before `black` so black normalizes the
  result).
- Lint with `flake8`.
- Add type hints to all new public functions and methods; check with `mypy`.

## Agent Behavior

- After creating or modifying any Python file matched by the paths above:
  1. Run `isort <file>` to sort imports.
  2. Run `black <file>` to format.
  3. Run `flake8 <file>` and fix all reported issues.
  4. Run `mypy <file>` and fix type errors.
- In pre-commit context: `.pre-commit-config.yaml` checks only;
  `.pre-commit-config-fix.yaml` applies fixes.

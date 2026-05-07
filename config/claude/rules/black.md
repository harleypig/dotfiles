---
paths:
  - "**/*.py"
  - "**/*.pyi"
---

# black Rules

**Version:** v1.0.0

## Flags

```bash
black <file>            # fix in place (default)
black --check <file>    # check only, non-zero exit on changes
black --diff <file>     # show diff without writing
```

## Configuration

black is intentionally near-zero-config. Settings live in `pyproject.toml`
under `[tool.black]`:

```toml
[tool.black]
line-length = 88        # black default; override per repo if needed
target-version = ["py311"]
```

Repos that pin a different line length should declare it in
`.claude/CONVENTIONS.md` and `pyproject.toml`.

## Conflict with yapf

black and yapf are mutually exclusive — never wire both into the same
repo's pre-commit. A repo picks one in `.claude/CONVENTIONS.md`; the
other is unused for that repo.

## Agent Behavior

- After creating or modifying any Python file matched by the paths above
  in a black-using repo:
  1. Run `isort <file>` first (see `isort.md`).
  2. Run `black <file>` to format. black must run *after* isort so it
     normalizes the result.
  3. Run `flake8 <file>` to catch any remaining issues.
- In pre-commit context: `.pre-commit-config.yaml` uses `--check`;
  `.pre-commit-config-fix.yaml` runs black without flags (fix in place).

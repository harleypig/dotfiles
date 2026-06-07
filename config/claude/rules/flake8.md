---
paths:
  - "**/*.py"
  - "**/*.pyi"
---

# flake8 Rules

**Version:** v1.0.0

Linter for Python. Pairs with `yapf` (format) and `isort` (imports); see
`python.md` for the toolchain and `yapf.md` / `isort.md` for the formatters.
flake8 is the linter half of this repo's `yapf + isort + flake8` choice — do
**not** also wire `ruff` (they are mutually exclusive, see `python.md`).

## Configuration File

flake8 config lives at `config/flake8` in this repo, which resolves to
`$XDG_CONFIG_HOME/flake8` (flake8's XDG user-config path) — the same pattern
as `config/yapf/style` and `config/yamllint/config`. flake8's *project*
discovery (`setup.cfg` / `tox.ini` / `.flake8`) does **not** look at the XDG
path, so the pre-commit hook points at it explicitly: `--config config/flake8`.

### Reconciled with yapf

The repo's yapf style (`config/yapf/style`) is **2-space** indent with
`column_limit = 79`. flake8's defaults assume 4-space, so `config/flake8` must
ignore the indent and the continuation/line-break checks yapf owns, and match
the line length:

```ini
[flake8]
max-line-length = 79
extend-ignore = E111,E114,E121,E123,E126,E133,E226,E24,E704,W503,W504
```

Run the tools formatters-first: `isort` → `yapf` → `flake8` (see `isort.md`).

### Separator comments

`code-style.md`'s `#####` / `#----` section and function separators trip
flake8's E265/E266. A Python file that uses them needs `E265,E266` added to
the ignore list (or must use plain comments — `#` followed by a space). The
currently-gated Python
(`config/claude/hooks/rule-coverage.py`) uses plain comments, so E265/E266 are
**not** ignored yet — revisit when the legacy bin/ Python scripts (which do use
the separators) are cleaned and brought under the gate (see `TODO.md`).

## Invocation

```bash
flake8 --config config/flake8 <file>
```

No errors permitted; fix all findings before committing.

## Agent Behavior

- After creating or modifying any Python file matched by the paths above: run
  `isort`, then `yapf`, then `flake8 --config config/flake8 <file>`, and fix
  all reported issues.
- In pre-commit context: the check config runs flake8 (lint-only — there is no
  fix variant); fixes come from `isort` / `yapf` in the fix config.

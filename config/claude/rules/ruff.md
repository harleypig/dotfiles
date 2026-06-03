---
paths:
  - "**/*.py"
---

# ruff Rules

**Version:** v1.0.0

Ruff is a single fast (Rust) tool that **consolidates** the Python
formatter + import-sorter + linter: `ruff format` replaces black, and
`ruff check` replaces isort (`I`) and flake8 (`E`/`F`) plus many code-smell
rule sets. It does **not** type-check — `pyright`/`mypy` still own that
(`python.md`). It is the JS/TS world's Biome for Python.

A repo picks **one** of {ruff} or {black + isort + flake8} — they are
mutually exclusive; never wire both into the same repo's pre-commit. The
repo declares its choice in `.claude/CONVENTIONS.md`.

## Flags

```bash
ruff format <path>            # format in place (black-compatible)
ruff format --check <path>    # check only, non-zero on changes
ruff check <path>             # lint
ruff check --fix <path>       # lint + apply safe fixes
```

## Ordering

Lint-fix **then** format: `ruff check --fix` may rewrite code (e.g. a
pyupgrade), which `ruff format` then normalizes. In pre-commit's fix config
run `ruff check --fix` before `ruff format`; the check config runs
`ruff check` + `ruff format --check`.

## Configuration

All config lives in `pyproject.toml` under `[tool.ruff]`:

- `line-length` and `target-version` on `[tool.ruff]`.
- `[tool.ruff.lint] select = [...]` — a sensible consolidated set is
  `E, F, I` (flake8 + isort) plus code-smell sets `B` (bugbear), `C4`
  (comprehensions), `SIM` (simplify), `UP` (pyupgrade), `RUF`. Add `ignore`
  for rules that conflict with the project's deliberate choices.
- **FastAPI:** `Depends`/`Query`/`Path`/etc. are *meant* to be called in
  argument defaults, so add them to
  `[tool.ruff.lint.flake8-bugbear] extend-immutable-calls` rather than
  fighting `B008`.
- Ruff is black-compatible, so the old `E203` / `W503` flake8 ignores are
  unnecessary.

## Suppression

A genuine false positive gets an inline `# noqa: <CODE>` with a brief reason
(a preceding comment), never a bare `# noqa` (which suppresses everything).
Project-wide exceptions belong in `ignore` / per-file ignores in the config.

## Agent Behavior

- After creating or modifying any `*.py` in a ruff-using repo:
  1. `ruff format <path>`.
  2. `ruff check <path>` (or `--fix`) and resolve findings.
  3. `pyright`/`mypy` for types (ruff does not type-check).
- In pre-commit context: `.pre-commit-config.yaml` runs `ruff check` +
  `ruff format --check`; `.pre-commit-config-fix.yaml` runs
  `ruff check --fix` + `ruff format`.
- Do not run black/isort/flake8 alongside ruff in the same repo.

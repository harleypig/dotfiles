---
paths:
  - "**/*.py"
  - "**/*.pyi"
---

# Python Rules

**Version:** v2.4.0

For concrete depth beyond these conventions — pytest technique (fixtures,
mocking discipline, async, flakiness) and typing technique (TypedDict,
Protocol, generics, narrowing, avoiding `# type: ignore`) — invoke the
**pytest-patterns** and **typing-patterns** skills.

## Detection

Active when the repository contains a `pyproject.toml` at root, or any
`*.py` file is being created or modified.

## Toolchain

| Concern             | Tool                                          |
|---------------------|-----------------------------------------------|
| Packaging / deps    | Poetry (`pyproject.toml`) — see `poetry.md`   |
| Linter              | flake8, or `ruff check` (see *Lint/format*)   |
| Type checker (dev)  | pyright                                       |
| Type checker (CI)   | mypy                                          |
| Runtime validation  | pydantic                                      |
| Test runner         | pytest                                        |
| Mocking             | pytest-mock                                   |
| Coverage            | pytest-cov                                    |
| Multi-version test  | tox — see `tox.md`                            |

**Lint/format is repo-specific.** Each repo declares its choice in its
`.claude/CONVENTIONS.md`, picking **one** of:

- **`ruff`** — one tool consolidating formatter + import-sort + linter
  (replaces black/isort/flake8) plus code-smell rule sets. Preferred for new
  repos. See `ruff.md`.
- **`black` + `isort` + `flake8`** (or `yapf` + `isort`) — the classic split.
  See `black.md`, `yapf.md`, `isort.md`.

These are mutually exclusive within a single repo — never wire both ruff and
black/isort/flake8 into the same pre-commit. Type-checking stays separate
(`pyright`/`mypy`) under either choice.

## Environments

Development MUST happen inside a virtual environment, never against
the system Python. Defaults:

- **Poetry-managed repos** (`[tool.poetry]` in `pyproject.toml`): use
  Poetry. See `poetry.md`.
- **Other repos:** use `python -m venv .venv` and activate before
  installing.

A repo opts out only by stating so explicitly in its
`.claude/CONVENTIONS.md` with a reason.

## Dependency Groups

Separate user-facing dependencies from development tooling. Optional
docs and CI dependencies go in their own groups.

### Canonical mapping

| Concern                                  | Poetry group                 | Non-Poetry equivalent     |
|------------------------------------------|------------------------------|---------------------------|
| Runtime / user-facing                    | (main)                       | `requirements.txt`        |
| Development tools (lint, format, types)  | `dev`                        | `requirements-dev.txt`    |
| Test runner and test helpers             | `test` (or fold into `dev`)  | `requirements-test.txt`   |
| Documentation builders                   | `docs` (optional)            | `requirements-docs.txt`   |

### Optional further splits

Add only when there's a concrete reason; do not pre-split.

| Concern                                  | Poetry group                 | Non-Poetry equivalent     |
|------------------------------------------|------------------------------|---------------------------|
| CI-only tooling (uploaders, gh-actions integrations) | `ci`             | `requirements-ci.txt`     |
| Release / build tooling (version bump, scm, codegen) | `release` / `build` | `requirements-release.txt` |

A package consumer MUST be able to install runtime deps alone, without
pulling in lint/test/docs tooling. For when to split vs fold see
`poetry.md` *Dependency Groups*; for tox env wiring see `tox.md`.

## Type Checking Strategy

Two type checkers are supported, each in its preferred role:

- **pyright** — primary checker for local development. Faster, stricter
  by default, native to Pylance / VS Code. Run during edit cycles and
  before commit.
- **mypy** — runs in CI (GitHub Actions) as a second pass. Catches issues
  pyright may miss and integrates with framework plugins (Django,
  SQLAlchemy, attrs) when needed.

Either may be run locally on demand: `pyright <file>` or `mypy <file>`.
A repo MAY add a tox env or Makefile target for the CI checker so it can
be reproduced locally.

## Naming

- **Modules / files:** lowercase with underscores (`vault_client.py`).
- **Classes:** PascalCase (`VaultClient`).
- **Functions / methods:** snake_case (`get_vault_item`).
- **Constants:** UPPER_SNAKE_CASE (`DEFAULT_TIMEOUT`).
- **Private members:** leading underscore (`_validate_token`).

## Type Hints and Validation

- All public functions and methods MUST have complete type annotations
  (parameters and return type).
- Use `pydantic` for any data crossing an external boundary (HTTP
  request/response, config files, CLI args).
- Trust pydantic-validated values internally; do not re-validate.
- Do not add `# type: ignore` without a comment explaining why.
- Do not introduce new untyped public APIs.

## Project Structure

- One package per repo, named to match the distribution name.
- `tests/` at repo root, mirroring the package layout.
- `examples/` at repo root for usage demonstrations of public APIs.
- `__init__.py` defines the public surface; keep internals unexported.

## Library vs Executable

See `code-style.md` *Error Handling Posture*. Libraries raise; CLIs may
exit non-zero. Never call `sys.exit` from library code.

## Pre-commit

Wire the repo's chosen formatter, `flake8`, and `pyright` into pre-commit
(see `pre-commit.md`). `mypy` typically runs in CI only, but a repo MAY
include it locally if its plugin ecosystem is in use.

## Agent Behavior

- After creating or modifying any Python file matched by the paths above:
  1. Run `isort <file>`.
  2. Run the repo's formatter (`black` or `yapf` per the repo's
     `.claude/CONVENTIONS.md`).
  3. Run `flake8 <file>` and fix all reported issues.
  4. Run `pyright <file>` and resolve type errors.
- Run `mypy <file>` on demand or rely on CI for the mypy pass.

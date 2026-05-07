---
paths:
  - "pyproject.toml"
---

# Poetry Rules

**Version:** v1.1.0

## Detection

Active when `pyproject.toml` contains a `[tool.poetry]` table.

## Project Layout

- `pyproject.toml` is the source of truth: package metadata,
  dependencies, and tool config.
- `poetry.lock` MUST be committed. It pins the exact resolved versions
  and is the contract for reproducible installs.
- One package per repo, declared via `[tool.poetry] packages = [...]`.

## Dependency Groups

Poetry 1.2+ supports named groups under
`[tool.poetry.group.<name>.dependencies]`. Use them to separate
concerns.

### Canonical groups

| Group              | Purpose                                          |
|--------------------|--------------------------------------------------|
| (main, no group)   | Runtime dependencies — what users install.       |
| `dev`              | Local dev ergonomics: formatters, linters, type checkers, pre-commit, scaffolding. |
| `test`             | Pytest and test-only helpers — needed by anyone running tests, locally or in CI. May fold into `dev` for small repos. |
| `docs`             | Sphinx, mkdocs, doc plugins. Optional.           |

### Optional further splits

Add only when there's a concrete need; do not pre-split prophylactically.

| Group              | Add when                                         |
|--------------------|--------------------------------------------------|
| `ci`               | CI uses tooling local devs do not run — coverage uploaders (`codecov-cli`), `tox-gh-actions`, etc. |
| `release` (or `build`) | Release/build pipelines need version bumpers, code generators, or `setuptools-scm` and you want release jobs to install a lighter set than `dev`. |

### When to split vs fold

The `dev`/`test` split pays off when:

- CI test jobs want `poetry install --only main,test` to skip a large
  linter/formatter set.
- Contributors who only run tests (not lint) want a lighter install.
- The `dev` group has grown large (many flake8 plugins, multiple
  formatters) and pulling them all in just to run pytest is wasteful.

Fold `test` into `dev` when the dev group is small or the same people
install everything anyway — the split is overhead with no payoff.

The same logic applies to `ci` and `release`: split out only when CI
or release pipelines genuinely need a different (smaller) install than
local dev.

Add deps with `poetry add --group <name> <pkg>`. Avoid hand-editing
`pyproject.toml` for deps; let Poetry resolve and update `poetry.lock`.

## Common Commands

```bash
poetry install                # main + default groups
poetry install --without docs # skip the docs group
poetry install --only main    # runtime only (CI / production)
poetry add <pkg>              # add to main
poetry add --group dev <pkg>  # add to a group
poetry update                 # bump within constraints
poetry lock --no-update       # rewrite lockfile without bumping
poetry run <cmd>              # run inside the venv
poetry shell                  # subshell in the venv
```

## Environments

Poetry creates and manages a venv automatically. Do not mix system-level
`pip install` with a Poetry-managed project — it bypasses the lockfile.

- `poetry config virtualenvs.in-project true` keeps the venv at `.venv/`
  inside the repo (recommended for IDE integration).

## CI

CI MUST install with `poetry install --only <groups>` matching what the
job needs, and use `poetry run` to invoke tools. Never reinstall deps
with pip in a Poetry-based job.

## Agent Behavior

- After modifying `pyproject.toml` dependency tables: run
  `poetry lock --no-update` and commit both files.
- When asked to add a tool, prefer `poetry add --group <name>` over
  hand-editing `pyproject.toml`.
- Never delete `poetry.lock` unilaterally.

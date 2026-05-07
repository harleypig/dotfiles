---
paths:
  - "tox.ini"
  - "pyproject.toml"
---

# tox Rules

**Version:** v1.0.0

## Detection

Active when the repo contains `tox.ini` at root, or `pyproject.toml`
contains a `[tool.tox]` table.

## Purpose

tox runs the test suite (and any other tox-managed env) against
multiple Python versions in clean isolated venvs. Use it for:

- Multi-version CI (Python 3.10, 3.11, 3.12, …).
- Reproducing CI failures locally.
- Running orthogonal toolchains (lint env, type-check env, docs env).

## Layout

Two equivalent locations for config — pick one:

- `tox.ini` (classic, standalone).
- `[tool.tox]` in `pyproject.toml` (modern; tox 4+).

Conventions:

- Default `envlist` covers each supported Python version.
- A `lint` env runs flake8 + pyright.
- A `docs` env builds Sphinx / mkdocs.
- Each env declares its own deps, or pulls from a Poetry group via
  `tox-poetry-installer`.

## Common Commands

```bash
tox                # run default envlist
tox -e py311       # one specific env
tox -e lint        # named env
tox -p auto        # parallel
tox -r             # rebuild envs
```

## Integration with Poetry

For Poetry-managed projects, install `tox-poetry-installer` so each tox
env reads dependency groups from `pyproject.toml` instead of
duplicating them. Otherwise envs drift from the lockfile.

## Agent Behavior

- After adding a new supported Python version: update `envlist`.
- After moving deps between Poetry groups: verify each tox env still
  pulls the right group (especially with `tox-poetry-installer`).

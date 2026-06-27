---
paths:
  - "**/*.py"
  - "**/*.pyi"
---

# pyright Rules

**Version:** v1.0.0

pyright is the type checker in `python.md`'s toolchain — primary for local
development and the gate that runs in pre-commit/CI here. This rule owns its
invocation and configuration; `python.md` owns the broader Python toolchain
and the pyright-vs-mypy role split (pyright = dev + CI, mypy = optional CI
second pass).

## Invocation

```bash
pyright <path>          # check a file or directory
pyright                 # check the project per pyrightconfig.json
pyright --outputjson    # machine-readable output (CI report tooling)
```

pyright exits non-zero when it reports errors, so it gates a CI step or a
pre-commit hook without extra flags.

## Configuration File

pyright reads, in order of preference, a `pyrightconfig.json` at the project
root, or a `[tool.pyright]` table in `pyproject.toml` — never both. Both
accept the same keys. The ones that matter most:

| Key | Purpose |
|-----|---------|
| `include` | Directories/files to analyze (relative to the config file). |
| `exclude` | Paths to skip (defaults already drop `node_modules`, `__pycache__`). |
| `ignore` | Paths whose diagnostics are suppressed but still parsed. |
| `typeCheckingMode` | `off` \| `basic` \| `standard` \| `strict` — the diagnostic rule set. Default is `standard`. |
| `pythonVersion` / `pythonPlatform` | Target version/platform assumed during analysis. |
| `venvPath` / `venv` | Locate a virtualenv so third-party imports resolve. |
| `executionEnvironments` | Per-subtree overrides (root, extraPaths, version). |

**Scope `include` deliberately.** Run from the project root, pyright analyzes
the whole tree — in a repo with vendored Python (toolchain installs, plugin
caches) that is thousands of spurious diagnostics. Point `include` at the
first-party source only.

**Pick the mode the code can actually hold.** `standard` is the right default;
`strict` additionally flags every `Unknown`/`Any` (e.g. anything derived from
`json.load`), which is noise for boundary code that legitimately handles
untyped data. Raise to `strict` only for a subtree that warrants it, via
`executionEnvironments` or the `strict` list — not repo-wide by reflex.

### This repo

`pyrightconfig.json` at the root scopes pyright to `config/claude/hooks`
(the first-party Python — the agent hooks) in `standard` mode, which is clean
with no suppressions. It is wired as a pre-commit hook
(`RobertCraigie/pyright-python`, `pass_filenames: false` so it uses the
project config) and therefore runs in the required `pre-commit` CI job —
mirroring how `flake8`/`isort`/`yapf` are wired. **mypy is deliberately not
used here**: the typed surface is small and fully pyright-clean, so a second
checker would add tooling and CI cost without catching anything (recorded in
`audit/decisions-log.md`). The `tests/python/` suite is out of scope — it
imports `pytest`, which would need installing for pyright to resolve.

## Sources

- pyright configuration — `pyrightconfig.json` / `[tool.pyright]` keys,
  `typeCheckingMode`, `include`/`exclude`/`ignore` (fetched 2026-06-27):
  <https://github.com/microsoft/pyright/blob/main/docs/configuration.md>
- pyright CI integration — CLI usage, `--outputjson`, gating (fetched
  2026-06-27):
  <https://github.com/microsoft/pyright/blob/main/docs/ci-integration.md>

## Agent Behavior

- After creating or modifying any Python file matched by the paths above,
  run `pyright <file>` and resolve type errors before committing (per
  `python.md`'s edit-cycle steps).
- Keep `include` scoped to first-party source; never let pyright recurse into
  vendored/toolchain Python.
- Use `standard` mode by default; reach for `strict` only on a subtree that
  earns it, not repo-wide.
- **Prefer pre-commit** when the repo has it (see `pre-commit.md`):
  `pre-commit run pyright --all-files` to check. Fall back to the direct
  invocation above only when pre-commit isn't configured or doesn't cover the
  file.

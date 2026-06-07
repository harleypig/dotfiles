---
paths:
  - "**/*.py"
  - "**/*.pyi"
---

# yapf Rules

**Version:** v1.0.0

## Flags

```bash
yapf --style="$XDG_CONFIG_HOME/yapf/style" -i <file>   # fix in place
yapf --style="$XDG_CONFIG_HOME/yapf/style" -d <file>   # diff (check only)
```

yapf's style lookup order: `--style` flag → `.style.yapf` in the directory
tree → `[yapf]` section in `setup.cfg` → `~/.config/yapf/style` (hardcoded,
not `$XDG_CONFIG_HOME`). Auto-discovery of the repo config only works when
`$XDG_CONFIG_HOME` is the default `~/.config`; otherwise pass `--style`
explicitly.

## Configuration File

Style config lives at `config/yapf/style` in this repo, which resolves to
`$XDG_CONFIG_HOME/yapf/style`. Key settings:

- `based_on_style = pep8`
- `indent_width = 2`
- `column_limit = 79`
- `dedent_closing_brackets = True`

## Agent Behavior

- After creating or modifying any Python file matched by the paths above:
  1. Run `yapf --style="$XDG_CONFIG_HOME/yapf/style" -i <file>` to format.
  2. Run `flake8 <file>` to catch any remaining issues.
- **Prefer pre-commit** when the repo has it (see `pre-commit.md`):
  `pre-commit run --files <file>` to check, and `pre-commit run --config
  .pre-commit-config-fix.yaml --files <file>` to fix. Fall back to the direct
  invocation above only when pre-commit isn't configured or doesn't cover the
  file.

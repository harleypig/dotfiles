---
paths:
  - "**/*.ps1"
  - "**/*.psm1"
  - "**/*.psd1"
  - "powershell/**"
---

# PowerShell Style

- Use approved verbs for function names (`Get-Verb` lists them).
- Add comment-based help to all functions.
- Lint with PSScriptAnalyzer (the standard PowerShell static analysis tool).

## Invocation

```powershell
Invoke-ScriptAnalyzer -Path <file>
```

No errors or warnings are permitted. Fix all reported issues.

**Note:** PSScriptAnalyzer runs under `pwsh` (PowerShell Core) on Linux.
Some rules that depend on Windows-only modules may not fire; results may
differ from a full Windows PowerShell 5.1 run. See the PowerShell Linux
Dev/Test research task in TODO.md.

## Agent Behavior

- After creating or modifying any PowerShell file matched by the paths above:
  1. Run `Invoke-ScriptAnalyzer -Path <file>` and fix all reported issues.
- **Prefer pre-commit** when the repo has it (see `pre-commit.md`):
  `pre-commit run --files <file>` to check, and `pre-commit run --config
  .pre-commit-config-fix.yaml --files <file>` to fix. Fall back to the direct
  invocation above only when pre-commit isn't configured or doesn't cover the
  file.

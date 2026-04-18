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
- In pre-commit context: `.pre-commit-config.yaml` checks only;
  `.pre-commit-config-fix.yaml` applies fixes.

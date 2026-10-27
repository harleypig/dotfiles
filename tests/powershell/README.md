# PowerShell tests

Pester tests for the repo's PowerShell side (e.g. `ps-startup.ps1`,
`powershell/`).

- Files: `*.Tests.ps1`
- Run: `pwsh -c 'Invoke-Pester tests/powershell'`

## On Linux

The suites run under Linux pwsh as well as on Windows. Commands that exist
only on Windows (the `py` launcher) are stubbed before they are mocked, so
the mocks bind. The `Install-Prereqs.Tests.ps1` tests whose fixtures or
expectations are Windows paths (`\` separators, drive letters, the
`;`-separated Machine and User `PATH`) are **skipped** off Windows, each with
that reason in the Pester output. Run on Windows for the full set.

See `.claude/TESTS.md` for this repo's test layout and the dotagents repo's
`rules/testing.md` for the multi-language test conventions.

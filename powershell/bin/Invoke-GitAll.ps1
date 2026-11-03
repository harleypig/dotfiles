#Requires -Version 7

<#
.SYNOPSIS
  Runs a git command in every repository under $env:REPOHOME.

.DESCRIPTION
  PowerShell port of bin/git-all. Finds every directory holding a `.git`
  directory under $env:REPOHOME (default: the home directory), runs
  `git <args>` in each, and prints a summary of the repositories that passed
  and failed. The exit code is 0 whether or not any repository failed, as in
  the bash original.

  Options come first and are matched exactly (case-sensitive), as bash's
  getopts does; everything from the first non-option word on goes to git
  untouched. There is no param block, so a git option such as `-s` is never
  mistaken for a parameter of this script.

    -S   List repositories with uncommitted changes to tracked files, and
         stop. All other options are ignored.
    -v   Print the output of failed repositories in the summary.
    -h   Show this help.

  Not ported: the ANSI colouring of the summary.

.EXAMPLE
  Invoke-GitAll fetch --all
  Fetches in every repository and summarises which failed.

.EXAMPLE
  Invoke-GitAll -v pull --ff-only
  Same, with the failed repositories' output shown.

.EXAMPLE
  Invoke-GitAll -S
  Lists the repositories with modified tracked files.
#>

$verbose = $false
$statusOnly = $false
$rest = @($args)

while ($rest.Count -gt 0 -and $rest[0] -is [string] -and $rest[0] -cmatch '^-[A-Za-z]$') {
  switch -CaseSensitive ($rest[0]) {
    '-S' { $statusOnly = $true }
    '-v' { $verbose = $true }
    '-h' { Get-Help -Name $PSCommandPath -Full; return }
    default {
      Write-Error "invalid option -- '$($rest[0])'"
      exit 1
    }
  }

  $rest = @($rest | Select-Object -Skip 1)
}

$repoHome = if ($env:REPOHOME) { $env:REPOHOME } else { $HOME }

if (-not (Test-Path -LiteralPath $repoHome -PathType Container)) {
  Write-Error "Invalid `$REPOHOME: $repoHome"
  exit 1
}

if (-not $statusOnly -and $rest.Count -eq 0) {
  Get-Help -Name $PSCommandPath -Full
  exit 1
}

# Walks without descending into .git or following symlinks, as find does.
function Find-Repository {
  param ([string]$Root)

  $pending = [Collections.Generic.Stack[string]]::new()
  $pending.Push($Root)

  while ($pending.Count -gt 0) {
    $dir = $pending.Pop()

    foreach ($child in Get-ChildItem -LiteralPath $dir -Directory -Force -ErrorAction SilentlyContinue) {
      if ($child.LinkType) {
        continue
      }

      if ($child.Name -eq '.git') {
        $dir
      } else {
        $pending.Push($child.FullName)
      }
    }
  }
}

$repos = @(Find-Repository -Root $repoHome | Sort-Object)

if ($statusOnly) {
  foreach ($repo in $repos) {
    Push-Location -LiteralPath $repo
    try {
      $changed = git status -s | Where-Object { $_ -notmatch '^\?\?' }
    } finally {
      Pop-Location
    }

    if ($changed) {
      Write-Output $repo
    }
  }

  return
}

$passed = [Collections.Generic.List[string]]::new()
$failed = [Collections.Generic.List[string]]::new()
$output = @{}

foreach ($repo in $repos) {
  Push-Location -LiteralPath $repo
  try {
    $output[$repo] = (git @rest 2>&1 | Out-String)
    $ok = $LASTEXITCODE -eq 0
  } finally {
    Pop-Location
  }

  if ($ok) { $passed.Add($repo) } else { $failed.Add($repo) }
}

Write-Host ''
Write-Host "==> Job Summary For $($repos.Count) Repos: git $($rest -join ' ')"

if ($failed.Count -eq 0) {
  Write-Host '  -> No errors were reported'
} else {
  foreach ($repo in $failed) {
    Write-Output "[FAIL] $repo"

    if ($verbose) {
      Write-Output (($output[$repo].TrimEnd() -split '\r?\n' | ForEach-Object { "   $_" }) -join "`n")
      Write-Output ''
    }
  }
}

Write-Output ''

foreach ($repo in $passed) {
  Write-Output "[PASS] $repo"
}

Write-Output ''

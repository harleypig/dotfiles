#Requires -Version 7

<#
.SYNOPSIS
  Deletes local branches whose remote branch is gone.

.DESCRIPTION
  PowerShell port of bin/git-branch-clean. Runs `git fetch --prune`, then
  lists (-DryRun) or deletes (-Force) each local branch whose upstream is
  gone. With -All, branches that were never pushed (no upstream at all) are
  included. The checked-out branch is never touched. Exactly one of -DryRun
  and -Force is required.

  Deliberate difference from the bash original: the checked-out branch is
  skipped up front, instead of failing inside `git branch -D`.

.PARAMETER DryRun
  Show what would be deleted. Alias: -n.

.PARAMETER Force
  Delete the branches (`git branch -D`). Alias: -f.

.PARAMETER All
  Include branches never pushed to a remote. Alias: -a.

.EXAMPLE
  Remove-StaleGitBranch -n
  Lists the local branches that would be deleted.

.EXAMPLE
  Remove-StaleGitBranch -f -a
  Deletes gone and never-pushed branches.
#>

[CmdletBinding()]
param (
  [Parameter(Mandatory, ParameterSetName = 'DryRun')]
  [Alias('n')]
  [switch]$DryRun,

  [Parameter(Mandatory, ParameterSetName = 'Force')]
  [Alias('f')]
  [switch]$Force,

  [Alias('a')]
  [switch]$All
)

git rev-parse --git-dir *> $null
if ($LASTEXITCODE -ne 0) {
  Write-Error 'Remove-StaleGitBranch: not a git repository'
  exit 1
}

git fetch --prune
if ($LASTEXITCODE -ne 0) {
  Write-Error 'Remove-StaleGitBranch: git fetch --prune failed'
  exit 1
}

$current = git branch --show-current

# `|` cannot occur in a ref name, so it is a safe field separator.
$refs = git for-each-ref --format '%(refname:short)|%(upstream)|%(upstream:track)' refs/heads

$stale = foreach ($ref in $refs) {
  $name, $upstream, $track = $ref -split '\|', 3

  if ($name -eq $current) {
    continue
  }

  if ($track -eq '[gone]') {
    [pscustomobject]@{ Name = $name; Reason = 'remote branch gone' }
  } elseif ($All -and -not $upstream) {
    [pscustomobject]@{ Name = $name; Reason = 'never pushed' }
  }
}

foreach ($branch in $stale) {
  if ($DryRun) {
    Write-Output "Would delete branch: $($branch.Name) ($($branch.Reason))"
  } else {
    Write-Output "Deleting branch: $($branch.Name)"
    git branch -D $branch.Name
  }
}

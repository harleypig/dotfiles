#Requires -Version 7

<#
.SYNOPSIS
  Runs gh under a per-scope GitHub credential.

.DESCRIPTION
  PowerShell port of bin/ghx. A single ambient token cannot reach every
  account we work in, so each scope keeps its own token in the private
  store and ghx loads the right one for the one invocation.

    ghx pr list            plain `gh pr list` (no token injected)
    ghx <scope> pr list    `gh pr list` under <scope>'s token

  The first argument that does not begin with '-' decides. If it is one of
  gh's own commands, or there is no such argument, every argument goes to gh
  untouched. Otherwise it is the scope name: it is removed from the argument
  list and gh runs with that scope's token in GH_TOKEN (GITHUB_TOKEN is
  cleared), both restored afterwards.

  Scopes live in <projects>/private_dotfiles/github/tokens, one file per
  scope holding only the token. The directory is the registry: a symlink is
  a short alias for another scope, and an empty file declares the scope but
  leaves gh on its own stored credential.

  ghx --list shows the scopes (never a token). ghx -h shows this help.

  Not ported from bin/ghx: --expiry, --rotate, --test, --refresh, and
  App-backed scopes (a file holding `app:<slug>`), which need the bash-only
  gh-app-token. An App-backed scope is refused, never run unauthenticated.

.EXAMPLE
  ghx harleypig pr list
  Runs `gh pr list` under the harleypig scope's token.
#>

# No param block: an advanced script would take -Verbose and the like for
# itself instead of passing them on to gh.

$projectsDir = $env:PROJECTS_DIR
if (-not $projectsDir) {
  $dotfiles = if ($env:DOTFILES) { $env:DOTFILES } else { Join-Path $HOME 'projects/dotfiles' }
  $projectsDir = Split-Path -Parent $dotfiles
}

$tokenDir = Join-Path $projectsDir 'private_dotfiles/github/tokens'

function Get-AppSlug {
  param ([string]$Path)

  $content = (Get-Content -LiteralPath $Path -Raw)
  if ($content -and $content.Trim() -like 'app:*') {
    return $content.Trim().Substring(4)
  }
}

# Test-Path reports a dangling symlink as present, so ask the link itself.
function Test-BrokenAlias {
  param ($Item)

  if (-not $Item.LinkType) { return $false }

  $target = $Item.ResolveLinkTarget($true)
  -not ($target -and $target.Exists)
}

function Show-Scope {
  if (-not (Test-Path -LiteralPath $tokenDir -PathType Container)) {
    "No scopes configured ($tokenDir does not exist)."
    return
  }

  $items = @(Get-ChildItem -LiteralPath $tokenDir -Force | Sort-Object Name)
  if ($items.Count -eq 0) {
    "No scopes configured ($tokenDir is empty)."
    return
  }

  "Scopes in ${tokenDir}:"

  foreach ($item in $items) {
    $name = $item.Name

    if (Test-BrokenAlias $item) {
      '  {0,-20} broken alias -> {1}' -f $name, ($item.Target -join ', ')
    } elseif ($item.LinkType) {
      '  {0,-20} alias -> {1}' -f $name, ($item.Target -join ', ')
    } elseif ($item.Length -eq 0) {
      '  {0,-20} declared; uses the stored credential' -f $name
    } elseif ($slug = Get-AppSlug $item.FullName) {
      '  {0,-20} App ({1})' -f $name, $slug
    } else {
      '  {0,-20} token' -f $name
    }
  }
}

# gh has no command that lists its commands, but it prints them when handed
# one it does not recognize, under either of two layouts depending on the gh
# version: `NAME COMMANDS` headings with `  cmd:  text` rows, or the legacy
# `Available commands:` list.
function Get-GhCommand {
  $out = & gh __ghx_probe_unknown_command__ 2>&1 | ForEach-Object { "$_" }
  $found = [Collections.Generic.List[string]]::new()
  $inBlock = $false

  foreach ($line in $out) {
    if ($line -cmatch '^[A-Z][A-Z ]*COMMANDS$') {
      $inBlock = $true
    } elseif ($line -cmatch '^[A-Z]') {
      $inBlock = $false
    } elseif ($inBlock -and $line -match '^  ([A-Za-z0-9_-]+):') {
      $found.Add($Matches[1])
    }
  }

  if ($found.Count -eq 0) {
    $legacy = $false
    foreach ($line in $out) {
      if ($line -eq 'Available commands:') {
        $legacy = $true
      } elseif ($legacy -and $line -match '^  ([A-Za-z0-9][A-Za-z0-9_-]*)\s*$') {
        $found.Add($Matches[1])
      }
    }
  }

  $found
}

function Invoke-Gh {
  param ([string[]]$GhArgs, [string]$Token)

  $savedGh = $env:GH_TOKEN
  $savedGithub = $env:GITHUB_TOKEN

  try {
    if ($PSBoundParameters.ContainsKey('Token')) {
      $env:GITHUB_TOKEN = $null
      if ($Token) { $env:GH_TOKEN = $Token }
    }

    & gh @GhArgs
    $script:ghCode = $LASTEXITCODE
  } finally {
    $env:GH_TOKEN = $savedGh
    $env:GITHUB_TOKEN = $savedGithub
  }
}


# Main

$ghArgs = [string[]]@($args)

switch ($(if ($ghArgs.Count) { $ghArgs[0] })) {
  { $_ -in '-h', '--help' } { Get-Help -Name $PSCommandPath -Full; exit 0 }
  '--list' { Show-Scope; exit 0 }
  { $_ -in '--expiry', '--rotate', '--test', '--refresh' } {
    Write-Error "ghx: $_ is not ported to PowerShell; use bin/ghx from bash."
    exit 2
  }
}

if (-not (Get-Command gh -ErrorAction SilentlyContinue)) {
  Write-Error 'ghx: gh is not installed or not on PATH'
  exit 1
}

$scopeIndex = -1
for ($i = 0; $i -lt $ghArgs.Count; $i++) {
  if (-not $ghArgs[$i].StartsWith('-')) { $scopeIndex = $i; break }
}

$script:ghCode = 0

if ($scopeIndex -lt 0) {
  Invoke-Gh -GhArgs $ghArgs
  exit $script:ghCode
}

$keywords = @(Get-GhCommand)
if ($keywords.Count -eq 0) {
  Write-Warning "ghx: could not read gh's command list; passing through"
  Invoke-Gh -GhArgs $ghArgs
  exit $script:ghCode
}

if ($ghArgs[$scopeIndex] -in $keywords) {
  Invoke-Gh -GhArgs $ghArgs
  exit $script:ghCode
}

$scope = $ghArgs[$scopeIndex]
$rest = [string[]]@(for ($i = 0; $i -lt $ghArgs.Count; $i++) { if ($i -ne $scopeIndex) { $ghArgs[$i] } })
$tokenFile = Join-Path $tokenDir $scope
$item = Get-Item -LiteralPath $tokenFile -Force -ErrorAction SilentlyContinue

if ($item -and (Test-BrokenAlias $item)) {
  Write-Error "ghx: alias '$scope' points at a missing scope: $($item.Target -join ', ')"
  exit 1
}

if (-not $item) {
  Write-Error ("ghx: no token defined for '$scope' (expected $tokenFile)`n" + ((Show-Scope) -join "`n"))
  exit 1
}

if (Get-AppSlug $tokenFile) {
  Write-Error "ghx: '$scope' is an App-backed scope, which the PowerShell port does not support."
  exit 1
}

$token = (Get-Content -LiteralPath $tokenFile -Raw)
$token = if ($token) { $token.Trim() } else { '' }

Invoke-Gh -GhArgs $rest -Token $token
exit $script:ghCode

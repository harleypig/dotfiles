#Requires -Version 7

<#
.SYNOPSIS
  Checks, and installs where needed, the Windows packages a repo or a host
  needs, as its win-*.json package lists declare them.

.DESCRIPTION
  The packages are not written here. They live in JSON files, validated
  against powershell/win-prereqs.schema.json before anything else runs:

    <repo>/win-prereqs.json        a repo's own Windows needs, standing
                                   alone, independent of any host.
    dotfiles/hosts/win-<host>.json { "repos": [...], "packages": [...] }:
                                   those repos' lists plus packages for
                                   that host only.

  How the name resolves:

    hosts/win-<name>.json exists              a host
    <projects>/<name>/win-prereqs.json exists a repo
    both                                      fails; pass -Host or -Repo
    neither                                   fails, listing the names
    no name                                   the repo the current
                                              directory is in

  <projects> is $env:PROJECTS_DIR, or, when that is unset, the parent of the
  dotfiles checkout this script is in (where ps-startup.ps1 would point
  PROJECTS_DIR). A repo named like this checkout ("dotfiles") is always this
  checkout, wherever PROJECTS_DIR points.

  Each package lists manager specs (choco, winget, npm, pip, uv tool,
  psgallery), tried in order until one works. Installed by any of them, or
  its command on PATH, counts as ok. Nothing is uninstalled, and nothing is
  upgraded unless a pinned version differs from the installed one. A package
  listed by several files is installed once; two entries with one name that
  differ in anything but why fail the run, naming both files. A checkOnly
  package is only looked for (git: upgrading it would collide with the Git
  Bash sessions in use).

  When dotfiles is part of the target, its built-in setup steps run too:
  the ~\.local\bin\python3.exe link and User PATH order, the MSYS symlink
  mode, removing repeated entries and those whose directory is missing from
  the User and the Machine PATH (the Machine one in the elevated pass), and
  the bin/s3cmd check. They are fixes, not packages.

  Each item reports ok, fixed, would fix, skipped, FAILED: <reason>, or
  PENDING: <action> for a step only the operator can take (a reboot).
  Everything that needs admin (Chocolatey's bootstrap, choco and winget,
  the Machine PATH) runs in one elevated copy of this script, behind one
  UAC prompt, and only when something needs it. The script exits 1 if any item failed or is
  pending.

.EXAMPLE
  install-prereqs sweetums -WhatIf
  Reports what the host sweetums, and its repos, would change.

.EXAMPLE
  install-prereqs dotagents
  Installs what the dotagents repo needs, on whatever machine this is.

.EXAMPLE
  install-prereqs
  Installs what the repo the current directory is in needs.
#>

[CmdletBinding(SupportsShouldProcess)]
param (
  # A host (dotfiles hosts/win-<name>.json) or a repo (a win-prereqs.json in
  # <projects>/<name>). Left off: the repo the current directory is in.
  [Parameter(Position = 0)]
  [string]$Name,

  # The name is a host, when it names both a host and a repo.
  [Alias('Host')]
  [switch]$AsHost,

  # The name is a repo, when it names both a host and a repo.
  [switch]$Repo,

  # For the elevated copy this script launches of itself.
  [Parameter(DontShow)]
  [string]$PlanPath,

  [Parameter(DontShow)]
  [string]$ResultPath,

  [Parameter(DontShow)]
  [string]$ExpectedSid
)

# The window title and the header come first, before any module load or slow
# work, so the window is never blank. Dot-sourcing (the tests) skips them.
if ($MyInvocation.InvocationName -ne '.') {
  $savedTitle = $Host.UI.RawUI.WindowTitle
  if ($PlanPath) {
    $Host.UI.RawUI.WindowTitle = 'install-prereqs (elevated)'
    $Host.UI.WriteLine('install-prereqs - elevated part')
    $Host.UI.WriteLine('Launched by install-prereqs to run the steps that need admin;')
    $Host.UI.WriteLine('that window waits for this one and reports the results.')
  } else {
    $Host.UI.RawUI.WindowTitle = 'install-prereqs'
    $targetText = if ($Name) { $Name } else { 'the repo the current directory is in' }
    $Host.UI.WriteLine("install-prereqs - the Windows packages $targetText needs")
  }
}

Set-StrictMode -Version Latest

#region Reporting

<#
.SYNOPSIS
  Prints one report line to the console (the information stream).
#>
function Write-Report {
  [CmdletBinding()]
  param (
    [AllowEmptyString()]
    [string]$Message = ''
  )

  Write-Information -MessageData $Message -InformationAction Continue
}

<#
.SYNOPSIS
  Builds one item's result.
#>
function New-StepResult {
  [Diagnostics.CodeAnalysis.SuppressMessageAttribute(
    'PSUseShouldProcessForStateChangingFunctions', '',
    Justification = 'Builds an in-memory object; changes no system state.')]
  [CmdletBinding()]
  [OutputType([pscustomobject])]
  param (
    [Parameter(Mandatory)]
    [ValidateSet('ok', 'fixed', 'would fix', 'skipped', 'needs admin', 'PENDING', 'FAILED')]
    [string]$Status,

    [string]$Detail = '',

    # Extra report lines, printed indented under the item's line.
    [string[]]$Line = @(),

    # For 'needs admin': what the elevated pass is to run.
    [hashtable]$Plan = $null
  )

  [pscustomobject]@{ Status = $Status; Detail = $Detail; Lines = @($Line); Plan = $Plan }
}

<#
.SYNOPSIS
  Runs one item, turning an exception into a failure.
#>
function Invoke-PrereqStep {
  [CmdletBinding()]
  [OutputType([pscustomobject])]
  param (
    [Parameter(Mandatory)]
    [scriptblock]$Step
  )

  try {
    $result = & $Step
  } catch {
    $result = New-StepResult -Status FAILED -Detail $_.Exception.Message
  }

  $result
}

<#
.SYNOPSIS
  Formats an item's result as its report lines.
#>
function Format-StepResult {
  [CmdletBinding()]
  [OutputType([string])]
  param (
    [Parameter(Mandatory)]
    [string]$Name,

    [Parameter(Mandatory)]
    [pscustomobject]$Result
  )

  if ($Result.Status -in 'FAILED', 'PENDING') {
    "${Name}: $($Result.Status): $($Result.Detail)"
  } elseif ($Result.Detail) {
    "${Name}: $($Result.Status) ($($Result.Detail))"
  } else {
    "${Name}: $($Result.Status)"
  }

  foreach ($extra in $Result.Lines) {
    "  $extra"
  }
}

<#
.SYNOPSIS
  Prints an item's result.
#>
function Write-StepResult {
  [CmdletBinding()]
  param (
    [Parameter(Mandatory)]
    [string]$Name,

    [Parameter(Mandatory)]
    [pscustomobject]$Result
  )

  foreach ($line in (Format-StepResult -Name $Name -Result $Result)) {
    Write-Report $line
  }
}

<#
.SYNOPSIS
  Prints the summary: each item's status, then the counts, or "nothing to
  change" when every item was already ok.
#>
function Write-Summary {
  [CmdletBinding()]
  param (
    [Parameter(Mandatory)]
    [System.Collections.IDictionary]$Results
  )

  Write-Report ''
  Write-Report 'Summary:'
  foreach ($n in $Results.Keys) {
    Write-Report "  ${n}: $($Results[$n].Status)"
  }

  $statuses = @($Results.Values | ForEach-Object { $_.Status })
  if (@($statuses | Where-Object { $_ -ne 'ok' }).Count -eq 0) {
    Write-Report 'nothing to change'
    return
  }

  # In the order the statuses first appear.
  $counts = [ordered]@{}
  foreach ($s in $statuses) { $counts[$s] = 1 + [int]$counts[$s] }
  Write-Report (($counts.Keys | ForEach-Object { "$_ $($counts[$_])" }) -join ', ')
}

#endregion

#region Elevation

<#
.SYNOPSIS
  Tests whether this process runs elevated.
#>
function Test-Elevated {
  [CmdletBinding()]
  [OutputType([bool])]
  param ()

  $principal = [Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()
  $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

<#
.SYNOPSIS
  Returns the SID of the account this process runs as.
#>
function Get-CurrentUserSid {
  [CmdletBinding()]
  [OutputType([string])]
  param ()

  [Security.Principal.WindowsIdentity]::GetCurrent().User.Value
}

<#
.SYNOPSIS
  Turns off console QuickEdit, so a stray click in this window cannot pause
  the script in Select mode.
#>
function Disable-QuickEdit {
  [CmdletBinding()]
  param ()

  if (-not ('Win32.ConsoleMode' -as [type])) {
    Add-Type -Namespace Win32 -Name ConsoleMode -MemberDefinition @'
[DllImport("kernel32.dll", SetLastError = true)]
public static extern IntPtr GetStdHandle(int nStdHandle);
[DllImport("kernel32.dll", SetLastError = true)]
public static extern bool GetConsoleMode(IntPtr hConsoleHandle, out uint lpMode);
[DllImport("kernel32.dll", SetLastError = true)]
public static extern bool SetConsoleMode(IntPtr hConsoleHandle, uint dwMode);
'@
  }

  # STD_INPUT_HANDLE; ENABLE_QUICK_EDIT_MODE off, ENABLE_EXTENDED_FLAGS on.
  $handle = [Win32.ConsoleMode]::GetStdHandle(-10)
  $mode = [uint32]0
  if ([Win32.ConsoleMode]::GetConsoleMode($handle, [ref]$mode)) {
    [Win32.ConsoleMode]::SetConsoleMode($handle, ($mode -band (-bnot [uint32]0x40)) -bor [uint32]0x80) | Out-Null
  }
}

<#
.SYNOPSIS
  Runs a plan in an elevated copy of this script and returns its results.

.DESCRIPTION
  Uses Start-Process -Verb RunAs to start this same pwsh, waits, and reads
  the results back from a temp JSON file. The plan goes over in another
  temp file, because an elevated process does not inherit this one's
  environment and so could not resolve the lists itself. The copy is passed
  this account's SID and refuses to change anything if UAC elevated it as
  someone else: the user-scope work after it assumes the same account.
#>
function Invoke-ElevatedRun {
  [CmdletBinding()]
  [OutputType([pscustomobject])]
  param (
    [Parameter(Mandatory)]
    [hashtable]$Plan
  )

  $names = @(Get-PlanItemName -Plan $Plan)
  $sid = Get-CurrentUserSid
  $temp = [IO.Path]::GetTempPath()
  $planFile = Join-Path -Path $temp -ChildPath "install-prereqs-$PID-plan.json"
  $resultFile = Join-Path -Path $temp -ChildPath "install-prereqs-$PID-results.json"
  $Plan | ConvertTo-Json -Depth 10 | Set-Content -LiteralPath $planFile -Encoding utf8 -WhatIf:$false

  $arguments = @(
    '-NoProfile', '-ExecutionPolicy', 'Bypass', '-File', "`"$PSCommandPath`"",
    '-PlanPath', "`"$planFile`"", '-ResultPath', "`"$resultFile`"", '-ExpectedSid', $sid
  )

  $failAll = {
    param($Reason)
    $results = @{}
    foreach ($n in $names) { $results[$n] = New-StepResult -Status FAILED -Detail $Reason }
    [pscustomobject]@{ Note = $Reason; Results = $results }
  }

  try {
    $process = Start-Process -FilePath (Get-Process -Id $PID).Path -Verb RunAs -Wait -PassThru -ArgumentList $arguments -ErrorAction Stop
  } catch {
    return & $failAll "elevation declined or failed: $($_.Exception.Message)"
  } finally {
    Remove-Item -LiteralPath $planFile -Force -ErrorAction SilentlyContinue -WhatIf:$false
  }

  if (-not (Test-Path -LiteralPath $resultFile)) {
    return & $failAll "the elevated run wrote no results (exit $($process.ExitCode))"
  }

  $data = Get-Content -LiteralPath $resultFile -Raw | ConvertFrom-Json -AsHashtable
  Remove-Item -LiteralPath $resultFile -Force -WhatIf:$false

  $results = @{}
  foreach ($n in $names) {
    $r = $data['Results'][$n]
    $results[$n] = if ($r) {
      New-StepResult -Status $r['Status'] -Detail $r['Detail'] -Line @($r['Lines'] | Where-Object { $_ })
    } else {
      New-StepResult -Status FAILED -Detail 'the elevated run reported nothing for this item'
    }
  }

  $note = if ($data['Sid'] -eq $sid) {
    "UAC accepted; ran $($names -join ', ') elevated as this same account (SID verified)"
  } else {
    "UAC elevated a different account ($($data['Sid'])); it changed nothing"
  }

  [pscustomobject]@{ Note = $note; Results = $results }
}

<#
.SYNOPSIS
  Returns the item names an elevation plan covers, in order.
#>
function Get-PlanItemName {
  [CmdletBinding()]
  [OutputType([string])]
  param (
    [Parameter(Mandatory)]
    [System.Collections.IDictionary]$Plan
  )

  if ($Plan['Chocolatey']) {
    'chocolatey'
  }

  foreach ($p in @($Plan['Packages'])) {
    if ($p) { $p['Name'] }
  }

  if ($Plan['MachinePath']) {
    'machine PATH'
  }
}

<#
.SYNOPSIS
  The elevated copy's run: says what it is doing at each step, runs the
  plan, and writes the results for the unelevated run.

.DESCRIPTION
  Its window is the only thing the operator sees while it works, so every
  step is announced before it starts, slow ones with a warning, the tools'
  own progress shows, and a summary closes it, followed by the
  window-close wait.
#>
function Invoke-ElevatedPlan {
  [CmdletBinding()]
  param (
    [Parameter(Mandatory)]
    [System.Collections.IDictionary]$Plan,

    [Parameter(Mandatory)]
    [string]$ExpectedSid,

    [Parameter(Mandatory)]
    [string]$ResultPath
  )

  $names = @(Get-PlanItemName -Plan $Plan)
  Write-Report "Admin steps: $($names -join ', ')"
  Write-Report ''

  $sid = Get-CurrentUserSid
  $guard = if ($sid -ne $ExpectedSid) {
    'elevated as a different account; nothing changed'
  } elseif (-not (Test-Elevated)) {
    'the elevated copy is not elevated'
  }

  $results = [ordered]@{}
  if ($Plan['Chocolatey']) {
    Write-Report '[chocolatey] installing Chocolatey from community.chocolatey.org...'
    $results['chocolatey'] = if ($guard) {
      New-StepResult -Status FAILED -Detail $guard
    } else {
      Invoke-PrereqStep -Step { Install-Chocolatey }
    }

    Write-StepResult -Name chocolatey -Result $results['chocolatey']
  }

  foreach ($p in @($Plan['Packages'] | Where-Object { $_ })) {
    $results[$p['Name']] = if ($guard) {
      Write-Report "[$($p['Name'])] skipped..."
      New-StepResult -Status FAILED -Detail $guard
    } else {
      Invoke-PrereqStep -Step { Install-PackageSpec -Package $p['Package'] -Spec @($p['Specs']) -Reinstall:$p['Reinstall'] }
    }

    Write-StepResult -Name $p['Name'] -Result $results[$p['Name']]
  }

  # Last, so a directory a package above just created is not dropped.
  if ($Plan['MachinePath']) {
    Write-Report '[machine PATH] removing repeated and missing entries...'
    $results['machine PATH'] = if ($guard) {
      New-StepResult -Status FAILED -Detail $guard
    } else {
      Invoke-PrereqStep -Step { Repair-PathValue -Scope Machine }
    }

    Write-StepResult -Name 'machine PATH' -Result $results['machine PATH']
  }

  [pscustomobject]@{ Sid = $sid; Results = $results } |
    ConvertTo-Json -Depth 6 | Set-Content -LiteralPath $ResultPath -Encoding utf8 -WhatIf:$false

  Write-Report ''
  Write-Report 'Summary:'
  foreach ($n in $results.Keys) {
    Write-Report "  ${n}: $($results[$n].Status)"
  }

  $failed = $null -ne ($results.Values | Where-Object { $_.Status -eq 'FAILED' } | Select-Object -First 1)
  Wait-ElevatedWindowClose -Failed:$failed
}

<#
.SYNOPSIS
  Closes the elevated window: after a short pause, or on Enter when a step
  failed, so the error can be read first.
#>
function Wait-ElevatedWindowClose {
  [CmdletBinding()]
  param (
    [switch]$Failed
  )

  if ($Failed) {
    Read-Host -Prompt 'done - a step FAILED; press Enter to close this window' | Out-Null
    return
  }

  $seconds = 10
  Write-Report "done - this window will close in $seconds seconds"
  Start-Sleep -Seconds $seconds
}

#endregion

#region Environment

<#
.SYNOPSIS
  Adds the Machine and User PATH entries this process lacks, so installs
  made since it started are found, keeping the session's own entries.
#>
function Sync-ProcessPath {
  [CmdletBinding()]
  param ()

  $have = [Collections.Generic.HashSet[string]]::new([StringComparer]::OrdinalIgnoreCase)
  $entries = [Collections.Generic.List[string]]::new()
  foreach ($e in @($env:Path -split ';' | Where-Object { $_ })) {
    if ($have.Add($e.TrimEnd('\'))) { $entries.Add($e) }
  }

  foreach ($scope in 'Machine', 'User') {
    $value = [Environment]::GetEnvironmentVariable('Path', $scope)
    foreach ($e in @($value -split ';' | Where-Object { $_ })) {
      if ($have.Add($e.TrimEnd('\'))) { $entries.Add($e) }
    }
  }

  $env:Path = $entries -join ';'
}

<#
.SYNOPSIS
  Returns the registry key that holds the User or the Machine environment.
#>
function Get-EnvironmentKeyPath {
  [CmdletBinding()]
  [OutputType([string])]
  param (
    [ValidateSet('User', 'Machine')]
    [string]$Scope = 'User'
  )

  if ($Scope -eq 'Machine') {
    'HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Environment'
  } else {
    'HKCU:\Environment'
  }
}

<#
.SYNOPSIS
  Returns a User (or, with -Scope Machine, a Machine) environment
  variable's raw value, %VARS% unexpanded, or $null when it is unset.
#>
function Get-UserEnvironmentValue {
  [CmdletBinding()]
  [OutputType([string])]
  param (
    [Parameter(Mandatory)]
    [string]$Name,

    [ValidateSet('User', 'Machine')]
    [string]$Scope = 'User'
  )

  (Get-Item -Path (Get-EnvironmentKeyPath -Scope $Scope)).GetValue($Name, $null, 'DoNotExpandEnvironmentNames')
}

<#
.SYNOPSIS
  Tells running programs the environment changed, so a shell started from
  Explorer afterwards sees the new User variables.
#>
function Send-EnvironmentChange {
  [CmdletBinding()]
  param ()

  if (-not ('Win32.EnvironmentBroadcast' -as [type])) {
    Add-Type -Namespace Win32 -Name EnvironmentBroadcast -MemberDefinition @'
[DllImport("user32.dll", SetLastError = true, CharSet = CharSet.Unicode)]
public static extern IntPtr SendMessageTimeout(IntPtr hWnd, uint Msg,
  UIntPtr wParam, string lParam, uint fuFlags, uint uTimeout,
  out UIntPtr lpdwResult);
'@
  }

  # HWND_BROADCAST, WM_SETTINGCHANGE, SMTO_ABORTIFHUNG.
  $unused = [UIntPtr]::Zero
  [Win32.EnvironmentBroadcast]::SendMessageTimeout(
    [IntPtr]0xffff, 0x1A, [UIntPtr]::Zero, 'Environment', 2, 5000, [ref]$unused
  ) | Out-Null
}

<#
.SYNOPSIS
  Writes a User (or, with -Scope Machine, a Machine) environment variable,
  keeping the registry value kind it already has (Path is usually
  REG_EXPAND_SZ, which [Environment]::SetEnvironmentVariable would flatten
  to REG_SZ).

.DESCRIPTION
  Callers gate this with ShouldProcess; it does not ask again. -Scope
  Machine needs admin.
#>
function Write-UserEnvironmentValue {
  [CmdletBinding()]
  param (
    [Parameter(Mandatory)]
    [string]$Name,

    [Parameter(Mandatory)]
    [string]$Value,

    [ValidateSet('User', 'Machine')]
    [string]$Scope = 'User'
  )

  $keyPath = Get-EnvironmentKeyPath -Scope $Scope
  $key = Get-Item -Path $keyPath
  $kind = 'String'
  if ($key.GetValueNames() -contains $Name) {
    $kind = $key.GetValueKind($Name).ToString()
  }

  New-ItemProperty -Path $keyPath -Name $Name -Value $Value -PropertyType $kind -Force | Out-Null
  Send-EnvironmentChange
}

#endregion

#region Resolving the target

<#
.SYNOPSIS
  Returns the projects directory repos are looked up in, and how it was
  chosen.
#>
function Get-ProjectsDir {
  [CmdletBinding()]
  [OutputType([pscustomobject])]
  param (
    [Parameter(Mandatory)]
    [string]$DotfilesRoot
  )

  if ($env:PROJECTS_DIR) {
    return [pscustomobject]@{ Path = $env:PROJECTS_DIR; How = 'from PROJECTS_DIR' }
  }

  [pscustomobject]@{
    Path = Split-Path -Parent $DotfilesRoot
    How  = 'PROJECTS_DIR is unset, so the parent of this dotfiles checkout'
  }
}

<#
.SYNOPSIS
  Returns the top of the git work tree a directory is in, or $null.
#>
function Get-RepoTopLevel {
  [CmdletBinding()]
  [OutputType([string])]
  param (
    [Parameter(Mandatory)]
    [string]$Path
  )

  $top = @(git -C $Path rev-parse --show-toplevel 2>$null) | Select-Object -First 1
  if ($LASTEXITCODE -ne 0 -or -not $top) {
    return $null
  }

  [IO.Path]::GetFullPath($top)
}

<#
.SYNOPSIS
  Returns the directory a repo name means: this dotfiles checkout for its
  own name, else <projects>/<name>.
#>
function Get-RepoRoot {
  [CmdletBinding()]
  [OutputType([string])]
  param (
    [Parameter(Mandatory)]
    [string]$Name,

    [Parameter(Mandatory)]
    [string]$DotfilesRoot,

    [Parameter(Mandatory)]
    [string]$ProjectsDir
  )

  if ($Name -eq (Split-Path -Leaf $DotfilesRoot)) {
    return $DotfilesRoot
  }

  Join-Path -Path $ProjectsDir -ChildPath $Name
}

<#
.SYNOPSIS
  Returns every name the script accepts: hosts, then repos.
#>
function Get-ValidName {
  [CmdletBinding()]
  [OutputType([string])]
  param (
    [Parameter(Mandatory)]
    [string]$DotfilesRoot,

    [Parameter(Mandatory)]
    [string]$ProjectsDir
  )

  $hostDir = Join-Path -Path $DotfilesRoot -ChildPath 'hosts'
  $hosts = @(Get-ChildItem -Path $hostDir -Filter 'win-*.json' -File -ErrorAction SilentlyContinue |
      ForEach-Object { $_.BaseName -replace '^win-', '' })

  $repoDirs = @(Get-ChildItem -LiteralPath $ProjectsDir -Directory -ErrorAction SilentlyContinue) +
  @(Get-Item -LiteralPath $DotfilesRoot)
  $repos = @($repoDirs |
      Where-Object { Test-Path -LiteralPath (Join-Path -Path $_.FullName -ChildPath 'win-prereqs.json') } |
      ForEach-Object { $_.Name } | Sort-Object -Unique)

  "hosts: $(if ($hosts) { ($hosts | Sort-Object) -join ', ' } else { '(none)' })"
  "repos: $(if ($repos) { $repos -join ', ' } else { '(none)' })"
}

<#
.SYNOPSIS
  Reads one package list, after validating it against the schema.
#>
function Read-PrereqFile {
  [CmdletBinding()]
  [OutputType([System.Collections.IDictionary])]
  param (
    [Parameter(Mandatory)]
    [string]$Path,

    [Parameter(Mandatory)]
    [string]$SchemaPath,

    [Parameter(Mandatory)]
    [ValidateSet('host', 'repo')]
    [string]$Kind
  )

  $raw = Get-Content -LiteralPath $Path -Raw -ErrorAction Stop
  $errors = $null
  $valid = Test-Json -Json $raw -SchemaFile $SchemaPath -ErrorAction SilentlyContinue -ErrorVariable errors
  if (-not $valid) {
    $why = @($errors | ForEach-Object { $_.Exception.Message } | Where-Object { $_ })
    $detail = if ($why) { $why -join '; ' } else { 'a package entry is not a valid install or checkOnly entry' }
    throw "$Path does not match $(Split-Path -Leaf $SchemaPath): $detail"
  }

  $data = $raw | ConvertFrom-Json -AsHashtable
  if ($Kind -eq 'repo' -and $data.Contains('repos')) {
    throw "$Path is a repo's list; repos belongs only in a hosts/win-<host>.json"
  }

  if ($Kind -eq 'host' -and -not $data.Contains('repos')) {
    throw "$Path is a host's list and has no repos"
  }

  $data
}

<#
.SYNOPSIS
  Works out which lists a name means and reads them, validating every one
  before anything else happens.

.DESCRIPTION
  Returns the target's label and kind, the repos it covers (name and root),
  and its documents in install order: each repo's list, then the host's own
  packages.
#>
function Resolve-PrereqTarget {
  [CmdletBinding()]
  [OutputType([pscustomobject])]
  param (
    [string]$Name,

    [switch]$AsHost,

    [switch]$Repo,

    [Parameter(Mandatory)]
    [string]$DotfilesRoot,

    [Parameter(Mandatory)]
    [string]$ProjectsDir,

    [Parameter(Mandatory)]
    [string]$CurrentDirectory,

    [Parameter(Mandatory)]
    [string]$SchemaPath
  )

  $valid = { (Get-ValidName -DotfilesRoot $DotfilesRoot -ProjectsDir $ProjectsDir) -join '; ' }
  $repos = [Collections.Generic.List[pscustomobject]]::new()
  $documents = [Collections.Generic.List[pscustomobject]]::new()

  if ($AsHost -and $Repo) {
    throw 'pass -Host or -Repo, not both'
  }

  if (-not $Name) {
    if ($AsHost -or $Repo) {
      throw '-Host and -Repo need a name'
    }

    $top = Get-RepoTopLevel -Path $CurrentDirectory
    if (-not $top) {
      throw "no name given, and $CurrentDirectory is not in a git repository; valid names: $(& $valid)"
    }

    if (-not (Test-Path -LiteralPath (Join-Path -Path $top -ChildPath 'win-prereqs.json'))) {
      throw "no name given, and the current repo ($top) has no win-prereqs.json; valid names: $(& $valid)"
    }

    $kind = 'repo'
    $label = Split-Path -Leaf $top
    $repos.Add([pscustomobject]@{ Name = $label; Root = $top })
  } else {
    $hostFile = Join-Path -Path $DotfilesRoot -ChildPath "hosts\win-$Name.json"
    $repoRoot = Get-RepoRoot -Name $Name -DotfilesRoot $DotfilesRoot -ProjectsDir $ProjectsDir
    $repoFile = Join-Path -Path $repoRoot -ChildPath 'win-prereqs.json'
    $isHost = Test-Path -LiteralPath $hostFile -PathType Leaf
    $isRepo = Test-Path -LiteralPath $repoFile -PathType Leaf

    $kind = if ($AsHost) {
      if (-not $isHost) { throw "-Host: there is no $hostFile" }
      'host'
    } elseif ($Repo) {
      if (-not $isRepo) { throw "-Repo: there is no $repoFile" }
      'repo'
    } elseif ($isHost -and $isRepo) {
      throw "'$Name' is both a host ($hostFile) and a repo ($repoFile); pass -Host or -Repo"
    } elseif ($isHost) {
      'host'
    } elseif ($isRepo) {
      'repo'
    } else {
      throw "'$Name' is neither a host (no $hostFile) nor a repo (no $repoFile); valid names: $(& $valid)"
    }

    $label = $Name
    if ($kind -eq 'repo') {
      $repos.Add([pscustomobject]@{ Name = $Name; Root = $repoRoot })
    } else {
      $hostData = Read-PrereqFile -Path $hostFile -SchemaPath $SchemaPath -Kind host
      foreach ($r in @($hostData['repos'])) {
        $root = Get-RepoRoot -Name $r -DotfilesRoot $DotfilesRoot -ProjectsDir $ProjectsDir
        if (-not (Test-Path -LiteralPath (Join-Path -Path $root -ChildPath 'win-prereqs.json'))) {
          throw "$hostFile lists the repo '$r', but there is no $(Join-Path -Path $root -ChildPath 'win-prereqs.json')"
        }

        $repos.Add([pscustomobject]@{ Name = $r; Root = $root })
      }
    }
  }

  foreach ($r in $repos) {
    $path = Join-Path -Path $r.Root -ChildPath 'win-prereqs.json'
    $documents.Add([pscustomobject]@{ Path = $path; Data = (Read-PrereqFile -Path $path -SchemaPath $SchemaPath -Kind repo) })
  }

  if ($kind -eq 'host') {
    $documents.Add([pscustomobject]@{ Path = $hostFile; Data = $hostData })
  }

  [pscustomobject]@{
    Label     = $label
    Kind      = $kind
    Repos     = @($repos)
    Documents = @($documents)
  }
}

<#
.SYNOPSIS
  Returns a value as JSON with every object's keys sorted, so two entries
  compare equal however their files order the keys.
#>
function ConvertTo-CanonicalJson {
  [CmdletBinding()]
  [OutputType([string])]
  param (
    [AllowNull()]
    $InputObject
  )

  $sort = {
    param($Value)
    if ($Value -is [System.Collections.IDictionary]) {
      $sorted = [ordered]@{}
      foreach ($k in ($Value.Keys | Sort-Object)) { $sorted[$k] = & $sort $Value[$k] }
      return $sorted
    }

    if ($Value -is [System.Collections.IList]) {
      return , @($Value | ForEach-Object { & $sort $_ })
    }

    $Value
  }

  ConvertTo-Json -InputObject (& $sort $InputObject) -Depth 10 -Compress
}

<#
.SYNOPSIS
  Merges the documents' packages: one entry per name, in first-seen order.

.DESCRIPTION
  A package listed twice is installed once. Two entries with one name must
  agree on everything but why (each repo cites its own evidence); if they
  differ the merge fails, naming both files.
#>
function Merge-PrereqPackage {
  [CmdletBinding()]
  [OutputType([pscustomobject])]
  param (
    [Parameter(Mandatory)]
    [AllowEmptyCollection()]
    [object[]]$Document
  )

  $merged = [ordered]@{}
  foreach ($doc in $Document) {
    foreach ($p in @($doc.Data['packages'])) {
      if (-not $p) { continue }

      $copy = [ordered]@{}
      foreach ($k in $p.Keys) { if ($k -ne 'why') { $copy[$k] = $p[$k] } }
      $key = ConvertTo-CanonicalJson -InputObject $copy

      $n = $p['name']
      if (-not $merged.Contains($n)) {
        $merged[$n] = [pscustomobject]@{ Name = $n; Package = $p; Key = $key; Sources = @($doc.Path) }
        continue
      }

      $seen = $merged[$n]
      if ($seen.Key -ne $key) {
        throw "package '$n' differs between $($seen.Sources[0]) and $($doc.Path); make the two entries agree (only why may differ)"
      }

      $seen.Sources += $doc.Path
    }
  }

  foreach ($m in $merged.Values) { $m }
}

<#
.SYNOPSIS
  Returns 'system' for a package installed elevated or only checked (choco,
  winget, checkOnly), else 'user' (npm, pip, uv, psgallery).

.DESCRIPTION
  System packages run first, and the one elevated pass with them, so that
  what the user-scope managers need (Python, Node.js for npm, uv) is in
  place before they are used, wherever a list puts those entries.
#>
function Get-PackagePhase {
  [CmdletBinding()]
  [OutputType([string])]
  param (
    [Parameter(Mandatory)]
    [System.Collections.IDictionary]$Package
  )

  if ($Package['checkOnly'] -or (Test-AdminManager -Manager $Package['install'][0]['manager'])) {
    return 'system'
  }

  'user'
}

#endregion

#region Package managers

# Each manager's installed packages, read once per run: manager -> @{ id ->
# version[] }.
$script:PackageInventory = @{}

<#
.SYNOPSIS
  Forgets what a manager (or every manager) has installed, so the next
  check asks it again.
#>
function Clear-PackageInventory {
  [CmdletBinding()]
  param (
    [string]$Manager
  )

  if ($Manager) {
    $script:PackageInventory.Remove($Manager)
  } else {
    $script:PackageInventory = @{}
  }
}

<#
.SYNOPSIS
  Tests whether a manager's installs need admin, and so the elevated pass.
#>
function Test-AdminManager {
  [CmdletBinding()]
  [OutputType([bool])]
  param (
    [Parameter(Mandatory)]
    [string]$Manager
  )

  $Manager -in 'choco', 'winget'
}

<#
.SYNOPSIS
  Formats a spec for a report line: "choco jq", "npm github:a/b",
  "pip pytest==8.0".
#>
function Format-Spec {
  [CmdletBinding()]
  [OutputType([string])]
  param (
    [Parameter(Mandatory)]
    [System.Collections.IDictionary]$Spec
  )

  $what = if ($Spec['source']) { $Spec['source'] } else { $Spec['id'] }
  if ($Spec['version']) {
    $what = "$what $($Spec['version'])"
  }

  "$($Spec['manager']) $what"
}

<#
.SYNOPSIS
  Normalizes a Python package name (PEP 503), for pip and uv.
#>
function ConvertTo-PythonName {
  [CmdletBinding()]
  [OutputType([string])]
  param (
    [Parameter(Mandatory)]
    [string]$Name
  )

  ($Name -replace '[-_.]+', '-').ToLowerInvariant()
}

<#
.SYNOPSIS
  Returns the path of an executable on PATH, or $null. The Microsoft Store
  stubs in WindowsApps do not count: python3 there only opens the Store.
#>
function Find-Executable {
  [CmdletBinding()]
  [OutputType([string])]
  param (
    [Parameter(Mandatory)]
    [string]$Name
  )

  $found = Get-Command -Name $Name -CommandType Application -ErrorAction SilentlyContinue |
    Where-Object { $_.Source -notlike '*\Microsoft\WindowsApps\*' } |
    Select-Object -First 1
  if (-not $found) {
    return $null
  }

  $found.Source
}

<#
.SYNOPSIS
  Tests whether choco is on PATH.
#>
function Test-Choco {
  [CmdletBinding()]
  [OutputType([bool])]
  param ()

  $null -ne (Get-Command -Name choco -CommandType Application -ErrorAction SilentlyContinue)
}

<#
.SYNOPSIS
  Runs choco; the tests mock this.
#>
function Invoke-Choco {
  [CmdletBinding()]
  param (
    [Parameter(Mandatory)]
    [string[]]$ArgumentList
  )

  choco @ArgumentList
}

<#
.SYNOPSIS
  Runs winget; the tests mock this.
#>
function Invoke-Winget {
  [CmdletBinding()]
  param (
    [Parameter(Mandatory)]
    [string[]]$ArgumentList
  )

  winget @ArgumentList
}

<#
.SYNOPSIS
  Runs npm.

.DESCRIPTION
  npm is npm.ps1, an external script, which Pester cannot mock by name; the
  tests mock this function instead.
#>
function Invoke-Npm {
  [CmdletBinding()]
  param (
    [Parameter(Mandatory)]
    [string[]]$ArgumentList
  )

  npm @ArgumentList
}

<#
.SYNOPSIS
  Runs python3; the tests mock this.
#>
function Invoke-Python3 {
  [CmdletBinding()]
  param (
    [Parameter(Mandatory)]
    [string[]]$ArgumentList
  )

  python3 @ArgumentList
}

<#
.SYNOPSIS
  Runs uv; the tests mock this.
#>
function Invoke-Uv {
  [CmdletBinding()]
  param (
    [Parameter(Mandatory)]
    [string[]]$ArgumentList
  )

  uv @ArgumentList
}

<#
.SYNOPSIS
  Runs an installer with its output straight to this console, progress
  bars and all, so a long install visibly moves. Returns its exit code.
#>
function Invoke-Installer {
  [CmdletBinding()]
  [OutputType([int])]
  param (
    [Parameter(Mandatory)]
    [string]$FilePath,

    [Parameter(Mandatory)]
    [string[]]$ArgumentList
  )

  $process = Start-Process -FilePath $FilePath -ArgumentList $ArgumentList -NoNewWindow -Wait -PassThru
  $process.ExitCode
}

<#
.SYNOPSIS
  Returns the Python that python3 runs's sys.prefix when it is a real
  Python, or $null when it is missing or is the Microsoft Store stub.
#>
function Get-Python3Prefix {
  [CmdletBinding()]
  [OutputType([string])]
  param ()

  if (-not (Find-Executable -Name python3)) {
    return $null
  }

  $prefix = @(Invoke-Python3 -ArgumentList '-c', 'import sys; print(sys.prefix)' 2>$null) | Select-Object -First 1
  if (-not $prefix -or $prefix -like '*\WindowsApps*') {
    return $null
  }

  "$prefix".Trim()
}

<#
.SYNOPSIS
  Reads one manager's installed packages: @{ id -> version[] }, empty when
  the manager is not there.
#>
function Read-ManagerInventory {
  [CmdletBinding()]
  [OutputType([hashtable])]
  param (
    [Parameter(Mandatory)]
    [ValidateSet('choco', 'npm', 'pip', 'uv')]
    [string]$Manager
  )

  $inventory = @{}
  $add = { param($Id, $Version) $inventory[$Id] = @($inventory[$Id] | Where-Object { $_ }) + "$Version" }

  switch ($Manager) {
    'choco' {
      if (Test-Choco) {
        foreach ($line in @(Invoke-Choco -ArgumentList 'list', '--limit-output' 2>$null)) {
          if ("$line" -match '^([^|]+)\|(.+)$') { & $add $Matches[1] $Matches[2] }
        }
      }
    }

    'npm' {
      if (Find-Executable -Name npm) {
        $json = @(Invoke-Npm -ArgumentList 'ls', '-g', '--json', '--depth=0' 2>$null) -join "`n"
        $deps = if ($json) { ($json | ConvertFrom-Json -AsHashtable)['dependencies'] }
        if ($deps) {
          foreach ($k in @($deps.Keys)) { & $add $k $deps[$k]['version'] }
        }
      }
    }

    'pip' {
      if (Get-Python3Prefix) {
        $json = @(Invoke-Python3 -ArgumentList '-m', 'pip', 'list', '--format=json', '--disable-pip-version-check' 2>$null) -join "`n"
        foreach ($p in @(if ($json) { $json | ConvertFrom-Json })) {
          if ($p) { & $add (ConvertTo-PythonName -Name $p.name) $p.version }
        }
      }
    }

    'uv' {
      if (Find-Executable -Name uv) {
        foreach ($line in @(Invoke-Uv -ArgumentList 'tool', 'list' 2>$null)) {
          if ("$line" -match '^(\S+) v(\S+)') { & $add (ConvertTo-PythonName -Name $Matches[1]) $Matches[2] }
        }
      }
    }
  }

  $inventory
}

<#
.SYNOPSIS
  Returns the versions of a module PowerShellGet installed, which leaves
  out the in-box copies (Pester 3.4) that Get-Module would list.
#>
function Get-PsGalleryVersion {
  [CmdletBinding()]
  [OutputType([string])]
  param (
    [Parameter(Mandatory)]
    [string]$Id
  )

  # Only a lookup; without this, loading PowerShellGet under -WhatIf prints
  # a "What if" line for every alias it defines.
  $WhatIfPreference = $false
  @(Get-InstalledModule -Name $Id -AllVersions -ErrorAction SilentlyContinue) |
    Where-Object { $_ } |
    ForEach-Object { "$($_.Version)" }
}

<#
.SYNOPSIS
  Returns the version winget lists for an id, or $null. winget also lists
  what other installers put in Add/Remove Programs.
#>
function Get-WingetVersion {
  [CmdletBinding()]
  [OutputType([string])]
  param (
    [Parameter(Mandatory)]
    [string]$Id
  )

  if (-not (Get-Command -Name winget -CommandType Application -ErrorAction SilentlyContinue)) {
    return $null
  }

  $out = @(Invoke-Winget -ArgumentList 'list', '--id', $Id, '--exact', '--accept-source-agreements', '--disable-interactivity' 2>$null)
  foreach ($line in $out) {
    if ("$line" -match "(^|\s)$([regex]::Escape($Id))\s+(\S+)") {
      return $Matches[2]
    }
  }

  $null
}

<#
.SYNOPSIS
  Returns the versions of a spec's package its manager has installed; none
  when it has not.
#>
function Get-InstalledVersion {
  [CmdletBinding()]
  [OutputType([string])]
  param (
    [Parameter(Mandatory)]
    [System.Collections.IDictionary]$Spec
  )

  $manager = $Spec['manager']
  $id = $Spec['id']
  if ($manager -in 'pip', 'uv') {
    $id = ConvertTo-PythonName -Name $id
  }

  # These two are asked one id at a time: winget has no quick full list,
  # and Get-InstalledModule takes no wildcard with -AllVersions.
  if ($manager -in 'winget', 'psgallery') {
    $key = "${manager}:$id"
    if (-not $script:PackageInventory.Contains($key)) {
      $script:PackageInventory[$key] = if ($manager -eq 'winget') {
        @(Get-WingetVersion -Id $id | Where-Object { $_ })
      } else {
        @(Get-PsGalleryVersion -Id $id)
      }
    }

    foreach ($v in $script:PackageInventory[$key]) { $v }
    return
  }

  if (-not $script:PackageInventory.Contains($manager)) {
    $script:PackageInventory[$manager] = Read-ManagerInventory -Manager $manager
  }

  $versions = @($script:PackageInventory[$manager][$id] | Where-Object { $_ })

  # npm's registry bats-file is a security placeholder (0.0.1-security),
  # not the library; a spec that names a source does not count it.
  if ($Spec['source']) {
    $versions = @($versions | Where-Object { $_ -notlike '*-security' })
  }

  foreach ($v in $versions) { $v }
}

<#
.SYNOPSIS
  Item chocolatey: install Chocolatey if choco is missing.
#>
function Install-Chocolatey {
  [CmdletBinding(SupportsShouldProcess)]
  [OutputType([pscustomobject])]
  param ()

  Sync-ProcessPath
  if (Test-Choco) {
    return New-StepResult -Status ok -Detail "choco $(@(Invoke-Choco -ArgumentList '--version') | Select-Object -First 1)"
  }

  if (-not $PSCmdlet.ShouldProcess('Chocolatey', 'Install from community.chocolatey.org/install.ps1')) {
    return New-StepResult -Status 'would fix' -Detail 'install Chocolatey (needs admin)'
  }

  if (-not (Test-Elevated)) {
    return New-StepResult -Status 'needs admin' -Detail 'install Chocolatey'
  }

  Invoke-ChocolateyBootstrap
  Sync-ProcessPath
  if (-not (Test-Choco)) {
    return New-StepResult -Status FAILED -Detail 'choco still not on PATH after the bootstrap'
  }

  New-StepResult -Status fixed -Detail "choco $(@(Invoke-Choco -ArgumentList '--version') | Select-Object -First 1)"
}

<#
.SYNOPSIS
  Runs Chocolatey's official install script.

.DESCRIPTION
  The documented bootstrap (https://chocolatey.org/install) pipes
  install.ps1 into Invoke-Expression; this saves it to a file and runs that
  instead, which is the same script without Invoke-Expression.
#>
function Invoke-ChocolateyBootstrap {
  [CmdletBinding()]
  param ()

  $script = Join-Path -Path ([IO.Path]::GetTempPath()) -ChildPath 'chocolatey-install.ps1'
  [Net.ServicePointManager]::SecurityProtocol = [Net.ServicePointManager]::SecurityProtocol -bor 3072
  Invoke-WebRequest -Uri 'https://community.chocolatey.org/install.ps1' -OutFile $script -UseBasicParsing
  Set-ExecutionPolicy -ExecutionPolicy Bypass -Scope Process -Force
  try {
    & $script
  } finally {
    Remove-Item -LiteralPath $script -Force -ErrorAction SilentlyContinue -WhatIf:$false
  }
}

<#
.SYNOPSIS
  Installs one spec. Returns '' on success, 'reboot' when the installer
  asked for one, else a failure reason.

.DESCRIPTION
  -Reinstall is for a pin that differs from what is installed: it moves
  the package to the pinned version, the one case that may change an
  installed package. Nothing here uninstalls.
#>
function Invoke-SpecInstall {
  [CmdletBinding()]
  [OutputType([string])]
  param (
    [Parameter(Mandatory)]
    [System.Collections.IDictionary]$Spec,

    [switch]$Reinstall
  )

  $id = $Spec['id']
  $version = $Spec['version']

  switch ($Spec['manager']) {
    'choco' {
      $exe = Find-Executable -Name choco
      if (-not $exe) { return 'choco is not installed' }

      $arguments = if ($version) {
        # upgrade installs a missing package too, and moves an installed one
        # to the pin either way.
        'upgrade', $id, '--version', $version, '--allow-downgrade', '-y'
      } else {
        'install', $id, '-y'
      }
    }

    'winget' {
      $exe = (Get-Command -Name winget -CommandType Application -ErrorAction SilentlyContinue | Select-Object -First 1).Source
      if (-not $exe) { return 'winget is not installed' }

      $arguments = @(
        'install', '--id', $id, '--exact', '--source', 'winget',
        '--accept-package-agreements', '--accept-source-agreements', '--disable-interactivity'
      )
      if ($version) { $arguments += '--version', $version }
      if ($Reinstall) { $arguments += '--force' }
    }

    'npm' {
      $exe = Find-Executable -Name npm
      if (-not $exe) { return 'npm is not installed (install Node.js)' }

      $target = if ($Spec['source']) {
        if ($version) { "$($Spec['source'])#$version" } else { $Spec['source'] }
      } elseif ($version) {
        "$id@$version"
      } else {
        $id
      }

      $arguments = 'install', '-g', $target
    }

    'pip' {
      if (-not (Get-Python3Prefix)) { return 'python3 does not run a real Python' }

      $exe = Find-Executable -Name python3
      $target = if ($version) { "$id==$version" } else { $id }
      $arguments = '-m', 'pip', 'install', '--user', '--disable-pip-version-check', $target
    }

    'uv' {
      $exe = Find-Executable -Name uv
      if (-not $exe) { return 'uv is not installed' }

      $target = if ($version) { "$id==$version" } else { $id }
      $arguments = 'tool', 'install', $target
    }

    'psgallery' {
      # -SkipPublisherCheck: an in-box module (Pester 3.4) is signed by
      # Microsoft and its gallery successor is not, which Install-Module
      # otherwise refuses.
      $splat = @{
        Name = $id; Scope = 'CurrentUser'; Repository = 'PSGallery'
        Force = $true; SkipPublisherCheck = $true; ErrorAction = 'Stop'
      }
      if ($version) { $splat['RequiredVersion'] = $version }

      try {
        Install-Module @splat
      } catch {
        return "Install-Module $id failed: $($_.Exception.Message)"
      }

      return ''
    }
  }

  $code = Invoke-Installer -FilePath $exe -ArgumentList $arguments
  if ($code -eq 0) { return '' }
  if ($code -in 1641, 3010) { return 'reboot' }

  "$(Split-Path -Leaf $exe) $($arguments -join ' ') exited $code"
}

<#
.SYNOPSIS
  Tests whether installed versions satisfy a spec: any version when it is
  unpinned, the pinned one when it is pinned.
#>
function Test-SpecSatisfied {
  [CmdletBinding()]
  [OutputType([bool])]
  param (
    [Parameter(Mandatory)]
    [System.Collections.IDictionary]$Spec,

    [AllowEmptyCollection()]
    [string[]]$Version = @()
  )

  if (@($Version).Count -eq 0) {
    return $false
  }

  -not $Spec['version'] -or $Version -contains $Spec['version']
}

<#
.SYNOPSIS
  Works out whether a package is installed.

.DESCRIPTION
  Returns Status 'ok' (with where it was found), 'missing', 'pin differs'
  (with the spec to move to its pin), or 'FAILED' (a checkOnly package that
  is absent).

  An unpinned package with a command on PATH is ok however it got there.
  Otherwise the specs are asked in order, and the first manager that has
  the package decides: ok when it satisfies the spec, 'pin differs' when
  its version is not the pinned one.
#>
function Get-PackageState {
  [CmdletBinding()]
  [OutputType([pscustomobject])]
  param (
    [Parameter(Mandatory)]
    [System.Collections.IDictionary]$Package
  )

  $state = { param($Status, $Detail, $Spec) [pscustomobject]@{ Status = $Status; Detail = $Detail; Spec = $Spec } }
  $command = $Package['command']

  if ($Package['checkOnly']) {
    $path = Find-Executable -Name $command
    if ($path) {
      return & $state ok "$path; check-only, never installed or upgraded here"
    }

    return & $state FAILED "$command not found on PATH; it is check-only, so install it by hand"
  }

  $specs = @($Package['install'])
  $pinned = @($specs | Where-Object { $_['version'] }).Count -gt 0
  if ($command -and -not $pinned) {
    $path = Find-Executable -Name $command
    if ($path) {
      return & $state ok $path
    }
  }

  foreach ($spec in $specs) {
    $versions = @(Get-InstalledVersion -Spec $spec)
    if ($versions.Count -eq 0) {
      continue
    }

    if (Test-SpecSatisfied -Spec $spec -Version $versions) {
      $shown = if ($spec['version']) { $spec['version'] } else { $versions[-1] }
      return & $state ok "$($spec['manager']) $($spec['id']) $shown"
    }

    return & $state 'pin differs' "$($spec['manager']) has $($spec['id']) $($versions -join ', '); pinned $($spec['version'])" $spec
  }

  & $state missing 'not installed'
}

<#
.SYNOPSIS
  Installs a package from its specs, in order, falling back to the next on
  failure.

.DESCRIPTION
  Each attempt is announced first, with the package's slow warning if it
  has one. Reaching an admin spec (choco, winget) unelevated stops with
  'needs admin', carrying the specs still to try for the elevated pass.
  Success is verified by asking the manager again, not by its exit code.
#>
function Install-PackageSpec {
  [CmdletBinding(SupportsShouldProcess)]
  [OutputType([pscustomobject])]
  param (
    [Parameter(Mandatory)]
    [System.Collections.IDictionary]$Package,

    [Parameter(Mandatory)]
    [System.Collections.IDictionary[]]$Spec,

    [switch]$Reinstall,

    # Failures from attempts made before this call (the elevated pass).
    [string[]]$Failure = @()
  )

  $name = $Package['name']
  $plan = ($Spec | ForEach-Object { Format-Spec -Spec $_ }) -join ', else '
  $verb = if ($Reinstall) { 'move to its pin via' } else { 'install via' }

  if (-not $PSCmdlet.ShouldProcess($name, "$verb $plan")) {
    $admin = if (@($Spec | Where-Object { Test-AdminManager -Manager $_['manager'] }).Count -gt 0) { ' (choco and winget need admin)' } else { '' }
    return New-StepResult -Status 'would fix' -Detail "$verb $plan$admin"
  }

  $failures = [Collections.Generic.List[string]]::new()
  foreach ($f in $Failure) { $failures.Add($f) }

  for ($i = 0; $i -lt $Spec.Count; $i++) {
    $s = $Spec[$i]
    if ((Test-AdminManager -Manager $s['manager']) -and -not (Test-Elevated)) {
      $rest = @($Spec[$i..($Spec.Count - 1)])
      return New-StepResult -Status 'needs admin' -Detail "$verb $(($rest | ForEach-Object { Format-Spec -Spec $_ }) -join ', else ')" -Plan @{
        Specs = $rest; Reinstall = [bool]$Reinstall; Failures = @($failures)
      }
    }

    $announce = "[$name] installing via $(Format-Spec -Spec $s)"
    if ($Package['slow']) { $announce += " - $($Package['slow'])" }
    Write-Report "$announce..."

    $outcome = Invoke-SpecInstall -Spec $s -Reinstall:$Reinstall
    if ($outcome -eq 'reboot') {
      return New-StepResult -Status PENDING -Detail "installed via $(Format-Spec -Spec $s); reboot, then rerun"
    }

    if ($outcome) {
      $failures.Add($outcome)
      continue
    }

    Sync-ProcessPath
    Clear-PackageInventory -Manager $s['manager']
    Clear-PackageInventory -Manager "$($s['manager']):$($s['id'])"
    $versions = @(Get-InstalledVersion -Spec $s)
    if (Test-SpecSatisfied -Spec $s -Version $versions) {
      return New-StepResult -Status fixed -Detail "$(Format-Spec -Spec $s) -> $($versions[-1])" -Line @($failures | ForEach-Object { "tried first: $_" })
    }

    $failures.Add("$(Format-Spec -Spec $s) reported success, but $($s['manager']) does not list it$(if ($s['version']) { " at $($s['version'])" })")
  }

  New-StepResult -Status FAILED -Detail "every manager failed: $($failures -join '; ')"
}

<#
.SYNOPSIS
  One package item: ok when installed, else installed (or moved to its pin)
  from its specs.
#>
function Invoke-Package {
  [CmdletBinding()]
  [OutputType([pscustomobject])]
  param (
    [Parameter(Mandatory)]
    [System.Collections.IDictionary]$Package
  )

  $state = Get-PackageState -Package $Package
  switch ($state.Status) {
    'ok' { return New-StepResult -Status ok -Detail $state.Detail }
    'FAILED' { return New-StepResult -Status FAILED -Detail $state.Detail }
    'pin differs' { return Install-PackageSpec -Package $Package -Spec @($state.Spec) -Reinstall }
  }

  Install-PackageSpec -Package $Package -Spec @($Package['install'])
}

#endregion

#region dotfiles built-in steps

<#
.SYNOPSIS
  Tests whether Windows Developer Mode is on, which lets a non-admin user
  create symbolic links.
#>
function Test-DeveloperMode {
  [CmdletBinding()]
  [OutputType([bool])]
  param ()

  $key = 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\AppModelUnlock'
  $value = Get-ItemProperty -Path $key -Name AllowDevelopmentWithoutDevLicense -ErrorAction SilentlyContinue
  $null -ne $value -and $value.AllowDevelopmentWithoutDevLicense -eq 1
}

<#
.SYNOPSIS
  Returns the path of the newest Python the py launcher lists, or $null.

.DESCRIPTION
  Parses `py -0p` lines such as ` -V:3.15 *  C:\Python315\python.exe`. Only
  plain X.Y tags count, so free-threaded (3.13t) and 32-bit (3.14-32)
  installs are passed over.
#>
function Get-NewestPython {
  [CmdletBinding()]
  [OutputType([string])]
  param ()

  if (-not (Get-Command -Name py -CommandType Application -ErrorAction SilentlyContinue)) {
    return $null
  }

  $found = foreach ($line in @(py -0p 2>$null)) {
    if ($line -match '^\s*-V:(\d+\.\d+)\s+(?:\*\s+)?(\S.*?)\s*$') {
      [pscustomobject]@{ Version = [version]$Matches[1]; Path = $Matches[2] }
    }
  }

  $newest = $found | Sort-Object -Property Version -Descending | Select-Object -First 1
  if ($null -eq $newest) {
    return $null
  }

  $newest.Path
}

<#
.SYNOPSIS
  Tests whether two filesystem paths name the same file.
#>
function Test-SamePath {
  [CmdletBinding()]
  [OutputType([bool])]
  param (
    [string]$Path,
    [string]$OtherPath
  )

  if (-not $Path -or -not $OtherPath) {
    return $false
  }

  [string]::Equals(
    [IO.Path]::GetFullPath($Path).TrimEnd('\'),
    [IO.Path]::GetFullPath($OtherPath).TrimEnd('\'),
    [StringComparison]::OrdinalIgnoreCase
  )
}

<#
.SYNOPSIS
  Returns the User PATH value with -Directory ahead of the first WindowsApps
  entry, or $null when it already is.
#>
function Get-ReorderedUserPath {
  [CmdletBinding()]
  [OutputType([string])]
  param (
    [Parameter(Mandatory)]
    [AllowEmptyString()]
    [AllowNull()]
    [string]$UserPath,

    [Parameter(Mandatory)]
    [string]$Directory
  )

  $entries = @($UserPath -split ';' | Where-Object { $_ })
  $isDirectory = @($entries | ForEach-Object {
      Test-SamePath -Path ([Environment]::ExpandEnvironmentVariables($_)) -OtherPath $Directory
    })

  # Walk in order: whichever of the two comes first decides.
  for ($i = 0; $i -lt $entries.Count; $i++) {
    if ($isDirectory[$i]) {
      return $null
    }

    if ($entries[$i].TrimEnd('\') -like '*\Microsoft\WindowsApps') {
      break
    }
  }

  $rest = for ($i = 0; $i -lt $entries.Count; $i++) {
    if (-not $isDirectory[$i]) {
      $entries[$i]
    }
  }

  (@($Directory) + @($rest)) -join ';'
}

<#
.SYNOPSIS
  Tests whether a PATH entry names a directory that is gone from a drive
  or share that is there.

.DESCRIPTION
  A disconnected drive or share, or an entry that is not a rooted path,
  does not count as missing: nothing can be told about it from here.
#>
function Test-MissingDirectory {
  [CmdletBinding()]
  [OutputType([bool])]
  param (
    [Parameter(Mandatory)]
    [string]$Path
  )

  if (-not [IO.Path]::IsPathRooted($Path)) {
    return $false
  }

  (Test-Path -LiteralPath ([IO.Path]::GetPathRoot($Path)) -PathType Container) -and
  -not (Test-Path -LiteralPath $Path -PathType Container)
}

<#
.SYNOPSIS
  Returns a PATH value without its repeated entries and without those whose
  directory is missing, and lists what it removed.

.DESCRIPTION
  Entries compare with %VARS% expanded, ignoring case and a trailing \.
  The first of a repeat keeps its place, and every kept entry is written as
  it was, %VARS% included. Missing is Test-MissingDirectory's sense.
  Returns Value, the cleaned value, and Repeated and Missing, the entries
  removed as written.
#>
function Get-CleanPath {
  [CmdletBinding()]
  [OutputType([pscustomobject])]
  param (
    [Parameter(Mandatory)]
    [AllowEmptyString()]
    [AllowNull()]
    [string]$Value
  )

  $seen = [Collections.Generic.HashSet[string]]::new([StringComparer]::OrdinalIgnoreCase)
  $kept = [Collections.Generic.List[string]]::new()
  $repeated = [Collections.Generic.List[string]]::new()
  $missing = [Collections.Generic.List[string]]::new()

  foreach ($entry in @($Value -split ';' | Where-Object { $_ })) {
    $expanded = [Environment]::ExpandEnvironmentVariables($entry).TrimEnd('\')

    if (-not $seen.Add($expanded)) {
      $repeated.Add($entry)
    } elseif (Test-MissingDirectory -Path $expanded) {
      $missing.Add($entry)
    } else {
      $kept.Add($entry)
    }
  }

  [pscustomobject]@{ Value = $kept -join ';'; Repeated = @($repeated); Missing = @($missing) }
}

<#
.SYNOPSIS
  dotfiles step: remove the repeated entries, and those whose directory is
  missing, from the User or the Machine PATH.

.DESCRIPTION
  Safe to rerun: a clean PATH is ok and is not written. The value keeps its
  registry kind (REG_EXPAND_SZ). Fixing the Machine PATH needs admin, so
  unelevated it comes back 'needs admin' for the one elevated pass.
#>
function Repair-PathValue {
  [CmdletBinding(SupportsShouldProcess)]
  [OutputType([pscustomobject])]
  param (
    [ValidateSet('User', 'Machine')]
    [string]$Scope = 'User'
  )

  $clean = Get-CleanPath -Value (Get-UserEnvironmentValue -Name Path -Scope $Scope)
  $count = $clean.Repeated.Count + $clean.Missing.Count
  if ($count -eq 0) {
    return New-StepResult -Status ok
  }

  $summary = "$($clean.Repeated.Count) repeated, $($clean.Missing.Count) missing"
  $lines = @($clean.Repeated | ForEach-Object { "repeated: $_" }) +
  @($clean.Missing | ForEach-Object { "missing: $_" })

  if (-not $PSCmdlet.ShouldProcess("$Scope PATH", "Remove $count entries ($summary)")) {
    $admin = if ($Scope -eq 'Machine') { ' (needs admin)' } else { '' }
    return New-StepResult -Status 'would fix' -Detail "remove $summary$admin" -Line $lines
  }

  if ($Scope -eq 'Machine' -and -not (Test-Elevated)) {
    return New-StepResult -Status 'needs admin' -Detail "remove $summary from the Machine PATH" -Line $lines -Plan @{}
  }

  Write-UserEnvironmentValue -Name Path -Value $clean.Value -Scope $Scope
  New-StepResult -Status fixed -Detail "removed $summary" -Line $lines
}

<#
.SYNOPSIS
  dotfiles step: symlink ~\.local\bin\python3.exe to the newest Python and
  put ~\.local\bin ahead of WindowsApps in the User PATH.
#>
function Repair-Python3 {
  [CmdletBinding(SupportsShouldProcess)]
  [OutputType([pscustomobject])]
  param ()

  $binDir = Join-Path -Path $HOME -ChildPath '.local\bin'
  $link = Join-Path -Path $binDir -ChildPath 'python3.exe'
  $changed = $false
  $pending = [System.Collections.Generic.List[string]]::new()

  $newest = Get-NewestPython
  if (-not $newest) {
    $status = if ($WhatIfPreference) { 'skipped' } else { 'FAILED' }
    return New-StepResult -Status $status -Detail 'the py launcher lists no Python X.Y install (py -0p)'
  }

  $existing = Get-Item -LiteralPath $link -Force -ErrorAction SilentlyContinue
  if ($existing -and $existing.LinkType -ne 'SymbolicLink') {
    return New-StepResult -Status FAILED -Detail "$link exists and is not a symlink; move it aside by hand"
  }

  if (-not $existing -or -not (Test-SamePath -Path $existing.Target -OtherPath $newest)) {
    if (-not (Test-DeveloperMode)) {
      return New-StepResult -Status FAILED -Detail 'Developer Mode is off, so a non-admin symlink cannot be made; turn it on in Settings > System > For developers (needs admin)'
    }

    if ($PSCmdlet.ShouldProcess($link, "Symlink to $newest")) {
      if (-not (Test-Path -LiteralPath $binDir)) {
        New-Item -ItemType Directory -Path $binDir -Force | Out-Null
      }

      if ($existing) {
        Remove-Item -LiteralPath $link -Force
      }

      New-Item -ItemType SymbolicLink -Path $link -Target $newest -ErrorAction Stop | Out-Null
      $changed = $true
    } else {
      $pending.Add("link $link -> $newest")
    }
  }

  $newPath = Get-ReorderedUserPath -UserPath (Get-UserEnvironmentValue -Name Path) -Directory $binDir
  if ($null -ne $newPath) {
    if ($PSCmdlet.ShouldProcess('User PATH', "Put $binDir ahead of WindowsApps")) {
      Write-UserEnvironmentValue -Name Path -Value $newPath
      $changed = $true
    } else {
      $pending.Add("put $binDir first in the User PATH")
    }
  }

  if ($pending.Count -gt 0) {
    return New-StepResult -Status 'would fix' -Detail ($pending -join '; ')
  }

  Sync-ProcessPath
  $prefix = Get-Python3Prefix
  if (-not $prefix) {
    return New-StepResult -Status FAILED -Detail 'python3 still does not resolve to a real Python'
  }

  Clear-PackageInventory -Manager pip
  $status = if ($changed) { 'fixed' } else { 'ok' }
  New-StepResult -Status $status -Detail "sys.prefix $prefix"
}

<#
.SYNOPSIS
  dotfiles step: add winsymlinks:nativestrict to the User MSYS variable,
  keeping its other tokens, so Git Bash `ln -s` makes real symlinks.
#>
function Set-MsysSymlinkMode {
  [CmdletBinding(SupportsShouldProcess)]
  [OutputType([pscustomobject])]
  param ()

  $token = 'winsymlinks:nativestrict'
  $tokens = @((Get-UserEnvironmentValue -Name MSYS) -split '\s+' | Where-Object { $_ })

  if ($tokens -contains $token) {
    return New-StepResult -Status ok -Detail "MSYS=$($tokens -join ' ')"
  }

  # Any other winsymlinks: mode conflicts with the one wanted, so it goes.
  $value = (@($tokens | Where-Object { $_ -notlike 'winsymlinks:*' }) + $token) -join ' '

  if (-not $PSCmdlet.ShouldProcess('User MSYS', "Set to '$value'")) {
    return New-StepResult -Status 'would fix' -Detail "set MSYS=$value"
  }

  Write-UserEnvironmentValue -Name MSYS -Value $value
  $env:MSYS = $value
  New-StepResult -Status fixed -Detail "MSYS=$value"
}

<#
.SYNOPSIS
  Returns the Git Bash bash.exe that sits beside git.exe, or $null.
#>
function Get-GitBash {
  [CmdletBinding()]
  [OutputType([string])]
  param ()

  $git = Get-Command -Name git -CommandType Application -ErrorAction SilentlyContinue | Select-Object -First 1
  if (-not $git) {
    return $null
  }

  # git.exe is in <Git>\cmd or <Git>\bin; bash.exe is in <Git>\bin.
  $bash = Join-Path -Path (Split-Path -Path (Split-Path -Path $git.Source)) -ChildPath 'bin\bash.exe'
  if (-not (Test-Path -LiteralPath $bash)) {
    return $null
  }

  $bash
}

<#
.SYNOPSIS
  Returns the `--version` line of s3cmd run through dotfiles' bin/s3cmd
  wrapper in Git Bash, or $null.
#>
function Get-S3cmdWrapperVersion {
  [CmdletBinding()]
  [OutputType([string])]
  param (
    [Parameter(Mandatory)]
    [string]$Bash,

    [Parameter(Mandatory)]
    [string]$Wrapper
  )

  if (-not (Test-Path -LiteralPath $Wrapper)) {
    return $null
  }

  # stdin closed: s3cmd waits on it when there is no console.
  $posix = [IO.Path]::GetFullPath($Wrapper) -replace '\\', '/'
  $line = @(& $Bash -c "'$posix' --version </dev/null" 2>$null) | Where-Object { $_ -match '^s3cmd version' } | Select-Object -First 1
  $line
}

<#
.SYNOPSIS
  dotfiles step: s3cmd, as uv installs it, runs by name from Git Bash
  through dotfiles' bin/s3cmd.
#>
function Test-S3cmdWrapper {
  [CmdletBinding()]
  [OutputType([pscustomobject])]
  param (
    [Parameter(Mandatory)]
    [string]$DotfilesRoot
  )

  $bash = Get-GitBash
  if (-not $bash) {
    return New-StepResult -Status FAILED -Detail 'Git Bash not found, so bin/s3cmd cannot be checked'
  }

  $wrapper = Join-Path -Path $DotfilesRoot -ChildPath 'bin\s3cmd'
  $version = Get-S3cmdWrapperVersion -Bash $bash -Wrapper $wrapper
  if (-not $version) {
    $status = if ($WhatIfPreference) { 'skipped' } else { 'FAILED' }
    return New-StepResult -Status $status -Detail "bin/s3cmd does not run s3cmd from Git Bash ($wrapper)"
  }

  New-StepResult -Status ok -Detail "$version, through bin/s3cmd in Git Bash"
}

#endregion

#region The run

<#
.SYNOPSIS
  Runs the items that came back 'needs admin' in the one elevated pass,
  then verifies each unelevated and finishes any user-scope fallback.
#>
function Invoke-AdminPass {
  [CmdletBinding()]
  param (
    [Parameter(Mandatory)]
    [System.Collections.IDictionary]$Results,

    # Item name -> its package, for the package items.
    [Parameter(Mandatory)]
    [System.Collections.IDictionary]$Packages
  )

  $names = @($Results.Keys | Where-Object { $Results[$_].Status -eq 'needs admin' })
  $plan = @{ Chocolatey = $names -contains 'chocolatey'; MachinePath = $names -contains 'machine PATH'; Packages = @() }
  foreach ($n in $names) {
    if ($n -in 'chocolatey', 'machine PATH') { continue }

    $p = $Results[$n].Plan
    $plan.Packages += @{
      Name      = $n
      Package   = $Packages[$n]
      Specs     = @($p.Specs | Where-Object { Test-AdminManager -Manager $_['manager'] })
      Reinstall = $p.Reinstall
    }
  }

  Write-Report ''
  Write-Report "elevating once for: $($names -join ', ') (one UAC prompt; a new window shows the progress)"
  $elevated = Invoke-ElevatedRun -Plan $plan
  Write-Report "elevation: $($elevated.Note)"

  foreach ($n in $names) {
    $fromAdmin = $elevated.Results[$n]
    $final = $fromAdmin
    Clear-PackageInventory
    Sync-ProcessPath

    if ($n -eq 'chocolatey') {
      if ($fromAdmin.Status -eq 'fixed' -and -not (Test-Choco)) {
        $final = New-StepResult -Status FAILED -Detail 'the elevated run installed Chocolatey, but choco is not on PATH here'
      }
    } elseif ($n -eq 'machine PATH') {
      $left = Get-CleanPath -Value (Get-UserEnvironmentValue -Name Path -Scope Machine)
      if ($fromAdmin.Status -eq 'fixed' -and ($left.Repeated.Count + $left.Missing.Count) -gt 0) {
        $final = New-StepResult -Status FAILED -Detail 'the elevated run cleaned the Machine PATH, but here it still has repeated or missing entries'
      }
    } elseif ($fromAdmin.Status -eq 'fixed') {
      $state = Get-PackageState -Package $Packages[$n]
      if ($state.Status -ne 'ok') {
        $final = New-StepResult -Status FAILED -Detail "the elevated run reported $($fromAdmin.Detail), but here it is $($state.Detail)"
      }
    } elseif ($fromAdmin.Status -eq 'FAILED') {
      # The user-scope specs after the admin ones are tried here, unelevated.
      $user = @($Results[$n].Plan.Specs | Where-Object { -not (Test-AdminManager -Manager $_['manager']) })
      if ($user.Count -gt 0) {
        $final = Install-PackageSpec -Package $Packages[$n] -Spec $user -Reinstall:$Results[$n].Plan.Reinstall -Failure @($fromAdmin.Detail)
      }
    }

    $Results[$n] = $final
    Write-StepResult -Name $n -Result $final
  }
}

<#
.SYNOPSIS
  Runs one item and prints its result.
#>
function Invoke-PrereqItem {
  [CmdletBinding()]
  param (
    [Parameter(Mandatory)]
    [System.Collections.IDictionary]$Results,

    [Parameter(Mandatory)]
    [string]$Name,

    [Parameter(Mandatory)]
    [scriptblock]$Step
  )

  $Results[$Name] = Invoke-PrereqStep -Step $Step
  Write-StepResult -Name $Name -Result $Results[$Name]
}

<#
.SYNOPSIS
  The whole unelevated run. Returns the exit code: 1 when any item failed
  or is pending, else 0.
#>
function Invoke-PrereqRun {
  [CmdletBinding()]
  [OutputType([int])]
  param (
    [string]$Name,

    [switch]$AsHost,

    [switch]$Repo,

    [Parameter(Mandatory)]
    [string]$DotfilesRoot,

    [Parameter(Mandatory)]
    [string]$CurrentDirectory
  )

  $schema = Join-Path -Path $DotfilesRoot -ChildPath 'powershell\win-prereqs.schema.json'
  $projects = Get-ProjectsDir -DotfilesRoot $DotfilesRoot
  Write-Report "projects directory: $($projects.Path) ($($projects.How))"
  Write-Report 'reading and validating the package lists...'

  try {
    $target = Resolve-PrereqTarget -Name $Name -AsHost:$AsHost -Repo:$Repo -DotfilesRoot $DotfilesRoot -ProjectsDir $projects.Path -CurrentDirectory $CurrentDirectory -SchemaPath $schema
    $merged = @(Merge-PrereqPackage -Document $target.Documents)
  } catch {
    Write-Report "FAILED: $($_.Exception.Message)"
    return 1
  }

  $withDotfiles = $null -ne ($target.Repos | Where-Object { Test-SamePath -Path $_.Root -OtherPath $DotfilesRoot } | Select-Object -First 1)
  Write-Report "target: $($target.Label), a $($target.Kind); repos: $(($target.Repos | ForEach-Object { $_.Name }) -join ', ')"
  foreach ($doc in $target.Documents) {
    Write-Report "  list: $($doc.Path)"
  }

  Write-Report "$($merged.Count) packages$(if ($withDotfiles) { ', plus the dotfiles setup steps' })"
  Write-Report ''

  Clear-PackageInventory
  $packages = [ordered]@{}
  foreach ($m in $merged) { $packages[$m.Name] = $m.Package }
  $system = @($merged | Where-Object { (Get-PackagePhase -Package $_.Package) -eq 'system' })
  $user = @($merged | Where-Object { (Get-PackagePhase -Package $_.Package) -eq 'user' })
  $results = [ordered]@{}
  $elevationUsed = $false

  Write-Report 'checking Chocolatey and the system packages (choco, winget, check-only)...'
  Invoke-PrereqItem -Results $results -Name chocolatey -Step { Install-Chocolatey }
  foreach ($m in $system) {
    Invoke-PrereqItem -Results $results -Name $m.Name -Step { Invoke-Package -Package $m.Package }
  }

  # A dotfiles step, but checked here so a fix rides the one elevated pass.
  if ($withDotfiles) {
    Invoke-PrereqItem -Results $results -Name 'machine PATH' -Step { Repair-PathValue -Scope Machine }
  }

  if (@($results.Values | Where-Object { $_.Status -eq 'needs admin' }).Count -gt 0) {
    Invoke-AdminPass -Results $results -Packages $packages
    $elevationUsed = $true
  }

  if ($withDotfiles) {
    Write-Report ''
    Write-Report 'dotfiles setup steps...'
    Invoke-PrereqItem -Results $results -Name 'python3 link' -Step { Repair-Python3 }
    Invoke-PrereqItem -Results $results -Name msys -Step { Set-MsysSymlinkMode }
  }

  if ($user.Count -gt 0) {
    Write-Report ''
    Write-Report 'checking the user-scope packages (npm, pip, uv, psgallery)...'
    foreach ($m in $user) {
      Invoke-PrereqItem -Results $results -Name $m.Name -Step { Invoke-Package -Package $m.Package }
    }
  }

  $late = @($results.Keys | Where-Object { $results[$_].Status -eq 'needs admin' })
  if ($late.Count -gt 0) {
    if ($elevationUsed) {
      foreach ($n in $late) {
        $results[$n] = New-StepResult -Status FAILED -Detail "needs admin ($($results[$n].Detail)) after this run's one elevated pass; rerun"
        Write-StepResult -Name $n -Result $results[$n]
      }
    } else {
      Invoke-AdminPass -Results $results -Packages $packages
    }
  }

  if ($withDotfiles) {
    # After every install, so a directory one just created is not dropped.
    Invoke-PrereqItem -Results $results -Name 'user PATH' -Step { Repair-PathValue -Scope User }
    Invoke-PrereqItem -Results $results -Name 'bin/s3cmd' -Step { Test-S3cmdWrapper -DotfilesRoot $DotfilesRoot }
  }

  Write-Summary -Results $results
  $bad = @($results.Values | Where-Object { $_.Status -in 'FAILED', 'PENDING' })
  [int]($bad.Count -gt 0)
}

#endregion

# Dot-sourcing (the Pester tests) loads the functions without running them.
if ($MyInvocation.InvocationName -ne '.') {
  try {
    if ($PlanPath) {
      Disable-QuickEdit
      $plan = Get-Content -LiteralPath $PlanPath -Raw | ConvertFrom-Json -AsHashtable
      Invoke-ElevatedPlan -Plan $plan -ExpectedSid $ExpectedSid -ResultPath $ResultPath
      exit 0
    }

    $code = Invoke-PrereqRun -Name $Name -AsHost:$AsHost -Repo:$Repo `
      -DotfilesRoot (Split-Path -Parent (Split-Path -Parent $PSScriptRoot)) `
      -CurrentDirectory (Get-Location).ProviderPath
    exit $code
  } finally {
    $Host.UI.RawUI.WindowTitle = $savedTitle
  }
}

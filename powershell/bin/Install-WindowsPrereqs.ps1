#Requires -Version 7

<#
.SYNOPSIS
  Checks, and fixes where needed, the Windows machine prerequisites for
  dotfiles and dotagents.

.DESCRIPTION
  Phase 1 of bringing dotfiles and dotagents up on Windows. It depends on
  neither repository being set up, so it can run before the shell profile is
  wired. Chocolatey is the package manager; winget is only for what the
  Chocolatey community repository lacks. Each item is check-then-fix and
  idempotent:

    chocolatey  choco installed, from the official bootstrap if missing.
    python3     ~\.local\bin\python3.exe symlinks to the newest Python the py
                launcher knows, and ~\.local\bin precedes WindowsApps (the
                Microsoft Store stub) in the User PATH.
    jq          installed with choco; a winget copy is removed.
    msys        the User MSYS variable contains winsymlinks:nativestrict, so
                Git Bash `ln -s` makes real symlinks instead of copies.
    bats        bats-core, bats-support, bats-assert and bats-file installed
                globally with npm. Reports BATS_LIB_PATH (npm root -g).
    pytest      importable by python3, installed with pip --user if not.
    uv-tools    pre-commit, linode-cli and s3cmd run, as uv tools; dead pipx
                shims and venvs they replace are removed.
    pester      Pester 5 or later installed for the current user.
    winget      winget-managed packages that have an exact Chocolatey
                equivalent are moved to choco (only with -ConvertWinget).
    docker      Docker Desktop installed with choco, and its engine answers.

  Each item reports ok, fixed, FAILED: <reason>, or PENDING: <action> for a
  step only the operator can take (a reboot, a licence prompt). Steps that
  need admin run in one elevated copy of this script, behind a UAC prompt;
  declining it fails those steps and the rest still run. The script exits 1
  if any item failed or is pending.

.PARAMETER ConvertWinget
  Move winget-managed packages with an exact Chocolatey equivalent to choco.
  Without it, the winget item only counts them. Mapping them takes several
  minutes; review it first with -ConvertWinget -WhatIf.

.EXAMPLE
  Install-WindowsPrereqs.ps1 -WhatIf
  Reports what would change, without changing anything.

.EXAMPLE
  Install-WindowsPrereqs.ps1
  Checks every item and fixes the ones that need it.

.EXAMPLE
  Install-WindowsPrereqs.ps1 -ConvertWinget -WhatIf
  Lists each winget package with its Chocolatey equivalent, if any.
#>

[CmdletBinding(SupportsShouldProcess)]
param (
  [switch]$ConvertWinget,

  # The rest are for the elevated copy this script launches of itself.
  [Parameter(DontShow)]
  [string]$ElevatedItem,

  [Parameter(DontShow)]
  [string]$ResultPath,

  [Parameter(DontShow)]
  [string]$ExpectedSid
)

Set-StrictMode -Version Latest

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
    [string[]]$Line = @()
  )

  [pscustomobject]@{ Status = $Status; Detail = $Detail; Lines = @($Line) }
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
  Runs the named items in an elevated copy of this script and returns their
  results.

.DESCRIPTION
  Uses Start-Process -Verb RunAs, as Elevate.ps1 does, but starts this same
  pwsh rather than Windows PowerShell, waits, and reads the results back
  from a file. The copy is passed this account's SID and refuses to change
  anything if UAC elevated it as someone else: the user-scope work after it
  (HKCU, ~\.local\bin, npm -g) assumes the same account and hive.
#>
function Invoke-ElevatedRun {
  [CmdletBinding()]
  [OutputType([pscustomobject])]
  param (
    [Parameter(Mandatory)]
    [string[]]$Name,

    [switch]$ConvertWinget
  )

  $sid = Get-CurrentUserSid
  $resultFile = Join-Path -Path ([IO.Path]::GetTempPath()) -ChildPath "Install-WindowsPrereqs-$PID.json"
  $arguments = @(
    '-NoProfile', '-ExecutionPolicy', 'Bypass', '-File', "`"$PSCommandPath`"",
    '-ElevatedItem', ($Name -join ','), '-ResultPath', "`"$resultFile`"", '-ExpectedSid', $sid
  )
  if ($ConvertWinget) {
    $arguments += '-ConvertWinget'
  }

  $failAll = {
    param($Reason)
    $results = @{}
    foreach ($n in $Name) { $results[$n] = New-StepResult -Status FAILED -Detail $Reason }
    [pscustomobject]@{ Note = $Reason; Results = $results }
  }

  try {
    $process = Start-Process -FilePath (Get-Process -Id $PID).Path -Verb RunAs -Wait -PassThru -ArgumentList $arguments -ErrorAction Stop
  } catch {
    return & $failAll "elevation declined or failed: $($_.Exception.Message)"
  }

  if (-not (Test-Path -LiteralPath $resultFile)) {
    return & $failAll "the elevated run wrote no results (exit $($process.ExitCode))"
  }

  $data = Get-Content -LiteralPath $resultFile -Raw | ConvertFrom-Json
  Remove-Item -LiteralPath $resultFile -Force -WhatIf:$false

  $results = @{}
  foreach ($n in $Name) {
    $r = $data.Results.$n
    $results[$n] = if ($r) {
      New-StepResult -Status $r.Status -Detail $r.Detail -Line @($r.Lines | Where-Object { $_ })
    } else {
      New-StepResult -Status FAILED -Detail 'the elevated run reported nothing for this item'
    }
  }

  $note = if ($data.Sid -eq $sid) {
    "UAC accepted; ran $($Name -join ', ') elevated as this same account (SID verified)"
  } else {
    "UAC elevated a different account ($($data.Sid)); it changed nothing"
  }

  [pscustomobject]@{ Note = $note; Results = $results }
}

<#
.SYNOPSIS
  Reloads this process's PATH from the Machine and User registry values, so
  installs made since the process started are found.
#>
function Sync-ProcessPath {
  [CmdletBinding()]
  param ()

  $machine = [Environment]::GetEnvironmentVariable('Path', 'Machine')
  $user = [Environment]::GetEnvironmentVariable('Path', 'User')
  $env:Path = (@($machine, $user) | Where-Object { $_ }) -join ';'
}

<#
.SYNOPSIS
  Returns a User environment variable's raw value, %VARS% unexpanded, or
  $null when it is unset.
#>
function Get-UserEnvironmentValue {
  [CmdletBinding()]
  [OutputType([string])]
  param (
    [Parameter(Mandatory)]
    [string]$Name
  )

  (Get-Item -Path 'HKCU:\Environment').GetValue($Name, $null, 'DoNotExpandEnvironmentNames')
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
  Writes a User environment variable, keeping the registry value kind it
  already has (the User Path is usually REG_EXPAND_SZ, which
  [Environment]::SetEnvironmentVariable would flatten to REG_SZ).

.DESCRIPTION
  Callers gate this with ShouldProcess; it does not ask again.
#>
function Write-UserEnvironmentValue {
  [CmdletBinding()]
  param (
    [Parameter(Mandatory)]
    [string]$Name,

    [Parameter(Mandatory)]
    [string]$Value
  )

  $key = Get-Item -Path 'HKCU:\Environment'
  $kind = 'String'
  if ($key.GetValueNames() -contains $Name) {
    $kind = $key.GetValueKind($Name).ToString()
  }

  New-ItemProperty -Path 'HKCU:\Environment' -Name $Name -Value $Value -PropertyType $kind -Force | Out-Null
  Send-EnvironmentChange
}

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
  Returns python3's sys.prefix when python3 is a real Python, or $null when
  it is missing or is the Microsoft Store stub.
#>
function Get-Python3Prefix {
  [CmdletBinding()]
  [OutputType([string])]
  param ()

  if (-not (Get-Command -Name python3 -CommandType Application -ErrorAction SilentlyContinue)) {
    return $null
  }

  $prefix = @(python3 -c 'import sys; print(sys.prefix)' 2>$null) | Select-Object -First 1
  if (-not $prefix -or $prefix -like '*\WindowsApps*') {
    return $null
  }

  $prefix.Trim()
}

<#
.SYNOPSIS
  Item python3: symlink ~\.local\bin\python3.exe to the newest Python and
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
    return New-StepResult -Status FAILED -Detail 'the py launcher lists no Python X.Y install (py -0p)'
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

  $status = if ($changed) { 'fixed' } else { 'ok' }
  New-StepResult -Status $status -Detail "sys.prefix $prefix"
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
  Tests whether Chocolatey has a package installed locally.
#>
function Test-ChocoPackage {
  [CmdletBinding()]
  [OutputType([bool])]
  param (
    [Parameter(Mandatory)]
    [string]$Id
  )

  $null -ne (@(choco list $Id --exact --limit-output 2>$null) | Where-Object { $_ -like "$Id|*" } | Select-Object -First 1)
}

<#
.SYNOPSIS
  Installs a Chocolatey package and classifies choco's exit code: '' for
  success, 'reboot' when the installer asked for one, else a failure reason.

.DESCRIPTION
  choco writes straight to the console, progress bar and all, so a long
  install (Docker Desktop is about 1 GB) visibly moves.
#>
function Install-ChocoPackage {
  [CmdletBinding()]
  [OutputType([string])]
  param (
    [Parameter(Mandatory)]
    [string]$Id
  )

  $process = Start-Process -FilePath choco -ArgumentList 'install', $Id, '-y' -NoNewWindow -Wait -PassThru
  switch ($process.ExitCode) {
    0 { '' }
    { $_ -in 1641, 3010 } { 'reboot' }
    default { "choco install $Id exited $($process.ExitCode)" }
  }
}

<#
.SYNOPSIS
  Tests whether winget lists a package as installed.
#>
function Test-WingetPackage {
  [CmdletBinding()]
  [OutputType([bool])]
  param (
    [Parameter(Mandatory)]
    [string]$Id
  )

  $out = @(winget list --id $Id --exact --accept-source-agreements --disable-interactivity 2>$null)
  $null -ne ($out | Where-Object { $_ -match "(^|\s)$([regex]::Escape($Id))(\s|$)" } | Select-Object -First 1)
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
  Item chocolatey: install Chocolatey if choco is missing.
#>
function Install-Chocolatey {
  [CmdletBinding(SupportsShouldProcess)]
  [OutputType([pscustomobject])]
  param ()

  Sync-ProcessPath
  if (Test-Choco) {
    return New-StepResult -Status ok -Detail "choco $(@(choco --version) | Select-Object -First 1)"
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

  New-StepResult -Status fixed -Detail "choco $(@(choco --version) | Select-Object -First 1)"
}

<#
.SYNOPSIS
  Item jq: install jq with choco and remove a winget copy.
#>
function Install-Jq {
  [CmdletBinding(SupportsShouldProcess)]
  [OutputType([pscustomobject])]
  param ()

  Sync-ProcessPath
  if (-not (Test-Choco)) {
    $status = if ($WhatIfPreference) { 'skipped' } else { 'FAILED' }
    return New-StepResult -Status $status -Detail 'needs Chocolatey (the chocolatey item)'
  }

  $changed = $false
  $pending = [System.Collections.Generic.List[string]]::new()

  if (-not (Test-ChocoPackage -Id jq)) {
    if (-not $PSCmdlet.ShouldProcess('jq', 'choco install')) {
      $pending.Add('choco install jq (needs admin)')
    } elseif (-not (Test-Elevated)) {
      return New-StepResult -Status 'needs admin' -Detail 'choco install jq'
    } else {
      $outcome = Install-ChocoPackage -Id jq
      if ($outcome -and $outcome -ne 'reboot') {
        return New-StepResult -Status FAILED -Detail $outcome
      }

      $changed = $true
    }
  }

  # Only once choco's copy is in, so jq is never missing in between.
  if ($pending.Count -eq 0 -and (Test-WingetPackage -Id jqlang.jq)) {
    if ($PSCmdlet.ShouldProcess('jqlang.jq', 'winget uninstall')) {
      winget uninstall --id jqlang.jq --exact --source winget --accept-source-agreements --disable-interactivity | Out-Null
      $changed = $true
    } else {
      $pending.Add('winget uninstall jqlang.jq')
    }
  } elseif ($pending.Count -gt 0) {
    $pending.Add('then winget uninstall jqlang.jq if present')
  }

  if ($pending.Count -gt 0) {
    return New-StepResult -Status 'would fix' -Detail ($pending -join '; ')
  }

  Sync-ProcessPath
  $jq = Get-Command -Name jq -CommandType Application -ErrorAction SilentlyContinue | Select-Object -First 1
  if (-not $jq) {
    return New-StepResult -Status FAILED -Detail 'jq not on PATH'
  }

  if ($jq.Source -notlike "$env:ProgramData\chocolatey\*") {
    return New-StepResult -Status FAILED -Detail "jq resolves to $($jq.Source), not Chocolatey's"
  }

  $status = if ($changed) { 'fixed' } else { 'ok' }
  New-StepResult -Status $status -Detail $jq.Source
}

<#
.SYNOPSIS
  Item msys: add winsymlinks:nativestrict to the User MSYS variable, keeping
  its other tokens.
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
  Returns the `bats --version` line as Git Bash sees it, or $null.

.DESCRIPTION
  bats runs under Git Bash. From PowerShell, npm's bats shim would run the
  first bash on PATH, which on this kind of machine is WSL's.
#>
function Get-BatsVersion {
  [CmdletBinding()]
  [OutputType([string])]
  param (
    [Parameter(Mandatory)]
    [string]$Bash
  )

  $line = @(& $Bash -c 'bats --version' 2>$null) | Select-Object -First 1
  if ($line -notmatch '^Bats \d') {
    return $null
  }

  $line
}

<#
.SYNOPSIS
  Runs npm with the given arguments.

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
  Item bats: install bats-core and its helper libraries globally with npm.
#>
function Install-BatsToolchain {
  [CmdletBinding(SupportsShouldProcess)]
  [OutputType([pscustomobject])]
  param ()

  Sync-ProcessPath
  if (-not (Get-Command -Name npm -ErrorAction SilentlyContinue)) {
    return New-StepResult -Status FAILED -Detail 'npm not found; install Node.js'
  }

  $bash = Get-GitBash
  if (-not $bash) {
    return New-StepResult -Status FAILED -Detail 'Git Bash (bin\bash.exe beside git.exe) not found'
  }

  $root = @(Invoke-Npm -ArgumentList root, -g) | Select-Object -First 1
  $missing = [System.Collections.Generic.List[string]]::new()
  if (-not (Get-BatsVersion -Bash $bash)) {
    $missing.Add('bats')
  }

  foreach ($lib in 'bats-support', 'bats-assert', 'bats-file') {
    if (-not (Test-Path -LiteralPath (Join-Path -Path $root -ChildPath "$lib\load.bash"))) {
      $missing.Add($lib)
    }
  }

  if ($missing.Count -eq 0) {
    return New-StepResult -Status ok -Detail "$(Get-BatsVersion -Bash $bash); BATS_LIB_PATH=$root"
  }

  # bats-core never published bats-file to npm (its package.json is
  # private); the registry's bats-file is a security placeholder with no
  # code. Install it from the project's repository, the way bats-core's
  # shared docs install their libraries with npm.
  $specs = @($missing | ForEach-Object {
      if ($_ -eq 'bats-file') { 'github:bats-core/bats-file' } else { $_ }
    })

  if (-not $PSCmdlet.ShouldProcess(($missing -join ', '), 'npm install -g')) {
    return New-StepResult -Status 'would fix' -Detail "npm install -g $($specs -join ' '); BATS_LIB_PATH=$root"
  }

  Invoke-Npm -ArgumentList (@('install', '-g') + $specs) | Out-Null
  $exitCode = $LASTEXITCODE

  Sync-ProcessPath
  $version = Get-BatsVersion -Bash $bash
  $still = @($missing | Where-Object {
      if ($_ -eq 'bats') { -not $version } else { -not (Test-Path -LiteralPath (Join-Path -Path $root -ChildPath "$_\load.bash")) }
    })

  if ($still.Count -gt 0) {
    return New-StepResult -Status FAILED -Detail "still missing after npm install -g (exit $exitCode): $($still -join ', ')"
  }

  New-StepResult -Status fixed -Detail "$version; BATS_LIB_PATH=$root"
}

<#
.SYNOPSIS
  Returns the `python3 -m pytest --version` line, or $null.
#>
function Get-PytestVersion {
  [CmdletBinding()]
  [OutputType([string])]
  param ()

  $line = @(python3 -m pytest --version 2>&1) | ForEach-Object { "$_" } | Where-Object { $_ -match '^pytest \d' } | Select-Object -First 1
  $line
}

<#
.SYNOPSIS
  Item pytest: install pytest for python3 with pip --user.
#>
function Install-Pytest {
  [CmdletBinding(SupportsShouldProcess)]
  [OutputType([pscustomobject])]
  param ()

  Sync-ProcessPath
  if (-not (Get-Python3Prefix)) {
    if ($WhatIfPreference) {
      return New-StepResult -Status skipped -Detail 'checked once python3 is fixed'
    }

    return New-StepResult -Status FAILED -Detail 'python3 does not resolve to a real Python'
  }

  $version = Get-PytestVersion
  if ($version) {
    return New-StepResult -Status ok -Detail $version
  }

  if (-not $PSCmdlet.ShouldProcess('pytest', 'python3 -m pip install --user')) {
    return New-StepResult -Status 'would fix' -Detail 'python3 -m pip install --user pytest'
  }

  python3 -m pip install --user pytest 2>&1 | Out-Null
  $exitCode = $LASTEXITCODE

  $version = Get-PytestVersion
  if (-not $version) {
    return New-StepResult -Status FAILED -Detail "pytest still not importable after pip install (exit $exitCode)"
  }

  New-StepResult -Status fixed -Detail $version
}

<#
.SYNOPSIS
  Returns a tool's `--version` line, or $null when it does not run.

.DESCRIPTION
  An .exe runs directly. Anything else is a Python script (s3cmd), run with
  the interpreter its #! line names, since Windows cannot run it by name.
  stdin is closed: s3cmd waits on it when there is no console.
#>
function Get-ToolVersion {
  [CmdletBinding()]
  [OutputType([string])]
  param (
    [Parameter(Mandatory)]
    [string]$Path
  )

  if (-not (Test-Path -LiteralPath $Path)) {
    return $null
  }

  if ($Path -like '*.exe') {
    $out = @('' | & $Path --version 2>$null)
  } else {
    $shebang = Get-Content -LiteralPath $Path -TotalCount 1
    if ($shebang -notmatch '^#!(.+)$') {
      return $null
    }

    $python = $Matches[1].Trim()
    if (-not (Test-Path -LiteralPath $python)) {
      return $null
    }

    $out = @('' | & $python $Path --version 2>$null)
  }

  if ($LASTEXITCODE -ne 0) {
    return $null
  }

  $out | Where-Object { $_ } | Select-Object -First 1
}

<#
.SYNOPSIS
  Item uv-tools: pre-commit, linode-cli and s3cmd installed as uv tools,
  replacing their dead pipx installs.
#>
function Repair-UvTool {
  [CmdletBinding(SupportsShouldProcess)]
  [OutputType([pscustomobject])]
  param ()

  # Package -> the executable to check, in uv's tool bin directory.
  $tools = [ordered]@{
    'pre-commit' = 'pre-commit.exe'
    'linode-cli' = 'linode-cli.exe'
    's3cmd'      = 's3cmd'
  }

  Sync-ProcessPath
  if (-not (Get-Command -Name uv -CommandType Application -ErrorAction SilentlyContinue)) {
    return New-StepResult -Status FAILED -Detail 'uv not found'
  }

  $bin = @(uv tool dir --bin) | Select-Object -First 1
  $changed = $false
  $failed = [System.Collections.Generic.List[string]]::new()
  $pending = [System.Collections.Generic.List[string]]::new()
  $versions = [System.Collections.Generic.List[string]]::new()

  foreach ($tool in $tools.Keys) {
    $exe = Join-Path -Path $bin -ChildPath $tools[$tool]
    $version = Get-ToolVersion -Path $exe
    if ($version) {
      $versions.Add($version)
      continue
    }

    if (-not $PSCmdlet.ShouldProcess($tool, 'Remove dead pipx install; uv tool install')) {
      $pending.Add("uv tool install $tool")
      continue
    }

    # pipx's shims share uv's bin directory (~\.local\bin), so they have to
    # go before uv can put its own executables there.
    $venv = Join-Path -Path $HOME -ChildPath "pipx\venvs\$tool"
    Get-ChildItem -LiteralPath $bin -Force -ErrorAction SilentlyContinue |
      Where-Object { $_.LinkType -eq 'SymbolicLink' -and "$($_.Target)" -like "$venv\*" } |
      ForEach-Object { Remove-Item -LiteralPath $_.FullName -Force }
    if (Test-Path -LiteralPath $venv) {
      Remove-Item -LiteralPath $venv -Recurse -Force
    }

    uv tool install --force $tool 2>&1 | Out-Null
    $version = Get-ToolVersion -Path $exe
    if ($version) {
      $versions.Add($version)
      $changed = $true
    } else {
      $failed.Add("$tool (uv tool install exit $LASTEXITCODE)")
    }
  }

  if ($failed.Count -gt 0) {
    return New-StepResult -Status FAILED -Detail "does not run after uv tool install: $($failed -join ', ')"
  }

  if ($pending.Count -gt 0) {
    return New-StepResult -Status 'would fix' -Detail ($pending -join '; ')
  }

  $status = if ($changed) { 'fixed' } else { 'ok' }
  New-StepResult -Status $status -Detail ($versions -join '; ')
}

<#
.SYNOPSIS
  Returns the newest Pester 5 or later that is installed, or $null.
#>
function Get-Pester5 {
  [CmdletBinding()]
  [OutputType([psmoduleinfo])]
  param ()

  Get-Module -ListAvailable -Name Pester |
    Where-Object { $_.Version -ge [version]'5.0' } |
    Sort-Object -Property Version -Descending |
    Select-Object -First 1
}

<#
.SYNOPSIS
  Item pester: install Pester 5 or later for the current user, beside the
  in-box Pester 3.4.
#>
function Install-Pester {
  [CmdletBinding(SupportsShouldProcess)]
  [OutputType([pscustomobject])]
  param ()

  $pester = Get-Pester5
  if ($pester) {
    return New-StepResult -Status ok -Detail "Pester $($pester.Version)"
  }

  if (-not $PSCmdlet.ShouldProcess('Pester', 'Install-Module -Scope CurrentUser')) {
    return New-StepResult -Status 'would fix' -Detail 'Install-Module Pester -Scope CurrentUser'
  }

  # -SkipPublisherCheck: the in-box 3.4 is signed by Microsoft and Pester 5
  # is not, which Install-Module otherwise refuses.
  Install-Module -Name Pester -MinimumVersion 5.0 -Scope CurrentUser -Repository PSGallery -Force -SkipPublisherCheck
  $pester = Get-Pester5
  if (-not $pester) {
    return New-StepResult -Status FAILED -Detail 'Pester 5 still not available after Install-Module'
  }

  New-StepResult -Status fixed -Detail "Pester $($pester.Version)"
}

<#
.SYNOPSIS
  Returns the packages winget manages: the ones `winget export` can tie to
  the winget or msstore source, not entries it only detects.
#>
function Get-WingetManagedPackage {
  [CmdletBinding()]
  [OutputType([pscustomobject])]
  param ()

  $file = Join-Path -Path ([IO.Path]::GetTempPath()) -ChildPath "winget-export-$PID.json"
  winget export --output $file --accept-source-agreements --disable-interactivity 2>&1 | Out-Null
  if (-not (Test-Path -LiteralPath $file)) {
    throw 'winget export wrote nothing'
  }

  $export = Get-Content -LiteralPath $file -Raw | ConvertFrom-Json
  # A scratch file: removed even under -WhatIf.
  Remove-Item -LiteralPath $file -Force -WhatIf:$false

  foreach ($source in $export.Sources) {
    $sourceName = $source.SourceDetails.Name
    if ($sourceName -in 'winget', 'msstore') {
      foreach ($package in $source.Packages) {
        [pscustomobject]@{ Id = $package.PackageIdentifier; Source = $sourceName }
      }
    }
  }
}

<#
.SYNOPSIS
  Returns a winget package's name, moniker and homepage from `winget show`.
#>
function Get-WingetPackageInfo {
  [CmdletBinding()]
  [OutputType([pscustomobject])]
  param (
    [Parameter(Mandatory)]
    [string]$Id,

    [Parameter(Mandatory)]
    [string]$Source
  )

  $info = [pscustomobject]@{ Name = ''; Moniker = ''; Homepage = '' }
  foreach ($line in @(winget show --id $Id --exact --source $Source --accept-source-agreements --disable-interactivity 2>$null)) {
    if ($line -match '^Found (.+) \[.+\]$') {
      $info.Name = $Matches[1].Trim()
    } elseif ($line -match '^Moniker:\s*(\S+)') {
      $info.Moniker = $Matches[1]
    } elseif ($line -match '^Homepage:\s*(\S+)') {
      $info.Homepage = $Matches[1]
    }
  }

  $info
}

<#
.SYNOPSIS
  Tests whether the Chocolatey community repository has a package with
  exactly this id.
#>
function Test-ChocoRemotePackage {
  [CmdletBinding()]
  [OutputType([bool])]
  param (
    [Parameter(Mandatory)]
    [string]$Id
  )

  $null -ne (@(choco search $Id --exact --limit-output 2>$null) | Where-Object { $_ -like "$Id|*" } | Select-Object -First 1)
}

<#
.SYNOPSIS
  Returns a Chocolatey package's Software Site and Software Source URLs.
#>
function Get-ChocoPackageSite {
  [CmdletBinding()]
  [OutputType([string])]
  param (
    [Parameter(Mandatory)]
    [string]$Id
  )

  foreach ($line in @(choco info $Id 2>$null)) {
    if ($line -match '^\s*Software (Site|Source):\s*(\S+)') {
      $Matches[2]
    }
  }
}

<#
.SYNOPSIS
  Tests whether two URLs point at the same project: the same host, and on a
  code host (GitHub and the like) the same owner/repository too.
#>
function Test-SameSite {
  [CmdletBinding()]
  [OutputType([bool])]
  param (
    [string]$Uri,
    [string]$OtherUri
  )

  $a = $null
  $b = $null
  if (-not [Uri]::TryCreate($Uri, 'Absolute', [ref]$a) -or -not [Uri]::TryCreate($OtherUri, 'Absolute', [ref]$b)) {
    return $false
  }

  $hostA = $a.Host.ToLowerInvariant() -replace '^www\.', ''
  $hostB = $b.Host.ToLowerInvariant() -replace '^www\.', ''
  if ($hostA -ne $hostB) {
    return $false
  }

  if ($hostA -notin 'github.com', 'gitlab.com', 'sourceforge.net', 'codeberg.org', 'bitbucket.org') {
    return $true
  }

  $repoA = (@($a.AbsolutePath.Trim('/') -split '/') | Select-Object -First 2) -join '/'
  $repoB = (@($b.AbsolutePath.Trim('/') -split '/') | Select-Object -First 2) -join '/'
  $repoA -and $repoA -eq $repoB
}

<#
.SYNOPSIS
  Maps one winget package to its Chocolatey equivalent, if it has one.

.DESCRIPTION
  Nothing is guessed. Candidate ids come from the winget moniker, id and
  name; each is looked up exactly in the community repository. A candidate
  counts only when its Software Site or Source is the winget homepage's
  project. One such candidate is a match; several are ambiguous; a name hit
  without a homepage match is low confidence. Only a match is converted,
  and only if Chocolatey does not already own the software (winget also
  lists what choco installed, and uninstalling that would remove it).
#>
function Resolve-ChocoEquivalent {
  [CmdletBinding()]
  [OutputType([pscustomobject])]
  param (
    [Parameter(Mandatory)]
    [pscustomobject]$Package,

    [Parameter(Mandatory)]
    [AllowEmptyCollection()]
    [string[]]$LocalChoco
  )

  $row = [pscustomobject]@{
    WingetId = $Package.Id; Source = $Package.Source; ChocoId = ''; Confidence = ''; Action = ''
  }

  if ($Package.Id -eq 'Microsoft.AppInstaller') {
    $row.Action = 'keep: this is winget itself'
    return $row
  }

  $info = Get-WingetPackageInfo -Id $Package.Id -Source $Package.Source
  $segments = @($Package.Id -split '\.')
  $candidates = @(
    $info.Moniker
    $segments[-1]
    ($segments | Select-Object -Skip 1) -join '-'
    $info.Name -replace '\s+', '-'
    $info.Name -replace '\s+', ''
  ) | ForEach-Object { "$_".ToLowerInvariant() } |
    Where-Object { $_ -match '^[a-z0-9][a-z0-9._-]*$' } |
    Select-Object -Unique

  $found = @($candidates | Where-Object { Test-ChocoRemotePackage -Id $_ })
  if ($found.Count -eq 0) {
    $row.Action = 'keep on winget: no choco equivalent'
    return $row
  }

  $matched = @($found | Where-Object {
      $id = $_
      $info.Homepage -and @(Get-ChocoPackageSite -Id $id | Where-Object { Test-SameSite -Uri $_ -OtherUri $info.Homepage }).Count -gt 0
    })

  $owned = @(@($matched) + @($found) | Where-Object { $LocalChoco -contains $_ } | Select-Object -First 1)
  if ($owned.Count -gt 0) {
    $row.ChocoId = $owned[0]
    $row.Confidence = if ($matched -contains $owned[0]) { 'exact id + same homepage' } else { 'exact id, name only' }
    $row.Action = 'skip: already installed by choco'
    return $row
  }

  if ($matched.Count -eq 1) {
    $row.ChocoId = $matched[0]
    $row.Confidence = 'exact id + same homepage'
    $row.Action = 'convert'
  } elseif ($matched.Count -gt 1) {
    $row.ChocoId = $matched -join ' | '
    $row.Confidence = 'ambiguous'
    $row.Action = 'keep on winget: ambiguous'
  } else {
    $row.ChocoId = $found -join ' | '
    $row.Confidence = 'exact id, name only (homepage differs or missing)'
    $row.Action = 'keep on winget: low confidence'
  }

  $row
}

<#
.SYNOPSIS
  Item winget: move winget-managed packages that have an exact Chocolatey
  equivalent to choco. Only maps and converts with -Convert.

.DESCRIPTION
  Each conversion uninstalls the winget copy first and then installs the
  choco one: both usually drive the same vendor installer and share one
  Add/Remove Programs entry, so uninstalling after the choco install would
  remove what choco had just installed. If the choco install fails, the
  winget package is put back.
#>
function Convert-WingetPackage {
  [CmdletBinding(SupportsShouldProcess)]
  [OutputType([pscustomobject])]
  param (
    [switch]$Convert
  )

  Sync-ProcessPath
  if (-not (Get-Command -Name winget -CommandType Application -ErrorAction SilentlyContinue)) {
    return New-StepResult -Status ok -Detail 'winget not installed; nothing to convert'
  }

  if (-not (Test-Choco)) {
    $status = if ($WhatIfPreference) { 'skipped' } else { 'FAILED' }
    return New-StepResult -Status $status -Detail 'needs Chocolatey (the chocolatey item)'
  }

  $packages = @(Get-WingetManagedPackage)
  if (-not $Convert) {
    return New-StepResult -Status skipped -Detail "$($packages.Count) winget-managed packages; map and convert them with -ConvertWinget"
  }

  $localChoco = @(@(choco list --limit-output 2>$null) | ForEach-Object { ($_ -split '\|')[0].ToLowerInvariant() })
  $rows = @($packages | ForEach-Object { Resolve-ChocoEquivalent -Package $_ -LocalChoco $localChoco })

  # Several winget packages on one choco id (WindowsAppRuntime 1.0 and 1.2
  # both -> windows-app-sdk) are not each other's equivalent: keep them all.
  $rows | Where-Object { $_.Action -eq 'convert' } | Group-Object -Property ChocoId |
    Where-Object { $_.Count -gt 1 } | ForEach-Object {
      foreach ($shared in $_.Group) {
        $shared.Confidence = 'ambiguous'
        $shared.Action = "keep on winget: $($_.Count) winget packages map to $($_.Name)"
      }
    }

  $toConvert = @($rows | Where-Object { $_.Action -eq 'convert' })

  if ($toConvert.Count -gt 0 -and -not $WhatIfPreference -and -not (Test-Elevated)) {
    return New-StepResult -Status 'needs admin' -Detail "convert $($toConvert.Count) packages"
  }

  $converted = 0
  $failures = 0
  foreach ($row in $toConvert) {
    if (-not $PSCmdlet.ShouldProcess($row.WingetId, "winget uninstall, then choco install $($row.ChocoId)")) {
      continue
    }

    winget uninstall --id $row.WingetId --exact --source $row.Source --silent --accept-source-agreements --disable-interactivity | Out-Null
    if ($LASTEXITCODE -ne 0) {
      $row.Action = "FAILED: winget uninstall exited $LASTEXITCODE; left on winget"
      $failures++
      continue
    }

    $outcome = Install-ChocoPackage -Id $row.ChocoId
    if ($outcome -and $outcome -ne 'reboot') {
      winget install --id $row.WingetId --exact --source $row.Source --silent --accept-package-agreements --accept-source-agreements --disable-interactivity | Out-Null
      $row.Action = "FAILED: $outcome; reinstalled from winget (exit $LASTEXITCODE)"
      $failures++
      continue
    }

    $row.Action = if ($outcome -eq 'reboot') { 'converted (reboot requested)' } else { 'converted' }
    $converted++
  }

  $table = @($rows | ForEach-Object {
      $choco = if ($_.ChocoId) { $_.ChocoId } else { '-' }
      $confidence = if ($_.Confidence) { " [$($_.Confidence)]" } else { '' }
      "$($_.WingetId) -> $choco$confidence : $($_.Action)"
    })

  $summary = "$($packages.Count) winget-managed, $($toConvert.Count) convertible, $converted converted"
  if ($failures -gt 0) {
    return New-StepResult -Status FAILED -Detail "$summary, $failures failed" -Line $table
  }

  if ($WhatIfPreference -and $toConvert.Count -gt 0) {
    return New-StepResult -Status 'would fix' -Detail $summary -Line $table
  }

  $status = if ($converted -gt 0) { 'fixed' } else { 'ok' }
  New-StepResult -Status $status -Detail $summary -Line $table
}

<#
.SYNOPSIS
  Returns the Docker engine's version, or $null when no engine answers.
#>
function Get-DockerServerVersion {
  [CmdletBinding()]
  [OutputType([string])]
  param ()

  if (-not (Get-Command -Name docker -CommandType Application -ErrorAction SilentlyContinue)) {
    return $null
  }

  $version = @(docker version --format '{{.Server.Version}}' 2>$null) | Select-Object -First 1
  if ($LASTEXITCODE -ne 0 -or -not $version) {
    return $null
  }

  $version
}

<#
.SYNOPSIS
  Tests whether WSL is installed (`wsl --status` succeeds).
#>
function Test-Wsl {
  [CmdletBinding()]
  [OutputType([bool])]
  param ()

  wsl.exe --status *> $null
  $LASTEXITCODE -eq 0
}

<#
.SYNOPSIS
  Item docker: Docker Desktop installed with choco, on WSL2, with an engine
  that answers `docker version`.

.DESCRIPTION
  A reboot, the first-launch licence prompt or a WSL install the operator
  must finish are reported as PENDING rather than waited on. Docker Desktop
  is started unelevated, and the engine is given a few minutes to come up.
#>
function Install-DockerDesktop {
  [CmdletBinding(SupportsShouldProcess)]
  [OutputType([pscustomobject])]
  param ()

  $desktop = Join-Path -Path $env:ProgramFiles -ChildPath 'Docker\Docker\Docker Desktop.exe'

  Sync-ProcessPath
  $engine = Get-DockerServerVersion
  if ($engine) {
    return New-StepResult -Status ok -Detail "engine $engine"
  }

  if (-not (Test-Choco)) {
    $status = if ($WhatIfPreference) { 'skipped' } else { 'FAILED' }
    return New-StepResult -Status $status -Detail 'needs Chocolatey (the chocolatey item)'
  }

  if (-not (Test-Wsl)) {
    if (-not $PSCmdlet.ShouldProcess('WSL', 'wsl --install --no-distribution')) {
      return New-StepResult -Status 'would fix' -Detail 'install WSL (needs admin and a reboot), then Docker Desktop'
    }

    if (-not (Test-Elevated)) {
      return New-StepResult -Status 'needs admin' -Detail 'install WSL'
    }

    wsl.exe --install --no-distribution | Out-Null
    return New-StepResult -Status PENDING -Detail 'WSL installed; reboot, then rerun to install Docker Desktop'
  }

  if (-not (Test-ChocoPackage -Id docker-desktop) -and -not (Test-Path -LiteralPath $desktop)) {
    if (-not $PSCmdlet.ShouldProcess('docker-desktop', 'choco install')) {
      return New-StepResult -Status 'would fix' -Detail 'choco install docker-desktop (needs admin), then start it'
    }

    if (-not (Test-Elevated)) {
      return New-StepResult -Status 'needs admin' -Detail 'choco install docker-desktop'
    }

    $outcome = Install-ChocoPackage -Id docker-desktop
    if ($outcome -eq 'reboot') {
      return New-StepResult -Status PENDING -Detail 'Docker Desktop installed; reboot, then rerun'
    }

    if ($outcome) {
      return New-StepResult -Status FAILED -Detail $outcome
    }
  }

  # Started elevated, Docker Desktop would run as admin; the unelevated
  # run after this one starts it instead.
  if (Test-Elevated) {
    return New-StepResult -Status fixed -Detail 'Docker Desktop installed; the unelevated run starts it'
  }

  if (-not $PSCmdlet.ShouldProcess('Docker Desktop', 'Start and wait for the engine')) {
    return New-StepResult -Status 'would fix' -Detail 'start Docker Desktop'
  }

  if (-not (Get-Process -Name 'Docker Desktop' -ErrorAction SilentlyContinue)) {
    Start-Process -FilePath $desktop
  }

  $deadline = (Get-Date).AddMinutes(3)
  while (-not $engine -and (Get-Date) -lt $deadline) {
    Start-Sleep -Seconds 5
    Sync-ProcessPath
    $engine = Get-DockerServerVersion
  }

  if (-not $engine) {
    return New-StepResult -Status PENDING -Detail 'Docker Desktop is running but its engine is not up; finish its first-launch steps (accept the Docker Subscription Service Agreement; sign out and in if it asks), then rerun'
  }

  New-StepResult -Status fixed -Detail "engine $engine"
}

<#
.SYNOPSIS
  The elevated copy's run: says what it is and what it is doing at each
  step, runs the steps, and writes their results for the unelevated run.

.DESCRIPTION
  Its window is the only thing the operator sees while it works, so every
  step is announced before it starts, long ones with a warning, and a
  summary closes it, followed by the window-close wait.
#>
function Invoke-ElevatedItem {
  [CmdletBinding()]
  [OutputType([string])]
  param (
    [Parameter(Mandatory)]
    [string[]]$Name,

    [Parameter(Mandatory)]
    [System.Collections.IDictionary]$Step,

    [Parameter(Mandatory)]
    [string]$ExpectedSid,

    [Parameter(Mandatory)]
    [string]$ResultPath
  )

  $announce = @{
    chocolatey = 'installing Chocolatey from community.chocolatey.org'
    jq         = 'installing jq via choco, then removing the winget copy'
    winget     = 'moving winget packages to choco (winget uninstall, then choco install, one at a time)'
    docker     = 'downloading Docker Desktop (~1 GB) via choco - this can take 20+ minutes'
  }

  Write-Output 'Install-WindowsPrereqs.ps1 - elevated part'
  Write-Output 'Launched by Install-WindowsPrereqs.ps1 to run the steps that need admin;'
  Write-Output 'that window waits for this one and reports the results.'
  Write-Output "Admin steps: $($Name -join ', ')"
  Write-Output ''

  $sid = Get-CurrentUserSid
  $results = [ordered]@{}
  foreach ($n in $Name) {
    $what = if ($announce.Contains($n)) { $announce[$n] } else { 'running' }
    Write-Output "[$n] $what..."

    $results[$n] = if ($sid -ne $ExpectedSid) {
      New-StepResult -Status FAILED -Detail 'elevated as a different account; nothing changed'
    } elseif (-not (Test-Elevated)) {
      New-StepResult -Status FAILED -Detail 'the elevated copy is not elevated'
    } else {
      Invoke-PrereqStep -Step $Step[$n]
    }

    Format-StepResult -Name $n -Result $results[$n]
  }

  [pscustomobject]@{ Sid = $sid; Results = $results } |
    ConvertTo-Json -Depth 5 | Set-Content -LiteralPath $ResultPath -Encoding utf8 -WhatIf:$false

  Write-Output ''
  Write-Output 'Summary:'
  foreach ($n in $Name) {
    Write-Output "  ${n}: $($results[$n].Status)"
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
  Write-Output "done - this window will close in $seconds seconds"
  Start-Sleep -Seconds $seconds
}

# Dot-sourcing (the Pester tests) loads the functions without running them.
if ($MyInvocation.InvocationName -ne '.') {
  $steps = [ordered]@{
    chocolatey = { Install-Chocolatey }
    python3    = { Repair-Python3 }
    jq         = { Install-Jq }
    msys       = { Set-MsysSymlinkMode }
    bats       = { Install-BatsToolchain }
    pytest     = { Install-Pytest }
    'uv-tools' = { Repair-UvTool }
    pester     = { Install-Pester }
    winget     = { Convert-WingetPackage -Convert:$ConvertWinget }
    docker     = { Install-DockerDesktop }
  }

  # The elevated copy: run only the items asked for, report back, stop.
  if ($ElevatedItem) {
    $Host.UI.RawUI.WindowTitle = 'Install-WindowsPrereqs (elevated)'
    Invoke-ElevatedItem -Name ($ElevatedItem -split ',') -Step $steps -ExpectedSid $ExpectedSid -ResultPath $ResultPath
    exit 0
  }

  $results = [ordered]@{}
  foreach ($name in $steps.Keys) {
    $results[$name] = Invoke-PrereqStep -Step $steps[$name]
    Format-StepResult -Name $name -Result $results[$name]
  }

  $admin = @($results.Keys | Where-Object { $results[$_].Status -eq 'needs admin' })
  if ($admin.Count -gt 0) {
    $elevated = Invoke-ElevatedRun -Name $admin -ConvertWinget:$ConvertWinget
    Write-Output "elevation: $($elevated.Note)"

    # Rerun each unelevated, to verify and finish the user-scope part
    # (removing jq's winget copy, starting Docker Desktop).
    foreach ($name in $admin) {
      $fromAdmin = $elevated.Results[$name]
      $final = $fromAdmin
      if ($fromAdmin.Status -notin 'FAILED', 'PENDING') {
        $final = Invoke-PrereqStep -Step $steps[$name]
        if ($final.Status -eq 'needs admin') {
          $final = New-StepResult -Status FAILED -Detail "still needs admin after the elevated run ($($fromAdmin.Detail))"
        } elseif ($final.Status -eq 'ok' -and $fromAdmin.Status -eq 'fixed') {
          $final.Status = 'fixed'
        }
      }

      $results[$name] = $final
      Format-StepResult -Name $name -Result $final
    }
  }

  $bad = @($results.Values | Where-Object { $_.Status -in 'FAILED', 'PENDING' })
  exit [int]($bad.Count -gt 0)
}

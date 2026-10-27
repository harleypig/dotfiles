# Set for every session, as bash does; only grep reads it.
$env:GREP_COLORS = 'mt=1;33'

if (-not $DOTFILES_INTERACTIVE) {
  return
}

##############################################################################
function Global:Set-ParentDirectory {
  param (
    [int]$levels = 1
  )

  for ($i = 0; $i -lt $levels; $i++) {
    Set-Location -Path ..
  }
}

function Global:Set-UpTwoLevels { Set-ParentDirectory -levels 2 }
function Global:Set-UpThreeLevels { Set-ParentDirectory -levels 3 }

function Global:Get-PathEntry {
  <#
  .SYNOPSIS
  Writes each PATH entry on its own line, split on the platform's own
  separator: ';' on Windows, ':' elsewhere.
  #>
  [OutputType([string])]
  param ()

  $env:PATH -split [IO.Path]::PathSeparator
}

##############################################################################
Set-Alias -Scope Global -Name c -Value Clear-Host
Set-Alias -Scope Global -Name h -Value Get-History
Set-Alias -Scope Global -Name l -Value Get-ChildItem
Set-Alias -Scope Global -Name dumppath -Value Get-PathEntry

Set-Alias -Scope Global -Name .. -Value Set-ParentDirectory
Set-Alias -Scope Global -Name ... -Value Set-UpTwoLevels
Set-Alias -Scope Global -Name .... -Value Set-UpThreeLevels

##############################################################################
# grep and diff, mirroring config/shell-startup/010-general. An alias cannot
# carry arguments, so each one with flags is a function plus an alias to it.
# Each is defined only where its external tool is on PATH, which Windows
# lacks by default, and the functions call that tool as an Application so
# an alias never resolves back to itself.

function Global:Get-ExternalCommand {
  <#
  .SYNOPSIS
  Returns the first executable on PATH named Name, or nothing. Ignore, not
  SilentlyContinue, so a miss leaves no record in $Error for the prompt to
  read as a failed command.
  #>
  [OutputType([System.Management.Automation.ApplicationInfo])]
  param ([string]$Name)

  Get-Command -Name $Name -CommandType Application -TotalCount 1 `
    -ErrorAction Ignore
}

if (Get-ExternalCommand -Name grep) {
  function Global:Invoke-Grep {
    <#
    .SYNOPSIS
    Runs the external grep with --color=auto, passing every argument and
    any pipeline input through.
    #>
    $grep = Get-ExternalCommand -Name grep

    if ($MyInvocation.ExpectingInput) {
      $input | & $grep --color=auto @args
    } else {
      & $grep --color=auto @args
    }
  }

  Set-Alias -Scope Global -Name grep -Value Invoke-Grep
  Set-Alias -Scope Global -Name g -Value Invoke-Grep
}

if ((Get-ExternalCommand -Name colordiff) -or
    (Get-ExternalCommand -Name diff)) {
  function Global:Compare-Directory {
    <#
    .SYNOPSIS
    Reports which files differ between two directory trees: colordiff -qr,
    or diff -qr without colordiff, passing every argument through.
    #>
    $diff = Get-ExternalCommand -Name colordiff

    if (-not $diff) {
      $diff = Get-ExternalCommand -Name diff
    }

    & $diff -qr @args
  }

  Set-Alias -Scope Global -Name diffdir -Value Compare-Directory
}

# On Windows diff is a built-in alias for Compare-Object, and it is kept:
# that is what diff means to PowerShell there. So colordiff takes the name
# only where nothing else holds it, as on Linux and macOS.
if ((Get-ExternalCommand -Name colordiff) -and
    -not (Get-Alias -Name diff -ErrorAction Ignore)) {
  Set-Alias -Scope Global -Name diff -Value colordiff
}

#: #-----------------------------------------------------------------------------
# History, mirroring the bash HIST* settings in
# config/shell-startup/010-general. Without XDG_STATE_HOME (e.g. on Windows)
# PSReadLine keeps its own default save path.
if (Get-Command Set-PSReadLineOption -ErrorAction SilentlyContinue) {
  if ($env:XDG_STATE_HOME) {
    $historyDir = Join-Path $env:XDG_STATE_HOME 'powershell'
    New-Item -ItemType Directory -Force -Path $historyDir | Out-Null
    Set-PSReadLineOption -HistorySavePath (Join-Path $historyDir 'history')
    Remove-Variable historyDir
  }

  Set-PSReadLineOption -HistoryNoDuplicates -MaximumHistoryCount 100000

  # bash's ignorespace plus its HISTIGNORE words, matched as whole lines.
  Set-PSReadLineOption -AddToHistoryHandler {
    param([string]$line)
    if ($line -match '^\s') { return $false }
    return $line.Trim() -notin @('exit', 'ls', 'bg', 'fg', 'history', 'clear')
  }
}

#: #-----------------------------------------------------------------------------
# XXX: ...
#: # See inputrc for macros
#: #run-help() { help "$READLINE_LINE" 2>/dev/null || man "$READLINE_LINE"; }

#: #-----------------------------------------------------------------------------
# XXX: How do we do or mimic bash-completions?

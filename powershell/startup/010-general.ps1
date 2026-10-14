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

function dumppath { $env:PATH -split ';' | ForEach-Object { Write-Output $_ } }

##############################################################################
Set-Alias -Scope Global -Name c -Value Clear-Host
Set-Alias -Scope Global -Name h -Value Get-History
Set-Alias -Scope Global -Name l -Value Get-ChildItem

Set-Alias -Scope Global -Name .. -Value Set-ParentDirectory
Set-Alias -Scope Global -Name ... -Value Set-UpTwoLevels
Set-Alias -Scope Global -Name .... -Value Set-UpThreeLevels

##############################################################################
# XXX: TBD
#: alias diffdir='diff -qr'
#:
#: if command -v colordiff &> /dev/null; then
#:   alias diff='colordiff'
#:   alias diffdir='colordiff -qr'
#: fi
#:
#: #-----------------------------------------------------------------------------
#: # https://wiki.archlinux.org/index.php/Core_Utilities#grep
#: export GREP_COLOR="1;33"
#: alias grep='grep --color=auto'
#: alias g='grep --color=auto'

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

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
# XXX: Does powershell have similar history configuration options?
#: HISTFILE="$XDG_CACHE_HOME/bash/history"
#: 
#: HISTCONTROL="erasedups:ignoreboth"
#: HISTFILESIZE=100000
#: HISTIGNORE="&:[ ]*:exit:ls:bg:fg:history:clear"
#: HISTSIZE=500000
#: HISTTIMEFORMAT='%F %T '
#: 
#: shopt -s cmdhist histappend histreedit histverify

#: #-----------------------------------------------------------------------------
# XXX: ...
#: # See inputrc for macros
#: #run-help() { help "$READLINE_LINE" 2>/dev/null || man "$READLINE_LINE"; }

#: #-----------------------------------------------------------------------------
# XXX: How do we do or mimic bash-completions?
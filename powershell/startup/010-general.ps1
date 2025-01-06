# Make all aliases in this file constants.

Set-Alias -Name c -Value Clear-Host
Set-Alias -Name h -Value Get-History

function Go-ParentDirectory {
  param (
    [int]$levels = 1
  )
  
  for ($i = 0; $i -lt $levels; $i++) {
    Set-Location -Path ..
  }
}
#Set-Variable -Name Go-ParentDirectory `
#  -Value (Get-Command Go-ParentDirectory) `
#  -Option Private

function Go-UpTwoLevels { Go-ParentDirectory -levels 2 }
function Go-UpThreeLevels { Go-ParentDirectory -levels 3 }

Set-Alias -Scope Global -Name .. -Value Go-ParentDirectory
Set-Alias -Name ... -Value Go-UpTwoLevels
Set-Alias -Name .... -Value Go-UpThreeLevels

# Add code to display which aliases have been created AI!

# TBD: move to a file found by Load-Files
function dumppath { $env:PATH -split ';' | ForEach-Object { Write-Output $_ } }

#: #-----------------------------------------------------------------------------
#: alias dumppath='echo -e ${PATH//:/\\n}'
#: alias dumpldpath='echo -e ${LD_LIBRARY_PATH//:/\\n}'
#: alias dotfiles='cd $DOTFILES'
#: 
#: #-----------------------------------------------------------------------------
#: # https://wiki.archlinux.org/index.php/Core_Utilities#ls
#: eval $(dircolors -b)
#: 
#: alias l='ls -AFl --color=auto'
#: alias sl=ls
#: 
#: #-----------------------------------------------------------------------------
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
#: 
#: #-----------------------------------------------------------------------------
#: # I got this from a co-worker many moons ago. Unfortunately, I don't remember
#: # who. Basically, if a tree program is not installed, fake it with this.
#: 
#: ! command -v tree &> /dev/null \
#:   && alias tree="find . -print | sed -e 's;[^/]*/;|____;g;s;____|; |;g'"
#: 
#: #-----------------------------------------------------------------------------
#: # https://unix.stackexchange.com/a/584733/9032
#: 
#: # Revalidate for another 15 minutes
#: # Echo expanded command
#: # Run expanded command
#: 
#: function sudo() {
#:   command sudo -v
#: 
#:   if [[ $(type -t "$1") == "alias" ]]; then
#:     set -- bash -ic "$(alias "$1"); $(printf "%q " "$@")"
#:   fi
#: 
#:   echo "Executing: sudo $*"
#: 
#:   # and do it
#:   command sudo "$@"
#: }
#: 
#: #-----------------------------------------------------------------------------
#: mkdir -p "$XDG_CACHE_HOME/bash"
#: HISTFILE="$XDG_CACHE_HOME/bash/history"
#: 
#: HISTCONTROL="erasedups:ignoreboth"
#: HISTFILESIZE=100000
#: HISTIGNORE="&:[ ]*:exit:ls:bg:fg:history:clear"
#: HISTSIZE=500000
#: HISTTIMEFORMAT='%F %T '
#: 
#: shopt -s cmdhist histappend histreedit histverify
#: 
#: alias h='history'
#: 
#: #-----------------------------------------------------------------------------
#: command -v chromium-browser &> /dev/null && export BROWSER='chromium-browser'
#: export DOCKER_CONFIG="${XDG_CONFIG_HOME}/docker"
#: 
#: #-----------------------------------------------------------------------------
#: 
#: # This overrides local ansible.cfg
#: #export ANSIBLE_CONFIG="${XDG_CONFIG_HOME}/ansible.cfg"
#: 
#: #-----------------------------------------------------------------------------
#: # Mimic Zsh run-help ability
#: # Press alt+h to get help for word on cursor
#: # https://wiki.archlinux.org/title/Bash#Mimic_Zsh_run-help_ability
#: # See inputrc for macros
#: #run-help() { help "$READLINE_LINE" 2>/dev/null || man "$READLINE_LINE"; }
#: 
#: #-----------------------------------------------------------------------------
#: # binenv
#: 
#: if command -v binenv &> /dev/null; then
#:   BINENV_BINDIR="/home/harleypig/.local/bin"
#:   BINENV_CACHEDIR="/home/harleypig/.cache/binenv"
#:   BINENV_CONFDIR="/home/harleypig/projects/dotfiles/config/binenv"
#: 
#:   source <(binenv completion bash)
#: fi
#: 
#: #-----------------------------------------------------------------------------
#: # Vault
#: 
#: if command -v vault &> /dev/null; then
#: 
#:   vaultpath="$(command -v vault 2> /dev/null)"
#: 
#:   if [[ -n $vaultpath ]]; then
#:     complete -C "$vaultpath" vault
#:   fi
#: 
#:   unset vaultpath
#: fi
#: 
#: #-----------------------------------------------------------------------------
#: # rust/rustup
#: 
#: if [[ -d "$XDG_DATA_HOME" ]]; then
#:   export CARGO_HOME="$XDG_DATA_HOME/cargo"
#:   export RUSTUP_HOME="$XDG_CONFIG_HOME/rustup"
#:   # The env file hard codes the location and is wrong
#:   #source "$CARGO_HOME/env"
#:   addpath "$CARGO_HOME/bin"
#: fi
#: 
#: #-----------------------------------------------------------------------------
#: # cygwin specific stuff
#: 
#: if [[ "$(uname -o)" == "Cygwin" ]]; then
#:   # cygwin specific (not in bash manpage)
#:   set -o igncr
#: fi
#: 
#: #-----------------------------------------------------------------------------
#: # gcloud stuff
#: 
#: if command -v gcloud &> /dev/null; then
#:   alias gcloud-auth='gcloud auth login --no-launch-browser && gcloud auth application-default login --no-launch-browser'
#: fi

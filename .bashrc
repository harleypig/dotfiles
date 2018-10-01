#!/bin/bash

#---------------------------------------------------------------------------------------
# See function at
# https://github.com/wschlich/bashinator/blob/master/bashinator.lib.0.sh#L940
# for ideas on building a better prefix.

function debug() {
  [[ -f $HOME/.dot_debug ]] || return 0

  local src func lineno

  src=$(basename "${BASH_SOURCE[1]:-$0}:")
  func="${FUNCNAME[1]}:"
  lineno="${BASH_LINENO[0]}"

  [[ $func =~ ^(main|source):$ ]] && func=

  echo "[$src$func$lineno] $*" >> "$HOME/.dotfiles.log"
}

export -f debug

#-----------------------------------------------------------------------
# Sources all files found in $1.
function source_dir() {
  local dir="$1"

  [[ -d $dir ]] || {
    debug "$dir does not exist or is not a directory"
    return
  }

  debug "Loading files in $dir ..."

  readarray -t files < <(find "$dir" -type f | sort)

  debug "Found ${#files[@]} files in $dir ..."

  for s in "${files[@]}"; do
    debug "Sourcing $s ..."
    source "$s"
  done

  debug "Done loading files in $dir."
}

export -f source_dir


#---------------------------------------------------------------------------------------
# Don't delete this, it's for figuring things out sometimes.

if [[ $- == *i* ]]; then
  debug "We are interactive ..."
else
  debug "We are *not* interactive ..."
fi

if shopt -q login_shell; then
  debug "We are in a login shell ..."
else
  debug "We are *not* in a login shell ..."
fi

#---------------------------------------------------------------------------------------
debug "Setting up shell options ..."

CDPATH="."
PROMPT_DIRTRIM=2
HISTCONTROL="erasedups:ignoreboth"
HISTFILESIZE=100000
HISTIGNORE="&:[ ]*:exit:ls:bg:fg:history:clear"
HISTSIZE=500000
HISTTIMEFORMAT='%F %T '

bind "set completion-ignore-case on"
bind "set completion-map-case on"
bind "set mark-symlinked-directories on"
bind "set show-all-if-ambiguous on"
bind Space:magic-space

shopt -s autocd 2> /dev/null
shopt -s cdspell 2> /dev/null
shopt -s dirspell 2> /dev/null
shopt -s globstar 2> /dev/null

shopt -s cdable_vars
shopt -s checkhash
shopt -s checkwinsize
shopt -s cmdhist
shopt -s dotglob
shopt -s histappend
shopt -s histreedit
shopt -s histverify
shopt -s nocaseglob

umask 022

#---------------------------------------------------------------------------------------
# Turn on bash completion

# Order matters, don't mess with the order.
declare -a FILES
FILES+=('/etc/bash_completion')
FILES+=('/etc/profile.d/bash-completion')

for file in "${FILES[@]}"; do
  [[ -f $file ]] && source "$file"
done

#---------------------------------------------------------------------------------------
# Simple check and source lines

#[[ -z $SSH_AUTH_SOCK && -r $DOTFILES/.ssh-agent ]] && source "$DOTFILES/.ssh-agent"
[[ -f $DOTFILES/.Xresources ]] && xrdb "$DOTFILES/.Xresources"
[[ -f $DOTFILES/bin/tokens ]] && source "$DOTFILES/bin/tokens"

source_dir "$DOTFILES/.bash_sources.d"
source_dir "$DOTFILES/$HOSTNAME"
source_dir "$DOTFILES/.sekrets"
source_dir "$HOME/.bash_profile.d"
source_dir "$HOME/.bashrc.d"

source "$DOTFILES/.bash_prompt"

#---------------------------------------------------------------------------------------
# PATH setup

# Run this last to allow for other stuff above modifying the path

# Do not alphabetize, order is important here.
# XXX: Use add_path function instead here.
# XXX: Add cleanup ability to add_path function.

declare -a BIN_DIRS
BIN_DIRS=("$DOTFILES/lib")
BIN_DIRS=("$DOTFILES/bin")
BIN_DIRS=("$HOME/bin")
BIN_DIRS+=("$HOME/.vim/bin")
BIN_DIRS+=("$HOME/.cabal/bin")
BIN_DIRS+=("$HOME/.minecraft/bin")
BIN_DIRS+=("$HOME/Dropbox/bin")
BIN_DIRS+=("$HOME/videos/bin")
BIN_DIRS+=("$HOME/projects/depot_tools")
#BIN_DIRS+=("$HOME/projects/android-sdk/tools")
#BIN_DIRS+=("$HOME/projects/android-sdk/platform-tools")
BIN_DIRS+=("/usr/lib/dart/bin")
BIN_DIRS+=("${GOROOT}/bin")
BIN_DIRS+=("${GOPATH}/bin")

for d in "${BIN_DIRS[@]}"; do
  dir=$(readlink -nf "$d")

  [[ -d $dir ]] || continue
  [[ $PATH != *"$dir"* ]] || continue
  PATH="${PATH}:${dir}"

done

export PATH="${PATH}:."

debug "Exiting ..."

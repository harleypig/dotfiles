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
# Force 256 color support

export TERM='xterm-256color'

#---------------------------------------------------------------------------------------
# PATH setup

# Completely rebuild the path to my specifications.

# Run this last to allow for other stuff above modifying the path

declare -a BIN_DIRS

IFS=':' read -ra BIN_DIRS <<< "$PATH"

# !!! Do not alphabetize, order is important here.

[[ -n $GOROOT ]] && BIN_DIRS+=("$GOROOT/bin")
[[ -n $GOPATH ]] && BIN_DIRS+=("$GOPATH/bin")
BIN_DIRS+=("/usr/lib/dart/bin")

BIN_DIRS+=("$DOTFILES/lib")
BIN_DIRS+=("$DOTFILES/bin")

BIN_DIRS+=("$HOME/bin")
BIN_DIRS+=("$HOME/.vim/bin")
BIN_DIRS+=("$HOME/.cabal/bin")
BIN_DIRS+=("$HOME/.minecraft/bin")
BIN_DIRS+=("$HOME/Dropbox/bin")
BIN_DIRS+=("$HOME/videos/bin")
BIN_DIRS+=("$HOME/projects/depot_tools")
#BIN_DIRS+=("$HOME/projects/android-sdk/tools")
#BIN_DIRS+=("$HOME/projects/android-sdk/platform-tools")

declare NEWPATH

# If using ccache, it needs to be first on the path
[[ -d /usr/lib/ccache/bin ]] && NEWPATH=':/usr/lib/ccache/bin'

for d in "${BIN_DIRS[@]}"; do
  [[ $d == '.' ]] && continue

  dir=$(readlink -ne "$d")

  [[ -z $dir ]] && continue
  [[ -d $dir ]] || continue
  [[ $NEWPATH != *"$dir"* ]] || continue

  NEWPATH="$NEWPATH:$dir"

done

export PATH="$NEWPATH:."

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
[[ -f $DOTFILES/.Xresources ]] && command -v xrdb &> /dev/null && xrdb "$DOTFILES/.Xresources"
#[[ -f $DOTFILES/bin/tokens ]] && source "$DOTFILES/bin/tokens"

source_dir "$DOTFILES/.bash_sources.d"
source_dir "$DOTFILES/$HOSTNAME"
#source_dir "$DOTFILES/.sekrets"
source_dir "$HOME/.bash_profile.d"
source_dir "$HOME/.bashrc.d"

#---------------------------------------------------------------------------------------
source "$DOTFILES/.bash_prompt"

debug "Exiting ..."

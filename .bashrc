#!/bin/bash

# Look into
#   https://gist.github.com/goodmami/6556701
#   https://github.com/deanrather/bash-logger/blob/master/bash-logger.sh
# as a way to log to syslog.

DEBUG_PREFIX=${BASH_SOURCE#$HOME/}

if ! [ -f "$HOME/.bash_functions" ]; then
  echo "$HOME/.bash_functions does not exist"
  exit 1
fi

# shellcheck source=/home/harleypig/.bash_functions
source "$HOME/.bash_functions"

## See function at
## https://github.com/wschlich/bashinator/blob/master/bashinator.lib.0.sh#L940
## for ideas on building a better prefix.
#
#DEBUG_PREFIX=${BASH_SOURCE#$HOME/}
#
#__debugit () {
#  if [ -f $HOME/.dot_debug ]; then
#    echo "$@" >> $HOME/.dotfiles_$$_$(date +%s).log
#  fi
#}

__debugit "${DEBUG_PREFIX}:$LINENO Entering ..."

########################################################################
# Don't delete this, it's for figuring things out sometimes.

#if [[ $- == *i* ]]; then
#  __debugit "${DEBUG_PREFIX} We are interactive ..."
#else
#  __debugit "${DEBUG_PREFIX} We are *not* interactive ..."
#fi
#
#if shopt -q login_shell; then
#  __debugit "${DEBUG_PREFIX} We are in a login shell ..."
#else
#  __debugit "${DEBUG_PREFIX} We are *not* in a login shell ..."
#fi
########################################################################

## Determines the fully qualified path of a file and sets $1 to the path.
## NOTE: Does not validate the path or file.
## Expects, in order:
##   The name of the variable to be set.
##   The name of the path to fully qualify.
#
#__realpath () {
#
#  local varname=$1  ; shift
#  local filename=$1 ; shift
#
#  fqfn=${filename//\$HOME/$HOME}
#  fqfn=$(readlink -nf $fqfn)
#
#  printf -v "${varname}" "%s" "$fqfn"
#
#}
#
## Builds a fully qualified path and sets $1 to the value.
## NOTE: Does not validate the path or file.
## Expects, in order:
##   The name of the variable to be set.
##   The name of the file to determine where to load files from.
##   The endpoint the path should have.
#
#__buildpath () {
#
#  local varname=$1    ; shift
#  local sourcefile=$1 ; shift
#  local endpoint=$1   ; shift
#
#  __realpath 'realpath' "$sourcefile"
#  realpath=$(dirname $realpath)
#
#  printf -v "$varname" '%s' "${realpath}${endpoint}"
#
#}
#
## Sources all files found in $1.
#__source_files () {
#
#  __debugit "${DEBUG_PREFIX}:${LINENO} Trying to source $1 ..."
#
#  for s in $(ls $1 2> /dev/null); do
#    __debugit "${DEBUG_PREFIX}:${LINENO} Sourcing $s ..."
#    source $s
#
#  done
#}
#
## Sources all files found in either a hostspecific directory or a default directory.
#__source_host_specific () {
#
#  local endpoint="$1"
#  local hostname=$(hostname)
#
#  __buildpath 'path' "${BASH_SOURCE}" '/hostspecific'
#
#  if [ -d "${path}/${hostname}" ]; then
#    path="${path}/${hostname}/${endpoint}"
#  else
#    path="${path}/default/${endpoint}"
#  fi
#
#  __source_files $path
#
#}

########################################################################
# Environment Variables

export EDITOR=vim
export LANG=en_US.UTF-8
export LANGUAGE=en_US.UTF-8
export LC_ALL=en_US.UTF-8

if command -v pacman > /dev/null; then
  command -v pacmatic > /dev/null 2>&1 && export PACMAN='pacmatic'
fi

if [[ -d "${HOME}/projects/go" ]]; then
  export GOROOT="${HOME}/projects/go"
  export GOPATH="${HOME}/.go"
fi

########################################################################

if [[ $- != *i* ]]; then
  # non-interactive shell, nothing else to do.
  __debugit "${DEBUG_PREFIX}:$LINENO Non-interactive shell, done."
  return
fi

# Check in a lookup table for a command before searching the path.
#   force a rescan for one or more commands: hash -d command command ...
#   force a complete rescan: hash -r
shopt -s checkhash

# Update the window/terminal size variables after each command.
shopt -s checkwinsize

shopt -s dotglob
shopt -s nocaseglob

umask 022

########################################################################################
# This is for hman.
export BROWSER='chromium-browser'

########################################################################################
# Load application specific files.

# shellcheck disable=SC2128
__buildpath 'SOURCES' "${BASH_SOURCE}" "/.bash_sources.d/*"
__source_files "$SOURCES"

########################################################################################
# Simple check and source lines

[[ -f $HOME/.Xresources ]] && xrdb "$HOME/.Xresources"

# Order matters, don't mess with the order.
declare -a FILES

FILES+=('/etc/bash_completion')
FILES+=('/etc/profile.d/bash-completion')
FILES+=("$HOME/.bash_prompt")
FILES+=('/.travis/travis.sh')
FILES+=('/usr/share/nvm/init-nvm.sh')
FILES+=('.task/completion/task-completion.sh')

for file in "${FILES[@]}"; do
  # shellcheck disable=SC1090
  [[ -f $file ]] && source "$file"
done

if [[ -d "${HOME}/projects/nvm" ]]; then
  export NVM_DIR="$HOME/projects/nvm"
  # shellcheck disable=SC1090
  [[ -s "$NVM_DIR/nvm.sh" ]] && source "${NVM_DIR}/nvm.sh"
fi

# shellcheck disable=SC1090
[[ -z $SSH_AUTH_SOCK && -f $HOME/.ssh-agent && -r $HOME/.ssh-agent ]] && source "$HOME/.ssh-agent"

# shellcheck disable=SC1090
command -v npm > /dev/null 2>&1 && source <(npm completion)

if [[ -d $HOME/.bash_completion.d ]]; then
  # shellcheck disable=SC2128
  __buildpath 'COMPLETION' "${BASH_SOURCE}" '/.bash_completion.d/*'
  __source_files "$COMPLETION"
fi

# shellcheck disable=SC1090
[[ -f $HOME/bin/tokens ]] && source "$HOME/bin/tokens"

########################################################################################
# Source any files we find in our host specific directory

__source_host_specific '*bashrc*'
#__buildpath 'HOSTSPECIFIC' "${BASH_SOURCE}" "/hostspecific/$(hostname)/*bashrc*"
#__source_files $HOSTSPECIFIC

########################################################################################
# Source any private files

__buildpath 'PRIVATE' "${HOME}" '/.bash_private.d'
__source_files "$PRIVATE"
__source_files "$HOME/.secrets"

__debugit "${DEBUG_PREFIX}:$LINENO Exiting ..."

########################################################################
# PATH setup

# Run this last to allow for other stuff above modifying the path

if [[ -d $HOME/.rbenv ]]; then

  PATH="$HOME/.rbenv/plugins/ruby-build/bin:$HOME/.rbenv/bin:${PATH}"
  eval "$(rbenv init -)"

fi

# Do not alphabetize, order is important here.
# XXX: Use add_path function instead here.
# XXX: Add cleanup ability to add_path function.

BIN_DIRS="${BIN_DIRS} ${HOME}/bin"
BIN_DIRS="${BIN_DIRS} ${HOME}/.vim/bin"
BIN_DIRS="${BIN_DIRS} ${HOME}/.cabal/bin"
BIN_DIRS="${BIN_DIRS} ${HOME}/.minecraft/bin"
BIN_DIRS="${BIN_DIRS} ${HOME}/Dropbox/bin"
BIN_DIRS="${BIN_DIRS} ${HOME}/videos/bin"
BIN_DIRS="${BIN_DIRS} ${HOME}/projects/depot_tools"
BIN_DIRS="${BIN_DIRS} ${HOME}/projects/dotfiles/bin"
BIN_DIRS="${BIN_DIRS} ${HOME}/projects/android-sdk/tools"
BIN_DIRS="${BIN_DIRS} ${HOME}/projects/android-sdk/platform-tools"
BIN_DIRS="${BIN_DIRS} /usr/lib/dart/bin"
BIN_DIRS="${BIN_DIRS} ${GOROOT}/bin"
BIN_DIRS="${BIN_DIRS} ${GOPATH}/bin"

for d in $BIN_DIRS; do

  __realpath 'dir' "$d"

  # shellcheck disable=SC2154
  if [[ -d $dir ]] && [[ $PATH != *"$dir"* ]]; then
    PATH="${PATH}:${dir}"
  fi
done

PATH="${PATH}:."
export PATH

#!/bin/bash

# Look into
#   https://gist.github.com/goodmami/6556701
#   https://github.com/deanrather/bash-logger/blob/master/bash-logger.sh
# as a way to log to syslog.

if ! [ -f "$HOME/.bash_functions" ]; then
  echo "$HOME/.bash_functions does not exist"
  exit 1
fi

# All other scripts depend on the functions defined here.
# shellcheck source=/home/harleypig/.bash_functions
source "$HOME/.bash_functions"

debug "After loading functions ..."

########################################################################
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

########################################################################

if [[ $- != *i* ]]; then
  # non-interactive shell, nothing else to do.
  debug "Non-interactive shell, done."
  return
fi

debug "Setting up shell options ..."

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
# Simple check and source lines

# shellcheck disable=SC1090
[[ -z $SSH_AUTH_SOCK && -r $HOME/.ssh-agent ]] && source "$HOME/.ssh-agent"

[[ -f $HOME/.Xresources ]] && xrdb "$HOME/.Xresources"

declare -a FILES

# Order matters, don't mess with the order.
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
command -v npm > /dev/null 2>&1 && source <(npm completion)

# shellcheck disable=SC1090
[[ -f $HOME/bin/tokens ]] && source "$HOME/bin/tokens"

########################################################################################
# Load application specific files.

source_files="$(realpath "${BASH_SOURCE[0]}")/.bash_sources.d"
debug "source_files: $source_files"

# shellcheck disable=SC1091
source source_dir "$SOURCES"

########################################################################################
# Source any files we find in our host specific directory

host_sources="$(realpath "${BASH_SOURCE[0]}")/$HOSTNAME"
debug "host_sources: $host_sources"

# shellcheck disable=SC1091
source source_dir "$host_sources"

########################################################################################
# Source any local files

local_files="$HOME/.bash_local"
debug "local_files: $local_files"

# shellcheck disable=SC1091
source source_dir "$local_files"

########################################################################################
# Source sekrets.

sekret_files="$HOME/.sekrets"
debug "sekret_files: $sekret_files"

# shellcheck disable=SC1091
source source_dir "$sekret_files"

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

  realpath 'dir' "$d"

  # shellcheck disable=SC2154
  if [[ -d $dir ]] && [[ $PATH != *"$dir"* ]]; then
    PATH="${PATH}:${dir}"
  fi
done

PATH="${PATH}:."
export PATH

debug "Exiting ..."


__debugit () {
  if [ -f ~/.dot_debug ]; then
    echo "$@" >> ~/.dotfiles_$$.log
  fi
}

__debugit "${BASH_SOURCE#$HOME/}:$LINENO Entering ..."

[[ -f $HOME/.bashrc ]] && source $HOME/.bashrc

__debugit "${BASH_SOURCE#$HOME/}:$LINENO Exiting ..."

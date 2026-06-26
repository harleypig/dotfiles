# dotvim symlinks (~/.vim, ~/.vimrc) are owned by bin/check-dotvim, not
# dotlinks — see config/shell-startup/zzz-check-dotvim.
$DOTFILES/dot-general/.bash_logout

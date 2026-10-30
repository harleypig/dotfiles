# dotvim symlinks (~/.vim, ~/.vimrc) are owned by bin/check-dotvim, not
# dotlinks — see config/shell-startup/zzz-check-dotvim.
$DOTFILES/dot-general/.bash_logout
$DOTFILES/config/user-tmpfiles.d/tmp.conf .config/user-tmpfiles.d/tmp.conf
/usr/lib/systemd/user/systemd-tmpfiles-clean.timer .config/systemd/user/timers.target.wants/systemd-tmpfiles-clean.timer

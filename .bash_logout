[[ -e ~/bash_startup.log ]] && rm ~/bash_startup.log

if [ "$SHLVL" = 1 ]; then
    [ -x /usr/bin/clear_console ] && /usr/bin/clear_console -q
fi

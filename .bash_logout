[[ -e ~/bash_startup.log ]] && rm ~/bash_startup.log

if [ `/usr/bin/whoami` = 'root' ]
then
  /bin/chown -R harleypig:harleypig /home/harleypig
fi

# Clear the screen for security's sake.
clear

#echo Started .bash_profile ... >> ~/bash_startup.log

# .bash_profile is run *first* and *only* on ssh (or terminal) but not when
# shelling out from vim or a new screen instance is being created.

[[ -f ~/.bashrc ]] && . ~/.bashrc

#echo '  ... ended .bash_profile.' >> ~/bash_startup.log

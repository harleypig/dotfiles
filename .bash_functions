#echo 'Started .bash_functions ...' >> ~/bash_startup.log

# Some of these are found on (and modified to fit):
#
# superuser.com
# commandlinefu.com

# Change to directory and list it
function cdl() { cd $1; l; }

# Make directory and cd to it
function mkcd() { mkdir -p -- "$@" && cd "$_"; }

# http://stackoverflow.com/questions/1687642/set-screen-title-from-shellscript/1687710#1687710
# XXX: Should check to see if we are in screen and do nothing unless we are.
function set_screen_title { echo -ne "\ek$1\e\\"; }

# join an array. join must be a single character
# Set the array you want to join in the __JOIN variable.

# XXX: Allow for any size separator if IFS can handle \0

function __join() {

  SAVE_IFS="$IFS"
  IFS="$*"
  local joined="${__JOIN[*]}"
  IFS="$SAVE_IFS"
  echo "$joined"

}

BIGFUNCTIONS="$(__basedir ~/.bash_functions)/.bash_functions.d"
SOURCE=$(ls ${BIGFUNCTIONS}/* 2> /dev/null)
for s in ${SOURCE}; do source $s; done

HOSTSPECIFIC="$(__basedir ~/.bash_functions)/hostspecific/$(hostname)"
SOURCE=$(ls ${HOSTSPECIFIC}/*functions* 2> /dev/null)
for s in ${SOURCE}; do source $s; done

#echo '  ... ended .bash_functions.' >> ~/bash_startup.log

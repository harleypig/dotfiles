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
# XXX: Should check to see if we are in screen or tmux and make appropriate calls.
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

function __duration() {

  local _date="$@"
  local _seconds=$(date --date="$_date" +%s)

  local _duration=$(($now - $_seconds))
  local _days=$(($_duration / (60*60*24) ))
  local _hours=$(($_duration % (60*60*24) / (60*60) ))
  local _minutes=$(($_duration % (60*60) / 60))

  local _string

  if [[ $_days -ne 0 ]]; then
    _string="${_string}${_days}d "
  fi

  if [[ $_hours -ne 0 ]]; then
    _string="${_string}${_hours}h "
  fi

  if [[ $_minutes -ne 0 ]]; then
    _string="${_string}${_minutes}m "
  fi

  echo $_string

}

# bash-completion for aliases
# https://unix.stackexchange.com/questions/4219/how-do-i-get-bash-completion-for-command-aliases
#
# alias gco='git checkout'
# make-completion-wrapper _git _git_checkout git checkout
# complete -F _git_checkout gco

function make-completion-wrapper () {
  local function_name="$2"
  local arg_count=$(($#-3))
  local comp_function_name="$1"
  shift 2
  local function="
    function $function_name {
      ((COMP_CWORD+=$arg_count))
      COMP_WORDS=( "$@" \${COMP_WORDS[@]:1} )
      "$comp_function_name"
      return 0
    }"
  eval "$function"
  echo $function_name
  echo "$function"
}

BIGFUNCTIONS="$(__basedir ~/.bash_functions)/.bash_functions.d"
SOURCE=$(ls ${BIGFUNCTIONS}/* 2> /dev/null)
for s in ${SOURCE}; do source $s; done

HOSTSPECIFIC="$(__basedir ~/.bash_functions)/hostspecific/$(hostname)"
SOURCE=$(ls ${HOSTSPECIFIC}/*functions* 2> /dev/null)
for s in ${SOURCE}; do source $s; done

#echo '  ... ended .bash_functions.' >> ~/bash_startup.log

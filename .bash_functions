#echo 'Started .bash_functions ...' >> ~/bash_startup.log

# Some of these are found on (and modified to fit):
#
# superuser.com
# commandlinefu.com

# Change to directory and list it
function cdl() { cd $1; l; }

# Make directory and cd to it
function mkcd() { mkdir -p -- "$@" && cd "$_"; }

function geoip() {

  wget -qO - www.ip2location.com/$1 | \
  grep -E '<span id=\"dgLookup__ctl2_lblI(Country|Region|City)\">' | \
  sed 's/<[^>]*>//g; s/^[\t]*//; s/&quot;/"/g; s/</</g; s/>/>/g; s/&amp;/\&/g'

}

function git_remove_missing_files() { git ls-files -d -z | xargs -0 git update-index --remove; }
function down4me() { curl -s "http://www.downforeveryoneorjustme.com/$1" | sed '/just you/!d;s/<[^>]*>//g'; }

# XXX: Move this to the CDARGS section
## http://www.commandlinefu.com/commands/view/6820/quick-directory-bookmarks
##
## /cd/to/very/long/path
## type 'bm project'
## type 'to project' to change to that directory from anywhere
##
## XXX: Add ability to save bookmark to hostspecific file
#
#function bm() { eval $1=$(pwd); }
#function to() { eval dir=\$$1; cd "$dir"; }

# http://www.commandlinefu.com/commands/view/7156/monitor-a-file-with-tail-with-timestamps-added
function tailfile () { tail -f $1 | xargs -IX printf "$(date -u)\t%s\n" X; }

# http://linuxcommando.blogspot.com/2007/10/dictionary-lookup-via-command-line.html
function define () { clear; curl dict://dict.org/d:$1; }

# http://www.commandlinefu.com/commands/view/2829/query-wikipedia-via-console-over-dns
# http://onethingwell.org/post/2858158431/wikipedia-cli
#function wiki() { dig +short txt $1.wp.gd.cx; }
function wiki() { host -t txt $1.wp.gd.cx; }

# Go to current git repo toplevel directory.
function gtl() { cd $(git rev-parse --show-toplevel); }

# Get an ordered list of subdirectory sizes
# http://www.shell-fu.org/lister.php?id=275
#function dusk() {
#
#  du -sk ./* | sort -n | awk 'BEGIN{ pref[1]="K"; pref[2]="M"; pref[3]="G";} { total = total + $1; x = $1; y = 1; while( x > 1024 ) { x = (x + 1023)/1024; y++; } printf("%g%s\t%s\n",int(x*10)/10,pref[y],$2); } END { y = 1; while( total > 1024 ) { total = (total + 1023)/1024; y++; } printf("Total: %g%s\n",int(total*10)/10,pref[y]); }';
#
#}

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

# https://github.com/ndbroadbent/ubuntu_config/blob/master/assets/bashrc/functions.sh

# This doesn't appear to work
# $ ? 3 - 5
# -2
#? () { echo "$*" | bc -l; }

# Try this when you have time! perl?

# Processes your git status output, exporting bash variables
# for the filepaths of each modified file.
# To ensure colored output, please run: $ git config --global color.status always
# Written by Nathan D. Broadbent (www.madebynathan.com)
# -----------------------------------------------------------
#gs() {
#  # Set your preferred shortcut letter here
#  pfix="e"
#  # Max changes before reverting to standard 'git status' (can be very slow otherwise)
#  max_changes=15
#  # ------------------------------------------------
#  # Only export variables for less than $max_changes
#  status=`git status --porcelain`
#  IFS=$'\n'
#  if [ $(echo "$status" | wc -l) -lt $max_changes ]; then
#    f=0  # Counter for the number of files
#    for line in $status; do
#      file=$(echo $line | sed "s/^.. //g")
#      let f++
#      files[$f]=$file           # Array for formatting the output
#      export $pfix$f=$file     # Exporting variable for use.
#    done
#    full_status=`git status`  # Fetch full status
#    # Search and replace each line, showing the exported variable name next to files.
#    for line in $full_status; do
#      i=1
#      while [ $i -le $f ]; do
#        search=${files[$i]}
#        # Need to strip the color character from the end of the line, otherwise
#        # EOL '$' doesn't work. This gave me a headache for long time.
#        # The echo ~> regex is very time-consuming, so we perform a simple search first.
#        if [[ $line = *$search* ]]; then
#          replace="\\\033[2;37m[\\\033[0m\$$pfix$i\\\033[2;37m]\\\033[0m $search"
#          line=$(echo $line | sed -r "s:$search(\x1B\[m)?$:$replace:g")
#          # Only break the while loop if a replacement was made.
#          # This is to support cases like 'Gemfile' and 'Gemfile.lock' both being modified.
#          if echo $line | grep -q "\$$pfix$i"; then break; fi
#        fi
#        let i++
#      done
#      echo -e $line                        # Print the final transformed line.
#    done
#  else
#    # If there are too many changed files, this 'gs' function will slow down.
#    # In this case, fall back to plain 'git status'
#    git status
#  fi
#  # Reset IFS separator to default.
#  unset IFS
#}

# http://vimeo.com/21538711 about 16:30
# function toggle_trace () {
#
#   if TRACEON eq 1; then
#     export PS4=
#     export TRACEON=
#     set +o xtrace
#   else
#     export PS4='+[${BASH_SOURCE}] : ${LINENO} : ${FUNCNAME[0]:+${FUNCNAME[0]}() $ }'
#     export TRACEON=1
#     set -o xtrace
#   fi
#
# }

# What is axel?
# http://axel.alioth.debian.org/ ?
# https://github.com/emiraga/axel ?
# https://github.com/viranch/axel-custom ?
# https://github.com/ghuntley/axel ?

## Download streaming mp3s & sanitize with ffmpeg
## -----------------------------------------------------------
#grooveshark_dl() {
#  if [ -n "$2" ]; then
#    echo "== Downloading .."
#    axel $1 -o "/tmp/$2.tmp"
#    echo "== Converting .."
#    ffmpeg -ab 128000 -i "/tmp/$2.tmp" "$2.mp3"
#    rm "/tmp/$2.tmp"
#    echo "== Finished!"
#  else
#    echo "Usage: grooveshark_dl <url> <title (w/o .mp3)>"
#  fi
#}

#function showpsformats () {
#
#  local r l a P f=/tmp/ps c='command ps wwo pid:6,user:8,vsize:8,comm:20' IFS=' ';
#  trap 'exec 66'
#  exec 66 $f && command ps L | tr -s ' ' >&$f;
#
#  while read -u66 l >&/dev/null; do
#    a=${l/% */};
#    $c,$a k -${a//%/} -A;
#    yn "Add $a" && P[$SECONDS]=$a;
#  done
#
#}

#echo '  ... ended .bash_functions.' >> ~/bash_startup.log

# Some of these are found on (and modified to fit):
#
# superuser.com
# commandlinefu.com

# Change to directory and list it
function cdl() { cd $1; l; }

# Make directory and cd to it
function mkcd() { mkdir -p -- "$@" && cd "$_"; }

# Geolocate an ip
function geoip() {

  wget -qO - www.ip2location.com/$1 | \
  grep "<span id=\"dgLookup__ctl2_lblICountry\">" | \
  sed 's/<[^>]*>//g; s/^[\t]*//; s/&quot;/"/g; s/</</g; s/>/>/g; s/&amp;/\&/g'

}

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

# http://www.commandlinefu.com/commands/view/6820/quick-directory-bookmarks
#
# /cd/to/very/long/path
# type 'bm project'
# type 'to project' to change to that directory from anywhere

function bm() { eval $1=$(pwd); }
function to() { eval dir=\$$1; cd "$dir"; }

# http://www.commandlinefu.com/commands/view/7156/monitor-a-file-with-tail-with-timestamps-added
function tailfile () { tail -f $1 | xargs -IX printf "$(date -u)\t%s\n" X; }

# http://linuxcommando.blogspot.com/2007/10/dictionary-lookup-via-command-line.html
function define () { clear; curl dict://dict.org/d:$1; }

# http://www.commandlinefu.com/commands/view/2829/query-wikipedia-via-console-over-dns
# http://onethingwell.org/post/2858158431/wikipedia-cli
function wiki() { dig +short txt $1.wp.gd.cx; }

# Go to current git repo toplevel directory.
function gtl() { cd $(git rev-parse --show-toplevel); }

HOSTSPECIFIC="$(dirname $(readlink ~/.bash_functions))/hostspecific/$(hostname)_functions"

[[ -f ${HOSTSPECIFIC} ]] && source ${HOSTSPECIFIC}

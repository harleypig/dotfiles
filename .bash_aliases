#!/bin/bash

__debugit "${BASH_SOURCE#$HOME/}:$LINENO Entering ..."

# Some of these aliases are:

# from the bash-it project on github:
#   https://github.com/revans/bash-it
#
# culled from superuser.com

# others are my own fault.

__buildpath 'BIGALIASES' "${BASH_SOURCE}" "/.bash_aliases.d/*"
for s in $(ls $BIGALIASES 2> /dev/null); do source $s; done

__buildpath 'HOSTSPECIFIC' "${BASH_SOURCE}" "/hostspecific/$(hostname)/*aliases*"
for s in $(ls $HOSTSPECIFIC 2> /dev/null); do source $s; done

__debugit "${BASH_SOURCE#$HOME/}:$LINENO Exiting ..."

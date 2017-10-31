#!/bin/bash

# For debugging login files, do:
#
# ssh -t localhost "PS4='+[\$BASH_SOURCE:\$LINENO]: ' BASH_XTRACEFD=7 bash -xl 7> login.trace"
#
# See https://unix.stackexchange.com/a/154971/9032

# We know this file exists, or else there's a real bad problem. Also, each of
# these files will be shellchecked as well. Tell shellcheck to ignore this
# problem.
#
# shellcheck disable=SC1090
[[ -f $HOME/.bashrc ]] && source "$HOME/.bashrc"

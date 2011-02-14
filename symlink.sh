#!/bin/bash

#debug=echo

[[ -z ${HOME} ]] && $HOME='/home/harleypig'

SELF=$(basename $(readlink -f $0))
DOTFILE_DIR=$(dirname $(readlink -f $0))

# We want to link these files
DOTFILES=( $(ls -A ${DOTFILE_DIR}) )

for d in "${DOTFILES[@]}"
do

  [ $d == ${SELF} ] && continue
  [ $d == 'README' ] && continue
  [ $d == 'TODO' ] && continue

  $debug ln -s ${DOTFILE_DIR}/$d ${HOME}/$d

done

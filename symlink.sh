#!/bin/bash

[[ -z ${HOME} ]] && $HOME='/home/harleypig'

SELF=$(basename $(readlink -f $0))
DOTFILE_DIR=$(dirname $(readlink -f $0))

cd ${HOME}

# We want to link these files
DOTFILES=( $(ls -A ${DOTFILE_DIR}) )

for d in "${DOTFILES[@]}"
do

  [ $d == ${SELF} ] && continue
  [ $d == 'README' ] && continue
  [ $d == 'TODO' ] && continue

  ln -s ${DOTFILE_DIR}/$d ${HOME}/$d

done

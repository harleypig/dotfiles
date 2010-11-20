#!/bin/bash

[[ -z ${HOME} ]] && $HOME='/home/harleypig'

DOTFILE_DIR="${HOME}/projects/dotfiles"

cd ${HOME}

DOTFILE=
DOTFILE="${DOTFILE} .aptitude"
DOTFILE="${DOTFILE} .bash_aliases"
DOTFILE="${DOTFILE} .bash_completion.d"
DOTFILE="${DOTFILE} .bash_functions"
DOTFILE="${DOTFILE} .bash_logout"
DOTFILE="${DOTFILE} .bash_profile"
DOTFILE="${DOTFILE} .bash_prompt"
DOTFILE="${DOTFILE} .bashrc"
DOTFILE="${DOTFILE} .cvsrc"
DOTFILE="${DOTFILE} .elinks"
DOTFILE="${DOTFILE} .git"
DOTFILE="${DOTFILE} .gitconfig"
DOTFILE="${DOTFILE} .gitignore_global"
DOTFILE="${DOTFILE} .htoprc"
DOTFILE="${DOTFILE} .mplayer"
DOTFILE="${DOTFILE} .perldb"
DOTFILE="${DOTFILE} .perltidyrc"
DOTFILE="${DOTFILE} .screenrc"

for i in ${DOTFILE}
do

  ln -s ${DOTFILE_DIR}/$i ${HOME}/$i

done

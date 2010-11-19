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
DOTFILE="${DOTFILE} .calcurse"
DOTFILE="${DOTFILE} .cvsrc"
DOTFILE="${DOTFILE} .elinks"
DOTFILE="${DOTFILE} .flexget"
DOTFILE="${DOTFILE} .git"
DOTFILE="${DOTFILE} .gitconfig"
DOTFILE="${DOTFILE} .gitignore_global"
DOTFILE="${DOTFILE} .htoprc"
DOTFILE="${DOTFILE} .mplayer"
DOTFILE="${DOTFILE} .perldb"
DOTFILE="${DOTFILE} .perltidyrc"
DOTFILE="${DOTFILE} .rtorrent.rc"
DOTFILE="${DOTFILE} .screenrc"

for i in ${DOTFILE}
do

  echo ln -s ${DOTFILE_DIR}/$i ${HOME}/$i

done

#ln -s ${DOTFILE_DIR}/.bash_aliases ${HOME}/.bash_aliases
#ln -s ${DOTFILE_DIR}/.bash_completion.d ${HOME}/.bash_completion.d
#ln -s ${DOTFILE_DIR}/.bash_logout ${HOME}/.bash_logout
#ln -s ${DOTFILE_DIR}/.bash_profile ${HOME}/.bash_profile
#ln -s ${DOTFILE_DIR}/.bashrc ${HOME}/.bashrc
#ln -s ${DOTFILE_DIR}/.cvsrc ${HOME}/.cvsrc
#ln -s ${DOTFILE_DIR}/.gitconfig ${HOME}/.gitconfig
##ln -s ${DOTFILE_DIR}/.gitignore_global ${HOME}/.gitignore_global
#ln -s ${DOTFILE_DIR}/.htoprc ${HOME}/.htoprc
#ln -s ${DOTFILE_DIR}/.perldb ${HOME}/.perldb
#ln -s ${DOTFILE_DIR}/.perltidyrc ${HOME}/.perltidyrc
#ln -s ${DOTFILE_DIR}/.screenrc ${HOME}/.screenrc


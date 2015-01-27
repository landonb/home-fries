# File: vendor_dubsacks.sh
# Author: Landon Bouma (home-fries &#x40; retrosoft &#x2E; com)
# Last Modified: 2015.01.26
# Project Page: https://github.com/landonb/home_fries
# Summary: Dubsacks VIM setup script.
# License: GPLv3

if [[ -z ${DO_INSTALL_DUBSACKS+x} ]]; then
  DO_INSTALL_DUBSACKS=true
fi

REMOTE_URI_DUBSACKS_VIM_GIT="https://github.com/landonb/dubsacks_vim.git"

stage_4_dubsacks_install () {

  cd ${HOME}

  if [[ -e ${HOME}/.vimrc ]]; then
    mv ${HOME}/.vimrc ${HOME}/BACKUP-vimrc-`date +%Y_%m_%d`-`uuidgen`
  fi

  if [[ -e ${HOME}/.vimprojects ]]; then
    mv ${HOME}/.vimprojects ${HOME}/BACKUP-vimprojects-`date +%Y_%m_%d`-`uuidgen`
  fi

  if [[ -e ${HOME}/.vim ]]; then
    mv ${HOME}/.vim ${HOME}/BACKUP-vim-`date +%Y_%m_%d`-`uuidgen`
  fi

  git clone ${REMOTE_URI_DUBSACKS_VIM_GIT} ${HOME}/.vim

} # end: stage_4_dubsacks_install

# ==============================================================
# Application Main()

setup_dubsacks_go () {

  if $DO_INSTALL_DUBSACKS; then
    stage_4_dubsacks_install
  fi

} # end: setup_dubsacks_go

setup_dubsacks_go


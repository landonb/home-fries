# File: vendor_dubsacks.sh
# Author: Landon Bouma (landonb &#x40; retrosoft &#x2E; com)
# Last Modified: 2016.11.14
# Project Page: https://github.com/landonb/home_fries
# Summary: Dubsacks VIM setup script.
# License: GPLv3

set -e

if [[ -z ${DO_INSTALL_DUBSACKS+x} ]]; then
  DO_INSTALL_DUBSACKS=true
fi

if [[ -z ${URI_DUBSACKS_VIM_GIT+x} ]]; then
  URI_DUBSACKS_VIM_GIT="https://github.com/landonb/dubsacks_vim.git"
fi

source ./linux_setup_base.sh

stage_4_dubsacks_install () {

  pushd ${HOME} &> /dev/null

  if [[ -e ${HOME}/.vimrc && ! -h ${HOME}/.vimrc ]]; then
    echo
    echo "WARNING: Was not expecting ~/.vimrc: moving it aside"
    mv ${HOME}/.vimrc ${HOME}/BACKUP-vimrc-`date +%Y_%m_%d`-`uuidgen`
  fi

  if [[ -e ${HOME}/.vimprojects ]]; then
    echo
    echo "WARNING: Was not expecting ~/.vimprojects: moving it aside"
    mv ${HOME}/.vimprojects ${HOME}/.vimprojects-TBD-`date +%Y_%m_%d`-`uuidgen`
  fi

  if [[ -e ${HOME}/.vim ]]; then
    if [[ ! -d ${HOME}/.vim/.git ]]; then
      echo
      echo "WARNING: Was expecting ~/.vim to be a git repo: moving it aside"
      mv ${HOME}/.vim ${HOME}/.vim-TBD-`date +%Y_%m_%d`-`uuidgen`
    else 
      cd ${HOME}/.vim &> /dev/null
      set +e
      git remote -v | grep "landonb/dubsacks_vim.git" > /dev/null
      exit_code=$?
      set -e
      if [[ $exit_code -ne 0 ]]; then
        echo
        echo "WARNING: Was expecting ~/.vim to be the Dubsacks repo: moving it aside"
        mv ${HOME}/.vim ${HOME}/.vim-TBD-`date +%Y_%m_%d`-`uuidgen`
      fi
    fi
  fi

  if [[ ! -e ${HOME}/.vim ]]; then
    git clone ${URI_DUBSACKS_VIM_GIT} ${HOME}/.vim
    cd ${HOME}/.vim
  else
    cd ${HOME}/.vim
    git pull
  fi

  # Grab or update the submodules.
  # Also, create the ~/.vimrc symlink.
  ./setup.sh

  popd &> /dev/null

  # Dubsacks uses the Hack font.
  source custom_setup.extras.sh
  stage_4_font_typeface_hack
  stage_4_parT_install

} # end: stage_4_dubsacks_install

# ==============================================================
# Application Main()

setup_dubsacks_go () {

  if ${DO_INSTALL_DUBSACKS}; then
    stage_4_dubsacks_install
  fi

} # end: setup_dubsacks_go

if [[ "$0" == "$BASH_SOURCE" ]]; then
  # Only run when not being sourced.
  setup_dubsacks_go
fi

# Stupid message for debugging ./setup_ubuntu.sh
echo 'Thank you for dubssacking!'


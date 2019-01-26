# File: vendor_dubs-vim.sh
# Author: Landon Bouma (landonb &#x40; retrosoft &#x2E; com)
# Last Modified: 2017.10.03
# Project Page: https://github.com/landonb/home-fries
# Summary: Dubs Vim setup script.
# License: GPLv3

set -e

if [[ -z ${DO_INSTALL_DUBSVIM+x} ]]; then
  DO_INSTALL_DUBSVIM=true
fi

if [[ -z ${URI_DUBSVIM_GIT+x} ]]; then
  URI_DUBSVIM_GIT="https://github.com/landonb/dubs-vim.git"
fi

source ./linux_setup_base.sh

stage_4_dubsvim_install () {

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
      git remote -v | grep "landonb/dubs-vim.git" > /dev/null
      exit_code=$?
      set -e
      if [[ $exit_code -ne 0 ]]; then
        echo
        echo "WARNING: Was expecting ~/.vim to be the Dubs Vim repo: moving it aside"
        mv ${HOME}/.vim ${HOME}/.vim-TBD-`date +%Y_%m_%d`-`uuidgen`
      fi
    fi
  fi

  if [[ ! -e ${HOME}/.vim ]]; then
    git clone ${URI_DUBSVIM_GIT} ${HOME}/.vim
    cd ${HOME}/.vim
  else
    cd ${HOME}/.vim
    git pull
  fi

  # Grab or update the submodules.
  # Also, create the ~/.vimrc symlink.
  ./setup.sh

  popd &> /dev/null

  # Dubs Vim uses the Hack font.
  source custom_setup.extras.sh
  stage_4_font_typeface_hack
  stage_4_parT_install

} # end: stage_4_dubsvim_install

# ==============================================================
# Application Main()

setup_dubsvim_go () {

  if ${DO_INSTALL_DUBSVIM}; then
    stage_4_dubsvim_install
  fi

} # end: setup_dubsvim_go

if [[ "$0" == "$BASH_SOURCE" ]]; then
  # Only run when not being sourced.
  setup_dubsvim_go
fi

# Stupid message for debugging ./setup_ubuntu.sh
echo 'Thank you for dubsvimming!'


# File: vendor_dubsacks.sh
# Author: Landon Bouma (landonb &#x40; retrosoft &#x2E; com)
# Last Modified: 2016.07.17
# Project Page: https://github.com/landonb/home_fries
# Summary: Dubsacks VIM setup script.
# License: GPLv3

if [[ -z ${DO_INSTALL_DUBSACKS+x} ]]; then
  DO_INSTALL_DUBSACKS=true
fi

if [[ -z ${URI_DUBSACKS_VIM_GIT+x} ]]; then
  URI_DUBSACKS_VIM_GIT="https://github.com/landonb/dubsacks_vim.git"
fi

source ./mint17_setup_base.sh

stage_4_dubsacks_install () {

  pushd ${HOME} &> /dev/null

  if [[ ! -h ${HOME}/.vimrc ]]; then
    echo
    echo "WARNING: Was expecting .vimrc to be a symlink: moving it aside: ${HOME}/.vimrc"
    mv ${HOME}/.vimrc ${HOME}/BACKUP-vimrc-`date +%Y_%m_%d`-`uuidgen`
    /bin/ln -s .vim/bundle/dubs_all/.vimrc.bundle .vimrc
  fi

  if [[ -e ${HOME}/.vimprojects ]]; then
    echo
    echo "WARNING: Not expecting vimprojects: moving it aside: ${HOME}/.vimprojects"
    mv ${HOME}/.vimprojects ${HOME}/BACKUP-vimprojects-`date +%Y_%m_%d`-`uuidgen`
  fi

  if [[ -e ${HOME}/.vim && ! -d ${HOME}/.vim/.git ]]; then
    echo
    echo "WARNING: Was expecting vim to be a git repo: moving it aside: ${HOME}/.vim"
    mv ${HOME}/.vim ${HOME}/BACKUP-vim-`date +%Y_%m_%d`-`uuidgen`
  fi
  if [[ ! -e ${HOME}/.vim ]]; then
    git clone ${URI_DUBSACKS_VIM_GIT} ${HOME}/.vim

    # The clone doesn't grab the submodules.
    # Also, create the ~/.vimrc symlink.
    pushd ${HOME}/.vim &> /dev/null
    ./setup.sh
    popd &> /dev/null
  else
    pushd ${HOME}/.vim &> /dev/null
    # We'll just assume that *we* setup .vim already,
    # i.e., that this is our repo and not something else.
    # We could check that, say, ~/.vim/bundle/dubs_core exists,
    # but it's unlikely that that'll not be there, and if it isn't,
    # then you got bigger problems.
    git pull

    # Update the submodules.
    git submodule update --init --remote

    popd &> /dev/null
  fi

  popd &> /dev/null

  # Dubsacks uses the Hack font.
  source custom_mint17.extras.sh
  stage_4_font_typeface_hack
  stage_4_parT_install

  if false; then
    # FIXME/MAYBE: Implement this:
    pushd ${HOME} &> /dev/null
    m4 \
      --define=YOUR_FULL_NAME_HERE=${YOUR_FULL_NAME_HERE} \
      --define=YOUR_EMAIL_ADDY_HERE=${YOUR_EMAIL_ADDY_HERE} \
      --define=YOUR_GITHUB_USERNAME=${YOUR_GITHUB_USERNAME} \
      .cookiecutterrc.m4
    popd &> /dev/null
  fi

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

# Stupid message for debugging ./setup_mint17.sh.
echo 'Thank you for dubssacking!'


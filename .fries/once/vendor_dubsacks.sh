# File: vendor_dubsacks.sh
# Author: Landon Bouma (landonb &#x40; retrosoft &#x2E; com)
# Last Modified: 2016.03.23
# Project Page: https://github.com/landonb/home_fries
# Summary: Dubsacks VIM setup script.
# License: GPLv3

if [[ -z ${DO_INSTALL_DUBSACKS+x} ]]; then
  DO_INSTALL_DUBSACKS=true
fi

if [[ -z ${URI_DUBSACKS_VIM_GIT+x} ]]; then
  URI_DUBSACKS_VIM_GIT="https://github.com/landonb/dubsacks_vim.git"
fi

echo $URI_DUBSACKS_VIM_GIT

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

  git clone ${URI_DUBSACKS_VIM_GIT} ${HOME}/.vim

  # Dubsacks uses the Hack font.
  source custom_mint17.extras.sh
  stage_4_font_typeface_hack

  if false; then
    # FIXME/MAYBE: Implement this:
    cd ${HOME}
    m4 \
      --define=YOUR_FULL_NAME_HERE=${YOUR_FULL_NAME_HERE} \
      --define=YOUR_EMAIL_ADDY_HERE=${YOUR_EMAIL_ADDY_HERE} \
      --define=YOUR_GITHUB_USERNAME=${YOUR_GITHUB_USERNAME} \
      .cookiecutterrc.m4
  fi

} # end: stage_4_dubsacks_install

# ==============================================================
# Application Main()

setup_dubsacks_go () {

  if ${DO_INSTALL_DUBSACKS}; then
    stage_4_dubsacks_install
  fi

} # end: setup_dubsacks_go

setup_dubsacks_go


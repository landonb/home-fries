#!/bin/bash
#  vim:tw=0:ts=2:sw=2:et:norl:

# File: ~/.fries/once/installers/vim_from_source.sh
# Author: Landon Bouma (landonb &#x40; retrosoft &#x2E; com)
# Last Modified: 2017.10.03
# Project Page: https://github.com/landonb/home-fries
# Summary: Third-party tools downloads compiles installs.
# License: GPLv3

set -e

source ./_announcement.sh

if sudo -n true 2>/dev/null; then
  # Has sudo already.
  :
else
  #echo
  echo "LET'S GET THE PARTY STARTED"
  sudo -v
fi

# EXPLAIN/2017-04-03: Frack. I added this function 2017-02-27 10:17:12.
#   I think it was so Command-T in Vim (activated by Ctrl-D) would work
#   (otherwise, it complains that Vim's Ruby version differs from the OS's.)
function git_install_from_git_core_ppa () {
  if ${SKIP_EVERYTHING:-false}; then
    echo "Skipping task!"
    return
  fi

  PAUSE_BETWEEN_INSTALLS=false
  stage_announcement "git_install_from_git_core_ppa"

  pushd ${OPT_DLOADS:-/srv/opt/.downloads} &> /dev/null

  # 2016-09-28: Stock 16.04 (latest Ubuntu):
  #    $ git --version
  #    git version 2.7.4
  # After installing git maintainers repo:
  #    git version 2.10.0

  sudo add-apt-repository -y ppa:git-core/ppa
  sudo apt-get update
  sudo apt-get install -y git

  popd &> /dev/null

} # end: git_install_from_git_core_ppa

# 2017-02-25: :CommandT (<C-D>)
#   command-t.vim could not load the C extension
#   Please see INSTALLATION and TROUBLE-SHOOTING in the help
#   Vim Ruby version: 1.9.3-p551
#   Expected version: 2.3.3-p222
#   For more information type:    :help command-t
#stage_4_custom_compile_vim_with_latest_ruby
#git_install_from_git_core_ppa

if [[ "$0" == "$BASH_SOURCE" ]]; then
  # Only run when not being sourced.
  echo "Adding repo and installing!"
  git_install_from_git_core_ppa
  stage_curtains "git_install_from_git_core_ppa"
fi


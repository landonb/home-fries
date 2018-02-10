#!/bin/bash
#  vim:tw=0:ts=2:sw=2:et:norl:

# File: ~/.fries/once/installers/vim_from_source.sh
# Author: Landon Bouma (landonb &#x40; retrosoft &#x2E; com)
# Last Modified: 2017.12.05
# Project Page: https://github.com/landonb/home-fries
# Summary: Third-party tools downloads compiles installs.
# License: GPLv3

set -e

source ./_announcement.sh

# EXPLAIN/2017-04-03: Frack. I added this function 2017-02-27 10:17:12.
#   I think it was so Command-T in Vim (activated by Ctrl-D) would work
#   (otherwise, it complains that Vim's Ruby version differs from the OS's.)
function vim_clone_compile_install () {
  if ${SKIP_EVERYTHING:-false}; then
    echo "Skipping task!"
    return
  fi

  PAUSE_BETWEEN_INSTALLS=false
  stage_announcement "vim_clone_compile_install"

  pushd ${OPT_DLOADS:-/srv/opt/.downloads} &> /dev/null

  if [[ ! -d vim/ ]]; then
    git clone https://github.com/vim/vim
    cd vim
  else
    cd vim
    git pull
  fi
  # src/Make_mvc.mak

  # 2017-11-03: If commant-t does not work, e.g., Ctrl-D responds:
  #
  #   Vim Ruby version: 2.3.1-p112
  #   Expected version: 2.3.3-p222
  #
  # Make sure you build command-t with the system Ruby:
  #
  #   cd ~/.vim/bundle/command-t/ruby/command-t/ext/command-t
  #   chruby system
  #   ruby extconf.rb
  #   make

  # 2017-11-03: I am not sure these environs do anything,
  #   since the build just uses the system ruby...
  export RUBY_VER=23
  export RUBY_VER_LONG=2.3.3

  make clean
  # See `./configure --help`
  # - Add ruby for commandt
  # - Add python3 for ternjs
  # - Add python2 for vim-instanbul
  ./configure \
    --enable-pythoninterp=yes \
    --enable-python3interp=yes \
    --enable-rubyinterp=yes \
    --prefix=${OPT_BIN:-/srv/opt/bin}
  # -j 3 to use 3 CPU cores to build.
  make -j 3
  make install
  # Test with:
  #   :ruby puts RUBY_DESCRIPTION
  #   :!/usr/bin/ruby -v

  popd &> /dev/null

} # end: vim_clone_compile_install

# 2017-02-25: :CommandT (<C-D>)
#   command-t.vim could not load the C extension
#   Please see INSTALLATION and TROUBLE-SHOOTING in the help
#   Vim Ruby version: 1.9.3-p551
#   Expected version: 2.3.3-p222
#   For more information type:    :help command-t
#stage_4_custom_compile_vim_with_latest_ruby
#vim_clone_compile_install

if [[ "$0" == "$BASH_SOURCE" ]]; then
  # Only run when not being sourced.
  echo "Clone-compile-installing!"
  vim_clone_compile_install
  stage_curtains "vim_clone_compile_install"
fi


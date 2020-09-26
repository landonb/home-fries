#!/usr/bin/env bash
# vim:tw=0:ts=2:sw=2:et:norl:ft=sh
# Author: Landon Bouma (landonb &#x40; retrosoft &#x2E; com)
# Project: https://github.com/landonb/home-fries#🍟
# License: MIT

# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #

home_fries_configure_gpg_tty () {
  # For pinentry (for vim-gnupg):
  export GPG_TTY=`tty`
}

# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #

main () {
  :
}

main "$@"
unset -f main


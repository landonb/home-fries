#!/usr/bin/env bash
# vim:tw=0:ts=2:sw=2:et:norl:ft=sh
# Author: Landon Bouma (landonb &#x40; retrosoft &#x2E; com)
# Project: https://github.com/landonb/home-fries#🍟
# License: MIT

# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #

check_deps () {
  check_dep 'rm_safe'
  check_dep 'rm_rotate'
}

# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #

# Fix `rm` to be a respectable trashcan.
home_fries_create_aliases_trash () {
  RM_SAFE_TRASH_HOME="${RM_SAFE_TRASH_HOME:-${HOME}}"
  alias rm='rm_safe'
  alias rmtrash='rm_rotate'
}

# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #

main () {
  check_deps
  unset -f check_deps
}

main "$@"
unset -f main


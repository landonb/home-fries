#!/usr/bin/env bash
# vim:tw=0:ts=2:sw=2:et:norl:ft=sh
# Author: Landon Bouma (landonb &#x40; retrosoft &#x2E; com)
# Project: https://github.com/landonb/home-fries#🍟
# License: MIT

# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #

function is_mount_type_crypt () {
  local curious_path="$1"
  local is_crypt
  lsblk --output TYPE,MOUNTPOINT |
    grep crypt |
    grep "^crypt \\+${curious_path}\$" \
      > /dev/null \
  && is_crypt=0 || is_crypt=1

  return ${is_crypt}
}

# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #

main () {
  :
}

main "$@"
unset -f main


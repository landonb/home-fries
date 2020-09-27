#!/usr/bin/env bash
# vim:tw=0:ts=2:sw=2:et:norl:ft=sh
# Author: Landon Bouma (landonb &#x40; retrosoft &#x2E; com)
# Project: https://github.com/landonb/home-fries#🍟
# License: MIT

# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #

home_fries_aliases_wire_python () {
  # [lb]: Python aliases for my lazy fingers.

  if ! command -v py &> /dev/null; then
    # [lb]: 2018-12-26: By convention, py should probably
    # run python2, but lately I've been living dangerously.
    alias py='/usr/bin/env python3'
  fi

  if ! command -v py2 &> /dev/null; then
    alias py2='/usr/bin/env python2'
  fi

  if ! command -v py3 &> /dev/null; then
    alias py3='/usr/bin/env python3'
  fi
}

# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #

unset_f_alias_python () {
  unset -f home_fries_aliases_wire_python
  # So meta.
  unset -f unset_f_alias_python
}

# @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@ #

main () {
  :
}

main ""
unset -f main

#!/usr/bin/env bash
# vim:tw=0:ts=2:sw=2:et:norl:ft=sh
# Author: Landon Bouma (landonb &#x40; retrosoft &#x2E; com)
# Project: https://github.com/landonb/home-fries#🍟
# License: MIT

# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #

home_fries_aliases_wire_cp () {
  # NOTE: Sometimes the -i doesn't get overriden by -f so it's best to call
  #       `/bin/cp` or `\cp` and not `cp -f` if you want to overwrite files.
  alias cp='cp -i'
}

# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #

unset_f_alias_cp () {
  unset -f home_fries_aliases_wire_cp
  # So meta.
  unset -f unset_f_alias_cp
}

# @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@ #

main () {
  :
}

main ""
unset -f main


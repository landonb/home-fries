#!/usr/bin/env bash
# vim:tw=0:ts=2:sw=2:et:norl:ft=sh
# Author: Landon Bouma (landonb &#x40; retrosoft &#x2E; com)
# Project: https://github.com/landonb/home-fries#🍟
# License: MIT

# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #

# less options:
#   -r  Raw control characters.
#   -R  Better Raw control characters (i.e., color).
#   -f  "Forces non-regular files to be opened."
#       "Also suppresses the warning message when a binary file is opened."
home_fries_aliases_wire_less () {
  alias less='less -Rf'
}

# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #

unset_f_alias_less () {
  unset -f home_fries_aliases_wire_less
  # So meta.
  unset -f unset_f_alias_less
}

# @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@ #

if [ "$0" = "${BASH_SOURCE[0]}" ]; then
  >&2 echo "ERROR: Trying sourcing the file instead: . $0" && exit 1
fi


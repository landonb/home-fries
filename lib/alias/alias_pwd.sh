#!/usr/bin/env bash
# vim:tw=0:ts=2:sw=2:et:norl:ft=sh
# Author: Landon Bouma (landonb &#x40; retrosoft &#x2E; com)
# Project: https://github.com/landonb/home-fries#🍟
# License: MIT

# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #

home_fries_aliases_wire_pwd () {
  # [lb] uses p frequently, just like h and ll.
  claim_alias_or_warn "p" "pwd"

  # 2021-01-28: A real wisenheimer.
  claim_alias_or_warn "P" 'pwd && pwd | tr -d "\n" | xclip -selection c'
}

# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #

unset_f_alias_pwd () {
  unset -f home_fries_aliases_wire_pwd
  # So meta.
  unset -f unset_f_alias_pwd
}

# @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@ #

if [ "$0" = "${BASH_SOURCE[0]}" ]; then
  >&2 echo "ERROR: Trying sourcing the file instead: . $0" && exit 1
fi


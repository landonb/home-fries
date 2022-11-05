#!/usr/bin/env bash
# vim:tw=0:ts=2:sw=2:et:norl:ft=sh
# Author: Landon Bouma (landonb &#x40; retrosoft &#x2E; com)
# Project: https://github.com/landonb/home-fries#🍟
# License: MIT

# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #

home_fries_aliases_wire_pwgen () {
  # 2016-09-24: Why didn't I think of this 'til now?
  # [Note also that pass can just do it, too.]
  claim_alias_or_warn "pwgen16" "pwgen -n 16 -s -N 1 -y"
  claim_alias_or_warn "pwgen21" "pwgen -n 21 -s -N 1 -y"

  # 2022-09-25: To make double-clicking passwords in the terminal easier
  # to copy-paste, ensure first two and final two characters are alphanums.
  # Not to give the game away. The password is still secure. At least
  # until quantum computing screws us over and we all need to move to
  # elliptic-curve cryptography.
  # - Note the surrounding () is necessary for redirection, e.g., `pwgen23 > foo`.
  claim_alias_or_warn "pwgen23" "( pwgen 2 1 | tr -d '\n' ; pwgen -n 21 -s -N 1 -y | tr -d '\n' ; pwgen 2 1 )"
}

# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #

unset_f_alias_pwgen () {
  unset -f home_fries_aliases_wire_pwgen
  # So meta.
  unset -f unset_f_alias_pwgen
}

# @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@ #

if [ "$0" = "${BASH_SOURCE[0]}" ]; then
  >&2 echo "ERROR: Trying sourcing the file instead: . $0" && exit 1
fi


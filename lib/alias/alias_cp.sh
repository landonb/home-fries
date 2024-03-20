#!/usr/bin/env bash
# vim:tw=0:ts=2:sw=2:et:norl:ft=sh
# Author: Landon Bouma (landonb &#x40; retrosoft &#x2E; com)
# Project: https://github.com/landonb/home-fries#🍟
# License: MIT

# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #

# SAVVY: Unless `cp -f`, the ~/.homefries/bin/cp command calls `cp -i`.
# - To use system cp, run: `/bin/cp`, `command cp`, `\cp` `"cp"`,
#                          `'cp'`, `/usr/bin/env cp`, or `env cp`

home_fries_aliases_wire_cp () {
  alias cp="${HOMEFRIES_BIN:-${HOME}/.homefries/bin}/cp_safe"
}

# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #

unset_f_alias_cp () {
  unset -f home_fries_aliases_wire_cp
  # So meta.
  unset -f unset_f_alias_cp
 }

# @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@ #

if [ "$0" = "${BASH_SOURCE[0]}" ]; then
  >&2 echo "ERROR: Trying sourcing the file instead: . $0" && exit 1
fi


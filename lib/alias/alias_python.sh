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
    claim_alias_or_warn "py" "/usr/bin/env python3"
  fi

  if ! command -v py2 &> /dev/null; then
    claim_alias_or_warn "py2" "/usr/bin/env python2"
  fi

  if ! command -v py3 &> /dev/null; then
    claim_alias_or_warn "py3" "/usr/bin/env python3"
  fi
}

# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #

home_fries_aliases_wire_poetry () {
  # [lb]: More Python aliases for my lazy fingers.

  # Note that we edit Poetry completion to recognize `po`, too.
  if ! command -v po &> /dev/null; then
    claim_alias_or_warn "po" "/usr/bin/env poetry"
  fi
}

# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #

unset_f_alias_python () {
  unset -f home_fries_aliases_wire_python

  unset -f home_fries_aliases_wire_poetry

  # So meta.
  unset -f unset_f_alias_python
}

# @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@ #

if [ "$0" = "${BASH_SOURCE[0]}" ]; then
  >&2 echo "ERROR: Trying sourcing the file instead: . $0" && exit 1
fi


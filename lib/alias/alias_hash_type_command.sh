#!/usr/bin/env bash
# vim:tw=0:ts=2:sw=2:et:norl:ft=sh
# Author: Landon Bouma (landonb &#x40; retrosoft &#x2E; com)
# Project: https://github.com/landonb/home-fries#🍟
# License: MIT

# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #

# Similar commands: `hash`, `type -a`, `command -v`.
home_fries_aliases_wire_hash_type_command () {
  # Show executable path or alias definition.
  claim_alias_or_warn "cmd" "command -v"

  # `where`, of a sort.
  claim_alias_or_warn "whence" "type -a"
}

# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #

unset_f_alias_hash_type_command () {
  unset -f home_fries_aliases_wire_hash_type_command
  # So meta.
  unset -f unset_f_alias_hash_type_command
}

# @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@ #

if [ "$0" = "${BASH_SOURCE[0]}" ]; then
  >&2 echo "ERROR: Trying sourcing the file instead: . $0" && exit 1
fi


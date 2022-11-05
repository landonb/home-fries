#!/usr/bin/env bash
# vim:tw=0:ts=2:sw=2:et:norl:ft=sh
# Author: Landon Bouma (landonb &#x40; retrosoft &#x2E; com)
# Project: https://github.com/landonb/home-fries#🍟
# License: MIT

# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #

# Note that /usr/bin/ht runs tex4ht programs, "used to convert TeX source
# files from numerous dialects of TeX into different hypertext variants."
# - I'm not aware of anyway nowadays (at least not running around in my
#   dev circles) that uses this program. So, yes, this is one of the rare
#   times where Homefries shadows an existing command.
home_fries_aliases_wire_htop () {
  # claim_alias_or_warn "ht" "htop"
  alias ht="htop"
}

# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #

unset_f_alias_htop () {
  unset -f home_fries_aliases_wire_htop
  # So meta.
  unset -f unset_f_alias_htop
}

# @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@ #

if [ "$0" = "${BASH_SOURCE[0]}" ]; then
  >&2 echo "ERROR: Trying sourcing the file instead: . $0" && exit 1
fi


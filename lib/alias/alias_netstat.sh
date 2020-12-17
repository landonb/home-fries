#!/usr/bin/env bash
# vim:tw=0:ts=2:sw=2:et:norl:ft=sh
# Author: Landon Bouma (landonb &#x40; retrosoft &#x2E; com)
# Project: https://github.com/landonb/home-fries#🍟
# License: MIT

# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #

home_fries_aliases_wire_netstat () {
  # See also: `ss`, fresher than netstat.
  #   "Netstat and ifconfig are part of net-tools, while ss and ip are part of iproute2."
  #   https://utcc.utoronto.ca/~cks/space/blog/linux/ReplacingNetstatNotBad
  alias n='netstat -tulpn'  # --tcp --udp --listening --program (name) --numeric
}

# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #

unset_f_alias_netstat () {
  unset -f home_fries_aliases_wire_netstat
  # So meta.
  unset -f unset_f_alias_netstat
}

# @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@ #

if [ "$0" = "${BASH_SOURCE[0]}" ]; then
  >&2 echo "ERROR: Trying sourcing the file instead: . $0" && exit 1
fi


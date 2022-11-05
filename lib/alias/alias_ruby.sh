#!/usr/bin/env bash
# vim:tw=0:ts=2:sw=2:et:norl:ft=sh
# Author: Landon Bouma (landonb &#x40; retrosoft &#x2E; com)
# Project: https://github.com/landonb/home-fries#🍟
# License: MIT

# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #

home_fries_aliases_wire_ruby () {
  # 2016-12-06: Not sure I need this... probably not.
  false && (
    if [ ! -e "/usr/bin/ruby1" ]; then
     claim_alias_or_warn "ruby1" "/usr/bin/env ruby1.9.1"
    fi
    if [ ! -e "/usr/bin/ruby2" ]; then
      # claim_alias_or_warn "ruby2" "/usr/bin/env ruby2.0"
      # claim_alias_or_warn "ruby2" "/usr/bin/env ruby2.2"
      claim_alias_or_warn "ruby2" "/usr/bin/env ruby2.3"
    fi
  )
}

# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #

home_fries_unset_f_alias_ruby () {
  unset -f home_fries_aliases_wire_ruby
  # So meta.
  unset -f home_fries_unset_f_alias_ruby
}

# @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@ #

if [ "$0" = "${BASH_SOURCE[0]}" ]; then
  >&2 echo "ERROR: Trying sourcing the file instead: . $0" && exit 1
fi


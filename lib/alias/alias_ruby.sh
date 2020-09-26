#!/usr/bin/env bash
# vim:tw=0:ts=2:sw=2:et:norl:ft=sh
# Author: Landon Bouma (landonb &#x40; retrosoft &#x2E; com)
# Project: https://github.com/landonb/home-fries#🍟
# License: MIT

# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #

home_fries_aliases_wire_ruby () {
  # 2016-12-06: Not sure I need this... probably not.
  #if [[ ! -e "/usr/bin/ruby1" ]]; then
  #  alias ruby1='/usr/bin/env ruby1.9.1'
  #fi
  #if [[ ! -e "/usr/bin/ruby2" ]]; then
  #  #alias ruby2='/usr/bin/env ruby2.0'
  #  #alias ruby2='/usr/bin/env ruby2.2'
  #  alias ruby2='/usr/bin/env ruby2.3'
  #fi
  :
}

# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #

unset_f_alias_ruby () {
  unset -f home_fries_aliases_wire_ruby
  # So meta.
  unset -f unset_f_alias_ruby
}

# @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@ #

main () {
  :
}

main ""
unset -f main


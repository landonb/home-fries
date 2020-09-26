#!/usr/bin/env bash
# vim:tw=0:ts=2:sw=2:et:norl:ft=sh
# Author: Landon Bouma (landonb &#x40; retrosoft &#x2E; com)
# Project: https://github.com/landonb/home-fries#🍟
# License: MIT

# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #

# Show grep differences in colour.
home_fries_aliases_wire_grep () {
  alias grep='grep --color'
}

# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #

# Include preferred egrep switches and excludes.
#   -n, --line-number
#   -R, --dereference-recursive
#   -i, --ignore-case
home_fries_aliases_wire_egrep () {
  if [ -e "$HOME/.grepignore" ]; then
    alias eg='egrep -n -R -i --color --exclude-from="$HOME/.grepignore"'
    alias egi='egrep -n -R --color --exclude-from="$HOME/.grepignore"'
  fi
}

# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #

home_fries_aliases_wire_grep_egrep () {
  home_fries_aliases_wire_grep
  home_fries_aliases_wire_egrep
}

# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #

unset_f_alias_grep_egrep () {
  unset -f home_fries_aliases_wire_grep_egrep
  unset -f home_fries_aliases_wire_grep
  unset -f home_fries_aliases_wire_egrep
  # So meta.
  unset -f unset_f_alias_grep_egrep
}

# @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@ #

main () {
  :
}

main ""
unset -f main


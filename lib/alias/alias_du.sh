#!/usr/bin/env bash
# vim:tw=0:ts=2:sw=2:et:norl:ft=sh
# Author: Landon Bouma (landonb &#x40; retrosoft &#x2E; com)
# Project: https://github.com/landonb/home-fries#🍟
# License: MIT

# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #

home_fries_aliases_wire_du () {
  alias du='du -h'

  alias dum="du -m -d 1 . | sort -n"

  alias dub="du -b -d 1 . | sort -n"

  # alias duhome='du -ah /home | sort -n'

  # Use same units, else sort mingles different sizes.
  # cd ~ && du -BG -d 1 . | sort -n

  # See also the `free` alias.

  # List the top 20 files/folders sizes.
  alias ddu='du -sh * | sort -hr | head -20'
}

# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #

unset_f_alias_du () {
  unset -f home_fries_aliases_wire_du
  # So meta.
  unset -f unset_f_alias_du
}

# @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@ #

if [ "$0" = "${BASH_SOURCE[0]}" ]; then
  >&2 echo "ERROR: Trying sourcing the file instead: . $0" && exit 1
fi


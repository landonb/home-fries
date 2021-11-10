#!/usr/bin/env bash
# vim:tw=0:ts=2:sw=2:et:norl:ft=sh
# Author: Landon Bouma (landonb &#x40; retrosoft &#x2E; com)
# Project: https://github.com/landonb/home-fries#🍟
# License: MIT

# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #

# 2020-09-26: -H/--hidden: Include hidden files and directories
# 2021-11-10: -I/--no-ignore: Ignore .gitignore, .ignore or .fdignore rules.
home_fries_aliases_wire_fd () {
  if command -v fd > /dev/null; then
    alias fd="fd -H -I"
  fi
}

# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #

unset_f_alias_fd () {
  unset -f home_fries_aliases_wire_fd
  # So meta.
  unset -f unset_f_alias_fd
}

# @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@ #

if [ "$0" = "${BASH_SOURCE[0]}" ]; then
  >&2 echo "ERROR: Trying sourcing the file instead: . $0" && exit 1
fi


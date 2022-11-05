#!/usr/bin/env bash
# vim:tw=0:ts=2:sw=2:et:norl:ft=sh
# Author: Landon Bouma (landonb &#x40; retrosoft &#x2E; com)
# Project: https://github.com/landonb/home-fries#🍟
# License: MIT

# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #

check_deps () {
  # Verify .homefries/lib/distro_util.sh loaded.
  check_dep 'os_is_macos'
}

# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #

home_fries_aliases_wire_df () {
  # Show resource usage, and default to human readable figures.
  # df -h: "Human-readable" output. [Not sure why man uses quotes.]
  # E.g., without -h:
  #         Filesystem  1K-blocks      Used Available Use% Mounted on
  #         /foo/bar    926199176 628671508 250409540  72% /baz/bat
  # and then with -h:
  #         Filesystem  Size  Used Avail Use% Mounted on
  #         /foo/bar    884G  600G  239G  72% /baz/bat
  if os_is_linux; then
    alias df="df -h -T"
  elif os_is_macos; then
    alias df="df -h"
  fi
}

# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #

unset_f_alias_df () {
  unset -f check_deps
  unset -f home_fries_aliases_wire_df
  # So meta.
  unset -f unset_f_alias_df
}

# @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@ #

_homefries_warn_on_execute () {
  >&2 echo "ERROR: Trying sourcing the file instead: . $0" && exit 1
}

main () {
  check_deps
  unset -f check_deps
}

if [ "$0" = "${BASH_SOURCE[0]}" ]; then
  _homefries_warn_on_execute
else
  main "$@"
fi
unset -f _homefries_warn_on_execute
unset -f main


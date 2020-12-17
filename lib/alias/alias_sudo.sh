#!/usr/bin/env bash
# vim:tw=0:ts=2:sw=2:et:norl:ft=sh
# Author: Landon Bouma (landonb &#x40; retrosoft &#x2E; com)
# Project: https://github.com/landonb/home-fries#🍟
# License: MIT

# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #

home_fries_aliases_wire_sudo () {
  # Apply alias resolution to whatever term follows a `sudo`.
  # 2019-03-26: From Bash manual: "If the last character of the alias value is
  # a space or tab character, then the next command word following the alias is
  # also checked for alias expansion."
  # E.g., by default, `sudo ll`'s sudo is checked for alias, but not ll -- and
  # alias is checked against current user's profile (and root's is not loaded).
  # With this trick, in `sudo ll`, both the `sudo` and the `ll` are alias-checked.
  # Thanks also:
  #   https://askubuntu.com/questions/22037/aliases-not-available-when-using-sudo
  alias sudo='sudo '
}

# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #

unset_f_alias_sudo () {
  unset -f home_fries_aliases_wire_sudo
  # So meta.
  unset -f unset_f_alias_sudo
}

# @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@ #

if [ "$0" = "${BASH_SOURCE[0]}" ]; then
  >&2 echo "ERROR: Trying sourcing the file instead: . $0" && exit 1
fi


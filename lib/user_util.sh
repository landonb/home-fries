#!/usr/bin/env bash
# vim:tw=0:ts=2:sw=2:et:norl:ft=sh
# Author: Landon Bouma (landonb &#x40; retrosoft &#x2E; com)
# Project: https://github.com/landonb/home-fries#🍟
# License: MIT

# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #

check_deps () {
  # Verify os_is_macos loaded, and then assume os_is_linux.
  check_dep 'os_is_macos'
}

# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #

# user_name_full aka user_full_name aka print the user's full name.
user_name_full () {
  os_is_linux && user_name_full_linux && return
  os_is_macos && user_name_full_macos && return

  >&2 echo "I have no idea what their name is."
}

# REFER: https://stackoverflow.com/questions/833227/
#   whats-the-easiest-way-to-get-a-users-full-name-on-a-linux-posix-system
user_name_full_linux () {
  getent passwd $(id -un) | cut -d ':' -f 5 | cut -d ',' -f 1
}

# REFER: https://apple.stackexchange.com/questions/269066/
#   how-can-i-obtain-the-full-name-of-the-currently-logged-in-user-via-terminal-when
user_name_full_macos () {
  id -P $(stat -f%Su /dev/console) | cut -d : -f 8
}

# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #

main () {
  check_deps
  unset -f check_deps
}

main "$@"
unset -f main


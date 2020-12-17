#!/usr/bin/env bash
# vim:tw=0:ts=2:sw=2:et:norl:ft=sh
# Author: Landon Bouma (landonb &#x40; retrosoft &#x2E; com)
# Project: https://github.com/landonb/home-fries#🍟
# License: MIT

# 2020-12-16: A snip from 2018-01-29 I don't use directly (you'll
# find different iterations of it, including Bash-only ones that
# use ${YES_OR_NO^^} instead of POSIX-friendly first_char_capped).

# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #

source_deps () {
  # Load: term_util.sh deps.
  . "${SHOILERPLATE:-${HOME}/.kit/sh}/sh-colors/bin/colors.sh"
  . "${SHOILERPLATE:-${HOME}/.kit/sh}/sh-logger/bin/logger.sh"
  . "${HOMEFRIES_LIB:-${HOME}/.homefries/lib}/distro_util.sh"

  # Load: first_char_capped.
  . "${HOMEFRIES_LIB:-${HOME}/.homefries/lib}/term_util.sh"
}

# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #

default_yes_question () {
  printf %s "Tell me yes or no. [Y/n] "
  read -e YES_OR_NO
  if [ -z "${YES_OR_NO}" ] || [ "$(first_char_capped ${YES_OR_NO})" = 'Y' ]; then
    echo "YESSSSSSSSSSSSS"
  else
    echo "Apparently not"
  fi
}

# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #

main () {
  source_deps

  default_yes_question
}

main "$@"
unset -f main


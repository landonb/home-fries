#!/usr/bin/env sh
# vim:tw=0:ts=2:sw=2:et:norl:ft=bash
# Author: Landon Bouma (landonb &#x40; retrosoft &#x2E; com)
# Project: https://github.com/landonb/home-fries#🍟
# License: MIT

# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #

# 2020-12-16: A snip from 2018-01-29 I don't use directly (you'll
# find different iterations of it, including Bash-only ones that
# use ${YES_OR_NO^^} instead of POSIX-friendly first_char_capped).

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

# 2020-08-25: Replace ${VAR^^} with POSIX-compliant pipe chain (because macOS's
# deprecated Bash is 3.x and does not support ${VAR^^} capitalization operator,
# and the now-default zsh shell does not support ${VAR^^} capitalization).
first_char_capped () {
  printf "$1" | cut -c1-1 | tr '[:lower:]' '[:upper:]'
}

# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #

# Run the function if being executed.
# Otherwise being sourced, so do not.
SCRIPT_NAME="default_yes_question.sh"
if [ "$(basename -- "$(realpath -- "$0")")" = "${SCRIPT_NAME}" ]; then
  default_yes_question "$@"
fi


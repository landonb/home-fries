#!/usr/bin/env bash
# vim:tw=0:ts=2:sw=2:et:norl:ft=bash
# Author: Landon Bouma (landonb &#x40; retrosoft &#x2E; com)
# Project: https://github.com/landonb/home-fries#🍟
# License: MIT

# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #

# MAYBE/2026-05-14 19:00: DRY.
# COPYD:
# ~/.depoxy/ambers/bin/demo-terminal-output-styles

prompt_user_to_continue() {
  printf "Continue? [Y/n] "

  read -n 1 the_choice

  # >&2 echo "the_choice: )))${the_choice}((("

  # Flush stdin.
  local its_complicated=false
  if read -t 0 notused; then
    local _ignored
    read -t 0.1 _ignored
    # Assume arrow key pressed, e.g., <Right>, and *don't* break.
    its_complicated=true
  fi

  # ***

  if false ||
    [ -z "${the_choice}" ] ||
    [ "${the_choice}" = "y" ] ||
    [ "${the_choice}" = "Y" ] ||
    ${its_complicated} \
    ; then

    return 0
  fi

  return 1
}

# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #

main() {
  set -e

  prompt_user_to_continue "$@"
}

# Only run when executed; no-op when sourced.
if [ -n "${BASH_SOURCE}" ] && [ "$0" = "${BASH_SOURCE[0]}" ]; then
  main "$@"
fi

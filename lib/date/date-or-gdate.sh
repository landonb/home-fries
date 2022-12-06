#!/usr/bin/env bash
# vim:tw=0:ts=2:sw=2:et:norl:ft=sh
# Author: Landon Bouma (landonb &#x40; retrosoft &#x2E; com)
# Project: https://github.com/landonb/home-fries#🍟
# License: MIT

# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #

date-or-gdate () {
  if date --help > /dev/null 2>&1; then
    # GNU `date` verified.
    echo "date"
  elif command -v gdate > /dev/null; then
    echo "gdate"
  else
    >&2 echo "ERROR: GNU \`date\` not found"
  fi
}

# ***

date-or-gdate--complicated () {
  if ! os_is_macos; then
    command -v date
  elif date --help > /dev/null 2>&1; then
    # `date` is GNU.
    echo date
  elif [ -n "${HOMEBREW_PREFIX}" ]; then
    local gdate="${HOMEBREW_PREFIX}/bin/gdate"

    if [ -x "${gdate}" ]; then
      echo "${gdate}"
    else
      >&2 echo "ERROR: Not found or not executable: ${gdate}"
    fi
  else
    >&2 echo "ERROR: GNU \`date\` not found"
  fi
}

# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #

main () {
  :
}

main "$@"
unset -f main


#!/usr/bin/env bash
# vim:tw=0:ts=2:sw=2:et:norl:ft=sh
# Author: Landon Bouma <https://tallybark.com/>
# Project: https://github.com/landonb/home-fries#🍟
# License: MIT

# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #

set -e

# ctags doesn't handle negative look behinds so instead this script
# strips false positives out of a tags file.

_ctags() {
  local found=false

  for cmd in "ctags-universal" "ctags"; do
    if command -v ${cmd} 2>/dev/null; then
      found=true

      break
    fi
  done

  if ! ${found}; then
    >&2 echo "ERROR: Ctags not found (neither Universal nor Exuberant)"

    return 1
  fi
}

# Guard clause: Print error and exit if no Ctags.
_ctags >/dev/null

# Call Ctags.
$(_ctags) "$@"

FILE="tags"

while [[ $# > 1 ]]; do
  key="$1"

  case $key in
  -f)
    FILE="$2"

    shift
    ;;
  esac

  shift
done

# Filter out false matches from class method regex
/usr/bin/env sed -i -E \
  '/^(if|switch|function|module\.exports|it|describe)	.+language:js$/d' \
  ${FILE}

# Filter out false matches from object definition regex
/usr/bin/env sed -i -E \
  '/var[ 	]+[a-zA-Z0-9_$]+[ 	]+=[ 	]+require\(.+language:js$/d' \
  ${FILE}

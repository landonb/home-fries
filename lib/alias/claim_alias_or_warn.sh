#!/usr/bin/env bash
# vim:tw=0:ts=2:sw=2:et:norl:ft=sh
# Author: Landon Bouma (landonb &#x40; retrosoft &#x2E; com)
# Project: https://github.com/landonb/home-fries#🍟
# License: MIT

# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #

claim_alias_or_warn () {
  local the_alias="$1"
  local the_command="$2"

  if ! type "${the_alias}" > /dev/null 2>&1; then
    eval "alias ${the_alias}=\"${the_command}\""
  else
    >&2 echo "WARNING: Refusing to alias existing command “${the_alias}”."
  fi
}

# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #


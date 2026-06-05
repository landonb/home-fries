#!/usr/bin/env bash
# vim:tw=0:ts=2:sw=2:et:norl:ft=sh
# Author: Landon Bouma (landonb &#x40; retrosoft &#x2E; com)
# Project: https://github.com/landonb/home-fries#🍟
# License: MIT

# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #

claim_alias_or_warn() {
  local the_alias="$1"
  local the_command="$2"
  local force=${3:-false}

  if [ $# -lt 1 ] || [ $# -gt 3 ]; then
    >&2 echo "USAGE: claim_alias_or_warn <alias> <command> [force?]"

    return 1
  fi

  if ${force} || ! type "${the_alias}" >/dev/null 2>&1; then
    eval "alias ${the_alias}=\"${the_command}\""
  else
    >&2 echo "WARNING: Refusing to alias existing command “${the_alias}”."
  fi
}

# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #

#!/bin/sh
# vim:tw=0:ts=2:sw=2:et:norl:nospell:ft=sh

source_deps () {
# FIXME/2019-10-26 03:20: Improve sourcing...
  # Load: warn, etc.
  . ${HOME}/.fries/lib/logger.sh
}

# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #

remote_add () {
  local remote_name="$1"
  local remote_url="$2"

  git remote remove "$1" 2> /dev/null || true
  git remote add "$1" "$2"
}

# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #

main () {
  source_deps
}

main "$@"


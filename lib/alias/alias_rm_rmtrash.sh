#!/usr/bin/env bash
# vim:tw=0:ts=2:sw=2:et:norl:ft=sh
# Author: Landon Bouma (landonb &#x40; retrosoft &#x2E; com)
# Project: https://github.com/landonb/home-fries#🍟
# License: MIT

# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #

check_deps () {
  check_dep 'rm_safe'
  check_dep 'rm_rotate'
}

# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #

# Change `rm` into a respectable trashcan.
home_fries_aliases_wire_rm_rmtrash () {
  RM_SAFE_TRASH_HOME="${RM_SAFE_TRASH_HOME:-${HOME}}"

  # Use full path so `sudo rm` works.
  alias rm="${SHOILERPLATE:-${HOME}/.kit/sh}/sh-rm_safe/bin/rm_safe"

  claim_alias_or_warn "rmtrash" "rm_rotate"

  # Remove a glob of files and include .dotted (hidden) files.
  # - CXREF: See extensive comments re: `alias mv`:
  #   ~/.homefries/lib/alias/alias_mv.sh
  claim_alias_or_warn "rm." "set +f ; shopt -s dotglob ; rm_dotglob"
  claim_alias_or_warn "rm_all" "set +f ; shopt -s dotglob ; rm_dotglob"
}

# - CXREF: See extensive comments re: `mv_dotglob`:
#   ~/.homefries/lib/alias/alias_mv.sh

rm_dotglob () {
  ${SHOILERPLATE:-${HOME}/.kit/sh}/sh-rm_safe/bin/rm_safe "$@"

  # Leave noglob unset (set +f)
  #  set -f

  shopt -u dotglob
}

# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #

unset_f_alias_rm_rmtrash () {
  unset -f home_fries_aliases_wire_rm_rmtrash
  # So meta.
  unset -f unset_f_alias_rm_rmtrash
}

# @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@ #

_homefries_warn_on_execute () {
  >&2 echo "ERROR: Trying sourcing the file instead: . $0" && exit 1
}

main () {
  check_deps
  unset -f check_deps
}

if [ "$0" = "${BASH_SOURCE[0]}" ]; then
  _homefries_warn_on_execute
else
  main "$@"
fi
unset -f _homefries_warn_on_execute
unset -f main


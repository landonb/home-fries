#!/usr/bin/env bash
# vim:tw=0:ts=2:sw=2:et:norl:ft=sh
# Author: Landon Bouma (landonb &#x40; retrosoft &#x2E; com)
# Project: https://github.com/landonb/home-fries#🍟
# License: MIT

# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #

# SAVVY: Unless `cp -f`, the ~/.homefries/bin/cp command calls `cp -i`.
# - To use system cp, run: `/bin/cp`, `command cp`, `\cp` `"cp"`,
#                          `'cp'`, `/usr/bin/env cp`, or `env cp`

# CXREF: ~/.homefries/bin/cp_safe
home_fries_aliases_wire_cp () {
  alias cp="${SHOILERPLATE:-${HOME}/.kit/sh}/sh-rm_safe/bin/cp_safe"

  # Copy a glob of files and include .dotted (hidden) files.
  # - CXREF: See extensive comments re: `alias mv`:
  #   ~/.homefries/lib/alias/alias_mv.sh
  claim_alias_or_warn "cp." "set +f ; shopt -s dotglob ; cp_dotglob"
  claim_alias_or_warn "cp_all" "set +f ; shopt -s dotglob ; cp_dotglob"
}

# - CXREF: See extensive comments re: `mv_dotglob`:
#   ~/.homefries/lib/alias/alias_mv.sh

cp_dotglob () {
  ${SHOILERPLATE:-${HOME}/.kit/sh}/sh-rm_safe/bin/cp_safe "$@"

  # Leave noglob unset (set +f)
  #  set -f

  shopt -u dotglob
}

# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #

unset_f_alias_cp () {
  unset -f home_fries_aliases_wire_cp
  # So meta.
  unset -f unset_f_alias_cp
 }

# @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@ #

if [ "$0" = "${BASH_SOURCE[0]}" ]; then
  >&2 echo "ERROR: Trying sourcing the file instead: . $0" && exit 1
fi


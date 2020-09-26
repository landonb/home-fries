#!/usr/bin/env bash
# vim:tw=0:ts=2:sw=2:et:norl:ft=sh
# Author: Landon Bouma (landonb &#x40; retrosoft &#x2E; com)
# Project: https://github.com/landonb/home-fries#🍟
# License: MIT

# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #

home_fries_aliases_wire_tmux_reset () {
  if [ -n "${TMUX}" ]; then
    # REMEMBER: It's quicker and just the same (AFAIK) to
    #   use Ctrl-l instead of `reset`.
    alias reset='clear; tmux clear-history; command reset'
  fi
}

# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #

unset_f_alias_tmux_reset () {
  unset -f home_fries_aliases_wire_tmux_reset
  # So meta.
  unset -f unset_f_alias_tmux_reset
}

# @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@ #

main () {
  :
}

main ""
unset -f main


#!/usr/bin/env bash
# vim:tw=0:ts=2:sw=2:et:norl:ft=sh
# Author: Landon Bouma (landonb &#x40; retrosoft &#x2E; com)
# Project: https://github.com/landonb/home-fries#🍟
# License: MIT

# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #

home_fries_aliases_wire_ag () {
  # The Silver Search.
  # Always allow lowercase, and, more broadly, all smartcase.
  alias ag='ag --smart-case --hidden'
}

# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #

# When you use the -m/--max-count option, you'll see a bunch of
#   ERR: Too many matches in somefile. Skipping the rest of this file.
# which come on stderr from each process thread and ends up interleaving
# with the results, making the output messy and unpredicatable.
# So that Vim can predictably parse the output, use this shim of a fcn.,
# i.e., from Vim as `set grepprg=ag_peek`. (2018-01-12: Deprecated;
# favor just inlining in the .vim file.)
# 2018-01-29: Obsolete. In Vim, idea to `set grepprg=ag_peek`, but didn't work.
ag_peek () {
  ag -A 0 -B 0 --hidden --follow --max-count 1 "${@}" 2> /dev/null
}

# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #

unset_f_alias_ag () {
  unset -f home_fries_aliases_wire_ag
  # So meta.
  unset -f unset_f_alias_ag
}

# @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@ #

main () {
  :
}

main ""
unset -f main


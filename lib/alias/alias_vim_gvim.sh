#!/usr/bin/env bash
# vim:tw=0:ts=2:sw=2:et:norl:ft=sh
# Author: Landon Bouma (landonb &#x40; retrosoft &#x2E; com)
# Project: https://github.com/landonb/home-fries#🍟
# License: MIT

# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #

home_fries_aliases_wire_vim_gvim () {
  home_fries_aliases_wire_vi_vim
}

# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #

# *** Vi(m)

home_fries_aliases_wire_vi_vim () {
  # Vi vs. Vim: When logged on as root, vi is a dumbed-down vim. Root rarely
  # needs vanilla `vi` -- only when the home directories aren't mounted -- so
  # we can alias vi to vim.
  if [ $EUID -eq 0 ]; then
    alias vi="vim"
  fi

  # 2019-03-26: Avoid errors when vim.tiny tries to load your ~/.vim! E.g.,
  #   E319: Sorry, the command is not available in this version: ...
  alias vim.tiny="vim.tiny -u NONE"

  # 2018-03-28: From MarkM. Except it doesn't quite work for me....
  #  claim_alias_or_warn "v" '${EDITOR} $(fc -s) ' # edit results of last command
}

# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #

unset_f_alias_vim_gvim () {
  unset -f home_fries_aliases_wire_vim_gvim
  unset -f home_fries_aliases_wire_vi_vim
  # So meta.
  unset -f unset_f_alias_vim_gvim
}

# @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@ #

if [ "$0" = "${BASH_SOURCE[0]}" ]; then
  >&2 echo "ERROR: Trying sourcing the file instead: . $0" && exit 1
fi


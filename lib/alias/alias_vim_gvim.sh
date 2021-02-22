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
  #  alias v='${EDITOR} $(fc -s) ' # edit results of last command
}

# *** Gvim/gVim

# A few different Home Fries commands that open Vim all use the same
# servername, so that the same instance of GVim is targeted by those
# commands. The name doesn't matter (too much; you'll see it in the
# window title bar), but it should be unique among all windows for
# xdotool to identify it (so on macOS you don't have to worry).
#
# Note that `fs` and `fa` assume that `gvim-open-kindness` will be
# found on PATH. Otherwise we could specify it more completely, e.g.,
# ${HOMEFRIES_BIN:-${HOME}/.homefries/bin}, but I don't see a need.

# The `fs` command is just easy to type, starts with 'f' (for 'file',
# I suppose), and so far it doesn't conflict with anything popular of
# which I know (unlike, say, `fd`). I type `fs` or `fs {file}` (or
# `fs <Alt-.>`) a lot when I want to starting editing in GVim.
fs () {
  # NOTE: The servername appears in the window title bar, so you are
  #       encouraged to personalize it accordingly!
  gvim-open-kindness "${HOMEFRIES_GVIM_PRIMARY:-SAMPI}" "" "" "$@"
}

# The `fa` command exists should you want to open a second instance
# of GVim. (I cannot remember the last time I used this command.)
fa () {
  gvim-open-kindness "${HOMEFRIES_GVIM_ALTERNATE:-ALPHA}" "" "" "$@"
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


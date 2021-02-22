#!/usr/bin/env bash
# vim:tw=0:ts=2:sw=2:et:norl:ft=sh
# Author: Landon Bouma (landonb &#x40; retrosoft &#x2E; com)
# Project: https://github.com/landonb/home-fries#🍟
# License: MIT

# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #

home_fries_aliases_wire_vim_gvim () {
  home_fries_aliases_wire_vi_vim
  home_fries_aliases_wire_gvim
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

home_fries_aliases_wire_gvim () {
  # 2020-09-26: (lb): I almost always open files to Gvim using `fs`,
  # it's easy to type, and it sends all files to the same instance.

  # 2021-02-07: I've probably never usedf `fh`, ha. (It's almost always `fs`, 
  #             and historically sometimes but rarely `fd`, now `fa`, and
  #             never the historical `fa`, now the new `fd`.)
  #  alias fh='gvim --servername DIGAMMA --remote-silent' # For those special occassions
  # 2020-02-12: Let's not shadow the `fd` [f]in[d] tool.
  #  alias fd='gvim --servername   DELTA --remote-silent' # when you want to get away
  # 2021-02-07: See new `fs` and `fa` commands.
  #  alias fs='gvim --servername   SAMPI --remote-silent' # because relaxation is key
  #  alias fa='gvim --servername   ALPHA --remote-silent' # follow your spirit.
  :
}

# 2021-02-07: I've finally grown tired of the bare `fs` error:
#
#   $ fs
#   VIM - Vi IMproved 8.2 (2019 Dec 12, compiled Mar 20 2020 04:00:36)
#   Argument missing after: "--remote-silent"
#   More info with: "vim -h"
fs () {
  _hf_gvim_servername "${HOMEFRIES_GVIM_PRIMARY:-SAMPI}" "$@"
}

fa () {
  _hf_gvim_servername "${HOMEFRIES_GVIM_ALTERNATE:-ALPHA}" "$@"
}

_hf_gvim_servername () {
  local servername="$1"
  shift

  if [ -z "${1+x}" ]; then
    gvim --servername ${servername} --remote-silent "~/README.rst"
  else
    gvim --servername ${servername} --remote-silent "$@"
  fi

  if ! os_is_macos; then
    # Bring GVim to front. (Happens automatically on macOS, which I like.)
    # FIXME/2021-02-21: Docs: Mention ${servername} uniqueness is important.
    xdotool search --name ${servername} windowactivate &> /dev/null
  fi
}

# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #

unset_f_alias_vim_gvim () {
  unset -f home_fries_aliases_wire_vim_gvim
  unset -f home_fries_aliases_wire_vi_vim
  unset -f home_fries_aliases_wire_gvim
  # So meta.
  unset -f unset_f_alias_vim_gvim
}

# @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@ #

if [ "$0" = "${BASH_SOURCE[0]}" ]; then
  >&2 echo "ERROR: Trying sourcing the file instead: . $0" && exit 1
fi


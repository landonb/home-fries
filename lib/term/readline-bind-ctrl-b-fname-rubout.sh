#!/usr/bin/env bash
# vim:tw=0:ts=2:sw=2:et:norl:ft=bash
# Author: Landon Bouma (landonb &#x40; retrosoft &#x2E; com)
# Project: https://github.com/landonb/home-fries#🍟
# License: MIT

# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #

# ABOUT: Wire a less greedy <Ctrl-w>, more akin to how Vim <C-w> behaves.
#
# - But not as non-greedy as Vim; we'll use unix-filename-rubout which
#   uses whitespace and slash characters as the word boundary.
#
# CXREF: Normally we'd put readline bindings in the readline config:
# ~/.inputrc
#
# - But <Ctrl-W> is actually an stty setting, which overrules inputrc
#   unless we disable it, which we do so here.
#
# REFER: See lots more comments at the bottom of the dot-inputrc inputrc:
#
#   https://github.com/DepoXy/dot-inputrc/blob/1.2.0/.inputrc#L874-L990
#
#     https://github.com/DepoXy/dot-inputrc#🎛️
#
# SAVVY: There's a less greedy backward-delete at <Alt-Backpsace>
#           (aka Meta-Delete, Meta-DEL, "\e\C-?"),
#        and at <Esc><Backspace>.
#   $ bind -P | grep -e "\-kill-word" -e "\-rubout"
#   backward-kill-word can be found on "\e\C-h", "\e\C-?".
#   ...

home_fries_hook_filename_rubout() {
  # DUNNO: The `stty werase undef` below hangs Terminal.app startup.
  # - Though you can run manually and it works.
  # - ODDLY: Adding `--norc` and/or `--noprofile` to Terminal.app
  #   startup command doesn't inhibit this script from running!?
  #   (Though other parts of Homefries setup *are* skipped.)
  local gpid="$(ps -o ppid= -p ${PPID} | tr -d " ")"
  if ps -p ${gpid} -o comm | tail -1 |
    grep -q "^/System/Applications/Utilities/Terminal.app/Contents/MacOS/Terminal" \
    ; then

    return
  fi

  local expect_txt="^unix-filename-rubout is not bound to any keys"
  if ! bind -P | grep -q -e "${expect_txt}"; then
    bind -P | grep filename
    echo
    bind -P | grep -e "${expect_txt}"

    return
  fi

  stty werase undef

  bind \\C-w:unix-filename-rubout
}

# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #

#!/usr/bin/env bash
# vim:tw=0:ts=2:sw=2:et:norl:ft=bash
# Author: Landon Bouma (landonb &#x40; retrosoft &#x2E; com)
# Project: https://github.com/landonb/home-fries#🍟
# License: MIT

# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #

# MAYBE/2020-09-09 15:58: Consider moving to .inputrc, e.g.,:
#   #bind \\C-b:unix-filename-rubout
#   bind "\C-b": unix-filename-rubout
# https://superuser.com/questions/606212/bash-readline-deleting-till-the-previous-slash

# DOCS/2020-09-09 16:00: Use Ctrl-b in shell to delete backward to space or slash.

#  $ bind -P | grep -e unix-filename-rubout -e C-b
#  backward-char can be found on "\C-b", "\eOD", "\e[D".
#  unix-filename-rubout is not bound to any keys
#
#  # Essentially, default <C-b> moves cursor back one, same as left arrow.
#
#  $ bind \\C-b:unix-filename-rubout
#  $ bind -P | grep unix-filename-rubout
#  unix-filename-rubout can be found on "\C-b".
home_fries_hook_filename_rubout () {
  local expect_txt

  expect_txt='unix-filename-rubout is not bound to any keys'
  if [[ $expect_txt != $(bind -P | grep -e unix-filename-rubout) ]]; then
    return
  fi

  expect_txt='backward-char can be found on '
  if [[ "$(bind -P | grep C-b)" != "${expect_txt}"* ]]; then
    return
  fi

  bind \\C-b:unix-filename-rubout
}

# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #


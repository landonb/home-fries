#!/usr/bin/env bash
# vim:tw=0:ts=2:sw=2:et:norl:ft=bash
# Author: Landon Bouma (landonb &#x40; retrosoft &#x2E; com)
# Project: https://github.com/landonb/home-fries#🍟
# License: MIT

# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #

# Auto-update mate-terminal window title.

# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #

# 2020-01-02: (lb): My first attempt using PROMPT_COMMAND failed,
# but then I learned that trapping DEBUG is the proper way. In any
# case, for posterity:
#
#   _fries_term_hook () {
#     # Works: Shows up before PS4 prompt, e.g.,
#     #       123user@host:/ $
#     #echo -n "123"
#     # Fails: Shows before PS4, e.g.,
#     #      ]0;echo -en ""user@host:/ $
#     #echo -en "\033]0;${BASH_COMMAND}\007"
#     # Fails: Prints line before every prompt, e.g.,
#     #     echo "${BASH_COMMAND}" 1>&2
#     #     user@host:/ $
#     #>&2 echo "${BASH_COMMAND}"
#     :
#   }
#
#   fries_hook_titlebar_update () {
#     if [[ ! ${PROMPT_COMMAND} =~ "_fries_term_hook" ]]; then
#       PROMPT_COMMAND="_fries_term_hook;${PROMPT_COMMAND}"
#     fi
#   }

fries_hook_titlebar_update () {
  # Show the command in the window titlebar.

  # MEH: (lb): I'd rather the title not flicker for fast commands,
  # but it's nice to have for long-running commands, like `man foo`
  # and `dob edit`, etc.

  # This overrides the title set in PS4 (which is, e.g., \W\a, which prints
  # the basename of the current directory; but fortunately it only overrides
  # it while the command is running: after the command completes, the \W\a
  # title is restored. This makes for a nice titlebar title that shows the
  # basename of the directory when the prompt is active, but shows the name
  # of the actively running command if there is one, e.g., `man bash`.
  trap 'printf "\033]0;%s\007" "${BASH_COMMAND}"' DEBUG
}

# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #


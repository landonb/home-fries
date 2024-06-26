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
#     #  echo -n "123"
#     # Fails: Shows before PS4, e.g.,
#     #      ]0;echo -en ""user@host:/ $
#     #  echo -en "\033]0;${BASH_COMMAND}\007"
#     # Fails: Prints line before every prompt, e.g.,
#     #     echo "${BASH_COMMAND}" 1>&2
#     #     user@host:/ $
#     #  >&2 echo "${BASH_COMMAND}"
#     :
#   }
#
#   _hf_hook_titlebar_update () {
#     if [[ ! ${PROMPT_COMMAND} =~ "_fries_term_hook" ]]; then
#       PROMPT_COMMAND="_fries_term_hook;${PROMPT_COMMAND}"
#     fi
#   }

# Show the currently running command name in the window titlebar.
_hf_hook_titlebar_update () {
  # Sets ITERM2_WINDOW_NUMBER
  _hf_set_iterm2_window_number_environ

  # MEH: (lb): I'd rather the title not flicker for fast commands,
  # but it's nice to have for long-running commands, like `man foo`
  # and `dob edit`, etc.

  # This overrides the title set in PS4 (which is, e.g., \W\a, which prints
  # the basename of the current directory; but fortunately it only overrides
  # it while the command is running: after the command completes, the \W\a
  # title is restored. This makes for a nice titlebar title that shows the
  # basename of the directory when the prompt is active, but shows the name
  # of the actively running command if there is one, e.g., `man bash`.
  trap 'printf "\033]0;%s\007" "${ITERM2_WINDOW_NUMBER}${BASH_COMMAND}"' DEBUG
}

# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #

# 2021-07-16: Add window number to iTerm2 window title.
# - This enables a collection of systemwide terminal foregrounder shortcuts.
#   See KE mappings in DepoXy project:
ITERM2_WINDOW_NUMBER=""

_hf_set_iterm2_window_number_environ () {
  local window_number
  window_number="$(_hf_print_terminal_window_number)"

  if [ -n "${window_number}" ]; then
    ITERM2_WINDOW_NUMBER="${window_number}. "
  fi
}

# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #

#     https://github.com/DepoXy/depoxy#🍯
#   Possibly at:
#     ~/.depoxy/ambers/home/.config/karabiner/assets/complex_modifications/0340-applcn-iterm2-fronter.json
# - Note that iTerm2 has its own *Shortcut to activate a window* shortcuts
#   (that default to <Cmd-Alt-n>), but these only work when iTerm2 is already
#   the active application. (lb): And I want shortcuts that work from anywhere!
_hf_print_terminal_window_number () {
  local window_number=""

  # iTerm2 defines a unique environment for each window that specifies
  # the window number, tab number, pane number, and window ID (GUID), e.g.,
  #   $ echo $ITERM_SESSION_ID
  #   w3t0p0:B1CDC558-062B-4830-A5EB-8EF1BBFFAB13

  if [ -n "${ITERM_SESSION_ID}" ]; then
    # iTerm2 v3.2.x prefixed the window number to the window title, e.g.,
    # "1. bash-command", but iTerm2 v3.3.x does not, which breaks the
    # Karabiner-Elements foregrounder shortcuts. This replicates the
    # functionality from iTerm2 v3.2.x.
    window_number="$(echo "${ITERM_SESSION_ID}" | sed 's/^w\([0-9]\+\).*/\1/')"
    let 'window_number += 1'
  fi

  printf "%s" "${window_number}"
}

# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #


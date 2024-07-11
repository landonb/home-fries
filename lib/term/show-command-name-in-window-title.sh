#!/usr/bin/env bash
# vim:tw=0:ts=2:sw=2:et:norl:ft=bash
# Author: Landon Bouma (landonb &#x40; retrosoft &#x2E; com)
# Project: https://github.com/landonb/home-fries#🍟
# License: MIT

# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #

# Auto-update mate-terminal window title.

# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #

# Show the currently running command name in the window titlebar.
# - Even though this special title is often short-lived, just in
#   case it's a long-running process, we'll show the window number
#   like we normally do, so the systemwide foregrounder shortcuts
#   still work.

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

ITERM2_WINDOW_NUMBER=""

_hf_set_iterm2_window_number_environ () {
  local window_number
  window_number="$(_hf_print_terminal_window_number)"

  if [ -n "${window_number}" ]; then
    ITERM2_WINDOW_NUMBER="${window_number}. "

    # For ssh, and if you run `bash` in an open terminal,
    # keep using the same window number.
    # - Note that ITERM_SESSION_ID is 0-based.
    # - See comment below for fuller explanation.
    if [ -z "${ITERM_SESSION_ID}" ]; then
      # For mate-terminal and Alacritty (or anything not iTerm2).
      ITERM_SESSION_ID="w$((${window_number}-1))t0p0:XXXXXXXX-XXXX-XXXX-XXXX-XXXXXXXXXXXX"
    fi
  fi

  # Necessary if you use `SendEnv ITERM_SESSION_ID` in ~/.ssh/config
  # to have `ssh` connections also use window_number in their title.
  export ITERM_SESSION_ID
}

# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #

# Print the terminal "window number".
#
# - The caller adds this to the terminal window title, to enable a
#   collection of systemwide terminal foregrounder shortcuts
#   (e.g., use <Cmd-4> to front the window that starts with "4. ").
#
# - For iTerm2 keybindings, see the DepoXy project:
#     https://github.com/DepoXy/depoxy#🍯
#   Possibly at:
#     ~/.depoxy/ambers/home/.config/karabiner/assets/complex_modifications/0340-applcn-iterm2-fronter.json
#   - Note that iTerm2 has its own *Shortcut to activate a window* shortcuts
#     (that default to <Cmd-Alt-n>), but these only work when iTerm2 is already
#     the active application. (lb): And I want shortcuts that work from anywhere!
#
# - For Alacritty macOS bindings, see the macOS-skhibidirc project:
#     https://github.com/DepoXy/macOS-skhibidirc#👤
#
# - For mate-terminal MATE bindings, you could add bindings such as:
#     - name: "'Window ‘1.’ mate-terminal focus'"
#       binding: "'<Mod4>1'"
#       action: "'/usr/bin/env bash -c \\\"wmctrl -a \\'1. \\'\\\"'"
#   using the zoidy_matecocido keybindings manager Ansible role
#   (which automates calling dcong/gsettings to wire the bindings):
#     https://github.com/landonb/zoidy_matecocido
#   but you probably don't want to mess with Ansible unless you're
#   familiar with it. Best just to make custom bindings yourself.

_hf_print_terminal_window_number () {
  ! ${HOMFRIES_NO_WINDOW_NUMBER:-false} || return 0

  local window_number=""

  false \
    || window_number="$(_hf_print_terminal_window_number_iterm)" \
    || window_number="$(_hf_print_terminal_window_number_alacritty)" \
    || window_number="$(_hf_print_terminal_window_number_mate_terminal)" \
    || true;

  printf "%s" "${window_number}"
}

# ***

# SAVVY: iTerm2 defines a unique environment for each window that includes
# the window number, tab number, pane number, and window ID (GUID), e.g.,
#   $ echo $ITERM_SESSION_ID
#   w3t0p0:B1CDC558-062B-4830-A5EB-8EF1BBFFAB13
#
# SAVVY: Various ways to suss if it's iTerm:
#   [ "${ITERM_SESSION_ID}" = "w3t0p0:B1CDC558-062B-4830-A5EB-8EF1BBFFAB13" ]  # E.g.
#   [ "${ITERM_PROFILE}" = "My Profile" ]  # User's iTerm2 Profile name, e.g.
#   [ "${LC_TERMINAL}" = "iTerm2" ]
#   [ "${TERM_PROGRAM}" = "iTerm.app" ]
#
# HSTRY: iTerm2 v3.2.x prefixed the window number to the window title,
# e.g., "1. bash-command", but iTerm2 v3.3.x does not, which breaks the
# Karabiner-Elements foregrounder shortcuts. This helps fill in the
# missing functionality from iTerm2 v3.2.x. (See also where Homefries
# recreates ITERM_SESSION_ID so that `ssh <host>` to another Homefries
# shell keeps using the same window number, even on a remote host.)

_hf_print_terminal_window_number_iterm () {
  if [ -z "${ITERM_SESSION_ID}" ]; then

    return 1
  fi

  local window_number=""

  window_number="$(echo "${ITERM_SESSION_ID}" | sed 's/^w\([0-9]\+\).*/\1/')"
  # The iTerm2 window numbers are 0-based.
  let 'window_number += 1'

  printf "%s" "${window_number}"
}

# ***

# SAVVY: Alacritty defaults the TERM environ to 'alacritty', but that
# can break (old) apps that use (old) ncurses to decide if they can
# run properly.
# - And the user might otherwise set a different TERM in Alacritty.toml.
# - So don't rely on TERM, but suss the parent process.
# - I.e., `[ "${TERM}" = "alacritty" ]` is not a robust suss in this fcn.

_hf_print_terminal_window_number_alacritty () {
  # FTREQ/2024-07-10: Try Alacritty on Linux and update this fcn.
  if ! os_is_macos; then

    return 1
  fi

  if ! ps -p $PPID -o comm | tail -1 | grep -q "^/Applications/Alacritty.app"; then

    return 1
  fi

  local window_number=""

  local lib_term_dir
  lib_term_dir="$(dirname -- "${BASH_SOURCE[0]}")"

  local osa_path
  # CXREF: ~/.kit/sh/home-fries/lib/term/window-title--alacritty-number.osa
  osa_path="${lib_term_dir}/window-title--alacritty-number.osa"

  window_number="$(osascript "${osa_path}")"

  printf "%s" "${window_number}"
}

# ***

# SAVVY: For MATE, we'll check all window titles to see which window
# number prefix is available. This is because the `wmctrl -a` command
# used to raise a window is also systemwide. (Also because the author
# didn't check if there's a way to limit `wmctrl -l` and `wmctrl -a`
# to one application, or to find an alternative method that would.
# It's unlikely another application is also prefixing numbers to
# their window titles, though, we're just that special).

_hf_print_terminal_window_number_mate_terminal () {
  if [ -z "${DISPLAY}" ] || ! command -v wmctrl > /dev/null; then

    return 1
  fi
  
  local window_number=""

  local assigned
  assigned="$(wmctrl -l | awk '{print $4}' | grep -e '^[0-9]\.$' | sed 's/\.$//')"

  local number
  for number in $(seq 1 9); do
    if ! echo "${assigned}" | grep -q "${number}"; then
      window_number="${number}"

      break
    fi
  done

  printf "%s" "${window_number}"
}

# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #

_hf_cleanup_lib_term_window_title_show_command_name () {
  unset -f _hf_set_iterm2_window_number_environ
  # Leave set: ITERM2_WINDOW_NUMBER

  unset -f _hf_print_terminal_window_number
  unset -f _hf_print_terminal_window_number_iterm
  unset -f _hf_print_terminal_window_number_alacritty
  unset -f _hf_print_terminal_window_number_mate_terminal

  unset -f _hf_cleanup_lib_term_window_title_show_command_name
}

# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #


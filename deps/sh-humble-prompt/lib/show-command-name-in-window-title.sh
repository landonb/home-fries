#!/usr/bin/env bash
# vim:tw=0:ts=2:sw=2:et:norl:ft=bash
# Author: Landon Bouma <https://tallybark.com/>
# Project: https://github.com/DepoXy/sh-humble-prompt#🙇
# License: MIT

# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #

# Auto-update mate-terminal window title.

# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #

# Show the currently running command name in the window titlebar.
# - Even though this special title is often short-lived, just in
#   case it's a long-running process, we'll show the window number
#   like we normally do, so the systemwide foregrounder shortcuts
#   still work.

_humb_hook_titlebar_update() {
  # Sets ITERM2_WINDOW_NUMBER
  _humb_set_iterm2_window_number_environ

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

  # This is a one-off script: Source it, then call _humb_hook_titlebar_update,
  # and it'll unset the functions it no longer needs.
  _humb_cleanup_lib_term_window_title_show_command_name
}

# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #

ITERM2_WINDOW_NUMBER=""

_humb_set_iterm2_window_number_environ() {
  local window_number
  window_number="$(_humb_print_terminal_window_number)"

  if [ -n "${window_number}" ]; then
    if ${DUBS_ALWAYS_ON_VISIBLE:-false} && ! _humb_titler_os_is_macos; then
      # Use a special character so we can grep the title to determine if
      # the mate-terminal window should be made sticky (aka it's kludgy).
      # - CXREF: ~/.kit/sh/home-fries/lib/term/perhaps-always-on-visible-desktop.sh
      # - Homefries uses a One Dot Leader (U+2024) that's visually
      #   indistinguisable from the period that we'd otherwise use.
      ITERM2_WINDOW_NUMBER="${window_number}${DUBS_STICKY_INDICATOR:-․} "
    else
      # This is just a regular (Full Stop) period ".".
      ITERM2_WINDOW_NUMBER="${window_number}${DUBS_NORMAL_INDICATOR:-.} "
    fi

    # For ssh, and if you run `bash` in an open terminal,
    # keep using the same window number.
    # - Note that ITERM_SESSION_ID is 0-based.
    # - See comment below for fuller explanation.
    if [ -z "${ITERM_SESSION_ID}" ]; then
      # For mate-terminal and Alacritty (or anything not iTerm2).
      ITERM_SESSION_ID="w$((${window_number} - 1))t0p0:XXXXXXXX-XXXX-XXXX-XXXX-XXXXXXXXXXXX"
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

_humb_print_terminal_window_number() {
  ! ${HOMFRIES_NO_WINDOW_NUMBER:-false} || return 0

  local window_number=""

  false ||
    window_number="$(_humb_print_terminal_window_number_iterm)" ||
    window_number="$(_humb_print_terminal_window_number_alacritty_macos)" ||
    window_number="$(_humb_print_terminal_window_number_linux_terminal)" ||
    true

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

_humb_print_terminal_window_number_iterm() {
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

# BUGGY/2024-07-10: Ha, the `borders` service hides the border when
# you first open a new Alacritty window and this function runs.
# - TRYME: Add a `return 1` atop this function, and (supposing you
#   use `borders`, because Alacritty doesn't draw one on macOS),
#   you'll see the border drawn around the new Alacritty window.
#   - But remove the `return 1` and let this function suss the
#     window number, and then the `borders` border disappears
#     until you refocus the window (i.e., bring another window
#     front, then return to the new Alacritty window).
# - SAVVY: It's the .osa script, but I don't know why.
#   - But it's not a bothersome issue, because I rarely need to
#     restart Alacritty.
#   - Interesting nonetheless tho.
# - OHHHK: Weird, it's not the whole border that goes missing,
#   just the Alacritty window border that overlaps other Alacritty
#   windows. But parts of the border that overlap other apps or
#   the Finder are still borderful (drawn).

_humb_print_terminal_window_number_alacritty_macos() {
  # FTREQ/2024-07-10: Try Alacritty on Linux and update this fcn.
  if ! _humb_titler_os_is_macos; then

    return 1
  fi

  if ! ps -p $PPID -o comm | tail -1 | grep -q "^/Applications/Alacritty.app"; then

    return 1
  fi

  local window_number=""

  local sh_humble_prompt_lib_dir
  sh_humble_prompt_lib_dir="$(dirname -- "${BASH_SOURCE[0]}")"

  local osa_path
  # CXREF: ~/.kit/sh/sh-humble-prompt/lib/window-title--alacritty-number.osa
  osa_path="${sh_humble_prompt_lib_dir}/window-title--alacritty-number.osa"

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

_humb_print_terminal_window_number_linux_terminal() {
  local window_number=""

  local dot_leader_group
  dot_leader_group="\\(\\${DUBS_NORMAL_INDICATOR:-.}\\|${DUBS_STICKY_INDICATOR:-․}\\)"

  # Call prefixes separately (author tried this in a pipeline, e.g.,
  #   assigned="$(_humb_print_terminal_window_title_prefixes | ...)"
  # but checking `${PIPESTATUS[0]} -ne 0` was always false).
  local prefixes
  if ! prefixes="$(_humb_print_terminal_window_title_prefixes)"; then

    return 1
  fi

  local assigned
  assigned="$(
    echo "${prefixes}" |
      grep -e "^[0-9]${dot_leader_group}\$" |
      sed "s/${dot_leader_group}\$//" |
      sort |
      uniq
  )"

  local number
  for number in $(seq 1 9); do
    if ! echo "${assigned}" | grep -q "^${number}\$"; then
      window_number="${number}"

      break
    fi
  done

  printf "%s" "${window_number}"
}

# ***

_humb_print_terminal_window_title_prefixes() {
  if [ "$(_humb_probe_desktop_environment)" = "GNOME" ]; then
    # Run in subshell to avoid polluting env.
    # w/ third-party deps/ funcs.
    (_humb_print_terminal_window_title_prefixes_Wayland)
  else
    _humb_print_terminal_window_title_prefixes_XWindow
  fi
}

# ***

# SAVVY: You can use wmctrl in Wayland to some extent, e.g.:
#   $ sudo apt install wmctrl && wmctrl -m
#   Name: GNOME Shell
# But `wmctrl -l` won't show all windows, e.g., author only
# sees Chrome and GVim windows listed.
# - So for GNOME, we'll use a special (and optional) GNOME
#   Shell extension that exposes a D-Bus interface to work
#   with windows on Wayland.

_humb_probe_desktop_environment() {
  # Colon-separated list, uppercased.
  local currdes
  currdes="$(echo "${XDG_CURRENT_DESKTOP}" | tr '[:lower:]' '[:upper:]')"

  (
    IFS=:
    for denv in ${currdes}; do
      if [ "${denv}" = "GNOME" ]; then
        echo "GNOME"
      elif [ "${denv}" = "MATE" ]; then
        echo "MATE"
      else

        continue
      fi

      break
    done
  )
}

# ***

# REFER: Uses integrated dependency to query Wayland window titles.
#   https://github.com/DepoXy/gnome-window-calls#🪟
# ~/.kit/sh/gnome-window-calls/lib/gnome-window-calls.sh

# DPNDS: Requires `window-calls` GNOME Shell extension:
#   https://extensions.gnome.org/extension/4724/window-calls/
#   https://github.com/ickyicky/window-calls
# REFER: Installs to:
#   ~/.local/share/gnome-shell/extensions/window-calls@domandoman.xyz/

# SAVVY:
# - Use jq filter to pick gnome-terminal window IDs only.
# - For each ID, send gdbus command to window-calls
#   extension to get window details, including title.
# - Use gawk to remove the '(' ... ',)' around details.
# - Remove embedded, escaped double quotes;
#   and resolve JSON string escapes.
#   - See raise-lower for comments — the Windows.Details
#     response varies based on `'` and/or `"` characters
#     in a window's title.
#   - Basically, if any double-quote is double-or-more
#     escaped, remove it (because it's part of a JSON
#     string); and then convert all \" to " (because
#     the outer window-call response was double-quoted,
#     and the embedded JSON string used escape-quoting
#     for JSON fields and values).
# - Use jq to print each window title.
# - Use awk to print only the first column, e.g.,
#   '1.', '2.', etc.

_humb_print_terminal_window_title_prefixes_Wayland() {
  # Load: get_window_ids_Wayland_filtered
  # - REFER: This dependency is included with the project,
  #   under the deps/ directory.
  #   - CXREF: In a DepoXy env., you'll find the original at:
  #     ~/.kit/sh/gnome-window-calls/lib/gnome-window-calls.sh
  local canon_base
  canon_base="$(dirname -- "$(realpath -- "${BASH_SOURCE[0]}")")"
  . "${canon_base}/../deps/gnome-window-calls/lib/gnome-window-calls.sh"

  local jq_filter='select(
    .wm_class == "gnome-terminal-server" or
    .wm_class == "Alacritty"
  )'

  local window_ids
  if ! window_ids="$(
    get_window_ids_Wayland_filtered "${jq_filter}"
  )" 2>/dev/null; then
    # Emits error (that we inhibited) if window-calls not installed.
    # - We don't print error. User should notice if the number prefix
    #   is missing, and then they can investigate themselves, e.g.,
    #   run `get_window_ids_Wayland_filtered` manually.

    return 1
  fi

  # USYNC: See similar pipeline in upstream lib:
  # ~/.kit/sh/gnome-window-calls/lib/gnome-window-calls.sh
  echo "${window_ids}" |
    xargs -I{} \
      gdbus call --session --dest org.gnome.Shell \
      --object-path /org/gnome/Shell/Extensions/Windows \
      --method org.gnome.Shell.Extensions.Windows.Details \
      {} |
    gawk 'match($0, /\{.*\}/, a) {print a[0]}' |
    sed -e 's/\\\(\\\)\+"//g' | sed -e 's/\\"/"/g' |
    jq -r '.title' |
    awk '{print $1}'
}

# ***

# CALSO:
#   xdotool search --onlyvisible -class mate-terminal getwindowname %@
# https://stackoverflow.com/questions/9407291/listing-of-all-gnome-terminal-windows
#
# CALSO:
#   xwininfo -root -children

_humb_print_terminal_window_title_prefixes_XWindow() {
  if [ -z "${DISPLAY}" ] || ! command -v wmctrl >/dev/null; then

    return 1
  fi

  # Print the fourth column, which is the start of the window title,
  # e.g., '1.', and assumes the `[0-9].` is followed by whitespace.
  wmctrl -l | awk '{print $4}'
}

# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #

_humb_titler_os_is_macos() {
  [ "$(uname)" = 'Darwin' ]
}

# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #

_humb_cleanup_lib_term_window_title_show_command_name() {
  unset -f _humb_set_iterm2_window_number_environ
  # Leave set: ITERM2_WINDOW_NUMBER

  unset -f _humb_titler_os_is_macos

  unset -f _humb_probe_desktop_environment

  unset -f _humb_print_terminal_window_title_prefixes
  unset -f _humb_print_terminal_window_title_prefixes_Wayland
  unset -f _humb_print_terminal_window_title_prefixes_XWindow

  unset -f _humb_print_terminal_window_number
  unset -f _humb_print_terminal_window_number_iterm
  unset -f _humb_print_terminal_window_number_alacritty_macos
  unset -f _humb_print_terminal_window_number_linux_terminal

  unset -f _humb_hook_titlebar_update

  unset -f _humb_cleanup_lib_term_window_title_show_command_name
}

# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #

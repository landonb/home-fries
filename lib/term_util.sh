#!/usr/bin/env bash
# vim:tw=0:ts=2:sw=2:et:norl:ft=sh
# Author: Landon Bouma (landonb &#x40; retrosoft &#x2E; com)
# Project: https://github.com/landonb/home-fries#🍟
# License: MIT

# YOU: Uncomment to re-source this file.
#  unset -v _LOADED_HF_TERM_UTIL
${_LOADED_HF_TERM_UTIL:-false} && return || _LOADED_HF_TERM_UTIL=true

# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #

check_deps () {
  # Verify sh-colors/bin/colors.sh loaded.
  check_dep '_hofr_no_color'
  # Verify sh-logger/bin/logger.sh loaded.
  check_dep '_sh_logger_log_msg'
  # Verify distro_util.sh loaded.
  # - Including 'os_is_macos'.
  check_dep 'suss_window_manager'
}

# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #

DUBS_STICKY_PREFIX="${DUBS_STICKY_PREFIX:-(Dubs) }"
DUBS_STICKY_PREFIX_RE="${DUBS_STICKY_PREFIX_RE:-\\(Dubs\\) }"

# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #

get_terminal_window_ids () {
  # 2018-02-14: `xdotool search` is returning 1 more than the number of
  # mate-terminals. I thought it was if I ran bash within bash within a
  # terminal, but that wasn't the case. Not sure what it is. But there's
  # another way we can get exactly what we want, with `wmctrl` instead.
  #   xdotool search --class "${WM_TERMINAL_APP}"
  wmctrl -l -x | grep "${WM_TERMINAL_APP}" | awk '{print $1}'
}

# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #

# Send commands to all the terminal windows.

# But first,
#  some xdotool notes...
#
# If you don't specify what to search, xdotool adds to stderr,
#   "Defaulting to search window name, class, and classname"
# We can search for the app name using --class or --classname.
#   xdotool search --class "mate-terminal"
# Translate the window IDs to their terminal titles:
#   xdotool search --class "mate-terminal" | xargs -d '\n' -n 1 xdotool getwindowname
# 2016-05-04: Note that the first window in the list is named "Terminal",
#   but it doesn't correspond to an actual terminal, it doesn't seem.
#     $ RESPONSE=$(xdotool windowactivate 77594625 2>&1)
#     $ echo $RESPONSE
#     XGetWindowProperty[_NET_WM_DESKTOP] failed (code=1)
#     $ echo $?
#     0
#   What's worse is that that window hangs on activate.
#     $ xdotool search --class mate-terminal -- windowactivate --sync %@ type "echo 'Hello buddy'\n"
#     XGetWindowProperty[_NET_WM_DESKTOP] failed (code=1)
#     [hangs...]
#   Fortunately, like all problems, this one can be solved with bash, by
#   checking the desktop of the terminal window before sending it keystrokes.

termdo-all () {
  suss_window_manager
  local THIS_WINDOW_ID=$(xdotool getactivewindow)
  local WINDOW_IDS=$(get_terminal_window_ids)
  local winid
  for winid in ${WINDOW_IDS}; do
    # Don't send the command to this window, at least not yet, since it'll
    # end up on stdin of this fcn. and won't be honored as a bash command.
    if [ ${THIS_WINDOW_ID} -ne ${winid} ]; then
      # See if this is a legit window or not.
      local DESKTOP_NUM=$(xdotool get_desktop_for_window ${winid} 2> /dev/null)
      # For real terminal, the number is 0 or greater;
      # for the fakey, it's 0, and also xdotool returns 1.
      if [ $? -eq 0 ]; then
        # This was my first attempt, before realizing the obvious.
        #   if false; then
        #     xdotool windowactivate --sync $winid
        #     sleep .1
        #     xdotool type "echo 'Hello buddy'
        ##"
        #     # Hold on a millisec, otherwise I've seen, e.g., the trailing
        #     # character end up in another terminal.
        #     sleep .2
        #   fi
        # And then this is the obvious:

        # Oh, wait, the type and key commands take a window argument...
        # NOTE: Without the quotes, e.g., xdotool type --window $winid $*,
        #       you'll have issues, e.g., xdotool sudo -K
        #       shows up in terminals as, sudo-K: command not found
        # NOTE: If you've bash'ed within a session, you'll find all 'em.
        #       And you'll xdotool them all. But not a big deal?
        xdotool windowactivate --sync ${winid} type "$*"
        # Note that 'type' isn't always good with newlines, so use 'key'.
        # 2018-02-14 16:42: Revisit that comment. Docs make it seem like newlines ok.
        xdotool windowactivate --sync ${winid} key Return
      fi
    fi
  done
  # Bring original window back to focus.
  xdotool windowactivate --sync ${THIS_WINDOW_ID}
  # Now we can do what we did to the rest to ourselves.
  eval $*
}

# Test:
if false; then
  termdo-all "echo Wake up get outta bed
"
fi

termdo-reset () {
  suss_window_manager
  local THIS_WINDOW_ID=$(xdotool getactivewindow)
  local WINDOW_IDS=$(get_terminal_window_ids)
  local winid
  for winid in $WINDOW_IDS; do
    if [ $THIS_WINDOW_ID -ne $winid ]; then
      local DESKTOP_NUM=$(xdotool get_desktop_for_window $winid 2> /dev/null)
      if [ $? -eq 0 ]; then
        # Note that the terminal from whence this command is being run
        # will get the keystrokes -- but since the command is running,
        # the keystrokes sit on stdin and are ignored. Then along comes
        # the ctrl-c, killing this fcn., but not until after all the other
        # terminals also got their fill.

        xdotool windowactivate --sync ${winid} key ctrl+c
        xdotool windowactivate --sync ${winid} type "cd $1"
        # Hrmm. 'Ctrl+c' and 'ctrl+c' are acceptable, but 'return' is not.
        xdotool windowactivate --sync ${winid} key Return
      fi
    fi
  done
  # Bring original window back to focus.
  xdotool windowactivate --sync ${THIS_WINDOW_ID}
  # Now we can act locally after having acted globally.
  cd $1
}

termdo-cmd () {
  suss_window_manager
  local THIS_WINDOW_ID=$(xdotool getactivewindow)
  local WINDOW_IDS=$(get_terminal_window_ids)
  local winid
  for winid in $WINDOW_IDS; do
    if [ $THIS_WINDOW_ID -ne ${winid} ]; then
      local DESKTOP_NUM=$(xdotool get_desktop_for_window ${winid} 2> /dev/null)
      if [ $? -eq 0 ]; then

        xdotool windowactivate --sync ${winid} key ctrl+c
        xdotool windowactivate --sync ${winid} key ctrl+d
        xdotool windowactivate --sync ${winid} type "$1"
        # Hrmm. 'Ctrl+c' and 'ctrl+c' are acceptable, but 'return' is not.
        xdotool windowactivate --sync ${winid} key Return
      fi
    fi
  done
  # Bring original window back to focus.
  xdotool windowactivate --sync ${THIS_WINDOW_ID}
  # Now we can act locally after having acted globally.
  eval $1
}

termdo-sudo-reset () {
  # sudo security
  # -------------
  # Make all-terminal fcn. to revoke sudo on all terms,
  # to make up for security hole of leaving terminals sudo-ready.
  # Then again, real reason against is doing something dumb,
  # so really you should always be sudo-promted.
  # But maybe the answer is really a confirm prompt,
  # not a password prompt (like in Windows, ewwwww!). -summer2016
  termdo-all "echo termdo-sudo-reset says"
  termdo-all sudo -K
}

# FIXME/MAYBE: Add a close-all fcn:
#               1. Send ctrl-c
#               2. Send exit one or more times (to exit nested shells)

# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #

enable_vi_style_editing () {
  # Vi-style editing.

  # MAYBE:
  #  set -o vi

  # Use ``bind -P`` to see the current bindings.

  # See: http://www.catonmat.net/download/bash-vi-editing-mode-cheat-sheet.txt
  # (from http://www.catonmat.net/blog/bash-vi-editing-mode-cheat-sheet/)
  # (also http://www.catonmat.net/download/bash-vi-editing-mode-cheat-sheet.pdf)

  # See: http://vim.wikia.com/wiki/Use_vi_shortcuts_in_terminal
  :
}

# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #

# 2020-08-25: Replace ${VAR^^} with POSIX-compliant pipe chain (because macOS's
# deprecated Bash is 3.x and does not support ${VAR^^} capitalization operator,
# and the now-default zsh shell does not support ${VAR^^} capitalization).
first_char_capped () {
  printf "$1" | cut -c1-1 | tr '[:lower:]' '[:upper:]'
}

# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #

# 2018-05-28: Bounce around workspaces. (lb): Metacity is griefing when
# I Alt-Tab between windows: It switches desktops to the window's owning
# desktop. You don't notice if the window is pinned to the current
# desktop, but if the the window is set to "Always on Visible Workspace",
# you might switch desktops! One option is to right-click on the window
# in the window list, send it to the desktop within which you want to
# work, switch to that desktop, and then enables always-on-visible. Or,
# you could just run this command and bring your windows to the desired
# desktop.
# 2019-01-05: And... now it seems the issue for which space() was writ
# to address is not longer an issue in 18.04. When I switch desktops
# by clicking in the applet widget and then alt-tab between windows,
# the desktop is not unexpectedly changing to another one. Thank you,
# whomeever fixed this bug! (I think between 14.04 and 18.04; not sure
# if it inflicted 16.04). / That said, space() is still useful to run
# at least once to make certain browser tabs and other application
# windows sticky.

space () {
  local re_num='^[1-4]+$'
  if ! [[ $1 =~ ${re_num} ]]; then
    echo 'USAGE: space [1-4]' 1>&2
    return 1
  fi
  local wspace=$(($1 - 1))
  local active_window=$(xdotool getactivewindow)
  echo "Reassigning sticky windows' parents..."
  # Early solution: Move known windows according to business logic.
  #  xdotool search --name '(Dubs)|SAMPI' | xargs -I % echo wmctrl -t ${wspace} -b add,sticky -i -r %
  #  xdotool search --name '(Dubs)|SAMPI' | xargs -I % wmctrl -t ${wspace} -b add,sticky -i -r %
  # Better solution: Move all windows known to be always-on-visible.
  # wmctrl:
  #   -t: desktop no.
  #   -i: -r is an integer
  #   -r: window str or id
  #   -b: modify property
  # NOTE: (lb): Apologies for the Business Logic, but the Gnome 2 Launcher
  #       Panels should not be touched. These are identified by:
  #
  #           | /bin/grep -v 'Bottom Expanded Edge Panel$' \
  #
  #       I mean, they can be touched, and all will seem well, but sometime in
  #       the future, when you double-click a window titlebar to maximize it,
  #       you'll see it's bottom edge goes beneath the bottom panels. (And I'm
  #       sure it should really just be 'Edge Panel$', to include cases where
  #       the panel is elsewhere (Left, Top, or Right), or where the panel is
  #       not expanded fully. But none of those cases apply to me, so ignoring.)
  winids=($(wmctrl -l \
    | /bin/grep -E '^0x[a-f0-9]{8} +-1 ' \
    | /bin/grep -v 'Bottom Expanded Edge Panel$' \
    | awk '{print $1}'))
  #printf "%s\n" "${winids[@]}" | xargs -I % echo wmctrl -t ${wspace} -b add,sticky -i -r %
  for winid in ${winids[@]}; do
    # Just for enduser enjoyment.
    echo_wmctrl_sticky_cmd_winid "${winid}"
  done
  # NOTE: Combining the 2 commands seems to work, but it doesn't:
  #  | xargs -I % wmctrl -t ${wspace} -b add,sticky -i -r %
  # So do the 2 operations separately.
  printf "%s\n" "${winids[@]}" | xargs -I % wmctrl -t ${wspace} -i -r %
  # Change active desktop. Can come before or after adding sticky.
  echo "Switching to Desktop “${wspace}” aka Workspace “$1”."
  wmctrl -s ${wspace}
  printf "%s\n" "${winids[@]}" | xargs -I % wmctrl -b add,sticky -i -r %
  # Restore previously active window.
  wmctrl -i -a ${active_window}
}

echo_wmctrl_sticky_cmd_winid () {
  local winid=$1
  printf '%s%b\n' \
    " wmctrl -b add,sticky -i -r ${winid}" \
    " $(fg_mintgreen)$(wmctrl -l | grep "^${winid}" | cut -d ' ' -f 4-)$(attr_reset)"
}

echo_wmctrl_sticky_cmd_winname () {
  local winname=$1
  local winid=$(wmctrl -l | grep "${winname}$" | cut -d ' ' -f 1)
  if [ -n "${winid}" ]; then
    winid="$(fg_mintgreen)${winid}"
  else
    #winid='~NOTFOUND~'
    #winid="$(fg_lightorange)${winid}"
    # On second thought, don't pollute.
    return
  fi
  printf '%b\n' " wmctrl -b add,sticky -i -r ${winid}$(attr_reset) ${winname}"
}

# TIPS: You can add your own, personal windows to the sticky list,
#       so that running `space` will make all your favorite windows
#       sticky. E.g.,
if false; then
  # —————— ✂ ——— ✁ —————— [ copy-paste ] —————— ✁ ——— ✂ ——————

  private_space () {
    declare -a winnames=()
    # Dubs Vim, e.g., if you send files to the same GVim with:
    #  gvim --servername SAMPI --remote-silent path/to/file
    winnames+=("SAMPI")
    # E.g., Gmail, etc.
    winnames+=("[mM]ail - Chromium")
    winnames+=("[mM]ail - Google Chrome")
    # Music apps 'n tabs:
    winnames+=("Live Stream | The Current from Minnesota Public Radio - Chromium")
    winnames+=("Live Stream | The Current from Minnesota Public Radio - Google Chrome")
    winnames+=("Spotify")
    for (( i = 0; i < ${#winnames[@]}; i++ )); do
      echo_wmctrl_sticky_cmd_winname "${winnames[$i]}"
      # We could just use -r, e.g.,
      #   wmctrl -b add,sticky -r "${winnames[$i]}"
      # But Grep let's us be a little more precise (i.e., use $ for EOL).
      local winid=$(wmctrl -l | grep "${winnames[$i]}$" | cut -d ' ' -f 1)
      if [ -n "${winid}" ]; then
        wmctrl -b add,sticky -i -r ${winid}
      fi
    done
  }

  monkey_patch_space () {
    # Remove the first two lines and last line, e.g.,:
    #   function()
    #   {
    #     ...
    #   }
    old_space=$(declare -f space | tail -n +3 | head -n -1)

    space () {
      # Meh. Don't validate the desktop number before making windows sticky.
      # (We need to do this before running old_space, to ensure that our
      #  favorite windows are sticky first, before reassigning sticky parents.
      #  Also, if we do this after old_space, there's a little screen flicker
      #  that makes that sequence look unnatural, ick.)

      echo "Making ${LOGNAME}'s windows sticky..."
      private_space

      eval "${old_space}"
    }
  }

  # —————— ✂ ——— ✁ —————— [ copy-paste ] —————— ✁ ——— ✂ ——————
fi

# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #

sleep_then_ensure_always_on_visible_desktop () {
  if ${DUBS_ALWAYS_ON_VISIBLE:-false}; then
    sleep 3  #  MAGIC_NUMBER: It takes a few seconds for Home Fries to load.
    local winids
    winids=($(wmctrl -l -p \
      | /bin/grep -E "^0x[a-f0-9]{8} +-?[0-3] +[0-9]+ +$(hostname) +${DUBS_STICKY_PREFIX_RE}" \
      | cut -d ' ' -f 1))
    printf "%s\n" "${winids[@]}" | xargs -I % wmctrl -b add,sticky -i -r %
  fi
}

dubs_always_on_visible_desktop () {
  if ${DUBS_ALWAYS_ON_VISIBLE:-false}; then
    # (lb): Gah. If you open lots of windows at once (or just change
    # focus to another window as the terminal is loading [as Home Fries
    # loads], the script's terminal window may no longer be the active
    # window! Like, duh! So this is no good:
    #
    #   wmctrl -r :ACTIVE: -b add,sticky
    #
    # Because I am unable to figure out how to find the owning window ID...
    # (I tried `xdotool search --pid $PPID`, but it appears all shells have
    # the same parent process, the one and only `mate-terminal`. And the
    # windows are not attached to the child, i.e., ``xdotool search --pid $$`
    # shows nothing (and `wmctrl -l -p` confirms that all terminal windows
    # share the same process ID (of the mate-terminal parent)), it looks like
    # our best bet is to use that special title prefix we set just prior to
    # this code being called (in dubs_set_terminal_prompt).
    #
    # Ug again. I thought the title would be set already, but it's not...
    #
    #  winids=($(wmctrl -l -p \
    #    | /bin/grep -E "^0x[a-f0-9]{8} +-?[0-3] +[0-9]+ +$(hostname) +${DUBS_STICKY_PREFIX_RE}" \
    #    | cut -d ' ' -f 1))
    #
    # So rely on special default title in use before ours applies... "Terminal".
    # ... Ug triple! Other windows also have that name while loading, duh!
    #
    #   winids=($(wmctrl -l -p \
    #     | /bin/grep -E "^0x[a-f0-9]{8} +-?[0-3] +[0-9]+ +$(hostname) +Terminal$" \
    #     | cut -d ' ' -f 1))
    #
    # So, like, really? A total kludge is in order?! Deal with this "later!"
    #
    # NOTE: Use (subshell) to suppress output (e.g., job number and 'Done').
    (sleep_then_ensure_always_on_visible_desktop &)
    # Lest we apply same always-on to any new window opened as child of this one.
    export DUBS_ALWAYS_ON_VISIBLE=
  fi

  unset -f sleep_then_ensure_always_on_visible_desktop
}

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
dubs_hook_filename_rubout () {
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

# 2020-03-20: I really need to split this file into dozens of little plugs!
# - For now, adding just another function to this really long file.
# - I don't normally care about Ctrl-s too much, but I find that the more
# I run Vim in a terminal (because I'm wicked into tmux panes recently),
# the more I inadvertently type Ctrl-s, thinking that I'm saving, then
# freaking out for a split second thinking my machine or Vim froze, to
# getting frustrated that I typed Ctrl-s and need to Ctrl-q, then :w. Ug.
# - tl;dr Make Ctrl-s work in terminal vim.
# - AFAIK, XON/XOFF flow control is only used for serial connections
#   (RS-232), so nothing lost by disabling this.
# - Ref: Some interesting background information on these settings:
#     https://unix.stackexchange.com/questions/12107/
#       how-to-unfreeze-after-accidentally-pressing-ctrl-s-in-a-terminal#12146
unhook_stty_ixon_ctrl_s_xon_xoff_flow_control () {
  # Disable XON/XOFF flow control, and sending of start/stop characters,
  # i.e., reclaim Ctrl-s and Ctrl-q.
  # - (lb): For whatever reason, -ixoff is already default for me, even on
  #           bash --noprofile --norc
  stty -ixon -ixoff
}

# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #

dubs_macos_silence_bash_warning () {
  os_is_macos || return

  # 2020-08-25: Disable "The default interactive shell is now zsh" alert.
  export BASH_SILENCE_DEPRECATION_WARNING=1
}

# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #

main () {
  check_deps
  unset -f check_deps

  unhook_stty_ixon_ctrl_s_xon_xoff_flow_control
}

main "$@"
unset -f main


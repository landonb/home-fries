#!/bin/bash
# vim:tw=0:ts=2:sw=2:et:norl:

# File: keys_util.sh
# Author: Landon Bouma (landonb &#x40; retrosoft &#x2E; com)
# Project Page: https://github.com/landonb/home-fries
# Summary: Generic Bash function library.
# License: GPLv3

# Usage: Source this script. Call its functions. Use its exports.

# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #

source_deps () {
  :
}

# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #

# Special key mapping for ThinkPad X201 laptops.

# HINTS: To reset your keyboard, run:
#           setxkbmap
#        To see current settings, run:
#           xmodmap -pke
#           xmodmap -pm
#        To find out your keyboard's key codes, run:
#           xev

# List of Keysyms Recognised by Xmodmap
#  http://wiki.linuxquestions.org/wiki/List_of_Keysyms_Recognised_by_Xmodmap

# CAVEAT: This doesn't care if you're using another keyboard.

# OTHER: Super_L is the "Windows" key.

home_fries_map_keys_lenovo () {
  # A sudo way:
  #   sudo dmidecode | \
  #     grep "Version: ThinkPad X201" > /dev/null \
  #     && echo true || echo false

  # A non-sudo way.
  # Note: xprop -root just checks that X is running (and we're not sshing in).
  if xprop -root &> /dev/null; then
    # Check that xmodmap is installed.
    command -v xmodmap &> /dev/null
    if [[ $? -eq 0 ]]; then
      if [[ -e /sys/class/dmi/id/product_version ]]; then
        if [[ $(cat /sys/class/dmi/id/product_version) == "ThinkPad X201" ]]; then
          # On Lenovo ThinkPad: Map Browser-back to Delete
          #   |-------------------------------|
          #   | Brw Bck | Up Arrow | Brow Fwd |
          #   |-------------------------------|
          #   | L Arrow | Down Arr | R Arrow  |
          #   |-------------------------------|
          # Here's the view of the bottom row:
          #  L-Ctrl|Fn|Win|Alt|--Space--|Alt|Menu|Ctrl|Browse-back|Up-arrow|Broforward
          #                                             Left-Arrow|Down-arw|Right-Arrow
          #xmodmap -e "keycode 166 = Delete" # brobackward
          # Use "mouse-over-submenu" key between Right Alt and Ctrl.
          xmodmap -e "keycode 135 = Delete"

          #xmodmap -e "keycode 166 = 112" # pageup
          #xmodmap -e "keycode 167 = 117" # pagedown
          xmodmap -e "keycode 166 = Page_Up"
          xmodmap -e "keycode 167 = Page_Down"

          # 2015.02.28: At some point, browser-back stopped working, and I used
          #             right-ctrl instead, but now browser back is remapping again.
          #               xmodmap -e "keycode 105 = Delete" # right-ctrl
        elif [[ $(cat /sys/class/dmi/id/product_version) == ThinkPad\ T*0 ]]; then
          # 2017-02-17: I shouldn't be hard-coding these settings here (it's my
          # personal taste; belongs in a private Bash module), but how many other
          # people really use home-fries, much less on an X201 or a T460?
          #
          # Here's the view of the bottom row as labeled (note hardware swap of Fn and L-Ctrl):
          #  Fn|L-Ctrl|Win|Alt|--Space--|Alt|PrtSc|Ctrl|PgUp|⬆|PgDn
          #                                                ⬅|⬇|➞
          /usr/bin/xmodmap -e "keycode 107 = Delete"
        fi
      fi
    fi
  fi
}

# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #

# 2018-01-29: This fcn. is no longer called.
#
#   QUESTION: What (laptop?) keyboard was this for?
#
home_fries_map_keys_2x3 () {
  # Not all keyboards arrange their six page keys the same way. Some use
  # two rows and three columns, and some use three rows and two columns.
  # And even when the rows and columns match, not all keyboards use the
  # same key combinations within.

  # The 2x3 keyboard layout that I like:
  #
  # ||============================||
  # || Insert || Print  || Pause  ||
  # ||        || Screen || Break  ||
  # ||============================||
  #
  # ||==================||
  # || Home   || End    ||
  # ||        ||        ||
  # ||==================||
  # || Insert || Page   ||
  # ||        || Up     ||
  # ||        ||========||
  # ||        || Page   ||
  # ||        || Down   ||
  # ||==================||

  # The 2x3 keyboard layout I do not like:
  #
  # ||============================||
  # || Print  || Scroll || Pause  ||
  # || Screen || Lock   || Break  ||
  # ||============================||
  #
  # ||==================||
  # || Home   || Page   ||
  # ||        || Up     ||
  # ||==================||
  # || End    || Page   ||
  # ||        || Down   ||
  # ||==================||
  # || Delete || Insert ||
  # ||        ||        ||
  # ||==================||

  # NOTE: To make changes to this list, clear your settings first: $ setxkbmap
  keysym Home = Home
  keysym Page_Up = End
  keysym End = Delete
  keysym Page_Down = Page_Up
  keysym Delete = Delete
  keysym Insert = Page_Down

  # These work (xmodmap takes 'em), but these don't work:
  #   keysym Print = Insert
  #   keysym Scroll_Lock = Print
  #   keysym Sys_Req = Insert
  # These also do not work:
  #   $ xmodmap -pke | grep Print
  #     keycode 107 = Print Sys_Req Print Sys_Req
  #     keycode 218 = Print NoSymbol Print
  #   $ xmodmap -pke | grep Print
  #     keycode  78 = Scroll_Lock NoSymbol Scroll_Lock
  #   keycode 107 = Insert
  #   keycode 218 = Insert
  #   keycode  78 = Print
  # Instead, go to GNOME > System > Preferences > Keyboard Shortcuts
  #   under Desktop, change "Take a screenshot" and "Take a screenshot
  #   of a window" to Scroll Lock and Alr+Scroll Lock, respectively.
  #   Now, you can override the Print Screen key.
  keysym Print = Insert
}

# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #

main () {
  : #source_deps
  unset -f source_deps
}

main "$@"


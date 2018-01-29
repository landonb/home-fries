#!/bin/bash
# vim:tw=0:ts=2:sw=2:et:norl:

# File: input_util.sh
# Author: Landon Bouma (landonb &#x40; retrosoft &#x2E; com)
# Project Page: https://github.com/landonb/home-fries
# Summary: Generic Bash function library.
# License: GPLv3

# Usage: Source this script. Call its functions. Use its exports.

# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #

source_deps() {
  :
}

# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #

# Disable the touchpad.
#
# 2015.02.20: The T440p is a great laptop but my thumbs keep
#             *lightly* brushing the touchpad, sending my cursor
#             (and screen or cursor focus) elsewhere.

# *** Touchpad Controller Option #1: syndaemon

# syndaemon is one option... but I always use a mouse, so why not
#  just disable the touchpad completely?
#    -i specifies how many seconds after last key press before
#       enabling the touchpad (default is 2 seconds)
#    -K allows modifiers such as Shift and Alt
#    -R uses XRecord for detecting keyboard activity instead of polling
#    -t only disables tapping and scrolling but allows mouse movement
#    -d will start syndaemon as a daemon
#  E.g.,
#    syndaemon -i 5 -K -R -t -d

# *** Touchpad Controller Option #2: `xinput set-prop`

touchpad_twiddle () {
  local touchpad_state=$1
  if [[ $(command -v xinput > /dev/null) || $? -eq 0 ]]; then
    local device_num=$(xinput --list --id-only "SynPS/2 Synaptics TouchPad" 2> /dev/null)
    if [[ -n ${device_num} ]]; then
      xinput set-prop ${device_num} "Device Enabled" ${touchpad_state}
    fi
  fi
}

touchpad_disable () {
  touchpad_twiddle 0
  # 2017-12-16 02:38: Something has been leaving 0~Bracketed1~ Paste enabled.
  #   This disables bracketed paste.
  echo -ne '\e]12;#ffcc00\a'
  echo -ne '\e]12;#ffffff\a'
}

touchpad_enable () {
  touchpad_twiddle 1
}

# *** Touchpad Controller Option #3: Auto-disable on `bash` startup: NO!

# 2018-01-29: This fcn., xinput_set_prop_touchpad_device_off, is never called!
#   See instead: `touchpad_disable` and `touchpad_enable`.
xinput_set_prop_touchpad_device_off () {
  touchpad_twiddle 0
}
# 2016-11-11: Let's not confuse first-time users by disabling their trackpad.
#   See instead: `touchpad_disable` and `touchpad_enable`.
#xinput_set_prop_touchpad_device_off

# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #

main() {
  : #source_deps
}

main "$@"


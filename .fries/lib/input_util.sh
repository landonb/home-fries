#!/bin/bash
# vim:tw=0:ts=2:sw=2:et:norl:

# File: input_util.sh
# Author: Landon Bouma (landonb &#x40; retrosoft &#x2E; com)
# Project Page: https://github.com/landonb/home-fries
# Summary: Generic Bash function library.
# License: GPLv3

# Usage: Source this script. Call its functions. Use its exports.

# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #

source_deps () {
  local curdir=$(dirname -- "${BASH_SOURCE[0]}")
  # Load: warn, etc.
  source ${curdir}/logger.sh
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
  # 2018-02-14 01:12: I've also noticed a problem with mouse state getting
  # stuck weird and then mouse clicking not working, but Alt-tab does, so
  # Alt-tab to a terminal, then run touchpad_disable, then mouse recovers...
  # what in the world did I do? Happens once or twice a day sometimes....
  # I also saw a right-click get into weird state where mouse didn't work,
  # nor Alt-tab, but after another right-click, I could Alt-Tab and then
  # run this command to fix things. Seriously, what??
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

# Disable desktop popup notifications.
#
# Use Cases:
#
# #1. Presenting!
#
#     The last thing you want is for your preso to be interrupto.
#     Think: Either presenting live to a monitor/projector, or
#     screencasting, e.g., to a Zoom meeting being recorded.
#
# #2. Quiet time!
#
#     I suppose you could disable desktop notifications if you need
#     to focus. Or you could just learn to passively ignore noise
#     better. Think: You need to be alert to HipChat activity but
#     you don't want to have your workflow interrupted.
#
# Easily test!
#
# E.g.,
#
#   notify-send -i face-wink 'Wut Wut!' "Hello! January"
#
#   notify-send 'Super Awesome Custom Icon' 'It is pretty cool, right?' \
#     -u normal -i '/home/user/Pictures/icons/excellent-icon.png'
#
# Even over SSH!
#
#   ssh -X user@192.168.0.112 \
#     'DISPLAY=:0 notify-send \
#       "HAHA I'm In Your Computer!" \
#       "Deleting all your stuff!" \
#       -u critical \
#       -i face-worried'
#
# See:
#
#   https://www.maketecheasier.com/desktop-notifications-for-linux-command/
#
#   https://wiki.ubuntu.com/NotificationDevelopmentGuidelines
#
#   The Desktop Notification Spec on
#
#     http://www.galago-project.org/specs/notification/
#
#   HINT: Run ``locate face-wink`` to find system icons.
#
# Differences in -u urgency level.
#
#   -u low: White vertical background stripe on left part of notification.
#   -u normal: Green stripe.
#   -u critical: Red stripe.

notifications-toggle () {
  local force_state=$1
  local notifsf="/usr/share/dbus-1/services/org.freedesktop.mate.Notifications.service"
  if [[ ${force_state} -ne 1 && -e "${notifsf}" && ! -e "${notifsf}.disabled" ]]; then
    sudo /bin/mv "${notifsf}" "${notifsf}.disabled"
    info "Disabled desktop notifications!"
  elif [[ ${force_state} -ne -1 && ! -e "${notifsf}" && -e "${notifsf}.disabled" ]]; then
    sudo /bin/mv "${notifsf}.disabled" "${notifsf}"
    info "Enabled desktop notifications!"
  elif [[ -e "${notifsf}" && -e "${notifsf}.disabled" ]]; then
    error "ERROR: Found live file and .disabled file. Don't know what to do!"
  elif [[ ! -e "${notifsf}" && ! -e "${notifsf}.disabled" ]]; then
    error "Did not find notifications file at: ${notifsf}"
  # else ${force_state} -ne 0 and state already set.
  fi
}

nonotifs () {
  eval "LOG_LEVEL=${LOG_LEVEL_INFO} notifications-toggle 0"
}

desktop-notification-on () {
  eval "LOG_LEVEL=${LOG_LEVEL_WARNING} notifications-toggle 1"
}

desktop-notification-off () {
  eval "LOG_LEVEL=${LOG_LEVEL_WARNING} notifications-toggle -1"
}

# NOTE: notify-send still sometimes works after disabling notifications.
#       It seems to eventually stick, though.
desktop-notification-test () {
  notify-send -i face-wink 'Wut Wut!' "Hello, Notified User!"
}

# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #

main () {
  source_deps
}

main "$@"


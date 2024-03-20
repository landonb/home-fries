#!/usr/bin/env bash
# vim:tw=0:ts=2:sw=2:et:norl:ft=sh
# Author: Landon Bouma (landonb &#x40; retrosoft &#x2E; com)
# Project: https://github.com/landonb/home-fries#🍟
# License: MIT

# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #

check_deps () {
  # Verify sh-logger/bin/logger.sh loaded.
  check_dep '_sh_logger_log_msg'
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

_touchpad_twiddle () {
  local touchpad_state=$1
  if [[ $(command -v xinput > /dev/null) || $? -eq 0 ]]; then
    local device_num=$(xinput --list --id-only "SynPS/2 Synaptics TouchPad" 2> /dev/null)
    if [[ -n ${device_num} ]]; then
      xinput set-prop ${device_num} "Device Enabled" ${touchpad_state}
    fi
  fi
}

touchpad-disable () {
  _touchpad_twiddle 0
  # 2017-12-16 02:38: Something has been leaving 0~Bracketed1~ Paste enabled.
  #   This disables bracketed paste.
  # 2018-02-14 01:12: I've also noticed a problem with mouse state getting
  # stuck weird and then mouse clicking not working, but Alt-tab does, so
  # Alt-tab to a terminal, then run touchpad_disable, then mouse recovers...
  # what in the world did I do? Happens once or twice a day sometimes....
  # I also saw a right-click get into weird state where mouse didn't work,
  # nor Alt-tab, but after another right-click, I could Alt-Tab and then
  # run this command to fix things. Seriously, what??
  # 2018-04-03 11:54: DUDE?!: I cannot disable bracketed paste on 14.04!!
  #   I exited and restarted Bash and it went away, but I'm getting tired
  #   of it cropping up! [2018-04-03 14:10: I compiled Bash 4.4 from scratch,
  #   upgrading from 4.3.11(1)-release to 4.4.18(1)-release. Wait and see if
  #   it works, though I cannot prove a negative. So if I never see this issue
  #   again, I won't know for sure if upgrading solved it. At least not without
  #   being able to knowingly recreate the problem.]
  echo -ne '\e]12;#ffcc00\a'
  echo -ne '\e]12;#ffffff\a'
  # https://askubuntu.com/questions/662222/why-bracketed-paste-mode-is-enabled-sporadically-in-my-terminal-scree
  # 2018-04-03: Haha, when I copied this from the web, it had a typo:
  #   bind 'set-enable-bracketed-paste off'
  # which for some reason masked all 'p' characters, e.g., I'd copy-paste
  # a word with 'p' in it, and the 'p' wouldn't be pasted!
  bind 'set enable-bracketed-paste off'
}

touchpad-enable () {
  _touchpad_twiddle 1
}

# *** Touchpad Controller Option #3: Auto-disable on `bash` startup: NO!

# 2018-01-29: This fcn., xinput_set_prop_touchpad_device_off, is never called!
#   See instead: `touchpad_disable` and `touchpad_enable`.
xinput_set_prop_touchpad_device_off () {
  _touchpad_twiddle 0
}
# 2016-11-11: Let's not confuse first-time users by disabling their trackpad.
#   See instead: `touchpad_disable` and `touchpad_enable`.
#xinput_set_prop_touchpad_device_off

# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #

# Disable middle mouse button (mouse scroll wheel) click.

# tl;dr: I often fat-finger a middle mouse click, which pastes; prevent this.
#
# Use case: I use my mouse with two fingers: my right pointer over the left mouse
# button, and my middle finger over the right button. Oftentimes, I accidentally
# press both buttons nearly simultaneously, which is interpreted as a middle mouse
# click (which performs a paste by default). This is Very Annoying. And while we
# cannot disable the two-buttons-is-a-middle-click mapping, we can at least disable
# the middle click response.

# Ref:
#
#   https://wiki.ubuntu.com/X/Config/Input
#
#  - "Example: Disabling middle-mouse button paste on a scrollwheel mouse"
#
#      "Scrollwheel mice support a middle-button click event when pressing the 
#       scrollwheel. This is a great feature, but you may find it irritating."
#                                                                 [Ya think!?]
#
# Try these commands:
#
#   xinput list
#
#   xinput list | grep pointer | grep Logitech | grep 'id='
#
#   xinput list | grep pointer | grep Logitech | /usr/bin/env sed -E 's/^.*id=([0-9]+).*/\1/'
#
#   # My mouse has 2 IDs, 9 and 10.
#   🍄 $ xinput get-button-map 9
#   1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16 17 18 19 20
#   🍄 $ xinput get-button-map 10
#   1 2 3 4 5 6 7

logitech-middle-mouse-click-disable () {
  # 2020-08-24: Bail on no `lsusb` (e.g., macOS).
  command -v lsusb > /dev/null || return
  # The function tail touches a skip-file after this function runs once.
  local suffix="-HOMEFRIES_SET_BUTTON_MAP"
  # See session_util.sh for touched_since_up.
  touched_since_up "${suffix}" && return
  # Look for Logitech M325c mouse (or, I guess, the USB receiver device, so this'll
  # probably match other models than just the M325c).
  if $(lsusb | grep "046d:c52f Logitech, Inc. Unifying Receiver" >& /dev/null); then
    if xinput list &> /dev/null; then
      # Run the commands, e.g.,
      #   xinput set-button-map 9 1 0 3
      #   xinput set-button-map 10 1 0 3
      xinput list \
      | grep pointer \
      | grep Logitech \
      | /usr/bin/env sed -E 's/^.*id=([0-9]+).*/\1/' \
      | xargs -I % /usr/bin/env bash -c 'xinput set-button-map % 1 0 3'
    fi
  fi
  # Leave touchfile so we skip this operation on subsequent sessions.
  # (lb): macOS does not support --suffix option.
  #         mktemp --suffix="${suffix}" > /dev/null
  local temptf="$(mktemp)"
  mv "${temptf}" "${temptf}${suffix}"
}

middle-mouse-click-disable () {
  logitech-middle-mouse-click-disable
}

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
    sudo /usr/bin/env mv -- "${notifsf}" "${notifsf}.disabled"
    info "Disabled desktop notifications!"
  elif [[ ${force_state} -ne -1 && ! -e "${notifsf}" && -e "${notifsf}.disabled" ]]; then
    sudo /usr/bin/env mv -- "${notifsf}.disabled" "${notifsf}"
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
  check_deps
  unset -f check_deps
}

main "$@"
unset -f main


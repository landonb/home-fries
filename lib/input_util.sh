#!/usr/bin/env bash
# vim:tw=0:ts=2:sw=2:et:norl:ft=sh
# Author: Landon Bouma (landonb &#x40; retrosoft &#x2E; com)
# Project: https://github.com/landonb/home-fries#🍟
# License: MIT

# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #

check_deps() {
  # Verify sh-logger/bin/logger.sh loaded.
  check_dep '_sh_logger_log_msg'
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

if ! os_is_macos; then
  notifications-toggle() {
    local force_state=$1

    local notifsf
    if [ "${XDG_CURRENT_DESKTOP}" = "GNOME" ]; then
      notifsf="/usr/share/dbus-1/services/org.gnome.Shell.Notifications.service"
    elif [ "${XDG_CURRENT_DESKTOP}" = "MATE" ]; then
      notifsf="/usr/share/dbus-1/services/org.freedesktop.mate.Notifications.service"
    else
      >&2 echo "ERROR: Unsupported Desktop Environment"

      return 1
    fi

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

  # HSTRY/2025-11-02: Née `nonotifs`, but renamed
  # so `non<Tab>` completes noname commands.
  notifs-toggle() {
    eval "LOG_LEVEL=${LOG_LEVEL_INFO} notifications-toggle 0"
  }

  desktop-notification-on() {
    eval "LOG_LEVEL=${LOG_LEVEL_WARNING} notifications-toggle 1"
  }

  desktop-notification-off() {
    eval "LOG_LEVEL=${LOG_LEVEL_WARNING} notifications-toggle -1"
  }

  # NOTE: notify-send still sometimes works after disabling notifications.
  #       It seems to eventually stick, though.
  desktop-notification-test() {
    notify-send -i face-wink 'Wut Wut!' "Hello, Notified User!"
  }
fi

# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #

main() {
  unset -f main

  check_deps
  unset -f check_deps
}

main "$@"

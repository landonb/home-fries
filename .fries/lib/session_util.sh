#!/bin/bash
# vim:tw=0:ts=2:sw=2:et:norl:

# File: session_util.sh
# Author: Landon Bouma (landonb &#x40; retrosoft &#x2E; com)
# Project Page: https://github.com/landonb/home-fries
# Summary: Generic Bash function library.
# License: GPLv3

# Usage: Source this script. Call its functions. Use its exports.

# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #

source_deps() {
  local curdir=$(dirname -- "${BASH_SOURCE[0]}")
  source ${curdir}/term_util.sh
}

# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #

bash-exit-bash-hole () {
  # If the parent process is also bash, we're bash-in-bash,
  # so we want to exit to the outer shell.
  ps aux | grep "bash" | grep $PPID &> /dev/null
  if [[ $? -eq 0 ]]; then
    #echo "exit"
    exit
  else
    echo "stay"
  fi
}

# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #

# 2016-10-10: Starting last month, on both 14.04/rebecca/trusty and
# 16.04/sarah/xenial, both laptop and desktop stopped asking for
# password on resume from suspend.
#
# This is a hacky work-around -- use the screen saver lock command.
# Note that the unlock screen is different than the Window Manager's,
# i.e., if you had gone though Mint Menu > Lock Screen.
#
# Might possibly be this bug 1 other person in known universe is seeing:
#   "no password prompt after suspend, settings ignored"
#     https://bugs.launchpad.net/linuxmint/+bug/1185681
#
# Not sure where I found the dbus-send trick.
lock_screensaver_and_power_suspend () {
  # 2016-10-25: Heck, why not! At least show some semblance of not being
  # a complete idiot.
  termdo-all sudo -K

  source /etc/lsb-release
  if [[ ${DISTRIB_CODENAME} = 'xenial' \
     || ${DISTRIB_CODENAME} = 'sarah' \
     || ${DISTRIB_CODENAME} = 'sonya' \
     ]]; then
    gnome-screensaver-command --lock && \
      systemctl suspend -i
  elif [[ ${DISTRIB_CODENAME} = 'trusty' || ${DISTRIB_CODENAME} = 'rebecca' ]]; then
    gnome-screensaver-command --lock && \
      dbus-send --system --print-reply --dest=org.freedesktop.UPower \
        /org/freedesktop/UPower org.freedesktop.UPower.Suspend
  else
    echo "ERROR: Unknown distro. I refuse to Lock Screensaver and Power Suspend."
    return 1
  fi
  # Sneak in enabling locking screen saver.
  screensaver_lockon
} # end: lock_screensaver_and_power_suspend

lock_screensaver_and_do_nothing_else () {
  gnome-screensaver-command --lock
  # I'm iffy about enabling locking screensaver on simple qq.
  # But also thinking maybe yeah.
  screensaver_lockon
} # end: lock_screensaver_and_do_nothing_else

# 2016-10-10: Seriously? `qq` isn't a command? Sweet!
alias qq="lock_screensaver_and_do_nothing_else"
alias qqq="lock_screensaver_and_power_suspend"

# 2016-11-12: I don't use this fcn. I moved it from
#   ~/.fries/once/setup_ubuntu.sh rather than delete it.
user_window_session_logout () {
  # The logout commands vary according to distro, so check what's there.
  # Bash has three built-its that'll tell is if a command exists on
  # $PATH. The simplest, ``command``, doesn't print anything but returns
  # 1 if the command is not found, while the other three print a not-found
  # message and return one. The other two commands are ``type`` and ``hash``.
  # All commands return 0 is the command was found.
  #  $ command -v foo >/dev/null 2>&1 || { echo >&2 "Not found."; exit 1; }
  #  $ type foo       >/dev/null 2>&1 || { echo >&2 "Not found."; exit 1; }
  #  $ hash foo       2>/dev/null     || { echo >&2 "Not found."; exit 1; }
  # Thanks to http://stackoverflow.com/questions/592620/
  #             how-to-check-if-a-program-exists-from-a-bash-script
  if ``command -v mate-session-save >/dev/null 2>&1``; then
    mate-session-save --logout
  elif ``command -v gnome-session-save >/dev/null 2>&1``; then
    gnome-session-save --logout
  else
    # This is the most destructive way to logout, so don't do it:
    #   Kill everything but kill and init using the special -1 PID.
    #   And don't run this as root or you'll be sorry (like, you'll
    #   kill kill and init, I suppose). This will cause a logout.
    #   http://aarklonlinuxinfo.blogspot.com/2008/07/kill-9-1.html
    #     kill -9 -1
    # Apparently also this, but less destructive
    #     sudo pkill -u $USER
    echo
    echo "WARNING: Logout command not found; cannot logout."
  fi
}

# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #

# 2016-10-05: [lb] not seeing the disable-wake-on-lid action working, from:
#
#     ~/.fries/once/recipe/usr/lib/pm-utils/sleep.d/33disablewakeups
#
#             so let's try this here in bashrc.

disable_wakeup_on_lid () {
  cat /proc/acpi/wakeup | grep "^LID" &> /dev/null
  if [[ $? -eq 0 ]]; then
    cat /proc/acpi/wakeup | grep "^LID" | grep disabled &> /dev/null
    if [[ $? -ne 0 ]]; then
      #echo " LID" | sudo tee /proc/acpi/wakeup
      echo " LID" | tee /proc/acpi/wakeup
    fi
  fi
} # end: disable_wakeup_on_lid

# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #

# Shell Options

home_fries_configure_shell_options() {
  # See man bash for more options.

  # Don't wait for job termination notification.
  # Report status of terminated bg jobs immediately (same as set -b).
  set -o notify

  # Use case-insensitive filename globbing.
  shopt -s nocaseglob

  # When changing directory small typos can be ignored by bash
  # for example, cd /vr/lgo/apaache would find /var/log/apache.
  # 2017-11-19: Let's give this a try!
  shopt -s cdspell
}

# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #

pm-latest() {
  if command -v journalctl &> /dev/null; then
    # NOTE: In lieu of a /var/log/pm-suspend.log, which you won't find
    #       on Ubuntu, use journalctl to see when system was last woke.
    #       (2018-01-29: (lb): I use this for back-filling hamster if
    #       I forget when I got to work, resumed, and started working.)
    journalctl -b 0 -r -t systemd-sleep \
      | grep -m 1 "Suspending system...$" \
      | awk '{print "Suspend at "$1" "$2" "$3}'

    journalctl -b 0 -r -t systemd-sleep \
      | grep -m 1 "System resumed.$" \
      | awk '{print "Resumed at "$1" "$2" "$3}'
  else
    # E.g.,
    #  Wed Jan  3 13:04:19 CST 2018: Awake.
    #  Wed Jan  3 13:04:19 CST 2018: Running hooks for resume
    #  Wed Jan  3 13:04:19 CST 2018: Finished.
    #  Thu Jan  4 22:55:36 CST 2018: Running hooks for suspend.
    #  Thu Jan  4 22:55:37 CST 2018: performing suspend
    tac /var/log/pm-suspend.log \
      | grep -m 1 ": Running hooks for suspend\.$" \
      | awk '{print "Suspend at "$2" "$3" "$4}'
    tac /var/log/pm-suspend.log \
      | grep -m 1 ": Awake\.$" \
      | awk '{print "Resumed at "$2" "$3" "$4}'
  fi

  # Ha. You can determine when the screen saver was unlocked by looking
  # in the auth log. But I do not think the screen saver lock time is
  # recorded.
  #
  # If you wanted, you could run a screen saver monitor to record this event:
  #
  #   dbus-monitor --session "type='signal',interface='org.gnome.ScreenSaver'" \
  #    | ( while true; do \
  #          read X \
  #          if echo "$X" | grep "boolean true" &> /dev/null; then \
  #            echo "Screen locked on $(date)" > $HOME/lock_screen.log \
  #          fi \
  #        done \
  #      )
  #
  #   Respek: https://askubuntu.com/questions/435069/
  #     how-can-i-know-when-my-screen-was-locked-last-time
  #
  # Use `tac` ("cat" backwards) to "concatenate and print files in reverse".
  tac /var/log/auth.log \
    | grep -m 1 \
      "gnome-screensaver-dialog: gkr-pam: unlocked login keyring" \
    | awk '{print "Unlockd at "$1" "$2" "$3}'
}

# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #

main() {
  source_deps
}

main "$@"

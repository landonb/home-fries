#!/bin/bash
# vim:tw=0:ts=2:sw=2:et:norl:ft=sh
# Author: Landon Bouma (landonb &#x40; retrosoft &#x2E; com)
# Project: https://github.com/landonb/home-fries#🍟
# License: MIT

# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #

check_deps () {
  # Verify distro_util.sh loaded.
  check_dep 'suss_window_manager'
  # Verify term_util.sh loaded.
  check_dep 'termdo-all'
}

# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #

bash-exit-bash-hole () {
  # If the parent process is also bash, we're bash-in-bash,
  # so we want to exit to the outer shell.
  # 2018-05-22: How have I not noticed this yet?! 'snot working!!
  #   The simple grep on "bash" is broken, as it matches, e.g.,
  #     mate-terminal --geometry 130x48+1486+65 -e /user/home/.local/bin/bash
  #   so isolate the program name, excluding args and other.
  # This is too simple:
  #   ps aux | grep "bash" | grep $PPID &> /dev/null
  # FIXME/2018-05-29: Here and elsewhere: prefer `grep -E`...
  ps ax -o pid,command | grep -P "^ *$PPID \S+/bash(?:($| ))" &> /dev/null
  if [[ $? -eq 0 ]]; then
    exit
  else
    echo "stay"
  fi
}

# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #

termdo-bash-reset () {
  # We could care or not whether we stacking subshells (i.e., calling
  # `bash` multiple times from the same terminal) -- it doesn't affect
  # performance.
  #
  # Nonetheless, if you like a mostly clean house, we can exit any
  # subshells first to minimize the depth of the bash hole we make.
  #
  # On approach might be to use kill. But then how do you distinguish
  # between a terminal that's in a subshell vs one that's not?
  # If you look at `ps aux | grep bash`, you'll see that the top-level
  # terminal processes are just 'bash', and subshells created are
  # generally '/bin/bash' (because our "alias bash=" calls /bin/bash,
  # and not just bash).
  #
  # So this could work, but it's blindly destructive:
  #
  #    kill -s 9 $(ps aux | grep "/bin/bash" | awk '{print $2}')
  #
  # We can be a bit more intelligent, and respect, say, a running
  # process, by sending an exit-maybe signal ahead of the /bin/bash.
  #
  # Note also the backgrounded and the sleep. 2 termdo-all's in a row
  # don't work from the same shell (the second is apparently ignored),
  # so sub-shell the first call and sleep to make it work.
  termdo-all bash-exit-bash-hole &
  #sleep 0.5
  sleep 1.0
  termdo-all /bin/bash
}

# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #

_homefries_screensaver_command () {
  # Could instead run:
  #   suss_window_manager
  #   if ${WM_IS_MATE}; then
  #     ...
  if command -v mate-screensaver-command > /dev/null; then
    mate-screensaver-command "$@"
  else
    gnome-screensaver-command "$@"
  fi
}

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

# FIXME: Gah.
  . /etc/lsb-release
  [[ ${DISTRIB_CODENAME} == 'rebecca' ]] && echo "Not on $(hostname)!" && return

  # 2016-10-25: Heck, why not! At least show some semblance of not being
  # a complete idiot.
  termdo-all "echo lock_screensaver_and_power_suspend says"
  termdo-all sudo -K
  # 2018-02-19: Tmux, Too!
  # NOTE: pane_id returns, e.g., %0, %1, %2; pane_index returns 1, 2, 3.
  for _pane in $(tmux list-panes -a -F '#{pane_index}'); do \
    # Test echoes:
    #   echo "pane: ${_pane}"
    #   tmux send-keys -t ${_pane} "echo 'pane: ${_pane}'" Enter
    tmux send-keys -t ${_pane} "echo 'pane: ${_pane}'" Enter
    tmux send-keys -t ${_pane} "sudo -K" Enter
  done

  . /etc/lsb-release
  if [[ ${DISTRIB_CODENAME} = 'xenial' \
     || ${DISTRIB_CODENAME} = 'sarah' \
     || ${DISTRIB_CODENAME} = 'sonya' \
     ]]; then
    _homefries_screensaver_command --lock && \
      systemctl suspend -i
  elif [[ ${DISTRIB_CODENAME} = 'trusty' || ${DISTRIB_CODENAME} = 'rebecca' ]]; then
    _homefries_screensaver_command --lock && \
      dbus-send --system --print-reply --dest=org.freedesktop.UPower \
        /org/freedesktop/UPower org.freedesktop.UPower.Suspend
  else
    echo "ERROR: Unknown distro. I refuse to Lock Screensaver and Power Suspend."
    return 1
  fi
# 2018-05-29: Do these even run after the suspend?
  # Sneak in enabling locking screen saver.
  screensaver_lockon

  # Show desktop / Minimize all windows
  xdotool key ctrl+alt+d
} # end: lock_screensaver_and_power_suspend

lock_screensaver_and_power_suspend_lite () {

# FIXME: Gah.
  . /etc/lsb-release
  [[ ${DISTRIB_CODENAME} == 'rebecca' ]] && echo "Not on $(hostname)!" && return

  # Show desktop / Minimize all windows
  xdotool key ctrl+alt+d

  . /etc/lsb-release
  if [[ ${DISTRIB_CODENAME} = 'xenial' \
     || ${DISTRIB_CODENAME} = 'sarah' \
     || ${DISTRIB_CODENAME} = 'sonya' \
     ]]; then
    _homefries_screensaver_command --lock && \
      systemctl suspend -i
  elif [[ ${DISTRIB_CODENAME} = 'trusty' || ${DISTRIB_CODENAME} = 'rebecca' ]]; then
    _homefries_screensaver_command --lock && \
      dbus-send --system --print-reply --dest=org.freedesktop.UPower \
        /org/freedesktop/UPower org.freedesktop.UPower.Suspend
  else
    echo "ERROR: Unknown distro. I refuse to Lock Screensaver and Power Suspend."
    return 1
  fi
}

lock_screensaver_and_do_nothing_else () {
  _homefries_screensaver_command --lock
  # I'm iffy about enabling locking screensaver on simple qq.
  # But also thinking maybe yeah.
  screensaver_lockon
} # end: lock_screensaver_and_do_nothing_else

# 2016-10-10: Seriously? `qq` isn't a command? Sweet!
alias qq="lock_screensaver_and_do_nothing_else"
alias qqq="lock_screensaver_and_power_suspend"
alias q4="lock_screensaver_and_power_suspend_lite"

# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #

# 2016-11-12: I don't use this fcn. I moved it from
#   .homefries/once/setup_ubuntu.sh rather than delete it.
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
  if command -v mate-session-save > /dev/null; then
    mate-session-save --logout
  elif command -v gnome-session-save > /dev/null; then
    gnome-session-save --logout
  else
    # This is the most destructive way to logout, so don't do it:
    #   Kill everything but kill and init using the special -1 PID.
    #   And don't run this as root or you'll be sorry (like, you'll
    #   kill kill and init, I suppose). This will cause a logout.
    #   http://aarklonlinuxinfo.blogspot.com/2008/07/kill-9-1.html
    #     kill -9 -1
    # Apparently also this, but less destructive
    #     sudo pkill -u $LOGNAME
    echo
    echo "WARNING: Logout command not found; cannot logout."
  fi
}

# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #

# 2016-10-05: [lb] not seeing the disable-wake-on-lid action working, from:
#
#     .homefries/once/recipe/usr/lib/pm-utils/sleep.d/33disablewakeups
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
}

# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #

# Shell Options

home_fries_configure_shell_options () {
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

pm-latest () {
  # See also:
  #   journalctl --list-boots
  # https://www.digitalocean.com/community/tutorials/how-to-use-journalctl-to-view-and-manipulate-systemd-logs
  # But takes a moment to run.
  # Also, this did not work like I expected it would:
  #   journalctl --list-boots -r -n 1
  # For log from previous boot (not suspend/wake):
  #   journalctl -b -1
  if command -v journalctl &> /dev/null; then    #
    # NOTE: In lieu of a /var/log/pm-suspend.log, which you won't find
    #       on Ubuntu, use journalctl to see when system was last woke.
    #       (2018-01-29: (lb): I use this for back-filling hamster if
    #       I forget when I got to work, resumed, and started working.)
    # 2020-04-09: Not finding good docs on values for --identifier=SYSLOG_IDENTIFIER.
    # And on latest Mint MATE, 'systemd-sleep' begets '-- No entries --'.
    # 'kernel' works for me, though.
    # - For posterity, the old code:
    if false; then
      show_latest_suspend_resume () {
        journalctl -b 0 -r -t systemd-sleep \
          | grep -m 1 "$1" \
          | awk '{print "$2 at "$1" "$2" "$3}'
      }
      show_latest_suspend_resume "Suspending system...$" "Suspend"
      show_latest_suspend_resume "System resumed.$" "Resumed"
    fi
    echo "FIXME: pm-latest is broke! and doesn't know to get get suspend or resume time."
    # 2020-04-09: Here's what I see nowadays, on Linux Mint MATE:
    #   Dec 12 16:29:59 lethe kernel: PM: suspend entry (deep)
    #   Dec 12 19:06:52 lethe kernel: PM: Syncing filesystems ... done.
    # except that's on a previous boot... I should just test this...
    show_latest_suspend_resume () {
      journalctl -b 0 -r -t kernel \
        | grep -m 1 "$1" \
        | awk '{print "$2 at "$1" "$2" "$3}'
    }
    show_latest_suspend_resume "kernel: PM: suspend entry (deep)$" "Suspend"
    show_latest_suspend_resume "kernel: PM: Syncing filesystems ... done.$" "Resumed"
  fi

  if [ -f "/var/log/pm-suspend.log" ]; then
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
  suss_window_manager
  if ${WM_IS_MATE}; then
    tac /var/log/auth.log \
      | grep -m 1 \
        "mate-screensaver-dialog: gkr-pam: unlocked login keyring" \
      | awk '{print "Unlockd at "$1" "$2" "$3}'
  else
    tac /var/log/auth.log \
      | grep -m 1 \
        "gnome-screensaver-dialog: gkr-pam: unlocked login keyring" \
      | awk '{print "Unlockd at "$1" "$2" "$3}'
  fi
}

# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #

# Test if Bash function exists.
fn_exists () {
  type -t $1 > /dev/null
}
alias function_exists=fn_exists

# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #

# 2020-03-27: I added this to help ssh-agent-kick check the env file,
#               HOMEFRIES_SSH_ENV="${HOME}/.ssh/environment"
#             to see if it had been created since user logged on.
#             - Then I realized I didn't need to.
#               So I'm recording this function to have a copy of it,
#               but note that nothing calls it,
#               and my feelings won't be hurt if you remove it.
touched_since_logged_on_desktop () {
  local cmpfile="$1"
  local touched_since=false

  # $ last -1 --fulltimes
  # user  tty7         :0               Fri Mar 27 17:25:50 2020   gone - no logout
  #
  # wtmp begins Wed Mar  4 20:06:32 2020
  #
  # $ last -1 --fulltimes | head -1 | /bin/sed -E 's/ +/ /g' | cut -d' ' -f4-8
  # Fri Mar 27 17:25:50 2020
  local logontime
  logontime="$(last -1 --fulltimes | head -1 | /bin/sed -E 's/ +/ /g' | cut -d' ' -f4-8)"

  # See `man mktemp`: It defaults to TMPDIR or /tmp.
  local logontouch=$(mktemp --suffix "-HOMEFRIES_TOUCHYLOGON")
  touch -d "${logontime}" "${logontouch}"
  [ "${logontouch}" -ot "${cmpfile}" ] && touched_since=true
  /bin/rm "${logontouch}"

  ${touched_since}
}

# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #

touched_since_up () {
  local suffix="$1"
  local touched_since=false
  local touchfile
  # See `man mktemp`: It defaults to TMPDIR or /tmp.
  touchfile="$(find ${TMPDIR:-/tmp}/ -maxdepth 1 -type f -name "*${suffix}" | head -1)"
  if [ -n "${touchfile}" ]; then
    local boottouch=$(mktemp --suffix "-HOMEFRIES_TOUCHYBOOT")
    touch -d "$(uptime -s)" "${boottouch}"
    [ "${boottouch}" -ot "${touchfile}" ] && touched_since=true
    /bin/rm "${boottouch}"
  fi
  ${touched_since}
}

# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #

main () {
  check_deps
  unset -f check_deps
}

main "$@"
unset -f main


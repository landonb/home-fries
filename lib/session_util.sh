#!/usr/bin/env bash
# vim:tw=0:ts=2:sw=2:et:norl:ft=sh
# Author: Landon Bouma (landonb &#x40; retrosoft &#x2E; com)
# Project: https://github.com/landonb/home-fries#🍟
# License: MIT

# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #

# If the parent process is also bash, we're bash-in-bash,
# so we want to exit to the outer shell.

# 2018-05-22: How have I not noticed this yet?! 'snot working!!
#   The simple grep on "bash" is broken, as it matches, e.g.,
#     mate-terminal --geometry 130x48+1486+65 -e /home/user/.local/bin/bash
#   so isolate the program name, excluding args and other.
# This is too simple:
#   ps aux | grep "bash" | grep $PPID &> /dev/null
# FIXME/2018-05-29: Here and elsewhere: prefer `grep -E`...

# 2022-11-20: `poetry shell`'s virtualenv uses `exit`, not `deactivate`.

bash-exit-bash-hole () {
  local parent_is_bash=false
  local parent_is_ibash=false
  local parent_is_poetry=false

  _hf_session_util_is_ppid_bash
  [ $? -ne 0 ] || parent_is_bash=true

  _hf_session_util_is_ppid_ibash
  [ $? -ne 0 ] || parent_is_ibash=true

  _hf_session_util_is_ppid_poetry_shell
  [ $? -ne 0 ] || parent_is_poetry=true

  if ${parent_is_bash}; then
    echo "exit, sh"

    exit 2> /dev/null
  elif ${parent_is_ibash}; then
    echo "exit, -b"

    exit 2> /dev/null
  elif ${parent_is_poetry}; then
    echo "exit, po"

    exit 2> /dev/null
  else
    echo "stay"
  fi
}

# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #

# FIXME: Not DRY: Copied from ~/.kit/git/git-smart/bin/git-brs.
#   grep-or-ggrep
_hf_grep_or_ggrep () {
  #   $ grep --version
  #   grep (BSD grep, GNU compatible) 2.6.0-FreeBSD
  #   # "GNU compatible" it's not.
  #   $ ggrep --version
  #   ggrep (GNU grep) 3.8
  if grep -q -e "GNU grep" <(grep --version | head -1); then
    echo "grep"
  elif command -v ggrep > /dev/null; then
    echo "ggrep"
  else
    >&2 echo "ERROR: GNU \`grep\` not found"
  fi
}

_HF_GREP="$(_hf_grep_or_ggrep)"

# E.g.,
#   18305 /home/user/.local/bin/bash
_hf_session_util_is_ppid_bash () {
  ps ax -o pid,command | ${_HF_GREP} -P "^ *${PPID} \S+/bash($| )" &> /dev/null
}

# E.g., login shell
#    9483 -bash
# Where the dash-bash means it was started as interactive session.
# And is what happens when you `bash` from within a `tmux` shell.
# - Though on macOS/iTerm2, /opt/homebrew/bin/bash is first shell's
#   parent process; and subshells are just `bash` (no dash).
_hf_session_util_is_ppid_ibash () {
  ps ax -o pid,command | ${_HF_GREP} -P "^ *${PPID} -?bash$" &> /dev/null
}

# E.g.,
#   23799 /home/user/.local/share/pypoetry/venv/bin/python /home/user/.local/bin/poetry shell
_hf_session_util_is_ppid_poetry_shell () {
  ps ax -o pid,command | ${_HF_GREP} -P "^ *${PPID} \S+/python3? \S+/poetry shell$" &> /dev/null
}

_hf_session_is_subshell () {
  false \
    || _hf_session_util_is_ppid_bash \
    || _hf_session_util_is_ppid_ibash \
    || _hf_session_util_is_ppid_poetry_shell
}

# `shexit` also comes to mind, but `be<TAB>` for the win.
# - Though beware macos Homebrew imagemagick `benchmark_xl`
#   conflicts, but you probably don't need that command and
#   can rename it.
home_fries_session_util_configure_aliases_bexit () {
  _hf_session_is_subshell \
    || return

  claim_alias_or_warn "bexit" "bash-exit-bash-hole"
}

# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #

# `dash` and `sh` shims to cleanup (and customize) PS1.

# Common advice re: dash PS1: "But really, you shouldn't use dash interactively."
#   https://unix.stackexchange.com/questions/158313/create-a-dash-prompt
# - But what if you want to copy-paste shell code to test that it's POSIX-compatible?
#   - So, yes, sometimes, though rarely, I run dash interactively.
# - dash doesn't render PS1 escape sequences, which is ignorable unless it's not.
#   - On Linux Mint, it's ignorable.
#     - Author see a longer prompt than normal, with all the escape sequences, e.g.,
#       \[\]\[\033[01;37m\]\u@\[\033[01;33m\]\h\[\033[00m\]∶\[\033[01;36m\]\W\[\033[00m\] 🍄 $ 
#     and with no colors or styling.
#     - But the prompt is still usable.
#   - But on macOS, on the other hand, the prompt is more messed up.
#     - Note that the hostname is substituted, so the line is slightly shorter, e.g.,
#       \[\]\[\033[01;37m\]\u@myhost\[\033[00m\]:\[\033[01;36m\]\W\[\033[00m\] 🍄 $ 
#     But more critically, starting at '@', the text is salmon-colored,
#     italic, and underlined, and so is what you type at the prompt and
#     all output and prompts thereafter.
#     - So dash on macOS is a lot less usable, or at least more difficult
#       to read what's going on.
# - From `man dash`: PS1 defaults to “$ ”, except superuser to “# ”.
# - Note that dash does variable expansion in PS1, but it doesn't
#   support color or the special variables like \h or \W that Bash does.
#   - CXREF: ~/.homefries/lib/term/set-shell-prompt-and-window-title.sh
dash () {
  local PS1_orig="$PS1"

  # Note that HOSTNAME set in Bash, not in dash.
  #  : "${_HF_PS1_USER=$(id -un)}" "${_HF_PS1_HOSTNAME=$(uname -n)}"
  export _HF_PS1_USER="$(id -un)"
  export _HF_PS1_HOSTNAME="$(uname -n)"

  # Show fullpath:
  #  export PS1='$_HF_PS1_USER@$_HF_PS1_HOSTNAME($0):$PWD 💨 \$ '
  # Show shorter tilde'd path:
  export PS1='$_HF_PS1_USER@$_HF_PS1_HOSTNAME($0):$(echo "$PWD" | sed -E "s@^${HOME}(/|$)@~\1@") 💨 \$ '

  command dash "$@"

  export PS1="${PS1_orig}"

  unset -v _HF_PS1_USER
  unset -v _HF_PS1_HOSTNAME
}

sh () {
  # On Linux Mint, /bin/sh -> dash. On macOS, /bin/sh is Bash v3.
  # - Here we only care when sh is dash.
  test "$(realpath -- "$(type -P sh)")" = "$(realpath -- "$(type -P dash)")" \
    && dash "$@" \
    || command sh "$@"
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
  check_dep 'termdo-all' || return $?

  # 2021-02-20: This function is stale; I haven't used in a while
  # (not since I used to travel a lot with my laptop and wanted a
  #  CLI vector to locking and sleeping; and to the security issue
  #  with an attacker being able to see the screen briefly on wake,
  #  so being sure to show-desktop before sleeping).

  # Restrict from running on macOS or if /etc/lsb-release not found.
  _hf_lock_screensaver_source_lsb_release || return $?

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
  if false \
    || [ ${DISTRIB_CODENAME} = 'xenial' ] \
    || [ ${DISTRIB_CODENAME} = 'sarah' ] \
    || [ ${DISTRIB_CODENAME} = 'sonya' ] \
  ; then
    _homefries_screensaver_command --lock && \
      systemctl suspend -i
  elif false \
    || [ ${DISTRIB_CODENAME} = 'trusty' ] \
    || [ ${DISTRIB_CODENAME} = 'rebecca' ] \
  ; then
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

# ***

_hf_lock_screensaver_source_lsb_release () {
  # INERT/2021-02-20: We could support macOS, but I have no use case.
  # - We'd need the macOS equivalent of termdo, which is
  #   probably osascript, but I think we'd also need the
  #   API to Quartz Compositor:
  #     https://pypi.org/project/pyobjc-framework-Quartz/
  if [ ! -f "/etc/lsb-release" ]; then
    # E.g., os_is_macos.
    >&2 echo "Not a recognized OS (/etc/lsb-release not found)"
    return 1
  fi

  . /etc/lsb-release

  if [ "${DISTRIB_CODENAME}" != "rebecca" ]; then
    # Old Linux Mint... can't remember what it's missing; something.
    >&2 echo "This command not available on Linux Mint 'rebecca'"
    return 1
  fi
}

# ***

lock_screensaver_and_power_suspend_lite () {

  # Restrict from running on macOS or if /etc/lsb-release not found.
  _hf_lock_screensaver_source_lsb_release || return $?

  # Show desktop / Minimize all windows
  xdotool key ctrl+alt+d

  . /etc/lsb-release
  if false \
    || [ ${DISTRIB_CODENAME} = 'xenial' ] \
    || [ ${DISTRIB_CODENAME} = 'sarah' ] \
    || [ ${DISTRIB_CODENAME} = 'sonya' ] \
  ; then
    _homefries_screensaver_command --lock && \
      systemctl suspend -i
  elif false \
    || [ ${DISTRIB_CODENAME} = 'trusty'] \
    || [ ${DISTRIB_CODENAME} = 'rebecca' ] \
  ; then
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

home_fries_session_util_configure_aliases_ps () {
  claim_alias_or_warn "qq" "lock_screensaver_and_do_nothing_else"
  claim_alias_or_warn "qqq" "lock_screensaver_and_power_suspend"
  claim_alias_or_warn "q4" "lock_screensaver_and_power_suspend_lite"
}

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
  if [ $? -eq 0 ]; then
    cat /proc/acpi/wakeup | grep "^LID" | grep disabled &> /dev/null
    if [ $? -ne 0 ]; then
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
  # 2020-05-11: Booting openSUSE from VM, you'll see a reboot message, e.g.,:
  #     journalctl -r | grep -m 1 "\-- Reboot --"
  # but it's on its own line, so include life after (before, because -r) for context:
  #     journalctl -r | grep -m 1 "\-- Reboot --" -B 1
  # Just FYI. Not plumbing into this function.

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
  auth_log_grep_latest () {
    # Use `tac` ("cat" backwards) to "concatenate and print files in reverse".
    tac /var/log/auth.log | grep -m 1 "$2" | awk "{print \"$1 \"\$1\" \"\$2\" \"\$3\"\"}"
  }

  # E.g.,: 17350 Apr 30 23:44:11 host systemd-logind[1163]: Lid closed.
  auth_log_grep_latest "Lidclsd at" "systemd-logind\[[0-9]\+]: Lid closed\."
  # E.g.,: 17348 Apr 30 23:41:49 host systemd-logind[1163]: Lid opened.
  auth_log_grep_latest "Lidopnd at" "systemd-logind\[[0-9]\+]: Lid opened\."
  # E.g.,: 17349 Apr 30 23:41:56 lethe mate-screensaver-dialog: gkr-pam: unlocked login keyring
  # 2020-05-01: Note that I do not see a corresponding "locked" event.
  # - See some (too much work) solutions at:
  #   https://superuser.com/questions/662974/logging-lock-screen-events
  # - This is a screensave message, e.g.,
  #     mate-screensaver-dialog: gkr-pam: unlocked login keyring
  #   or
  #     gnome-screensaver-dialog: gkr-pam: unlocked login keyring
  auth_log_grep_latest "Unlockd at" "gkr-pam: unlocked login keyring"
}

# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #

# Test if Bash function exists.
# - 2022-11-04: Nothing calls this.
fn_exists () {
  type -t $1 > /dev/null
}

# home_fries_session_util_configure_aliases_fn () {
#   claim_alias_or_warn "function_exists" "fn_exists"
# }

# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #

# 2020-03-27: I added this to help ssh-agent-kick check the env file,
#               _321OPEN_SSH_ENV="${HOME}/.ssh/environment"
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
  # $ last -1 --fulltimes | head -1 | /usr/bin/env sed -E 's/ +/ /g' | cut -d' ' -f4-8
  # Fri Mar 27 17:25:50 2020
  local logontime
  logontime="$(last -1 --fulltimes | head -1 | /usr/bin/env sed -E 's/ +/ /g' | cut -d' ' -f4-8)"

  # See `man mktemp`: It defaults to TMPDIR or /tmp.
  local logontouch=$(mktemp --suffix "-HOMEFRIES_TOUCHYLOGON")
  touch -d "${logontime}" -- "${logontouch}"
  [ "${logontouch}" -ot "${cmpfile}" ] && touched_since=true
  command rm -- "${logontouch}"

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
    # Not a typo: Use Homefries' `uptime-s`, not Linux-only `uptime -s`.
    # ALTLY:
    #   touch -t "$(uptime-s +"%C%y%m%d%H%M.%S")" -- "${boottouch}"
    touch -d "$(uptime-s)" -- "${boottouch}"
    [ "${boottouch}" -ot "${touchfile}" ] && touched_since=true
    command rm -- "${boottouch}"
  fi
  ${touched_since}
}

# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #


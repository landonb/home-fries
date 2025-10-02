#!/usr/bin/env bash
# vim:tw=0:ts=2:sw=2:et:norl:ft=sh
# Author: Landon Bouma <https://tallybark.com/>
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

bash-exit-bash-hole() {
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

    exit 2>/dev/null
  elif ${parent_is_ibash}; then
    echo "exit, -b"

    exit 2>/dev/null
  elif ${parent_is_poetry}; then
    echo "exit, po"

    exit 2>/dev/null
  else
    echo "stay"
  fi
}

# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #

# USYNC: Not DRY: Copied from ~/.kit/git/git-smart/bin/git-brs.
#   grep-or-ggrep
_hf_grep_or_ggrep() {
  #   $ grep --version
  #   grep (BSD grep, GNU compatible) 2.6.0-FreeBSD
  #   # "GNU compatible" it's not.
  #   $ ggrep --version
  #   ggrep (GNU grep) 3.8
  if grep -q -e "GNU grep" <(grep --version | head -1); then
    echo "grep"
  elif command -v ggrep >/dev/null; then
    echo "ggrep"
  else
    >&2 echo "ERROR: GNU \`grep\` not found"
  fi
}

_HF_GREP="$(_hf_grep_or_ggrep)"

# E.g.,
#   18305 /home/user/.local/bin/bash
_hf_session_util_is_ppid_bash() {
  ps ax -o pid,command | ${_HF_GREP} -P "^ *${PPID} \S+/bash($| )" &>/dev/null
}

# E.g., login shell
#    9483 -bash
# Where the dash-bash means it was started as interactive session.
# And is what happens when you `bash` from within a `tmux` shell.
# - Though on macOS/iTerm2, /opt/homebrew/bin/bash is first shell's
#   parent process; and subshells are just `bash` (no dash).
_hf_session_util_is_ppid_ibash() {
  ps ax -o pid,command | ${_HF_GREP} -P "^ *${PPID} -?bash$" &>/dev/null
}

# E.g.,
#   23799 /home/user/.local/share/pypoetry/venv/bin/python /home/user/.local/bin/poetry shell
_hf_session_util_is_ppid_poetry_shell() {
  ps ax -o pid,command | ${_HF_GREP} -P "^ *${PPID} \S+/python3? \S+/poetry shell$" &>/dev/null
}

_hf_session_is_subshell() {
  false ||
    _hf_session_util_is_ppid_bash ||
    _hf_session_util_is_ppid_ibash ||
    _hf_session_util_is_ppid_poetry_shell
}

# ***

# `shexit` also comes to mind, but `be<TAB>` for the win.
# - Though beware macos Homebrew imagemagick `benchmark_xl`
#   conflicts, but you probably don't need that command and
#   can rename it.
home_fries_session_util_configure_aliases_bexit() {
  _hf_session_is_subshell ||
    return

  claim_alias_or_warn "bexit" "bash-exit-bash-hole"

  _hf_bexit_deconflict_imagemagick_benchmark_xl
}

# Homefries defines a `bexit` command so you can easily exit subshells
# but not the enclosing shell.
# - So that you can `be<TAB>` to auto-complete `bexit` (and not have to
#   type the longer `bex<TAB>`), remove the conflict from PATH search.
# - REFER: /opt/homebrew/bin/benchmark_xl ->
#     /opt/homebrew/Cellar/jpeg-xl/*/bin/benchmark_xl
_hf_bexit_deconflict_imagemagick_benchmark_xl() {
  EXECIGNORE="*/benchmark_xl:${EXECIGNORE}"
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
#   - CXREF: ~/.kit/sh/sh-humble-prompt/lib/set-shell-prompt-and-window-title.sh
dash() {
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

sh() {
  # On Linux Mint, /bin/sh -> dash. On macOS, /bin/sh is Bash v3.
  # - Here we only care when sh is dash.
  test "$(realpath -- "$(type -P sh)")" = "$(realpath -- "$(type -P dash)")" &&
    dash "$@" ||
    command sh "$@"
}

# ***

# Noisy startup.
home_fries_session_util_configure_aliases_sh() {
  claim_alias_or_warn "bbash" "_hf_homefries_bash_verbose"
}

_hf_homefries_bash_verbose() {
  HOMEFRIES_TRACE=${HOMEFRIES_TRACE:-true} \
    HOMEFRIES_PROFILING=${HOMEFRIES_PROFILING:-true} \
    HOMEFRIES_HELLO=${HOMEFRIES_HELLO:-true} \
    HOMEFRIES_LOADEDDOTS=${HOMEFRIES_LOADEDDOTS:-true} \
    bash
}

# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #

# CALSO: DepoXy wires accelerator that sets idle-delay to 1,
# then resets it, which causes screen to fade out and sleep,
# without locking. / CXREF: In a DepoXy environment, see:
#   ~/.depoxy/ambers/bin/gnome/toggle-idle-delay
# - This command locks the screen.

# MAYBE/2025-10-01: Move these desktop-specific funcs to DepoXy.

_hf_desktop_lock() {
  # CALSO: if [ "${XDG_CURRENT_DESKTOP}" = "GNOME" ]; then ...
  if command -v xdg-screensaver >/dev/null; then
    # ALTLY: Call dbus directly instead:
    #   dbus-send --type=method_call --dest=org.gnome.ScreenSaver \
    #     /org/gnome/ScreenSaver org.gnome.ScreenSaver.Lock
    # - THANX: https://askubuntu.com/questions/7776/
    #     how-do-i-lock-the-desktop-screen-via-command-line
    # CALSO: In DepoXy environment, <Ctrl-Cmd-Q> binding calls lock screen,
    #   via "GNOME Settings > Keyboard Shortcuts > System > Lock screen"
    # aka gsettings org.gnome.settings-daemon.plugins.media-keys screensaver.
    xdg-screensaver lock
  elif command -v mate-screensaver-command >/dev/null; then
    # On Linux Mint MATE.
    mate-screensaver-command --lock
  elif command -v gnome-screensaver-command >/dev/null; then
    # On <= GNOME 3.5.
    gnome-screensaver-command --lock
  else
    echo
    echo "ERROR: Unknown screensaver command (not GNOME or MATE?)"

    return false
  fi
}

# HSTRY: (Way back) Circa 2016-10-10, LM MATE (14.04/rebecca/trusty
# and 16.04/sarah/xenial), did not request the user password on
# resume from suspend. So I added a lock-and-suspend command that's
# not as relevant on Debian GNOME.

# CALSO: `systemctl hibernate`

_hf_desktop_suspend() {
  tmux_expire_sudo

  if command -v systemctl >/dev/null; then
    systemctl suspend
  else
    return false
  fi
}

# HSTRY: On MATE, would be painfully "secure", and send each
# open terminal a `sudo -K` command (via obsolete termdo-all).
# - This tmux loop is a remnant of that paranoia.
# - 2018-02-19: Tmux, Too!
#   - REFER: pane_id returns, e.g., %0, %1, %2; pane_index returns 1, 2, 3.
tmux_expire_sudo() {
  if ! command -v tmux >/dev/null; then

    return
  fi

  for _pane in $(
    tmux list-panes -a -F '#{pane_index}'
  ); do
    # Test echoes:

    #   echo "pane: ${_pane}"
    #   tmux send-keys -t ${_pane} "echo 'pane: ${_pane}'" Enter
    tmux send-keys -t ${_pane} "echo 'pane: ${_pane}'" Enter
    tmux send-keys -t ${_pane} "sudo -K" Enter
  done
}

# ***

home_fries_session_util_configure_aliases_ps() {
  claim_alias_or_warn "qq" "_hf_desktop_lock"
  claim_alias_or_warn "qqq" "_hf_desktop_suspend"
}

# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #

# ISOFF/2025-10-01: Not wired (but manually callable).
_hf_desktop_logout() {
  if command -v gnome-session-quit >/dev/null; then
    # Modern GNOME Shell.
    # REFER:
    #   --logout — Prompt the user to confirm logout (default).
    #   --force — Ignore any inhibitors.
    #   --power-off — Prompt the user to confirm system power off.
    gnome-session-quit --logout --no-prompt
  elif command -v mate-session-save >/dev/null; then
    mate-session-save --logout
  elif command -v gnome-session-save >/dev/null; then
    # GNOME circa 2011.
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
    echo "ERROR: Missing logout command (not GNOME or MATE?)"
  fi
}

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

# 2020-03-27: I added this to help ssh-agent-kick check the env file,
#               _321OPEN_SSH_ENV="${HOME}/.ssh/environment"
#             to see if it had been created since user logged on.
#             - Then I realized I didn't need to.
#               So I'm recording this function to have a copy of it,
#               but note that nothing calls it,
#               and my feelings won't be hurt if you remove it.
touched_since_logged_on_desktop() {
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

touched_since_up() {
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

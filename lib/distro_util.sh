#!/usr/bin/env bash
# vim:tw=0:ts=2:sw=2:et:norl:ft=sh
# Author: Landon Bouma (landonb &#x40; retrosoft &#x2E; com)
# Project: https://github.com/landonb/home-fries#🍟
# License: MIT

# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #

check_deps() {
  # Verify process_util.sh loaded.
  check_dep 'tweak_errexit'
}

check_dep() {
  if ! command -v "$1" >/dev/null 2>&1; then
    >&2 printf '\r%s\n' "GAFFE: Missing dependency (distro_util.sh): ‘$1’"

    false
  else
    true
  fi
}

# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #

# REFER: Ways to check OS, with example output:
#
#   $ cat /proc/version
#   Linux version ... (gcc-12 (Debian 12.2.0-14) ...
#
#   $ cat /etc/os-release
#   ...
#   ID=debian
#
#   $ hostnamectl
#   ...
#   Operating System: Debian GNU/Linux 12 (bookworm)
#
#   $ uname -o
#   GNU/Linux

# *** Ubuntu-related

distro_complain_unless_supported_by_homefries() {
  if [ -e /etc/os-release ]; then
    if cat /etc/os-release | grep -q "^ID=debian\$"; then
      # Debian
      : # no-op
    elif cat /etc/os-release | grep -q "^ID=linuxmint\$"; then
      # Linux Mint
      : # no-op
    elif cat /etc/os-release | grep -q "^ID=fedora\$"; then
      # Fedora
      : # noop
    elif ! ${HOMEFRIES_INHIBIT_OS_GRIPE:-false}; then
      local this_file
      this_file=$( (echo ${BASH_SOURCE[0]}) 2>/dev/null)
      test -n "${this_file}" || this_file=$(basename -- "$0")
      echo "ALERT: Unrecognized distro ‘$(cat /proc/version)’"
      echo "- Please disable this gripe, or update: ${this_file}"
    fi
  else
    # /etc/os-release does not exist.
    # - Might be macOS, etc.
    : # nop
  fi
}

# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #

# *** Window Manager Wat.

# NOTE: VirtualBox does not supply a graphics driver for Cinnamon 2.0,
#       which runs DRI2 (Direct Rendering Interface2). But Xfce runs
#       DRI1, which VirtualBox supports.
suss_window_manager() {
  _suss_window_manager() {
    suss_window_manager_reset

    if os_is_macos; then
      WM_IS_QUARTZ=true
    else
      if ! wmctrl -m >/dev/null 2>&1; then
        # Either `wmctrl` not installed, or might be connected via SSH.
        # - E.g., over SSH, `wmctrl -m` echoes "Cannot open display."
        WM_DETACHED=true
        # MAYBE/2020-05-11: Remove wmctrl greps below, and use command -v checks instead?
        suss_window_manager_via_command_v
      fi

      if ! ${WM_IS_UNKNOWN}; then
        suss_window_manager_via_wmctrl_m
      fi
    fi

    suss_window_manager_report

    suss_window_manager_response
  }

  suss_window_manager_reset() {
    WM_IS_CINNAMON=false
    WM_IS_GNOME=false
    WM_IS_KDE=false
    WM_IS_MATE=false
    WM_IS_XFCE=false
    WM_IS_QUARTZ=false
    WM_IS_UNKNOWN=false
    WM_DETACHED=false
    WM_TERMINAL_APP=''
  }

  suss_window_manager_report() {
    return

    echo "WM_IS_CINNAMON: $WM_IS_CINNAMON"
    echo "WM_IS_GNOME: $WM_IS_GNOME"
    echo "WM_IS_KDE: $WM_IS_KDE"
    echo "WM_IS_MATE: $WM_IS_MATE"
    echo "WM_IS_XFCE: $WM_IS_XFCE"
    echo "WM_IS_QUARTZ: $WM_IS_QUARTZ"
    echo "WM_IS_UNKNOWN: $WM_IS_UNKNOWN"
    echo "WM_DETACHED: $WM_DETACHED"
    echo "WM_TERMINAL_APP: $WM_TERMINAL_APP"
  }

  suss_window_manager_via_command_v() {
    if command -v mate-terminal >/dev/null 2>&1; then
      WM_IS_MATE=true
      WM_TERMINAL_APP='mate-terminal'
    elif command -v gnome-terminal >/dev/null 2>&1; then
      WM_IS_GNOME=true
      WM_TERMINAL_APP='gnome-terminal'
    elif command -v konsole >/dev/null 2>&1; then
      WM_IS_KDE=true
      WM_TERMINAL_APP='konsole'
    else
      WM_IS_UNKNOWN=true
    fi
  }

  suss_window_manager_via_wmctrl_m() {
    if wmctrl -m | grep -q -e "^Name: Mutter (Muffin)$"; then
      WM_IS_CINNAMON=true
      WM_TERMINAL_APP='gnome-terminal'
    elif wmctrl -m | grep -e "^Name: Xfwm4$"; then
      WM_IS_XFCE=true
      WM_TERMINAL_APP='WHO_CARES'
    elif wmctrl -m | grep -e "^Name: Metacity (Marco)$"; then
      # Linux Mint 17.1.
      WM_IS_MATE=true
      WM_TERMINAL_APP='mate-terminal'
    elif wmctrl -m | grep -e "^Name: Marco$"; then
      # Linux Mint 17.
      WM_IS_MATE=true
      WM_TERMINAL_APP='mate-terminal'
    elif wmctrl -m | grep -e "^Name: KWin$"; then
      # openSUSE, etc.
      WM_IS_KDE=true
      WM_TERMINAL_APP='konsole'
    else
      WM_IS_UNKNOWN=true
    fi
  }

  suss_window_manager_response() {
    if ! ${WM_IS_UNKNOWN}; then

      return 0
    fi

    echo
    echo "ERROR: Unknown Window manager."

    return 1
  }

  _suss_window_manager
}

# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #

# *** Screen saver on/off

screensaver_lockoff() {
  suss_window_manager

  if ${WM_IS_MATE}; then
    # Disable screen saver and lock-out.
    #  gsettings doesn't seem to stick 'til now.
    #?: sudo gsettings set org.mate.screensaver lock-enabled false
    # Or did it just require an apt-get update to finally work?
    gsettings set org.mate.screensaver idle-activation-enabled false
    gsettings set org.mate.screensaver lock-enabled false
    # 2018-03-01: Still not quite working... missing sleep-display-ac?
    #   gsettings list-recursively | grep sleep
    #   gsettings list-recursively | grep idle
    gsettings set org.mate.power-manager sleep-display-ac 0
    # 2018-03-02: Bah. Try 10-folding the idle-delay.
    # Huh: 2 hours is the max. So 130 gets floored to 120.
    gsettings set org.mate.session idle-delay 130
  elif ${WM_IS_CINNAMON}; then
    tweak_errexit +eEx
    gsettings set org.cinnamon.desktop.screensaver lock-enabled false \
      &>/dev/null
    reset_errexit
  else
    >&2 echo "That command is not plumbed for this window manager!"
    return 1
  fi

  return 0
}

screensaver_lockon() {
  suss_window_manager

  if ${WM_IS_MATE}; then
    gsettings set org.mate.screensaver idle-activation-enabled true
    gsettings set org.mate.screensaver lock-enabled true
    # 2018-03-01: 30 minutes, sleep display.
    gsettings set org.mate.power-manager sleep-display-ac 1800
  elif ${WM_IS_CINNAMON}; then
    tweak_errexit +eEx
    gsettings set org.cinnamon.desktop.screensaver lock-enabled true \
      &>/dev/null
    reset_errexit
  else
    >&2 echo "That command is not plumbed for this window manager!"

    return 1
  fi

  return 0
}

# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #

# *** Apache-related

# Determines the apache user name, and the /etc/ dir path.

# SAVVY/2025-01-14: Currently uncalled.
suss_apache() {
  if ! [ -e /etc/os-release ]; then
    >&2 echo "ERROR: Cannot suss Apache user or dir: Unsupported Homefries OS"

    return 1
  fi

  if cat /etc/os-release | grep -q "^ID=\(debian\|linuxmint\|ubuntu\)\$"; then
    # Debian, or Ubuntu.
    httpd_user=www-data
    httpd_etc_dir=/etc/apache2
  elif cat /etc/os-release | grep -q "^ID=\(fedora\|rhel\)\$"; then
    # Red Hat: Fedora, or RHEL.
    httpd_user=apache
    httpd_etc_dir=/etc/httpd
  fi
}

# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #

# *** Postgres-related

# Sets POSTGRESABBR to, e.g., '8.4' or '9.1'.
# - Also sets POSTGRES_MAJOR, POSTGRES_MINOR.
#
# DUNNO/2025-01-14: I don't remember how these environs are used
# (and it's been a while since I've used postgres...).
# - I don't see any usage across codebases other than these definitions.

suss_postgres() {
  tweak_errexit

  if command -v psql >/dev/null; then
    POSTGRESABBR=$(
      psql --version |
        grep psql |
        /usr/bin/env sed -E 's/psql \(PostgreSQL\) ([0-9]+\.[0-9]+)\.[0-9]+/\1/'
    )
    POSTGRES_MAJOR=$(
      psql --version |
        grep psql |
        /usr/bin/env sed -E 's/psql \(PostgreSQL\) ([0-9]+)\.[0-9]+\.[0-9]+/\1/'
    )
    POSTGRES_MINOR=$(
      psql --version |
        grep psql |
        /usr/bin/env sed -E 's/psql \(PostgreSQL\) [0-9]+\.([0-9]+)\.[0-9]+/\1/'
    )
  fi
  # else, psql not installed.

  reset_errexit
}

# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #

# Determine OS.
# - Homefries only cares macOS vs. Linux.
# - Here's a Windows-inclusive if-else block from
#   https://stackoverflow.com/questions/3466166/how-to-check-if-running-in-cygwin-mac-or-linux
#
#     if [ "$(uname)" = "Darwin" ]; then
#       # Do something under Mac OS X platform
#     elif [ "$(expr substr $(uname -s) 1 5)" = "Linux" ]; then
#       # Do something under GNU/Linux platform
#     elif [ "$(expr substr $(uname -s) 1 10)" = "MINGW32_NT" ]; then
#       # Do something under 32 bits Windows NT platform
#     elif [ "$(expr substr $(uname -s) 1 10)" = "MINGW64_NT" ]; then
#       # Do something under 64 bits Windows NT platform
#     fi
#
# SAVVY: Built-in macOS `expr` is BSD, not GNU, and prints:
#   expr: syntax error
# - If you used it, you'd want to prefer the GNU variant, e.g.:
#     gnu_expr () {
#       for cmd in "gexpr" "expr"; do
#         ( unset -f ${cmd}; unalias ${cmd}; command -v ${cmd} ) 2> /dev/null \
#           && break
#       done
#     }

os_is_macos() {
  [ "$(uname)" = "Darwin" ]
}

# On author's Linux Mint and Debian distros, `uname` and `uname -s`
# each print "Linux"
os_is_linux() {
  [ "$(uname)" = "Linux" ]
}

# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #

main() {
  unset -f main

  check_deps
  unset -f check_deps
}

main "$@"

#!/usr/bin/env bash
# vim:tw=0:ts=2:sw=2:et:norl:ft=sh
# Author: Landon Bouma (landonb &#x40; retrosoft &#x2E; com)
# Project: https://github.com/landonb/home-fries#🍟
# License: MIT

# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #

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
#   Linux version ... (x86_64-linux-gnu-gcc-14 (Debian 14.2.0-19) ...
#
#   $ cat /etc/os-release
#   ...
#   ID=debian
#
#   $ hostnamectl
#   ...
#   Operating System: Debian GNU/Linux 13 (trixie)
#
#   $ uname -o
#   GNU/Linux

# *** Ubuntu-related

distro_complain_unless_supported_by_homefries() {
  # I can't imagine that a distro (or even XDG_CURRENT_DESKTOP)
  # check is necessary.
  if true; then

    return
  fi

  # ***

  if os_is_macos; then
    # macOS
    return
  elif [ -e /etc/os-release ]; then
    # CALSO: ${XDG_CURRENT_DESKTOP} = "GNOME" | "MATE" | etc.
    if cat /etc/os-release | grep -q "^ID=debian\$"; then
      # Debian
      return
    elif cat /etc/os-release | grep -q "^ID=linuxmint\$"; then
      # Linux Mint
      return
    elif cat /etc/os-release | grep -q "^ID=fedora\$"; then
      # Fedora
      return
    fi
  fi

  >&2 echo "ALERT: Unrecognized distro: ‘$(cat /proc/version)’"
  >&2 echo "- Disable this gripe: HOMEFRIES_INHIBIT_OS_GRIPE=true"
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
# each print "Linux".
os_is_linux() {
  [ "$(uname)" = "Linux" ]
}

# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #

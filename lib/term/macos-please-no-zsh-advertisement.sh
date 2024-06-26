#!/usr/bin/env bash
# vim:tw=0:ts=2:sw=2:et:norl:ft=bash
# Author: Landon Bouma (landonb &#x40; retrosoft &#x2E; com)
# Project: https://github.com/landonb/home-fries#🍟
# License: MIT

# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #

check_deps () {
  # Verify distro_util.sh loaded.
  check_dep 'os_is_macos' || return $?
}

# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #

home_fries_macos_silence_bash_warning () {
  os_is_macos || return 0

  # 2020-08-25: Disable "The default interactive shell is now zsh" alert.
  export BASH_SILENCE_DEPRECATION_WARNING=1
}

# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #


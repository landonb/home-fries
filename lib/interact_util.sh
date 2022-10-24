#!/usr/bin/env bash
# vim:tw=0:ts=2:sw=2:et:norl:ft=sh
# Author: Landon Bouma (landonb &#x40; retrosoft &#x2E; com)
# Project: https://github.com/landonb/home-fries#🍟
# License: MIT

# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #

check_deps () {
  # Verify distro_util.sh loaded.
  check_dep 'os_is_macos'
}

# ============================================================================

# LOPRI/2022-10-23: This is broken on Linux Mint 19.3:
#   $ xcalib -invert -alter
#   Error - unsupported ramp size 0
# Not sure what's up, but also cannot remember last time I used this function.
# Oh, well, if was fun while it lasted.

define_flicker () {
  os_is_macos && return

  # Invert screen colors. Useful for alerting thyself from thine script.
  # SETUP: sudo apt-get install xcalib
  # SOURCE: https://github.com/OpenICC/xcalib
  # RELATED: https://github.com/zoltanp/xrandr-invert-colors
  flicker () {
    xcalib -invert -alter
    # NOTE: If you have multiple screens, you need to target them specially,
    #       e.g., to make both monitors flicker:
    #
    #         xcalib -i -a -s 0 && xcalib -i -a -s 1
  }

  alias invert='flicker'
}

# ============================================================================

main () {
  check_deps
  unset -f check_deps

  define_flicker
  unset -f define_flicker
}

main "$@"
unset -f main


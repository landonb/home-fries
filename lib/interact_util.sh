#!/usr/bin/env bash
# vim:tw=0:ts=2:sw=2:et:norl:ft=sh
# Author: Landon Bouma (landonb &#x40; retrosoft &#x2E; com)
# Project: https://github.com/landonb/home-fries#🍟
# License: MIT

# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #

check_deps () {
  :
}

# ============================================================================

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

# ============================================================================

main () {
  check_deps
  unset -f check_deps
}

main "$@"
unset -f main


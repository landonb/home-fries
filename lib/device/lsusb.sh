#!/usr/bin/env bash
# vim:tw=0:ts=2:sw=2:et:norl:ft=sh
# Author: Landon Bouma (landonb &#x40; retrosoft &#x2E; com)
# Project: https://github.com/landonb/home-fries#🍟
# License: MIT

# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #

# https://stackoverflow.com/questions/17058134/is-there-an-equivalent-of-lsusb-for-os-x

maybe_wire_lsusb () {
  os_is_macos || return 0

  lsusb-system_profiler () {
    system_profiler SPUSBDataType
  }
  # OR:
  lsusb-ioreg () {
    ioreg -p IOUSB -l -w 0
   }
  # OR: (I should've read the instructions completely before starting
  #      to answer, i.e., I didn't need to bother with this script...
  #      but at least I learned about `ioreg` and `system_profiler`).
  false && (
    brew install mikhailai/misc/usbutils
  )
}

# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #

main () {
  maybe_wire_lsusb
  unset -f maybe_wire_lsusb
}

main "$@"
unset -f main


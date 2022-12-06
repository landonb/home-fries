#!/usr/bin/env bash
# vim:tw=0:ts=2:sw=2:et:norl:ft=sh
# Author: Landon Bouma (landonb &#x40; retrosoft &#x2E; com)
# Project: https://github.com/landonb/home-fries#🍟
# License: MIT

# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #

# CXREF: https://stackoverflow.com/questions/32458095/
#          how-can-i-get-the-default-browser-name-in-bash-script-on-mac-os-x

# CXREF: This VIM plugin has much more robust logic:
#          https://github.com/landonb/dubs_web_hatch#🐣
#            ~/.vim/pack/landonb/start/dubs_web_hatch/bin/macOS-which-browser

default-browser () {
  os_is_macos || return 0

  # E.g., "com.google.chrome".
  plutil -p ~/Library/Preferences/com.apple.LaunchServices/com.apple.launchservices.secure.plist \
    | grep 'https' -b3 \
    | awk 'NR==3 {split($4, arr, "\""); print arr[2]}'
}

# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #

main () {
  :
}

main "$@"
unset -f main


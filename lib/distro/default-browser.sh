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
  if os_is_macos; then
    # E.g., "com.google.chrome".
    plutil -p ~/Library/Preferences/com.apple.LaunchServices/com.apple.launchservices.secure.plist \
      | grep 'https' -b3 \
      | awk 'NR==3 {split($4, arr, "\""); print arr[2]}'
  else
    # E.g., "/usr/bin/google-chrome"
    #  echo "${BROWSER}"
    # E.g., "google-chrome.desktop"
    xdg-settings get default-web-browser
  fi
}

# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #

source_deps () {
  # Load tweak_errexit.
  . "${HOMEFRIES_LIB:-${HOME}/.homefries/lib}/process_util.sh"
  # Load os_is_macos.
  . "${HOMEFRIES_LIB:-${HOME}/.homefries/lib}/distro_util.sh"
}

main () {
  source_deps
  default-browser "$@"
}

# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #

# Run the function if being executed.
# Otherwise being sourced, so do not.
if [ "$0" = "${BASH_SOURCE[0]}" ]; then
  main
fi

unset -f main
unset -f source_deps


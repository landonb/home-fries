#!/bin/bash

# File: quick_basics.sh
# Author: Landon Bouma (landonb &#x40; retrosoft &#x2E; com)
# Last Modified: 2017.10.03
# Project Page: https://github.com/landonb/home-fries
# License: GPLv3

set -e

# ==================================================================
# Copy-n-paste Convenience! Some commands to run on Very Fresh Mint.

# The basics: you might want to run this quick after first installing:
__just_the_basics__ () {
  gsettings set org.mate.caja.desktop computer-icon-visible false
  gsettings set org.mate.caja.desktop home-icon-visible false
  gsettings set org.mate.caja.desktop volumes-visible false
  gsettings set org.mate.screensaver idle-activation-enabled false
  gsettings set org.mate.screensaver lock-enabled false
}

__just_the_basics__

# Vim modeline:
# vim:tw=0:ts=2:sw=2:et:norl:


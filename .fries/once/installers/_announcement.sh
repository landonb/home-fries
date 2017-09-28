#!/bin/bash
#  vim:tw=0:ts=2:sw=2:et:norl:

# File: ~/.fries/once/installers/_announcement.sh
# Author: Landon Bouma (landonb &#x40; retrosoft &#x2E; com)
# Last Modified: 2017.09.28
# Project Page: https://github.com/landonb/home_fries
# Summary: Third-party tools downloads compiles installs.
# License: GPLv3

# *** Common environ/path checkers.

if [[ -z ${OPT_DLOADS+x} && ! -d /srv/opt/.downloads ]]; then
  echo "ERROR: Set \$OPT_DLOADS environ or mkdir /srv/opt/.downloads"
  exit 1
fi

if [[ -z ${OPT_BIN+x} && ! -d /srv/opt/bin ]]; then
  echo "ERROR: Set \$OPT_BIN environ or mkdir /srv/opt/bin"
  exit 1
fi

# *** Common installation routines.

stage_announcement () {
  echo
  echo "===================================================================="
  echo "$1"
  echo
  echo
  if ${PAUSE_BETWEEN_INSTALLS}; then
    echo " ####################################################"
    echo " ###################### PAUSED ######################"
    echo " ####################################################"
    echo -n " press any key to continue... "
    read -n 1 __ignored__
  fi
}

stage_curtains () {
  echo
  echo "Done: $1"
  echo "===================================================================="
}


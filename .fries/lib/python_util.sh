#!/bin/bash
# vim:tw=0:ts=2:sw=2:et:norl:

# File: python_util.sh
# Author: Landon Bouma (landonb &#x40; retrosoft &#x2E; com)
# Project Page: https://github.com/landonb/home-fries
# Summary: Generic Bash function library.
# License: GPLv3

# Usage: Source this script. Call its functions. Use its exports.

# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #

source_deps () {
  :
}

# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #

# LINUX OS FLAVOR SPECIFICS
###########################

# OS-Specific HTTPd User Shortcut and Default Python Version.

# SYNC_ME: See $cp/scripts/setupcp/runic/auto_install/check_parms.sh

whats_python3 () {
  # Determine the Python version-path.
  #PYTHON_VER=$(python --version 2>&1)
  # Convert, e.g., 'Python 3.4.0' to '3.4'.
  # Note the |&, which is like 2>&1, i.e., send stderr to stdout.
  # 2016-07-18: Ubuntu 16.04: Adds a plus sign!: Python 3.5.1+
  local PYVERS_RAW3=`python3 --version \
    |& /usr/bin/awk '{print $2}' \
    | /bin/sed -r 's/^([0-9]+\.[0-9]+)\.[0-9]+\+?/\1/g'`
  if [[ -n $PYVERS_RAW3 ]]; then
    export PYTHONVERS3=python${PYVERS_RAW3}
    export PYVERSABBR3=py${PYVERS_RAW3}
  else
    echo
    echo "######################################################################"
    echo
    echo "WARNING: Unexpected: Could not parse Python3 version."
    echo "python3 --version: `python3 --version`"
    python3 --version
    python3 --version |& /usr/bin/awk '{print $2}'
    python3 --version |& /usr/bin/awk '{print $2}' | /bin/sed -r 's/^([0-9]+\.[0-9]+)\.[0-9]+\+?/\1/g'
    echo
    echo "######################################################################"
    echo
    # If we exit, you cannot log on the terminal! Because /bin/bash exits...
    #exit 1
  fi
}

whats_python2 () {
  # Convert, e.g., 'Python 2.7.6' to '2.7'.
  # 2016-07-18: NOTE: Default on Mint 17: Python 2.7.6
  #              Default on Ubuntu 16.04: Python 2.7.12
  local PYVERS_RAW2=`python2 --version \
    |& /usr/bin/awk '{print $2}' \
    | /bin/sed -r 's/^([0-9]+\.[0-9]+)\.[0-9]+/\1/g'`
  local PYVERS_DOTLESS2=`python2 --version \
    |& /usr/bin/awk '{print $2}' \
    | /bin/sed -r 's/^([0-9]+)\.([0-9]+)\.[0-9]+/\1\2/g'`
  if [[ -z $PYVERS_RAW2 ]]; then
    echo
    echo "######################################################################"
    echo
    echo "WARNING: Unexpected: Could not parse Python2 version."
    echo
    echo "######################################################################"
    echo
    # If we exit, you cannot log on the terminal! Because /bin/bash exits...
    #exit 1
  fi
  PYVERS_RAW2=${PYVERS_RAW2}
  PYVERS_RAW2_m=${PYVERS_RAW2}m
  PYTHONVERS2_m=python${PYVERS_RAW2_m}
  PYVERS_CYTHON2=${PYVERS_DOTLESS2}m
  #
  export PYTHONVERS2=python${PYVERS_RAW2}
  export PYVERSABBR2=py${PYVERS_RAW2}
}

# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #

main () {
  : #source_deps
}

main "$@"


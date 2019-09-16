#!/bin/bash
# vim:tw=0:ts=2:sw=2:et:norl:

# File: cygwin_util.sh
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

# Cygwin section
################

# 2018-01-29: This fcn. is not called; has not been called in *YEARS*.
home_fries_create_aliases_cygwin () {
  alias c:='cd /cygdrive/c'
  alias d:='cd /cygdrive/d'
  alias e:='cd /cygdrive/e'
  alias f:='cd /cygdrive/f'
  alias g:='cd /cygdrive/g'
  alias h:='cd /cygdrive/h'
  alias i:='cd /cygdrive/i'
}

# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #

main () {
  : #source_deps
  unset -f source_deps
}

main "$@"


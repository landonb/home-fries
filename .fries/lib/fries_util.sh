#!/bin/bash
# Last Modified: 2017.10.03
# vim:tw=0:ts=2:sw=2:et:norl:

# File: fries_util.sh
# Author: Landon Bouma (landonb &#x40; retrosoft &#x2E; com)
# Project Page: https://github.com/landonb/home_fries
# Summary: Generic Bash function library.
# License: GPLv3

# Usage: Source this script. Call its functions. Use its exports.
# NOTE/2017-10-03: This particular script has no useful fcns, just environs.

source_deps() {
  local curdir=$(dirname -- "${BASH_SOURCE[0]}")
  source ${curdir}/process_util.sh
}

# ============================================================================
# *** Dubsacks-related

# -- Local resources, downloaded. Where they go.
default_opt_paths() {
  # We could download tarchives and whatnots to ~/Downloads but so many
  # applications use the home directory anyway, it's easier to keep
  # track of our files (what we'll deliberately setup) by using our own
  # location to store downloaded files and their compiled offsprings.
  # 2016-11-12: Also, keep things off the SSD (where home lives).
  OPT_DLOADS=/srv/opt/.downloads
  OPT_BIN=/srv/opt/bin
  OPT_SRC=/srv/opt/src
  OPT_DOCS=/srv/opt/docs
  # 2016-10-10: Google's NoTo zip is nearly 500 MB, so moving .fonts off home.
  OPT_FONTS=/srv/opt/.fonts
  # 2016-11-12: Keeping stuff off the SSD.
  OPT_LARGER=/srv/opt/LARGE
}

main() {
  source_deps

  must_sourced "${BASH_SOURCE[0]}"

  default_opt_paths
}

main "$@"


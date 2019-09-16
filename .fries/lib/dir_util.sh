#!/bin/bash
# vim:tw=0:ts=2:sw=2:et:norl:
# Project: https://github.com/landonb/home-fries
# License: GPLv3

# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #

source_deps () {
  :
}

# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #

# C.f. ${HOMEFRIES_DIR}/lib/bash_base.sh.
dir_resolve () {
  # Squash error messages but return error status, maybe.
  pushd "$1" &> /dev/null || return $?
  # -P returns the full, link-resolved path.
  local dir_resolved="`pwd -P`"
  popd &> /dev/null
  echo "$dir_resolved"
}

# symlink_dirname gets the dirname of
# a filepath after following symlinks;
# can be used in lieu of dir_resolve.
symlink_dirname () {
  echo $(dirname -- $(readlink -f -- "$1"))
}

# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #

# 2016-09-26: This is just a reminder of a good way to iterate over directories.
# I used to just change IFS, but this trick handles newlines and asterisks in paths,
# in addition to spaces in file/directory/path names.
#   http://unix.stackexchange.com/questions/9496/looping-through-files-with-spaces-in-the-names
printdirsincur () {
  find . -maxdepth 1 -type d ! -path . -print0 | while IFS= read -r -d '' file; do
    echo "file = $file"
  done
}
unset -f printdirsincur

printdirsincur_better () {
  # HA. HA. HA!
  # http://unix.stackexchange.com/questions/272698/why-is-the-array-empty-after-the-while-loop
  #
  # This one avoids an issue with the '|' pipe causing a subsheel to run.
  #
  # Which means an environment variable you set outside the while loop, such as
  # an array, will not be affected by whatever happens inside the while loop.
  # So use <() instead, which causes no subshell.
  while IFS= read -r -d '' file; do
    echo "file = $file"
  done < <(find . -maxdepth 1 -type d ! -path . -print0)
}
unset -f printdirsincur_better

# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #

main () {
  : #source_deps
  unset -f source_deps
}

main "$@"
unset -f main


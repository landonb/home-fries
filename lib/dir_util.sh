#!/bin/bash
# vim:tw=0:ts=2:sw=2:et:norl:ft=sh
# Author: Landon Bouma (landonb &#x40; retrosoft &#x2E; com)
# Project: https://github.com/landonb/home-fries#🍟
# License: MIT

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
  # This one avoids an issue with the '|' pipe causing a subshell to run.
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
  :
}

main "$@"
unset -f main


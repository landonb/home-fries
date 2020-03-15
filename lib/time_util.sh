#!/bin/bash
# vim:tw=0:ts=2:sw=2:et:norl:ft=sh
# Author: Landon Bouma (landonb &#x40; retrosoft &#x2E; com)
# Project: https://github.com/landonb/home-fries#🍟
# License: MIT

# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #

simpletimeit () {
  # Python has a great timeit fcn. you could use on a command, or
  # you could just do it in Bash. Except msg is not as friendly here.
  local time_0
  if [ -z ${simpletimeit_0+x} ]; then
    if [ -z $1 ]; then
      echo "Nothing took no time."
      return
    else
      time_0=$(date +%s.%N)
      $*
    fi
  else
    time_0=${simpletimeit_0}
  fi
  local time_1=$(date +%s.%N)
  local elapsed=`printf "%.2F" $(echo "($time_1 - $time_0) / 60.0" | bc -l)`
  echo
  echo "Your task took ${elapsed} mins."
}

# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #

main () {
  :
}

main "$@"
unset -f main


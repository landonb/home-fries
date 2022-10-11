#!/bin/sh
# vim:tw=0:ts=2:sw=2:et:norl:ft=bash
# Author: Landon Bouma (landonb &#x40; retrosoft &#x2E; com)
# Project: https://github.com/landonb/sh-print-nanos-now#⏱️
# License: MIT (See LICENSE file)

# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #

print_nanos_now () {
  if command -v gdate > /dev/null 2>&1; then
    # macOS (brew install coreutils).
    gdate +%s.%N
  elif date --version > /dev/null 2>&1; then
    # Linux/GNU.
    date +%s.%N
  elif command -v python > /dev/null 2>&1; then
    # macOS pre-coreutils.
    python -c 'import time; print("{:.9f}".format(time.time()))'
  else
    >&2 echo "ERROR: Could not locate an appropriate command."
    >&2 echo "- Hint: Trying installing \`date\`, \`gdate\`, or \`python\`."

    return 1
  fi
}

# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #
# ================================================================= #
# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #

this_file_name='print-nanos-now.sh'
shell_sourced () { [ "$(basename -- "$0")" != "${this_file_name}" ]; }
# Note that bash_sourced only meaningful if shell_sourced is true.
bash_sourced () { declare -p FUNCNAME > /dev/null 2>&1; }

if ! shell_sourced; then
  print_nanos_now "$@"
else
  bash_sourced && export -f print_nanos_now
  unset -v this_file_name
  unset -f shell_sourced
  unset -f bash_sourced
fi


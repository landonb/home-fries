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
    # Base macOS without coreutils... but you'd still need Python.
    python -c 'import time; print("{:.9f}".format(time.time()))'
  elif command -v perl > /dev/null 2>&1; then
    # 2023-01-26: I thought Python was standard on macOS, but if I
    # open a `/bin/bash --noprofile --norc` iTerm2 terminal, there's
    # no Python. But at least there's (fallback) Perl.
    # - Thank you for this Perl incantation, https://superuser.com/a/713000
    #   Via https://superuser.com/questions/599072/
    #         how-to-get-bash-execution-time-in-milliseconds-under-mac-os-x
    perl -MTime::HiRes -e 'printf("%.0f\n",Time::HiRes::time())'
  elif command -v bc > /dev/null 2>&1; then
    # 2023-01-26: Huh, is this the universal fallback? This works
    # on stock (BSD) macOS for me.
    # - I'm surprised I didn't suss this before, but perhaps I just
    #   didn't scratch hard enough, because it's not that `date +%s.%N`
    #   is not supported, it's just the `%N` part, i.e.,:
    #     bash-3.2$ /bin/date +%s.N
    #     1674796987.N
    bc -e "$(/bin/date +%s) * 1000"
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


#!/usr/bin/env bash
# vim:tw=0:ts=2:sw=2:et:norl:ft=sh
# Author: Landon Bouma (landonb &#x40; retrosoft &#x2E; com)
# Project: https://github.com/landonb/home-fries#🍟
# License: MIT

# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #

# ============================================================================
# *** Are we being run or sourced?

must_sourced () {
  if [ -z "$1" ]; then
    >&2 echo "must_sourced: missing param: \${BASH_SOURCE[0]}"

    exit 1
  fi

  if [ "$0" = "$1" ]; then
    # Not being sourced, but being run.
    >&2 echo "Why are you running this file?"

    exit 1
  fi
}

# ============================================================================
# *** Bash stack trace, of sorts.

# http://wiki.bash-hackers.org/commands/builtin/caller

where () {
  local frame=0

  while caller $frame; do
    # NOTE: In some cases, this call with end the program...
    ((frame++));
  done

  echo "$*"
}

die () {
  where

  exit 1
}

# ============================================================================
# *** errexit respect.

# Reset errexit to what it was . If we're not anticipating an error, make
# sure this script stops so that the developer can fix it.
#
# NOTE: You can determine the current setting from the shell using:
#
#        $ set -o | grep errexit | /usr/bin/env sed -E 's/^errexit\s+//'
#
#       which returns on or off.
#
#       However, from within this script, whether we set -e or set +e,
#       the set -o always returns the value from our terminal -- from
#       when we started the script -- and doesn't reflect any changes
#       herein. So use a variable to remember the setting.
#
reset_errexit_ () {
  if ${USING_ERREXIT}; then
    # set -ex
    set -e
  else
    # set +ex
    set +e
  fi
}

reset_errtrace_ () {
  if ${USING_ERRTRACE}; then
    set -E
  else
    set +E
  fi
}

reset_errexit_errtrace () {
  reset_errexit_
  reset_errtrace_
}

# MAYBE/2019-06-16: For backwards compatibility, since added errtrace
# (read: I don't want to find-and-replace all current usages).
reset_errexit () {
  reset_errexit_errtrace
}

suss_errexit_errtrace () {
  # Note that we cannot pipe ${SHELLOPTS} to grep, because Bash always unsets
  # errexit on pipeline commands (so test would always show errexit disabled).
  #  local shell_opts="${SHELLOPTS}"
  # 2023-02-10: Note that ${SHELLOPTS} unset for scripts; use $- instead.
  local shell_opts="$-"

  set +eE

  # echo "${shell_opts}" | grep errexit >/dev/null 2>&1
  echo "${shell_opts}" | grep "e" >/dev/null 2>&1
  if [ $? -eq 0 ]; then
    USING_ERREXIT=true
  else
    USING_ERREXIT=false
  fi

  # echo "${shell_opts}" | grep errtrace >/dev/null 2>&1
  echo "${shell_opts}" | grep "e" >/dev/null 2>&1
  if [ $? -eq 0 ]; then
    USING_ERRTRACE=true
  else
    USING_ERRTRACE=false
  fi

  if ${USING_ERREXIT}; then
	  set -e
  fi

  if ${USING_ERRTRACE}; then
	  set -E
  fi
}

tweak_errexit_errtrace () {
  local flags="${1:-+eE}"

  suss_errexit_errtrace

  set ${flags}
}

# MAYBE/2019-06-16: For backwards compatibility, since added errtrace
# (read: I don't want to find-and-replace all current usages).
tweak_errexit () {
  tweak_errexit_errtrace "$@"
}

# ============================================================================
# *** Llik gnihtemos.

# DUSTY/2021-08-18: I think `killsomething` is now useless,
#                   given that `pkill` does same, and more.
#
killsomething () {
  local something="$1"

  if [ -z "${something}" ]; then
    >&2 echo 'Not killing nothing!'

    return 1
  fi

  ${HOMEFRIES_TRACE} && echo "killsomething: ${something}"

  # The $2 is the awk way of saying, second column. I.e., ps aux shows
  #   apache 27635 0.0 0.1 238736 3168 ? S 12:51 0:00 /usr/sbin/httpd
  # and awk splits it on whitespace and sets $1..$11 to what was split.
  # You can even {print $99999} but it's just a newline for each match.
  # Here's the naive command:
  #   somethings=$(ps aux | grep "${something}" | awk '{print $2}')
  # But we want to exclude the pipeline grep process that also matches.
  local somethings=$(
    ps aux |
      grep "${something}" |
      grep -v "\<grep\>" |
      awk '{print $2}'
  )

  if [ -n "${somethings}" ]; then
    # Skip debug trace if called from another program.
    if $(printf %s "$0" | grep -q -E '(^-?|\/)(ba|da|fi|z)?sh$' -); then
      # Running from shell.
      ${HOMEFRIES_TRACE} && echo "$(ps aux | grep "${something}" | grep -v "\<grep\>")"
      ${HOMEFRIES_TRACE} && echo "Killing: ${somethings}"
    fi

    echo "${somethings}" | xargs sudo kill -s 9 >/dev/null 2>&1
  fi

  return 0
}

# ***

# On macOS, `pkill Chrome` leaves some windows open.
# - The author did not investigate further.

killall-chrome () {
  if os_is_macos; then
    ps aux \
      | grep -e "/Applications/Google Chrome.app" \
      | grep -v "grep .*\/Applications\/Google Chrome.app$" \
      | awk '{ print $2; }' \
      | xargs -n 1 kill -9
  else
    pkill chrome
  fi
}

# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #

main () {
  suss_errexit_errtrace
}

main "$@"
unset -f main


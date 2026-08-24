#!/usr/bin/env bash
# vim:tw=0:ts=2:sw=2:et:norl:ft=sh
# Author: Landon Bouma (landonb &#x40; retrosoft &#x2E; com)
# Project: https://github.com/landonb/home-fries#🍟
# License: MIT

# DEVEL: Uncomment for blather:
# DEBUG_TRACE=true

# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #

_hfldu_check_dep() {
  if ! command -v "$1" >/dev/null; then
    >&2 printf '\r%s\n' "WARNING: Missing dependency: '$1'"

    false
  else
    true
  fi
}

_hfldu_check_deps() {
  _hfldu_check_dep 'bc'
  _hfldu_check_dep 'grep'
  _hfldu_check_dep 'print_nanos_now'
}

# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #

# Tries to mkdir a directory that's being used as a process lock.

dirlock() {
  local FLOCKING_DIR_PATH="$1"
  local DONT_FLOCKIN_CARE=${2:-false}
  local FLOCKING_REQUIRED=${3:-false}
  # Use -1 to mean forever, 0 to mean never, or 1 to mean once, 2 twice, etc.
  local FLOCKING_RE_TRIES=${4:-0}
  # Use -1 to mean forever, 0 to ignore, or max. # of secs (int or float).
  local FLOCKING_TIME_OUT="${5:-0}"

  # 0: got lock / 1: timed out / 2: other error
  local got_lock=2

  if [ -z "${FLOCKING_DIR_PATH}" ]; then
    echo "ERROR: Missing dirlock dir path"

    return ${got_lock}
  fi

  local DEBUG_TRACE="${DEBUG_TRACE:-false}"

  local fcn_time_0
  fcn_time_0=$(print_nanos_now)

  $DEBUG_TRACE && >&2 echo "Attempting to acquire mutex: ${FLOCKING_DIR_PATH}"

  local resp
  if resp=$(mkdir -- "${FLOCKING_DIR_PATH}" 2>&1); then
    # We made the directory, meaning we got the mutex.
    $DEBUG_TRACE && >&2 echo "Mutex acquired tango foxtrot"

    got_lock=0
  elif ${DONT_FLOCKIN_CARE}; then
    # We were unable to make the directory, but the dev. wants us to go on.
    if [ $(printf "${resp}" | grep 'exists') ]; then
      # E.g., mkdir: cannot create directory `tmp': File exists
      $DEBUG_TRACE && >&2 echo "Mutex exists and owned but: DONT_FLOCKIN_CARE."

      got_lock=0
    elif [ $(printf "${resp}" | grep 'denied') ]; then
      # E.g., mkdir: cannot create directory `tmp': Permission denied
      $DEBUG_TRACE && >&2 echo "Mutex cannot be created but: DONT_FLOCKIN_CARE."

      got_lock=0
    else
      $DEBUG_TRACE && >&2 echo "ERROR: Unexpected response from mkdir: $resp."

      got_lock=2
    fi

    return ${got_lock}
  else
    # We could not get the mutex.
    #
    # We'll either: a) try again; b) give up; or c) fail miserably.
    #
    # E.g., mkdir: cannot create directory `tmp': Permission denied
    if [ $(printf "${resp}" | grep 'denied') ]; then
      # This is a developer problem. Fix perms. and try again.
      >&2 echo
      >&2 echo "=============================================="
      >&2 echo "GAFFE: The directory could not be created."
      >&2 echo "- Hey, you, DEV: This is probably _your_ fault."
      >&2 echo "  - Try:"
      >&2 echo "    chmod 2775 $(dirname -- "${FLOCKING_DIR_PATH}")"
      >&2 echo "=============================================="
      >&2 echo
    #
    # We expect that the directory already exists... though maybe the other
    # process deleted it already!
    #   elif [[ ! `echo $resp | grep exists` ]]; then
    #     $DEBUG_TRACE && >&2 echo "ERROR: Unexpected response from mkdir: $resp."
    #     $DEBUG_TRACE && >&2 echo ""
    #
    #     return ${got_lock}
    #   fi
    else
      # Like Ethernet, retry, but with a random backoff. This is because cron
      # might be running all of our scripts simultaneously, and they might each
      # be trying for the same locks to see what to do -- and it'd be a shame
      # if every time cron ran, the same script won the lock contest and all of
      # the other scripts immediately bailed, because then nothing would happen!
      #
      # NOTED: If your wait logic here could exceed the interval between crons,
      #        you could end up with always the same number of scripts running.
      #        E.g., consider one instance of a script running for an hour, but
      #        every minute you create a process that waits up to three minutes
      #        for the lock -- at minute 0 is the hour-long process, and minute
      #        1 is a process that tries for the lock until minute 4; at minute
      #        2 is a process that tries for the lock until minute 5; and so
      #        on, such that, starting at minute 4, you'll always have the
      #        hour-long process and three other scripts running (though not
      #        doing much, other than sleeping and waiting for the lock every
      #        once in a while).
      #
      local debug_traced_once=false
      while [ ${FLOCKING_RE_TRIES} -ne 0 ]; do
        if [ ${FLOCKING_RE_TRIES} -gt 0 ]; then
          FLOCKING_RE_TRIES=$((FLOCKING_RE_TRIES - 1))
        fi

        if ! ${debug_traced_once}; then
          $DEBUG_TRACE && >&2 echo \
            "Mutex in use: will retry at most ${FLOCKING_RE_TRIES} times " \
            "or for at most ${FLOCKING_TIME_OUT} secs."
          debug_traced_once=true
        fi

        local debug_trace_time_0
        debug_trace_time_0=$(print_nanos_now)

        # Pick a random number btw. 0.01 and 0.06.
        local RAND_10_to_60="0.0$((RANDOM % 51 + 10))"
        sleep "${RAND_10_to_60}"

        local fcn_time_1
        local elapsed_time
        fcn_time_1=$(print_nanos_now)
        elapsed_time=$(echo "${fcn_time_1} - ${fcn_time_0}" | bc -l)

        # Try again — See if it's our turn yet!
        if resp="$(mkdir -- "${FLOCKING_DIR_PATH}" 2>&1)"; then
          $DEBUG_TRACE && >&2 echo \
            "Got mutex: took: ${elapsed_time} secs." \
            "/ tries left: ${FLOCKING_RE_TRIES}."

          got_lock=0
          FLOCKING_RE_TRIES=0
        elif [ "${FLOCKING_TIME_OUT}" != "0" ]; then
          if [ $(echo "${elapsed_time} > ${FLOCKING_TIME_OUT}" | bc -l) -eq 1 ]; then
            $DEBUG_TRACE && >&2 echo "Could not get mutex: ${FLOCKING_DIR_PATH}."
            $DEBUG_TRACE && >&2 echo "Waited too long for mutex: ${elapsed_time}."

            got_lock=1
            FLOCKING_RE_TRIES=0
          else
            # There's still time left, but see if an echo is in order.
            local prev_debug_trace
            prev_debug_trace=$(echo "${fcn_time_1} - ${debug_trace_time_0}" | bc -l)
            # What's a good time here? Every ten minutes?
            if [ $(echo "${prev_debug_trace} > ${HUMBLE_TRACE_FREQ:-600}" | bc -l) -eq 1 ]; then
              local elapsed_mins
              elapsed_mins=$(echo "(${fcn_time_1} - ${fcn_time_0}) / 60.0" | bc -l)
              $DEBUG_TRACE && >&2 echo \
                "Update: Mutex still in use after: " \
                "${elapsed_mins} mins.; still trying..."
              debug_trace_time_0=$(print_nanos_now)
            fi
          fi
        # else, loop forever, maybe. ;)
        fi
      done
    fi
  fi

  if [ ${got_lock} -eq 0 ]; then
    chmod 2777 -- "${FLOCKING_DIR_PATH}" &>/dev/null
    # Let the world know who's the boss.
    local script_name
    local receipt_path
    script_name=$(basename -- "$0")
    receipt_path="${FLOCKING_DIR_PATH}--${script_name}"
    $DEBUG_TRACE && >&2 echo "Creating backref: ${FLOCKING_DIR_PATH}"
    mkdir -p -- "${receipt_path}"
  elif ${FLOCKING_REQUIRED}; then
    $DEBUG_TRACE && >&2 echo "Mutex in use: giving up!"
    $DEBUG_TRACE && >&2 echo "Could not secure flock dir: Bailing now."
    $DEBUG_TRACE && >&2 echo "FLOCKING_DIR_PATH: ${FLOCKING_DIR_PATH}"
  fi

  return ${got_lock}
}

dunlock() {
  local FLOCKING_DIR_PATH="$1"

  if [ -z "${FLOCKING_DIR_PATH}" ]; then
    echo "ERROR: Missing dirlock dir path"

    return 1
  fi

  local DEBUG_TRACE="${DEBUG_TRACE:-false}"

  local script_name
  local receipt_path
  script_name=$(basename -- "$0")
  receipt_path="${FLOCKING_DIR_PATH}--${script_name}"
  if ! rmdir -- "${receipt_path}" 2>/dev/null; then
    # Should be an unreachable path (under normal circumstances).
    $DEBUG_TRACE && >&2 echo "GAFFE: Lock release failed: ${receipt_path}"
  fi

  if ! rmdir -- "${FLOCKING_DIR_PATH}" 2>/dev/null; then
    # Should be an unreachable path (under normal circumstances).
    $DEBUG_TRACE && >&2 echo "GAFFE: Lock release failed: ${FLOCKING_DIR_PATH}"
  fi
}

# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #

# *** Main.

main() {
  unset -f main

  # ISOFF/2026-08-23: Skip this (on shell startup), for speed's sake:
  #   _hfldu_check_deps
  unset -f _hfldu_check_dep
  unset -f _hfldu_check_deps
}

main "$@"

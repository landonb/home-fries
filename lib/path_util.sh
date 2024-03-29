#!/usr/bin/env bash
# vim:tw=0:ts=2:sw=2:et:norl:ft=sh
# Author: Landon Bouma (landonb &#x40; retrosoft &#x2E; com)
# Project: https://github.com/landonb/home-fries#🍟
# License: MIT

# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #

check_dep () {
  if ! command -v $1 > /dev/null 2>&1; then
    >&2 printf '\r%s\n' "WARNING: Missing dependency: ‘$1’"
    false
  else
    true
  fi
}

check_deps () {
  # Verify logger.sh loaded (die, reset_errexit, tweak_errexit).
  check_dep '_sh_logger_log_msg'
  # Verify process_util.sh loaded (die, reset_errexit, tweak_errexit).
  check_dep 'reset_errexit'
}

# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #

# *** Path-related

dir_resolve () {
  # Squash error messages but return error status, maybe.
  pushd "$1" &> /dev/null || return $?
  # -P returns the full, link-resolved path.
  # EXPLAIN/2017-10-03: How is this different from $(realpath -- "$1") ??
  local dir_resolved=$(pwd -P)
  popd &> /dev/null
  echo "${dir_resolved}"
}

# symlink_dirname gets the dirname of
# a filepath after following symlinks;
# can be used in lieu of dir_resolve.
symlink_dirname () {
  echo "$(dirname -- "$(realpath -- "$1")")"
}

# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #

# *** Call ista Flock hart

# Tries to mkdir a directory that's being used as a process lock.

flock_dir () {
  local not_got_lock=1

  local FLOCKING_DIR_PATH=$1
  local DONT_FLOCKING_CARE=${2:-0}
  local FLOCKING_REQUIRED=${3:-0}
  # Use -1 to mean forever, 0 to mean never, or 1 to mean once, 2 twice, etc.
  local FLOCKING_RE_TRIES=${4:-0}
  # Use -1 to mean forever, 0 to ignore, or max. # of secs.
  local FLOCKING_TIMELIMIT=${5:-0}

  if [ -z "${FLOCKING_DIR_PATH}" ]; then
    echo "Missing flock dir path"
    exit 1
  fi

  tweak_errexit +eE # Stay on error

  local fcn_time_0=$(print_nanos_now)

  $DEBUG_TRACE && echo "Attempting grab on mutex: ${FLOCKING_DIR_PATH}"

  local resp=$(mkdir "${FLOCKING_DIR_PATH}" 2>&1)
  if [ $? -eq 0 ]; then
    # We made the directory, meaning we got the mutex.
    $DEBUG_TRACE && echo "Got mutex: yes, running script."
    $DEBUG_TRACE && echo
    not_got_lock=0
  elif [ ${DONT_FLOCKING_CARE} -eq 1 ]; then
    # We were unable to make the directory, but the dev. wants us to go on.
    #
    # E.g., mkdir: cannot create directory `tmp': File exists
    if [ $(printf "${resp}" | grep 'exists') ]; then
      $DEBUG_TRACE && echo "Mutex exists and owned but: DONT_FLOCKING_CARE."
      $DEBUG_TRACE && echo
    #
    # E.g., mkdir: cannot create directory `tmp': Permission denied
  elif [ $(printf "${resp}" | grep 'denied') ]; then
      $DEBUG_TRACE && echo "Mutex cannot be created but: DONT_FLOCKING_CARE."
      $DEBUG_TRACE && echo
    #
    else
      $DEBUG_TRACE && echo "ERROR: Unexpected response from mkdir: $resp."
      $DEBUG_TRACE && echo
      exit 1
    fi
  else
    # We could not get the mutex.
    #
    # We'll either: a) try again; b) give up; or c) fail miserably.
    #
    # E.g., mkdir: cannot create directory `tmp': Permission denied
    if [ $(printf "${resp}" | grep 'denied') ]; then
      # This is a developer problem. Fix perms. and try again.
      echo
      echo "=============================================="
      echo "ERROR: The directory could not be created."
      echo "Hey, you, DEV: This is probably _your_ fault."
      echo "Try: chmod 2777 $(dirname -- "${FLOCKING_DIR_PATH}")"
      echo "=============================================="
      echo
    #
    # We expect that the directory already exists... though maybe the other
    # process deleted it already!
    #   elif [[ ! `echo $resp | grep exists` ]]; then
    #     $DEBUG_TRACE && echo "ERROR: Unexpected response from mkdir: $resp."
    #     $DEBUG_TRACE && echo ""
    #     exit 1
    #   fi
    else
      # Like Ethernet, retry, but with a random backoff. This is because cron
      # might be running all of our scripts simultaneously, and they might each
      # be trying for the same locks to see what to do -- and it'd be a shame
      # if every time cron ran, the same script won the lock contest and all of
      # the other scripts immediately bailed, because then nothing would
      # happen!
      #
      # NOTE: If your wait logic here could exceed the interval between crons,
      #       you could end up with always the same number of scripts running.
      #       E.g., consider one instance of a script running for an hour, but
      #       every minute you create a process that waits up to three minutes
      #       for the lock -- at minute 0 is the hour-long process, and minute
      #       1 is a process that tries for the lock until minute 4; at minute
      #       2 is a process that tries for the lock until minute 5; and so
      #       on, such that, starting at minute 4, you'll always have the
      #       hour-long process and three other scripts running (though not
      #       doing much, other than sleeping and waiting for the lock every
      #       once in a while).
      #
      local spoken_once=false
      while [ ${FLOCKING_RE_TRIES} -ne 0 ]; do
        if [ ${FLOCKING_RE_TRIES} -gt 0 ]; then
          FLOCKING_RE_TRIES=$((FLOCKING_RE_TRIES - 1))
        fi
        # Pick a random number btw. 1 and 10.
        local RAND_0_to_10=$((($RANDOM % 10) + 1))
        #$DEBUG_TRACE && echo \
        #  "Mutex in use: will try again after: ${RAND_0_to_10} secs."
        if ! ${spoken_once}; then
          $DEBUG_TRACE && echo \
            "Mutex in use: will retry at most ${FLOCKING_RE_TRIES} times " \
            "or for at most ${FLOCKING_TIMELIMIT} secs."
          spoken_once=true
        fi
        local spoken_time_0=$(print_nanos_now)
        sleep ${RAND_0_to_10}
        # Try again.
        local resp="$(mkdir "${FLOCKING_DIR_PATH}" 2>&1)"
        local success=$?
        # Get the latest time.
        local fcn_time_1=$(print_nanos_now)
        local elapsed_time=$(echo "($fcn_time_1 - $fcn_time_0) / 1.0" | bc -l)
        # See if we made it.
        if [ ${success} -eq 0 ]; then
          $DEBUG_TRACE && echo \
            "Got mutex: took: ${elapsed_time} secs." \
            "/ tries left: ${FLOCKING_RE_TRIES}."
          $DEBUG_TRACE && echo
          not_got_lock=0
          FLOCKING_RE_TRIES=0
        elif [ ${FLOCKING_TIMELIMIT} -gt 0 ]; then
          # [lb] doesn't know how to compare floats in bash, so divide by 1
          #      to convert to int.
          if [[ $elapsed_time -gt ${FLOCKING_TIMELIMIT} ]]; then
            $DEBUG_TRACE && echo "Could not get mutex: ${FLOCKING_DIR_PATH}."
            $DEBUG_TRACE && echo "Waited too long for mutex: ${elapsed_time}."
            $DEBUG_TRACE && echo
            FLOCKING_RE_TRIES=0
          else
            # There's still time left, but see if an echo is in order.
            local last_spoken=$(echo "($fcn_time_1 - $spoken_time_0) / 1.0" | bc -l)
            # What's a good time here? Every ten minutes?
            if [ $last_spoken -gt 600 ]; then
              local elapsed_mins=$(echo "($fcn_time_1 - $fcn_time_0) / 60.0" | bc -l)
              $DEBUG_TRACE && echo \
                "Update: Mutex still in use after: "\
                "${elapsed_mins} mins.; still trying..."
              spoken_time_0=$(print_nanos_now)
            fi
          fi
        # else, loop forever, maybe. ;)
        fi
      done
    fi
  fi

  if [ ${not_got_lock} -eq 0 ]; then
    /bin/chmod 2777 "${FLOCKING_DIR_PATH}" &> /dev/null
    # Let the world know who's the boss
    local script_name=$(basename -- "$0")
    mkdir -p "${FLOCKING_DIR_PATH}-${script_name}"
  elif [ ${FLOCKING_REQUIRED} -ne 0 ]; then
    $DEBUG_TRACE && echo "Mutex in use: giving up!"

    $DEBUG_TRACE && echo "Could not secure flock dir: Bailing now."
    $DEBUG_TRACE && echo "FLOCKING_DIR_PATH: ${FLOCKING_DIR_PATH}"
    exit 1
  fi

  reset_errexit

  return $not_got_lock
}

# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #

# *** Make Directory Hierarchy, Possibly Using sudo.

# Verify or create a directory, possibly sudo'ing to do so.
ensure_directory_hierarchy_exists () {
  local DIR_PATH=$1
  local cur_path=${DIR_PATH}
  local last_dir=''
  tweak_errexit +eEx
  while [[ -n ${cur_path} && ! -e ${cur_path} ]]; do
    mkdir ${cur_path} &> /dev/null
    if [[ $? -eq 0 ]]; then
      # Success. We were able to create the directory.
      last_dir=''
    else
      # Failed. Either missing intermediate dirs, or access denied.
      # In either case, mkdir returns 1. As such, keep going up
      # hierarchy until rooting or until we can create a directory.
      last_dir=${cur_path}
      cur_path=$(dirname -- "${cur_path}")
    fi
  done
  reset_errexit
  if [[ -n ${last_dir} ]]; then
    # We're here if we found a parent to the desired
    # new directory but couldn't create a directory.
    echo
    echo "NOTICE: Need to sudo to make ${DIR_PATH}"
    echo
    sudo mkdir ${last_dir}
    sudo chmod 2775 ${last_dir}
    sudo chown $LOGNAME:$USE_STAFF_GROUP_ASSOCIATION ${last_dir}
  fi
  mkdir -p ${DIR_PATH}
  if [[ ! -d ${DIR_PATH} ]]; then
    echo
    echo "WARNING: Unable to procure download directory: ${DIR_PATH}"
    exit 1
  fi
}

# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #

# A note on errexit: If you call this fcn. (or a fcn. that calls this fcn.)
#   and if you use `&& true` or `|| true`, errexit will be disabled (though
#   you'll still see it in SHELLOPTS). Which means that a `cd` or `pushd` that
#   fails will not stop the function from proceeding.
# Consequently, we either need to check for error on pushd, so that we don't
#   call popd later when we didn't change directories in the first place; or
#   we need to store the current working directory and use cd instead of popd.

# FIXME/2020-03-19 02:10: Replace pushd usage with cd:
#  local before_cd="$(pwd -L)"
#  cd "${<>}"
#  ...
#  cd "${before_cd}"

pushd_or_die () {
  [ -z "$1" ] && return
  pushd "$1" &> /dev/null
  [ $? -ne 0 ] && error "No such path: $1" && error " working dir: $(pwd -P)" && die
  # Be sure to return a zero success value: If we left the `$? -ne 0`
  # as the last line, it'll trigger errexit!
  return 0
}

popd_perhaps () {
  [ -z "$1" ] && return
  popd &> /dev/null
  [ $? -ne 0 ] && error "Unexpected popd failure in: $(pwd -P)" && die
  return 0
}

# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #

# So that we don't step on toes of previously defined aliases.

pushd_alias_or_warn () {
  if ! pushd_alias "$@"; then
    >&2 echo "WARNING: Cannot alias: “$1” already assigned"

    return 1
  fi
}

pushd_alias () {
  if type "$1" > /dev/null 2>&1; then
    return 1
  fi

  eval "alias $1='pushd \"$2\" > /dev/null'"
}

# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #

# *** Main.

main () {
  check_deps
  unset -f check_deps
}

main "$@"
unset -f main


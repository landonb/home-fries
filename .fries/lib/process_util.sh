#!/bin/bash
# vim:tw=0:ts=2:sw=2:et:norl:

# File: process_util.sh
# Author: Landon Bouma (landonb &#x40; retrosoft &#x2E; com)
# Project Page: https://github.com/landonb/home-fries
# Summary: Generic Bash function library.
# License: GPLv3

# Usage: Source this script. Call its functions. Use its exports.

# ============================================================================
# *** Are we being run or sourced?

must_sourced() {
  [[ -z "$1" ]] && echo "must_sourced: missing param: \${BASH_SOURCE[0]}" && exit 1
  if [[ "$0" == "$1" ]]; then
    # Not being sourced, but being run.
    echo "Why are you running this file?"
    exit 1
  fi
}

# ============================================================================
# *** Bash stack trace, of sorts.

# http://wiki.bash-hackers.org/commands/builtin/caller

where () {
  local frame=0
  while caller $frame; do
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
#        $ set -o | grep errexit | /bin/sed -r 's/^errexit\s+//'
#
#       which returns on or off.
#
#       However, from within this script, whether we set -e or set +e,
#       the set -o always returns the value from our terminal -- from
#       when we started the script -- and doesn't reflect any changes
#       herein. So use a variable to remember the setting.
#
reset_errexit () {
  if ${USING_ERREXIT}; then
    #set -ex
    set -e
  else
    set +ex
  fi
}

suss_errexit () {
  local shell_opts=${SHELLOPTS}
  set +e
  echo ${shell_opts} | grep errexit >/dev/null 2>&1
  if [[ $? -eq 0 ]]; then
    USING_ERREXIT=true
  else
    USING_ERREXIT=false
  fi
  if ${USING_ERREXIT}; then
	  set -e
  fi
}

tweak_errexit () {
  local flags="${1:-+e}"
  suss_errexit
  set ${flags}
}

# ============================================================================
# *** Common script fcns.

check_prev_cmd_for_error () {
  if [[ -z "$1" || -z "$2" ]]; then
    echo "Usage: $0 last_status log_file [no_errexit] [ignr_case] [just_tail]"
    exit 1;
  fi
  PREV_CMD_VALUE=$1
  SAVED_LOG_FILE=$2
  DONT_EXIT_ON_ERROR=$3
  ERROR_IGNORE_CASE=$4
  JUST_TAIL_FILE=$5
  #
  if [[ -z $JUST_TAIL_FILE ]]; then
    JUST_TAIL_FILE=0
  fi
  #
  #$DEBUG_TRACE && echo "check_prev: ext code: ${PREV_CMD_VALUE}"
  #$DEBUG_TRACE && echo "check_prev: grep err: " `grep ERROR ${SAVED_LOG_FILE}`
  #
  # pyserver's logging2.py uses 4-char wide verbosity names, so ERROR is ERRR.
  # NOTE: We're usually case-sensitive. Real ERRORs should be capitalized.
  #       BUT: Sometimes you don't want to care.
  if [[ -z ${ERROR_IGNORE_CASE} || ${ERROR_IGNORE_CASE} -eq 0 ]]; then
    GREP_CMD="/bin/grep 'ERRO\?R'"
  else
    GREP_CMD="/bin/grep -i 'ERRO\?R'"
  fi
  if [[ -z ${JUST_TAIL_FILE} || ${JUST_TAIL_FILE} -eq 0 ]]; then
    FULL_CMD="${GREP_CMD} ${SAVED_LOG_FILE}"
  else
    FULL_CMD="tail -n ${JUST_TAIL_FILE} ${SAVED_LOG_FILE} | ${GREP_CMD}"
  fi
  # grep return 1 if there's no match, so make sure we don't exit
  set +e
  GREP_RESP=`eval $FULL_CMD`
  #set -e
  if [[ ${PREV_CMD_VALUE} -ne 0 || -n "${GREP_RESP}" ]]; then
    echo "Some script failed. Please examine the output in"
    echo "   ${SAVED_LOG_FILE}"
    # Also append the log file (otherwise error just goes to, e.g., email).
    echo "" >> ${SAVED_LOG_FILE}
    echo "ERROR: check_prev_cmd_for_error says we failed" >> ${SAVED_LOG_FILE}
    # (Maybe) stop everything we're doing.
    if [[ -z $DONT_EXIT_ON_ERROR || $DONT_EXIT_ON_ERROR -eq 0 ]]; then
      exit 1
    fi
  fi
}

exit_on_last_error () {
  LAST_ERROR=$1
  LAST_CMD_HINT=$2
  if [[ $LAST_ERROR -ne 0 ]]; then
    echo "ERROR: The last command failed: '$LAST_CMD_HINT'"
    exit 1
  fi
}

wait_bg_tasks () {
  WAITPIDS=$1
  WAITLOGS=$2
  WAITTAIL=$3

  $DEBUG_TRACE && echo "Checking for background tasks: WAITPIDS=${WAITPIDS[*]}"
  $DEBUG_TRACE && echo "                           ... WAITLOGS=${WAITLOGS[*]}"
  $DEBUG_TRACE && echo "                           ... WAITTAIL=${WAITTAIL[*]}"

  if [[ -n ${WAITPIDS} ]]; then
    time_1=$(date +%s.%N)
    $DEBUG_TRACE && printf "Waiting for background tasks after %.2F mins.\n" \
        $(echo "(${time_1} - ${script_time_0}) / 60.0" | bc -l)

    # MAYBE: It'd be nice to detect and report when individual processes
    #        finish. But wait doesn't have a timeout value.
    wait ${WAITPIDS[*]}
    # Note that $? is the exit status of the last process waited for.

    # The subprocesses might still be spewing to the terminal so hold off a
    # sec, otherwise the terminal prompt might get scrolled away after the
    # script exits if a child process output is still being output (and if that
    # happens, it might appear to the user that this script is still running
    # (or, more accurately, hung), since output is stopped but there's no
    # prompt (until you hit Enter and realize that script had exited and what
    # you're looking at is background process blather)).

    sleep 1

    $DEBUG_TRACE && echo "All background tasks complete!"
    $DEBUG_TRACE && echo ""

    time_2=$(date +%s.%N)
    $DEBUG_TRACE && printf "Waited for background tasks for %.2F mins.\n" \
        $(echo "(${time_2} - ${time_1}) / 60.0" | bc -l)
  fi

  # We kept a list of log files that the background processes to done wrote, so
  # we can analyze them now for failures.
  no_errexit=1
  if [[ -n ${WAITLOGS} ]]; then
    for logfile in ${WAITLOGS[*]}; do
      check_prev_cmd_for_error $? ${logfile} ${no_errexit}
    done
  fi

  if [[ -n ${WAITTAIL} ]]; then
    # Check the log_jammin.py log file, which might contain free-form
    # text from the SVN log (which contains the word "error").
    no_errexit=1
    ignr_case=1
    just_tail=25
    for logfile in ${WAITTAIL[*]}; do
      check_prev_cmd_for_error $? ${logfile} \
        ${no_errexit} ${ignr_case} ${just_tail}
    done
  fi
}

# ============================================================================
# *** Llik gnihtemos.

# SYNC_ME: See also fcn. of same name in bash_base.sh/bashrc_core.sh.
# EXPLAIN/FIXME: Why doesn't bash_core.sh just use what's in bash_base.sh
#                and share like a normal script?
killsomething () {
  local something=$1
  ${DUBS_TRACE} && echo "killsomething: $something"
  # The $2 is the awk way of saying, second column. I.e., ps aux shows
  #   apache 27635 0.0 0.1 238736 3168 ? S 12:51 0:00 /usr/sbin/httpd
  # and awk splits it on whitespace and sets $1..$11 to what was split.
  # You can even {print $99999} but it's just a newline for each match.
  #somethings=`ps aux | grep "${something}" | awk '{print $2}'`
  # Let's exclude the grep process that our grep is what is.
  local somethings=`ps aux | grep "${something}" | grep -v "\<grep\>" | awk '{print $2}'`
  # NOTE: The quotes in awk are loosely placed:
  #         similarly: `... | awk {'print $2'}`
  if [[ "$somethings" != "" ]]; then
    # FIXME: From command, line these two echos make sense; from another script, no.
    ${DUBS_TRACE} && echo $(ps aux | grep "${something}" | grep -v "\<grep\>")
    ${DUBS_TRACE} && echo "Killing: $somethings"
    echo $somethings | xargs sudo kill -s 9 >/dev/null 2>&1
  fi
  return 0
}

main() {
  suss_errexit
}

main "$@"


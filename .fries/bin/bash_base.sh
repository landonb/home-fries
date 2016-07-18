#!/bin/bash

# File: bash_base.sh
# Author: Landon Bouma (landonb &#x40; retrosoft &#x2E; com)
# Last Modified: 2016.07.18
# Project Page: https://github.com/landonb/home_fries
# Summary: Bash function library.
# License: GPLv3

# Usage: Call this script from another script.

# FIXME: Prepend 'local' keyword to function variables.

# ============================================================================
# *** Setup

# Make it easy to reference the script name and relative or absolute path.

# NOTE: The parent `source`d us, so $0 is _its_ name, usually.
#       If bash is being loaded via sudo, e.g., `sudo su - some_user`,
#       and if some bashrc sourced us, then $0 might be '-su' or '-bash'.

# Note: If sourced from a bash startup script, $0 might be '/bin/bash',
#       or, if you sudo'd, e.g., `sudo su - some_user`, then
#       $0 is '-su', i.e., ${0:0:1} = '-', so the bash startup scripts
#       should not include bash_bash.sh, or we should manually set/hardcode
#       the paths here. For now, assuming this script _not_ loaded from bashrc.
#HERE_WE_ARE=$(pwd -P)
if [[ ${0:0:1} != '-' ]]; then
  script_name=$(basename $0)
  script_relbase=$(dirname $0)
  #script_path=$(readlink -e -- "$0")
  # This method follows symlinks and is less verbose than dir_resolve.
  # Usually you'll want the readlink path and not the dir_resolve path,
  # so you can execute scripts better via symlinks if you need to use
  # a relative script path.
  SCRIPT_DIR=$(dirname $(readlink -f $0))
else
  # Being sourced. Just hardcode path. <cough> <cough> <hack!>
  # NOTE: This code path currently not exercised.
  # CORRECTION: 2016-05-05: I added sourcing this file to bashrc, so
  #             some fcns. can be shared, like determine_window_manager.
  #             This path should be fine... I think.
  #echo "UNEXPECTED: \$0: ${0}"
  script_name="bash_base.sh"
  script_relbase="/home/${USER}/.fries/bin"
  SCRIPT_DIR="/home/${USER}/.fries/bin"
fi

# When you run a Bash script, generally:
#  SCRIPT_PATH=$(dirname $0)
#  CALLED_FROM=$(pwd -P)
# where SCRIPT_PATH is relative to CALLED_FROM.
dir_resolve () {
  # Squash error messages but return error status, maybe.
  pushd "$1" &> /dev/null || return $?
  # -P returns the full, link-resolved path.
  dir_resolved="`pwd -P`"
  popd &> /dev/null
  echo "$dir_resolved"
}

script_path=$(dir_resolve $script_relbase)

# EXPLAIN: How is dir_resolve (script_path) better than, e.g.,
# 2016-05-05: What's up with this? This isn't how pwd works!
#             pwd ignores the param and just pwds the curdir.
#             Wrong:
#               script_absbase=`pwd $script_relbase`
pushd $script_relbase &> /dev/null
script_absbase=$(pwd -P)
popd &> /dev/null

if [[    "$script_path" != "$script_absbase"
      || "$script_path" != "$SCRIPT_DIR" ]]; then
  # You got some 'splain to do.
  echo "WARNING: Unexpected: not all equal:"
  echo "         script_path:     $script_path"
  echo "         script_relbase:  $script_relbase"
  echo "         script_absbase:  $script_absbase"
  echo "         SCRIPT_DIR:      $SCRIPT_DIR"
fi

# ============================================================================
# *** Chattiness

# If the user is running from a terminal (and not from cron), always be chatty.
# But don't change the debug trace flag if caller set it before calling us.
# NOTE -z is false if DEBUG_TRACE is true or false and true if it's unset.
if [[ -z $DEBUG_TRACE ]]; then
  if [[ "dumb" != "${TERM}" ]]; then
    DEBUG_TRACE=true
  else
    DEBUG_TRACE=false
  fi
fi

# Say hello to the user.

$DEBUG_TRACE && echo "Hello, ${LOGNAME}. (From: bash_base!)"
$DEBUG_TRACE && echo ""

# Time this script

script_time_0=$(date +%s.%N)

# ============================================================================
# *** Apache-related

# Determine the name of the apache user.
if [[ "`cat /proc/version | grep Ubuntu`" ]]; then
  # echo Ubuntu.
  httpd_user=www-data
  httpd_etc_dir=/etc/apache2
elif [[ "`cat /proc/version | grep Red\ Hat`" ]]; then
  # echo Red Hat.
  httpd_user=apache
  httpd_etc_dir=/etc/httpd
else
  echo "Error: Unknown OS."
  exit 1
fi;

# Reload the Web server.
ccp_apache_reload () {
  ${DUBS_TRACE} && echo "ccp_apache_reload"
  if [[ -z "$1" ]]; then
    COMMAND="reload"
  elif [[ $1 -ne 1 ]]; then
    COMMAND="reload"
  else
    COMMAND="restart"
  fi
  if [[ "`cat /proc/version | grep Ubuntu`" ]]; then
    # echo Ubuntu.
    sudo /etc/init.d/apache2 $COMMAND
  elif [[ "`cat /proc/version | grep Red\ Hat`" ]]; then
    # echo Red Hat.
    sudo service httpd $COMMAND
  else
    echo "Error: Unknown OS."
    exit 1
  fi;
}

# ============================================================================
# *** Python-related

# Determine the Python version-path.

# NOTE: The |& redirects the python output (which goes to stderr) to stdout.

# FIXME: Delete this and use the parsing version below.
#
## FIXME: Is this flexible enough? Probably...
## 2012.08.21: Ubuntu 8.04 does not support the |& redirection syntax?
#if [[ -n "`cat /etc/issue | grep '^Ubuntu 8.04'`" ]]; then
#  PYTHONVERS2=python2.5
#  PYVERSABBR2=py2.5
#elif [[ -n "`python --version |& grep 'Python 2.7'`" ]]; then
#  PYTHONVERS2=python2.7
#  PYVERSABBR2=py2.7
#elif [[ -n "`python --version |& grep 'Python 2.6'`" ]]; then
#  PYTHONVERS2=python2.6
#  PYVERSABBR2=py2.6
#else
#  echo 
#  echo "Unexpected Python version."
#  exit 1
#fi

# Here's another way:
#if [[ "`cat /proc/version | grep Ubuntu`" ]]; then
#  if [[ -n "`cat /etc/issue | grep '^Ubuntu 11.04'`" ]]; then
#    PYTHONVERS2=python2.7
#    PYVERSABBR2=py2.7
#  elif [[ -n "`cat /etc/issue | grep '^Ubuntu 10.04'`" ]]; then
#    PYTHONVERS2=python2.6
#    PYVERSABBR2=py2.6
#  else
#    echo "Warning: Unexpected host OS: Cannot set PYTHONPATH."
#  fi
#elif [[ "`cat /proc/version | grep Red\ Hat`" ]]; then
#  PYTHONVERS2=python2.7
#fi

# Convert, e.g., 'Python 2.7.6' to '2.7'.
PYVERS_RAW2=`python2 --version \
	|& /usr/bin/awk '{print $2}' \
	| /bin/sed -r 's/^([0-9]+\.[0-9]+)\.[0-9]+/\1/g'`
PYVERS2_DOTLESS=`python2 --version \
	|& /usr/bin/awk '{print $2}' \
	| /bin/sed -r 's/^([0-9]+)\.([0-9]+)\.[0-9]+/\1\2/g'`
if [[ -z $PYVERS_RAW2 ]]; then
  echo
  echo "######################################################################"
  echo
	echo "WARNING: Unexpected: Could not parse Python2 version."
  echo
  echo "######################################################################"
  echo
	exit 1
fi
PYVERS_RAW2=python${PYVERS_RAW2}
PYVERS_RAW2_m=python${PYVERS_RAW2}m
PYVERS_CYTHON2=${PYVERS2_DOTLESS}m
#
PYTHONVERS2=python${PYVERS_RAW2}
PYVERSABBR2=py${PYVERS_RAW2}

# ============================================================================
# *** Postgres-related

# Set this to, e.g., '8.4' or '9.1'.
#
# Note that if you alias sed, e.g., sed='sed -r', then you'll get an error if
# you source this script from the command line (e.g., it expands to sed -r -r).
# So use /bin/sed to avoid any alias.
if [[ `command -v psql` ]]; then
  POSTGRESABBR=$( \
    psql --version \
    | grep psql \
    | /bin/sed -r 's/psql \(PostgreSQL\) ([0-9]+\.[0-9]+)\.[0-9]+/\1/')
  POSTGRES_MAJOR=$( \
    psql --version \
    | grep psql \
    | /bin/sed -r 's/psql \(PostgreSQL\) ([0-9]+)\.[0-9]+\.[0-9]+/\1/')
  POSTGRES_MINOR=$( \
    psql --version \
    | grep psql \
    | /bin/sed -r 's/psql \(PostgreSQL\) [0-9]+\.([0-9]+)\.[0-9]+/\1/')
fi # else, psql not installed (yet).

# ============================================================================
# *** Ubuntu-related

# In the regex, \1 is the Fedora release, e.g., '14', and \2 is the friendly
# name, e.g., 'Laughlin'.
FEDORAVERSABBR=$(cat /etc/issue \
                 | grep Fedora \
                 | /bin/sed 's/^Fedora release ([0-9]+) \((.*)\)$/\1/')
# /etc/issue is, e.g., 'Ubuntu 12.04 LTS (precise) \n \l'
UBUNTUVERSABBR=$(cat /etc/issue \
                 | grep Ubuntu \
                 | /bin/sed -r 's/^Ubuntu ([.0-9]+) [^(]*\((.*)\).*$/\1/')
# /etc/issue is, e.g., 'Linux Mint 16 Petra \n \l'
MINTVERSABBR=$(cat /etc/issue \
               | grep "Linux Mint" \
               | /bin/sed -r 's/^Linux Mint ([.0-9]+) .*$/\1/')

# ============================================================================
# *** Common script fcns.

check_prev_cmd_for_error () {
  if [[ -z "$1" || -z "$2" ]]; then
    echo "Usage: $0 last_status log_file [no_errexit] [ignr_case] [just_tail]"
    exit 1;
  fi;
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
# *** errexit wrapper.

# Configure errexit usage. If we're not anticipating an error, make
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
  if $USING_ERREXIT; then
    #set -ex
    set -e
  else
    set +ex
  fi
}

shush_errexit () {
  # This FAILS is errexit is set because grep fails. So remember, then parse.
  #test_opts=`echo $SHELLOPTS | grep errexit` >/dev/null 2>&1
  test_opts=$(echo $SHELLOPTS)
  set +e
  `echo $test_opts | grep errexit` >/dev/null 2>&1
  if [[ $? -eq 0 ]]; then
    USING_ERREXIT=true
  else
    USING_ERREXIT=false
  fi
}

# ============================================================================
# *** Machine I.P. address

# There are lots of ways to get the machine's IP address:
#   $ ip addr show
# or, to filter,
#   $ ip addr show eth0
#   2: eth0: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc mq state UP ...
#       link/ether d4:ae:52:73:42:c4 brd ff:ff:ff:ff:ff:ff
#       inet 128.101.34.16/24 brd 128.101.34.255 scope global eth0
# You can also use nslookup:
#   $ nslookup runic
#   Server:   128.101.34.21
#   Address:  128.101.34.21#53
#   Name:     ccp.server.tld
#   Address:  123.456.78.90
# Or ifconfig, again filtering by device,
#   $ ifconfig eth0
#   eth0      Link encap:Ethernet  HWaddr d4:ae:52:73:42:c4  
#             inet addr:128.101.34.16  Bcast:128.101.34.255  Mask:255.255.255.0
#             ...
# But probably the easiest to parse is host:
#   $ host -t a ${CP_PRODNAME}
#   ${CS_PRODUCTION} has address 123.456.78.90

shush_errexit

# 2016.03.23: On a new machine install, young into the standup,
#             and not having editing /etc/hosts,
#             host -t a ${HOSTNAME} says:
#               Host ${HOSTNAME} not found: 3(NXDOMAIN)
# 2016.05.05: I don't remember writing that last comment, and it wasn't
#             that long ago. Anyway, $(host -t a ${HOSTNAME}) still saying
#             the same thing: not found.
MACHINE_IP=`host -t a ${HOSTNAME} | awk '{print $4}' | egrep ^[1-9]`
if [[ $? != 0 ]]; then
  MACHINE_IP=""
  ifconfig eth0 | grep "inet addr" &> /dev/null
  if [[ $? -eq 0 ]]; then
    IFCFG_DEV=`ifconfig eth0 2> /dev/null`
  else
    ifconfig wlan0 | grep "inet addr" &> /dev/null
    if [[ $? -eq 0 ]]; then
      IFCFG_DEV=`ifconfig wlan0 2> /dev/null`
    else
      # VirtualBox. I'm guessing.
      IFCFG_DEV=`ifconfig enp0s3 2> /dev/null`
    fi
  fi
  MACHINE_IP=`echo ${IFCFG_DEV} | grep "inet addr" \
              | sed "s/.*inet addr:([.0-9]+).*/\1/" \
              2> /dev/null`
  if [[ $? != 0 ]]; then
    MACHINE_IP=`echo ${IFCFG_DEV} | grep "inet addr" \
                | sed "s/.*inet addr:\([.0-9]\+\).*/\1/" \
                2> /dev/null`
  fi
fi
if [[ -z ${MACHINE_IP} ]]; then
  echo -e "\nWARNING: Could not determine the machine's IP address."
  # 2016.05.05: This path being followed on initial cli_gk12 go, but
  #             otherwise not just on /bin/bash... so what gives?
  echo -e "$ host -t a ${HOSTNAME}\n`host -t a ${HOSTNAME}`"
  echo -e "$ ifconfig eth0\n`ifconfig eth0`"
  echo -e "$ ifconfig wlan0\n`ifconfig wlan0`"
fi

reset_errexit

# ============================================================================
# *** Script timering

script_finished_print_time () {
  time_1=$(date +%s.%N)
  $DEBUG_TRACE && echo ""
  $DEBUG_TRACE && printf "All done: Elapsed: %.2F mins.\n" \
      $(echo "($time_1 - $script_time_0) / 60.0" | bc -l)
}

# ============================================================================
# *** Bash array contains

# Named after flashclient.utils.misc.Collection.array_in:
# and graciously c/x/p/d/ed from
#   http://stackoverflow.com/questions/3685970/bash-check-if-an-array-contains-a-value
# Usage: if `array_in "some key" "${some_array[@]}"`; then ... fi
array_in () {
  local elem
  for elem in "${@:2}"; do
    if [[ "$elem" == "$1" ]]; then
      return 0
    fi
  done
  # WATCH_OUT: If the calling script is using 'set -e' it's going to exit!
  # MAYBE: Can we call 'set +e' here, before returning? Or warn?
  return 1
}

alias elem_in_arr=array_in

# ============================================================================
# *** Bash array multidimensionalization

# In Bash, arrays are one-dimensional, though they allow multiple word entries.
# But when you pass an array as a function parameter, it gets flattened.
#
# Consider an array of names and ages. You cannot use =() when entries have
# multiple words. E.g., this is wrong,
#
#   people=("'chester a. arthur' 45" "'maurice moss' 26")
#
# because ${people[1][0]} => 'maurice moss' 26
#
# And you cannot set another list (multidimensionality); this doesn't work,
#
#   people[0]=("chester a. arthur" 45)
#
# But you can make a long, flat list.
#
#   people=("chester a. arthur" "45"
#           "maurice moss" "26")
#
# where ${people[2]} => maurice moss
# 
# So this fcn. wraps a flat list and treats it as a 2-dimensional array,
# using the elements in each sub-array as arguments to the function on
# which we're iterating.

arr2_fcn_iter () {
  the_fcn=$1
  cols_per_row=$2
  # This is a sneaky way to pass an array in Bash -- pass it's name.
  # The bang operator here resolves a name to a variable value.
  two_dim_arr=("${!3}")
  arr_total_rows=$((${#two_dim_arr[@]} / ${cols_per_row}))
  for arr_index in $(seq 0 $((${arr_total_rows} - 1))); do
    beg_index=$((${arr_index} * ${cols_per_row}))
    fin_index=$((${beg_index} + ${cols_per_row}))
    # This doesn't work:
    #   the_fcn ${two_dim_arr[*]:${beg_index}:${fin_index}}
    # because if you have spaces in any one param the fcn. will get
    # words around the spaces as multiple params.
    # WHATEVER: [lb] doesn't care anymore. Ignoring $cols_per_row
    #                                      and hard-coding))]}.
    if [[ ${cols_per_row} -lt 10 ]]; then
      ${the_fcn} "${two_dim_arr[$((${beg_index} + 0))]}" \
                 "${two_dim_arr[$((${beg_index} + 1))]}" \
                 "${two_dim_arr[$((${beg_index} + 2))]}" \
                 "${two_dim_arr[$((${beg_index} + 3))]}" \
                 "${two_dim_arr[$((${beg_index} + 4))]}" \
                 "${two_dim_arr[$((${beg_index} + 5))]}" \
                 "${two_dim_arr[$((${beg_index} + 6))]}" \
                 "${two_dim_arr[$((${beg_index} + 7))]}" \
                 "${two_dim_arr[$((${beg_index} + 8))]}" \
                 "${two_dim_arr[$((${beg_index} + 9))]}"
    else
      echo "Too many arguments for arr2_fcn_iter, sorry!" 1>&2
      exit 1
    fi
  done
}

# ============================================================================
# *** Llik gnihtemos.

# SYNC_ME: See also fcn. of same name in bash_base.sh/bashrc_core.sh.
# EXPLAIN/FIXME: Why doesn't bash_core.sh just use what's in bash_base.sh
#                and share like a normal script?
killsomething () {
  something=$1
  ${DUBS_TRACE} && echo "killsomething: $something"
  # The $2 is the awk way of saying, second column. I.e., ps aux shows
  #   apache 27635 0.0 0.1 238736 3168 ? S 12:51 0:00 /usr/sbin/httpd
  # and awk splits it on whitespace and sets $1..$11 to what was split.
  # You can even {print $99999} but it's just a newline for each match.
  #somethings=`ps aux | grep "${something}" | awk '{print $2}'`
  # Let's exclude the grep process that our grep is what is.
  somethings=`ps aux | grep "${something}" | grep -v "\<grep\>" | awk '{print $2}'`
  # NOTE: The quotes in awk are loosely placed: similarly: `... | awk {'print $2'}`
  if [[ "$somethings" != "" ]]; then
    # FIXME: From command, line these two echos make sense; from another script, no.
    #echo $(ps aux | grep "${something}" | grep -v "\<grep\>")
    #echo "Killing: $somethings"
    echo $somethings | xargs sudo kill -s 9 >/dev/null 2>&1
  fi
  return 0
}

# ============================================================================
# *** Call ista Flock hart

# Tries to mkdir a directory that's been used as a process lock.
#
# DEVS: This fcn. calls `set +e` but doesn't reset it ([lb] doesn't know how
# to find the current value of that option so we can restore it; oh well).

flock_dir () {

  not_got_lock=1

  FLOCKING_DIR_PATH=$1
  DONT_FLOCKING_CARE=$2
  FLOCKING_REQUIRED=$3
  FLOCKING_RE_TRIES=$4
  FLOCKING_TIMELIMIT=$5
  if [[ -z $FLOCKING_DIR_PATH ]]; then
    echo "Missing flock dir path"
    exit 1
  fi
  if [[ -z $DONT_FLOCKING_CARE ]]; then
    DONT_FLOCKING_CARE=0
  fi
  if [[ -z $FLOCKING_REQUIRED ]]; then
    FLOCKING_REQUIRED=0
  fi
  if [[ -z $FLOCKING_RE_TRIES ]]; then
    # Use -1 to mean forever, 0 to mean never, or 1 to mean once, 2 twice, etc.
    FLOCKING_RE_TRIES=0
  fi
  if [[ -z $FLOCKING_TIMELIMIT ]]; then
    # Use -1 to mean forever, 0 to ignore, or max. # of secs.
    FLOCKING_TIMELIMIT=0
  fi

  set +e # Stay on error

  fcn_time_0=$(date +%s.%N)

  $DEBUG_TRACE && echo "Attempting grab on mutex: ${FLOCKING_DIR_PATH}"

  resp=`/bin/mkdir "${FLOCKING_DIR_PATH}" 2>&1`
  if [[ $? -eq 0 ]]; then
    # We made the directory, meaning we got the mutex.
    $DEBUG_TRACE && echo "Got mutex: yes, running script."
    $DEBUG_TRACE && echo ""
    not_got_lock=0
  elif [[ ${DONT_FLOCKING_CARE} -eq 1 ]]; then
    # We were unable to make the directory, but the dev. wants us to go on.
    #
    # E.g., mkdir: cannot create directory `tmp': File exists
    if [[ `echo $resp | grep exists` ]]; then
      $DEBUG_TRACE && echo "Mutex exists and owned but: DONT_FLOCKING_CARE."
      $DEBUG_TRACE && echo ""
    #
    # E.g., mkdir: cannot create directory `tmp': Permission denied
    elif [[ `echo $resp | grep denied` ]]; then
      $DEBUG_TRACE && echo "Mutex cannot be created but: DONT_FLOCKING_CARE."
      $DEBUG_TRACE && echo ""
    #
    else
      $DEBUG_TRACE && echo "ERROR: Unexpected response from mkdir: $resp."
      $DEBUG_TRACE && echo ""
      exit 1
    fi
  else
    # We could not get the mutex.
    #
    # We'll either: a) try again; b) give up; or c) fail miserably.
    #
    # E.g., mkdir: cannot create directory `tmp': Permission denied
    if [[ `echo $resp | grep denied` ]]; then
      # This is a developer problem. Fix perms. and try again.
      echo ""
      echo "=============================================="
      echo "ERROR: The directory could not be created."
      echo "Hey, you, DEV: This is probably _your_ fault."
      echo "Try: chmod 2777 `dirname ${FLOCKING_DIR_PATH}`"
      echo "=============================================="
      echo ""
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
      spoken_once=false
      while [[ ${FLOCKING_RE_TRIES} -ne 0 ]]; do
        if [[ ${FLOCKING_RE_TRIES} -gt 0 ]]; then
          FLOCKING_RE_TRIES=$((FLOCKING_RE_TRIES - 1))
        fi
        # Pick a random number btw. 1 and 10.
        RAND_0_to_10=$((($RANDOM % 10) + 1))
        #$DEBUG_TRACE && echo \
        #  "Mutex in use: will try again after: ${RAND_0_to_10} secs."
        if ! ${spoken_once}; then
          $DEBUG_TRACE && echo \
            "Mutex in use: will retry at most ${FLOCKING_RE_TRIES} times " \
            "or for at most ${FLOCKING_TIMELIMIT} secs."
          spoken_once=true
          spoken_time_0=$(date +%s.%N)
        fi
        sleep ${RAND_0_to_10}
        # Try again.
        resp=`/bin/mkdir "${FLOCKING_DIR_PATH}" 2>&1`
        success=$?
        # Get the latest time.
        fcn_time_1=$(date +%s.%N)
        elapsed_time=$(echo "($fcn_time_1 - $fcn_time_0) / 1.0" | bc -l)
        # See if we made it.
        if [[ ${success} -eq 0 ]]; then
          $DEBUG_TRACE && echo "Got mutex: took: ${elapsed_time} secs." \
                                "/ tries left: ${FLOCKING_RE_TRIES}."
          $DEBUG_TRACE && echo ""
          not_got_lock=0
          FLOCKING_RE_TRIES=0
        elif [[ ${FLOCKING_TIMELIMIT} > 0 ]]; then
          # [lb] doesn't know how to compare floats in bash, so divide by 1
          #      to convert to int.
          if [[ $elapsed_time -gt ${FLOCKING_TIMELIMIT} ]]; then
            $DEBUG_TRACE && echo "Could not get mutex: ${FLOCKING_DIR_PATH}."
            $DEBUG_TRACE && echo "Waited too long for mutex: ${elapsed_time}."
            $DEBUG_TRACE && echo ""
            FLOCKING_RE_TRIES=0
          else
            # There's still time left, but see if an echo is in order.
            last_spoken=$(echo "($fcn_time_1 - $spoken_time_0) / 1.0" | bc -l)
            # What's a good time here? Every ten minutes?
            if [[ $last_spoken -gt 600 ]]; then
              elapsed_mins=$(echo "($fcn_time_1 - $fcn_time_0) / 60.0" | bc -l)
              $DEBUG_TRACE && echo "Update: Mutex still in use after: "\
                                   "${elapsed_mins} mins.; still trying..."
              spoken_time_0=$(date +%s.%N)
            fi
          fi
        # else, loop forever, maybe. ;)
        fi
      done
    fi
  fi

  if [[ ${not_got_lock} -eq 0 ]]; then
    /bin/chmod 2777 "${FLOCKING_DIR_PATH}" &> /dev/null
    # Let the world know who's the boss
    /bin/mkdir -p "${FLOCKING_DIR_PATH}-${script_name}"
  elif [[ ${FLOCKING_REQUIRED} -ne 0 ]]; then
    $DEBUG_TRACE && echo "Mutex in use: giving up!"
  
    $DEBUG_TRACE && echo "Could not secure flock dir: Bailing now."
    $DEBUG_TRACE && echo "FLOCKING_DIR_PATH: ${FLOCKING_DIR_PATH}"
    exit 1
  fi

  return $not_got_lock
}

# ============================================================================
# *** Logs Rot.

# This fcn. is not used. It was writ for logrotate but an alternative solution
# was implemented.
logrot_backup_file () {
  log_path=$1
  if [[ -f ${log_path} ]]; then
    log_name=$(basename $log_path)
    log_relbase=$(dirname $log_path)
    last_touch=${log_relbase}/archive-logcheck/${log_name}
    # Using the touch file wouldn't be necessary if logrotate's
    # postrotate worked with apache, but the server has to be
    # restarted, so we use lastaction, and at that point, we
    # don't know if the log file we're looking at has been backed
    # up or not. So we use a touch file to figure it out.
    if [[ ! -e ${last_touch} || ${log_path} -nt ${last_touch} ]]; then
      # Remember not to backup again.
      touch ${last_touch}
      # How to remove the file extension from the file name. Thanks to:
      # http://stackoverflow.com/questions/125281/how-do-i-remove-the-
      #        file-suffix-and-path-portion-from-a-path-string-in-bash
      # $ x="/foo/fizzbuzz.bar.quux"
      # $ y=${x%.*}
      # $ echo $y
      # /foo/fizzbuzz.bar
      # $ y=${x%%.*}
      # $ echo $y
      # /foo/fizzbuzz
      extless=${log_name%.*}
      today=`date '+%Y.%m.%d'`
      bkup=${log_relbase}/archive-logcheck/${extless}-${today}.gz
      # "-c --stdout Write output on std out; keep orig files unchanged"
      # "-9 --best indicates the slowest compression method (best comp.)"
      gzip -c -9 ${log_path} > ${bkup}
    fi
  fi
}

# ============================================================================
# *** Question Asker and Input Taker.

# Ask a yes/no question and take just one key press as answer
# (not waiting for user to press Enter), and complain if answer
# is not y or n (or one of some other two characters).
ask_yes_no_default () {

  # Don't exit on error, since `read` returns $? != 0 on timeout.
  set +e
  # Also -x prints commands that are run, which taints the output.
  set +x

  # Bash has nifty built-ins for capilizing and lower-casing strings,
  # names ${x^^} and ${x,,}
  local choice1_u=${1^^}
  local choice1_l=${1,,}
  local choice2_u=${3^^}
  local choice2_l=${3,,}
  # Use default second choice if yes-or-no question.
  if [[ -z $choice2_u ]]; then
    if [[ $choice1_u == 'Y' ]]; then
      choice2_u='N'
      choice2_l='n'
    elif [[ $choice1_u == 'N' ]]; then
      choice2_u='Y'
      choice2_l='y'
    else
      echo "ERROR: ask_yes_no_default: cannot infer second choice."
      exit 1
    fi
  fi
  # Make sure the choices are really just single-character strings.
  if [[ ${#choice1_u} -ne 1 || ${#choice2_u} -ne 1 ]]; then
    echo "ERROR: ask_yes_no_default: choices should be single letters."
    exit 1
  fi
  # Last check: uniqueness.
  if [[ ${choice1_u} == ${choice2_u} ]]; then
    echo "ERROR: ask_yes_no_default: choices should be unique."
    exit 1
  fi

  if [[ ${choice1_u} == 'Y' && ${choice2_u} == 'N' ]]; then
    local choices='[Y]/n'
  elif [[ ${choice1_u} == 'N' && ${choice2_u} == 'Y' ]]; then
    local choices='y/[N]'
  else
    local choices="[${choice1_u}]/${choice2_l}"
  fi

  if [[ -z $2 ]]; then
    # Default timeout: 15 seconds.
    local timeo=15
  else
    local timeo=$2
  fi

  # https://stackoverflow.com/questions/2388090/
  #   how-to-delete-and-replace-last-line-in-the-terminal-using-bash
  # $ seq 1 1000000 | while read i; do echo -en "\r$i"; done

  local valid_answers="${choice1_u}${choice1_l}${choice2_u}${choice2_l}"

  unset the_choice
  # Note: The while-pipe trick causes `read` to return immediately with junk.
  #  Nope: seq 1 5 | while read i; do
  local not_done=true
  while $not_done; do
    not_done=false
    for elaps in `seq 0 $((timeo - 1))`; do 
      echo -en \
        "[Default in $((timeo - elaps)) seconds...] Please answer $choices "
      read -n 1 -t 1 the_choice
      if [[ $? -eq 0 ]]; then
        # Thanks for the hint, stoverflove.
        # https://stackoverflow.com/questions/8063228/
        #   how-do-i-check-if-a-variable-exists-in-a-list-in-bash
        if [[ $valid_answers =~ $the_choice ]]; then
          # The user answered the call correctly.
          echo
          break
        else
          echo
          #echo "Please try answering with a Y/y/N/n answer!"
          echo "That's not the answer I was hoping for..."
          echo "Let's try this again, shall we?"
          sleep 1
          not_done=true
          break
        fi
      fi
      if [[ $elaps -lt $((timeo - 1)) ]]; then
        # Return to the start of the line.
        echo -en "\r"
      fi
    done
  done

  if [[ -z $the_choice ]]; then
    the_choice=${choice1_u}
    #echo $1'!'
  fi

  # Uppercase the return character. Which we return in a variable.
  the_choice=${the_choice^^}

  reset_errexit

} # end: ask_yes_no_default

# Test:
#  ask_yes_no_default 'Y'
#  echo $the_choice

# ============================================================================
# *** Window Manager Wat.

# NOTE: VirtualBox does not supply a graphics driver for Cinnamon 2.0, 
#       which runs DRI2 (Direct Rendering Interface2). But Xfce runs
#       DRI1, which VirtualBox supports.
determine_window_manager () {
  WM_IS_CINNAMON=false
  WM_IS_XFCE=false
  WM_IS_MATE=false # Pronouced, mah-tay!
  WM_IS_UNKNOWN=false

  shush_errexit
  WIN_MGR_INFO=`wmctrl -m >/dev/null 2>&1`
  if [[ $? -ne 0 ]]; then
    # E.g., if you're ssh'ed into a server, returns 1 and "Cannot open display."
    WM_IS_UNKNOWN=true
  fi
  reset_errexit

  if ! ${WM_IS_UNKNOWN}; then
    if [[ `wmctrl -m | grep -e "^Name: Mutter (Muffin)$"` ]]; then
      WM_IS_CINNAMON=true
      WM_TERMINAL_APP='gnome-terminal'
    elif [[ `wmctrl -m | grep -e "^Name: Xfwm4$"` ]]; then
      WM_IS_XFCE=true
      WM_TERMINAL_APP='WHO_CARES'
    elif [[ `wmctrl -m | grep -e "^Name: Metacity (Marco)$"` ]]; then
      # Linux Mint 17.1.
      WM_IS_MATE=true
      WM_TERMINAL_APP='mate-terminal'
    elif [[ `wmctrl -m | grep -e "^Name: Marco$"` ]]; then
      # Linux Mint 17.
      WM_IS_MATE=true
      WM_TERMINAL_APP='mate-terminal'
    else
      WM_IS_UNKNOWN=true
      echo
      echo "ERROR: Unknown Window manager."
      exit 1
    fi
  fi
  #echo "WM_IS_CINNAMON: $WM_IS_CINNAMON"
  #echo "WM_IS_XFCE: $WM_IS_XFCE"
  #echo "WM_IS_MATE: $WM_IS_MATE"
  #echo "WM_IS_UNKNOWN: $WM_IS_UNKNOWN"
  #echo "WM_TERMINAL_APP: $WM_TERMINAL_APP"
}

# ============================================================================
# *** Make Directory Hierarchy, Possibly Using sudo.

# Verify or create a directory, possibly sudo'ing to do so.
ensure_directory_hierarchy_exists () {
  local DIR_PATH=$1
  local cur_path=${DIR_PATH}
  local last_dir=''
  set +ex
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
      cur_path=$(dirname ${cur_path})
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
    sudo chown $USER:$USE_STAFF_GROUP_ASSOCIATION ${last_dir}
  fi
  mkdir -p ${DIR_PATH}
  if [[ ! -d ${DIR_PATH} ]]; then
    echo
    echo "WARNING: Unable to procure download directory: ${DIR_PATH}"
    exit 1
  fi
}

# ============================================================================
# *** End of bashy goodness.


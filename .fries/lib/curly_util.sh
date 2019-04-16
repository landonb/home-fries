# File: curly_util.sh
# Author: Landon Bouma (landonb &#x40; retrosoft &#x2E; com)
# Last Modified: 2017.10.03
# Project Page: https://github.com/landonb/home-fries
# Summary: Dumping ground for unused Bash functions, apparently.
#          2016-10-24: I'll throw a useful fcn herein, passtore-ci
# License: GPLv3
# vim:tw=0:ts=2:sw=2:et:norl:

# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #

source_deps () {
  local curdir=$(dirname -- "${BASH_SOURCE[0]}")
  source ${curdir}/logger.sh
}

# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #

setup_users_curly_path () {
  source_deps

  if [[ -f ${HOME}/.curly/master_chef || -f ${HOME}/.curly/junior_chef ]]; then
    # You can cd and pwd -P or just readlink.
    #  pushd ${HOME}/.curly &> /dev/null
    #  USERS_CURLY=$(pwd -P)
    #  popd &> /dev/null
    USERS_CURLY=$(readlink -f -- "${HOME}/.curly")
  else
    local CANDIDATES=()
    if [[ -z ${USERS_CURLY} ]]; then

      # First try to find it under ~/.
      while IFS= read -r -d '' file; do
        #echo "Checking candidate at: $file"
        # Check if this dir contains the working private dotfiles...
        if [[ -e ${file}/master_chef ]]; then
          #echo "found: ${file}/master_chef"
          # for the main development machine;
          CANDIDATES+=("${file}")
        elif [[ -e ${file}/junior_chef ]]; then
          #echo "found: ${file}/junior_chef"
          # or for a satellite machine.
          CANDIDATES+=("${file}")
        fi
      # HA. HA. HA!
      # http://unix.stackexchange.com/questions/272698/why-is-the-array-empty-after-the-while-loop
      done < <(find ${HOME} -maxdepth 1 -type d ! -path . -name '.*' -print0)

      #echo "No. candidates found: ${#CANDIDATES[@]}"
      if [[ ${#CANDIDATES[@]} -gt 1 ]]; then
        echo "WARNING: More than one candidate found."
        for ((i = 0; i < ${#CANDIDATES[@]}; i++)); do
          CANDIDATE="${CANDIDATES[$i]}"
          echo "CANDIDATE: ${CANDIDATE}"
        done
        echo
        CANDIDATES=()
      elif [[ ${#CANDIDATES[@]} -lt 1 ]]; then
        echo "Welcome to curly!"
        echo
        echo "Please specify where to make your private dotfiles repository."
        #echo
        echo -n "Path to destination [~/.curly]: "
        read -e USERS_CURLY
        #echo
        if [[ -z ${USERS_CURLY} ]]; then
          USERS_CURLY=${HOME}/.curly
        fi
      else
        USERS_CURLY=${CANDIDATES[0]}
      fi
    fi
  fi

  if [[ -z ${USERS_CURLY} ]]; then
    echo "FATAL: Destination path not indicated."
    exit 1
  fi
  if [[ ! -d ${USERS_CURLY} ]]; then
    if [[ -e ${USERS_CURLY} ]]; then
      echo "FATAL: Destination path exists but is not a directory."
      exit 1
    fi
    echo "NOTICE: Destination path does not exist. Attempting to make it at: ${USERS_CURLY}"
    /bin/mkdir ${USERS_CURLY}
    # We `set -e` above, so if we're here, it worked.
  fi
  USERS_BNAME=$(basename -- "${USERS_CURLY}")
  #echo
  info "So-called Curly found at: ${FG_LAVENDER}${USERS_CURLY}"
} # end: setup_users_curly_path

# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #

ensure_dropbox_running () {
  #dropbox.py status | grep "Dropbox isn't running" &> /dev/null
  #if [[ $? -eq 0 ]]; then
  dropbox.py status | grep "Up to date" &> /dev/null
  if [[ $? -ne 0 ]]; then
    echo -n "Starting Dropbox... "
    # statuses:
    #   "Dropbox isn't running!"
    #   "Connecting..."
    #   "Downloading file list..."
    #   "Up to date"
    dropbox.py start &> /dev/null
    NOT_STARTED=true
    NUM_LOOKSIES=0
    while $NOT_STARTED; do
      dropbox.py status | grep "Up to date" &> /dev/null
      if [[ $? -eq 0 ]]; then
        echo "started."
        NOT_STARTED=false
      else
        NUM_LOOKSIES=$(($NUM_LOOKSIES+1))
        if [[ $NUM_LOOKSIES -gt 15 ]]; then
          echo
          echo
          echo "WARNING: Waited too long for Dropbox to start."
          echo
          # Just move along.
          NOT_STARTED=false
        fi
        sleep 0.3
      fi
    done
  fi
} # end: ensure_dropbox_running

# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #

passtore-ci () {
  pushd ${HOME}/.password-store &> /dev/null
  git push origin master
  popd &> /dev/null
  # And then pull into mobile pass repo [Android Password Store app].
} # end: passtore-ci

# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #


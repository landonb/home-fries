# File: util.sh
# Author: Landon Bouma (landonb &#x40; retrosoft &#x2E; com)
# Last Modified: 2016.10.09
# Project Page: https://github.com/landonb/home-fries
# Summary: Dumping ground for unused Bash functions, apparently.
# License: GPLv3
# vim:tw=0:ts=2:sw=2:et:norl:

# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #

setup_users_curly_path () {
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
      echo -n "Path to destination [~/.mydots]: "
      read -e USERS_CURLY
      #echo
      if [[ -z ${USERS_CURLY} ]]; then
        USERS_CURLY=${HOME}/.mydots
      fi
    else
      USERS_CURLY=${CANDIDATES[0]}
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
  USERS_BNAME=$(basename ${USERS_CURLY})
  #echo
  echo "Using curly destination at: ${USERS_CURLY}"
} # end: setup_users_curly_path

# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #

# From: https://github.com/ginatrapani/todo.txt-cli/wiki/Tips-and-Tricks
# See also hex-to-xterm converter: http://www.frexx.de/xterm-256-notes/

if false; then
  export PINK='\\033[38;5;211m'
  export ORANGE='\\033[38;5;203m'
  export SKYBLUE='\\033[38;5;111m'
  export MEDIUMGREY='\\033[38;5;246m'
  export LAVENDER='\\033[38;5;183m'
  export TAN='\\033[38;5;179m'
  export FOREST='\\033[38;5;22m'
  export MAROON='\\033[38;5;52m'
  export HOTPINK='\\033[38;5;198m'
  export MINTGREEN='\\033[38;5;121m'
  export LIGHTORANGE='\\033[38;5;215m'
  export LIGHTRED='\\033[38;5;203m'
  export JADE='\\033[38;5;35m'
  export LIME='\\033[38;5;154m'
  #
  export PINK_BG='\\033[48;5;211m'
  export ORANGE_BG='\\033[48;5;203m'
  export SKYBLUE_BG='\\033[48;5;111m'
  export MEDIUMGREY_BG='\\033[48;5;246m'
  export LAVENDER_BG='\\033[48;5;183m'
  export TAN_BG='\\033[48;5;179m'
  export FOREST_BG='\\033[48;5;22m'
  export MAROON_BG='\\033[48;5;52m'
  export HOTPINK_BG='\\033[48;5;198m'
  export MINTGREEN_BG='\\033[48;5;121m'
  export LIGHTORANGE_BG='\\033[48;5;215m'
  export LIGHTRED_BG='\\033[48;5;203m'
  export JADE_BG='\\033[48;5;35m'
  export LIME_BG='\\033[48;5;154m'
  #
  export UNDERLINE='\\033[4m'
else
  ### === HIGH-COLOR === compatible with most terms including putty
  ### for windows... use colors that don't make your eyes bleed :)
  export PINK="\033[38;5;211m"
  export ORANGE="\033[38;5;203m"
  # 2016-10-09: SKYBLUE broken.
  #export SKYBLUE="\033[38;5;111m"
  export MEDIUMGREY="\033[38;5;246m"
  export LAVENDER="\033[38;5;183m"
  export TAN="\033[38;5;179m"
  export FOREST="\033[38;5;22m"
  export MAROON="\033[38;5;52m"
  export HOTPINK="\033[38;5;198m"
  export MINTGREEN="\033[38;5;121m"
  export LIGHTORANGE="\033[38;5;215m"
  export LIGHTRED="\033[38;5;203m"
  export JADE="\033[38;5;35m"
  export LIME="\033[38;5;154m"
  ### background colors
  export PINK_BG="\033[48;5;211m"
  export ORANGE_BG="\033[48;5;203m"
  export SKYBLUE_BG="\033[48;5;111m"
  export MEDIUMGREY_BG="\033[48;5;246m"
  export LAVENDER_BG="\033[48;5;183m"
  export TAN_BG="\033[48;5;179m"
  export FOREST_BG="\033[48;5;22m"
  export MAROON_BG="\033[48;5;52m"
  export HOTPINK_BG="\033[48;5;198m"
  export MINTGREEN_BG="\033[48;5;121m"
  export LIGHTORANGE_BG="\033[48;5;215m"
  export LIGHTRED_BG="\033[48;5;203m"
  export JADE_BG="\033[48;5;35m"
  export LIME_BG="\033[48;5;154m"
  ### extra attributes
  export UNDERLINE="\033[4m"

  BASH_COLORS=()
  BASH_COLORS+=(${PINK})
  BASH_COLORS+=(${ORANGE})
  #BASH_COLORS+=(${SKYBLUE})
  BASH_COLORS+=(${MEDIUMGREY})
  BASH_COLORS+=(${LAVENDER})
  BASH_COLORS+=(${TAN})
  BASH_COLORS+=(${FOREST})
  BASH_COLORS+=(${MAROON})
  BASH_COLORS+=(${HOTPINK})
  BASH_COLORS+=(${MINTGREEN})
  BASH_COLORS+=(${LIGHTORANGE})
  BASH_COLORS+=(${LIGHTRED})
  BASH_COLORS+=(${JADE})
  BASH_COLORS+=(${LIME})
  BASH_COLORS+=(${PINK_BG})
  BASH_COLORS+=(${ORANGE_BG})
  BASH_COLORS+=(${SKYBLUE_BG})
  BASH_COLORS+=(${MEDIUMGREY_BG})
  BASH_COLORS+=(${LAVENDER_BG})
  BASH_COLORS+=(${TAN_BG})
  BASH_COLORS+=(${FOREST_BG})
  BASH_COLORS+=(${MAROON_BG})
  BASH_COLORS+=(${HOTPINK_BG})
  BASH_COLORS+=(${MINTGREEN_BG})
  BASH_COLORS+=(${LIGHTORANGE_BG})
  BASH_COLORS+=(${LIGHTRED_BG})
  BASH_COLORS+=(${JADE_BG})
  BASH_COLORS+=(${LIME_BG})
  BASH_COLORS+=(${UNDERLINE})
fi

### sample of combining foreground and background
# export PRI_A=$HOTPINK$MEDIUMGREY_BG$UNDERLINE

# 2016-08-15: `tput` discovers the right sequences to send to the terminal:
export font_bold_tput=$(tput bold)
export font_normal_tput=$(tput sgr0)
export font_bold_bash="\033[1m"
export font_normal_bash="\033[0m"
export font_underline_bash="\033[4m"
# E.g.,
#   echo -e "Some \e[93mCOLOR"
#   echo -e "Some ${MINTGREEN}COLOR ${font_underline_bash}is ${font_bold_bash}nice ${font_normal_bash}surely."
# Hints:
#  tput sgr0 # Reset text attributes to normal without clear.

# To strip color codes from Bash stdout whatever.
# http://stackoverflow.com/questions/17998978/removing-colors-from-output
alias stripcolors='/bin/sed -r "s/\x1B\[([0-9]{1,2}(;[0-9]{1,2})?)?[mGK]//g"'

test_colors () {
  for ((i = 0; i < ${#BASH_COLORS[@]}; i++)); do
    BASH_COLOR="${BASH_COLORS[$i]}"
    echo -e "Some ${BASH_COLOR}COLOR ${font_underline_bash}is ${font_bold_bash}nice ${font_normal_bash}surely."
  done
}

# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #

function ensure_dropbox_running () {
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


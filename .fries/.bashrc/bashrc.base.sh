# File: bashrc.base.sh
# Author: Landon Bouma (landonb &#x40; retrosoft &#x2E; com)
# Last Modified: 2016.10.03
# Project Page: https://github.com/landonb/home_fries
# Summary: Smart Bash Startup Script
# License: GPLv3

# Overview
# ========
#
# This script loads bashrc startup/profile scripts.

# Specifics
# =========
#
# First loads:    /etc/bash.bashrc
# Then sources:   ./bashrx.private.sh
#                 ./bashrx.private.$HOSTNAME.sh
#                 ./bashrx.private.$USER.sh
#                 ./bashrc.core.sh
#                    (which may source additional files)
# And finally:    ./bashrc.*.base.sh
#                    (so you can add project-specific profiles)

# Script Setup
# ============

export DUBS_TRACE=false
#export DUBS_TRACE=true

$DUBS_TRACE && echo "User's EUID is $EUID"

# Get the path to this script's parent directory.
# Doesn't work?!:
#   HARD_PATH=$(dirname $(readlink -f $0))
# Carnally related:
#   HARD_PATH=$(dirname $(readlink -f ~/.bashrc))
# Universally Bashy:
HARD_PATH=$(dirname $(readlink -f $BASH_SOURCE))

# System-wide Profile
# ===================

# Source global definitions.
if [[ -f "/etc/bashrc" ]]; then
  # Fedora.
  . /etc/bashrc
elif [[ -f "/etc/bash.bashrc" ]]; then
  # Debian/Ubuntu.
  . /etc/bash.bashrc
fi

# Machine-specific Profiles
# =========================

# Load the machine-specific scripts first so their exports are visible.

if [[ $EUID -ne 0 ]]; then

  $DUBS_TRACE && echo "User is not root"

  # Load a private, uncommitted bash profile script, maybe.

  # Rather than assuming we're in the user's home, e.g.,
  #  if [[ -f "./somefile" ]] ...
  # use the `echo` trick:
  if [[ -f `echo ${HARD_PATH}/bashrx.private.sh` ]]; then
    $DUBS_TRACE && echo "Loading private resource script: bashrx.private.sh"
    source ${HARD_PATH}/bashrx.private.sh
  fi

  # Load a machine-specific, private, uncommitted script, maybe.

  # EXPLAIN: Is there a difference between $(hostname) and $HOSTNAME?
  #          One is a command and one is an environment variable.
  #          But does it matter which one we use?
  machfile=`echo ${HARD_PATH}/bashrx.private.$HOSTNAME.sh`

  if [[ -f "$machfile" ]]; then
    $DUBS_TRACE && echo "Loading machine-specific resource script: $machfile"
    source $machfile
  else
    $DUBS_TRACE && echo "Did not find a machine-specific resource: $machfile"
  fi

  userfile=`echo ${HARD_PATH}/bashrx.private.$USER.sh`

  if [[ -f "$userfile" ]]; then
    $DUBS_TRACE && echo "Loading user-specific resource script: $userfile"
    source $userfile
  else
    $DUBS_TRACE && echo "Did not find a user-specific resource: $userfile"
  fi

else

  # If the user is root, we'll just load the core script, and nothing fancy.

  $DUBS_TRACE && echo "User is root"

fi

# This Developer's Basic Bash Profile
# ===================================

# Load the basic script. Defines aliases, configures things,
# adjusts the terminal prompt, and adds a few functions.

source ${HARD_PATH}/bashrc.core.sh

# Additional Fancy -- Project Specific Profiles
# =============================================
  
if [[ $EUID -ne 0 ]]; then

  # CONVENTION: Load scripts named like bashrc.*.base.sh
  #
  #             This lets the user define a bunch of
  #             project-specific scripts; the *.base.sh
  #             files will be sourced from here, and then
  #             those scripts can source whatever else they
  #             wants, and you, the user, can keep all your
  #             bash profiles neatly (alphabetically) organized.

  # Load all bash scripts that are named thusly: bashrc.*.base.sh
  for f in $(find ${HARD_PATH} -maxdepth 1 -type f -name "bashrc.*.base.sh" \
                                       -or -type l -name "bashrc.*.base.sh"); do
    $DUBS_TRACE && echo "Loading project-specific Bash resource script: $f"
    source $f
  done

fi

# Load scripts named like bashrc0.*.base.sh, even for root.
for f in $(find ${HARD_PATH} -maxdepth 1 -type f -name "bashrc0.*.base.sh" \
                                     -or -type l -name "bashrc0.*.base.sh"); do
  # Avoid stderr message if symlink points at naught.
  if [[ -e $f ]]; then
    $DUBS_TRACE && echo "Loading project-specific Bash resource script: $f"
    # 2016-09-23: I've been mkdir 'ing my way around Dubsacks Gvim `ag` complaints
    #             on the laptop where not /jus/cache is loaded.
    if [[ ! -d $f ]]; then
      source $f
    fi
  fi
done

# Additional Fancy -- Starting Directory and Kickoff Command
# ==========================================================

# See the script:
#
#   ~/.fries/bin/termdub.py
#
# which sets the DUBS_* environment variables to tell us what
# to do once a new terminal is ready. The three options are:
#
#   DUBS_STARTIN  -- Where to `cd`.
#   DUBS_STARTUP  -- Some command to run.
#   DUBS_TERMNAME -- Title of the terminal window.

if [[ $EUID -ne 0 ]]; then

  # Start out in the preferred development directory.
  if [[ -n "$DUBS_STARTIN" ]]; then
    cd $DUBS_STARTIN
  elif [[ -d "$DUBS_STARTIN_DEFAULT" ]]; then
    cd $DUBS_STARTIN_DEFAULT
  fi
  # See: ${HARD_PATH}/.fries/bin/openterms.sh for usage.
  if [[ -n "$DUBS_STARTUP" ]]; then
    # Add the command we're about to execute to the command history (so if the
    # user Ctrl-C's the process, then can easily re-execute it).
    # See also: history -c, which clears the history.
    history -s $DUBS_STARTUP
    # Run the command.
    # FIXME: Does this hang the startup script? I.e., we're running the command
    #        from this script... so this better be the last command we run!
    #$DUBS_STARTUP
    eval "$DUBS_STARTUP"
  fi

  # The variables have served us well; now whack 'em.
  export DUBS_STARTIN=''
  export DUBS_STARTUP=''
  export DUBS_TERMNAME=''

fi

# Cleanup
# =======

# I thought you had to `export` variables for them to persist,
# but I guess that's not the case when variables are defined
# in a sourced Bash profile and not defined within a function.

unset HARD_PATH
unset machfile
unset userfile


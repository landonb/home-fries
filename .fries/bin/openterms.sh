#!/bin/bash

# File: openterms.sh
# Author: Landon Bouma (landonb &#x40; retrosoft &#x2E; com)
# Last Modified: 2015.03.18
# Project Page: https://github.com/landonb/home_fries
# License: GPLv3

"""
Open and Setup Lots of Terminal Windows
=======================================

This script helps you prepare your work environment
by opening a bunch of terminal windows to friendly
dimensions and screen placesments, and changing
directories and running scripts as specified.

This script basically calls termdub.py a bunch;
see that script for more details.
"""

# 2012.10.17: This script created so I don't need to click so many terminal
#             buttons... and so I don't need to keep editing Gnome shortcuts.

# NOTE: To kill all existing gnome-terminals (it's just one process), run,
#
#   killsomething gnome-terminal

# NOTE: If we don't use & to execute these terminals in the background, the
#       gnome shortcut opens just the first terminal, and then when you close
#       that one, it'll open the second terminal, etc.
# NOTE: If we don't wait between each terminal being opened, they won't claim
#       their proper place in the gnome taskbar.

# Save a few lines of code to make $script_path,
# which will be, e.g., /home/$USER/.fries/bin.
DEBUG_TRACE=false
source $(dirname $0)/bash_base.sh

function do_sleep () {
  echo "import time;time.sleep(0.5)" | python
}

# Make sure we reset the DUBs vars btw calls, otherwise
# they'll be used in subsequent commands (if you're running
# this openterms.sh script from a gnome taskbar shortcut).

# 2015.03.04: DUBS_STARTUP is now sticking at "mount_sepulcher".
#             E.g., when I click the `mate-terminal` panel launcher,
#             it tries running mount_sepulcher. So weird!
#             I prefixed the panel launcher terminal commands with
#               env DUBS_STARTUP=""
#             which fixes it, so I'll prefix herein, too, with env.

#
env \
  DUBS_TERMNAME="" \
  DUBS_STARTIN=/kit \
  DUBS_STARTUP="mount_sepulcher" \
  $script_path/termdub.py -t lhs \
  &
do_sleep

env \
  DUBS_TERMNAME="" \
  DUBS_STARTIN=/kit \
  DUBS_STARTUP="" \
  $script_path/termdub.py -t lhs \
  &
do_sleep

#
env \
  DUBS_TERMNAME="" \
  DUBS_STARTIN="" \
  DUBS_STARTUP="" \
  $script_path/termdub.py -t rhs \
  &
do_sleep

env \
  DUBS_TERMNAME="" \
  DUBS_STARTIN="" \
  DUBS_STARTUP="" \
  $script_path/termdub.py -t rhs \
  &
do_sleep

#
env \
  DUBS_TERMNAME="logs" \
  DUBS_STARTIN=/srv/excensus \
  DUBS_STARTUP="" \
  $script_path/termdub.py -t logs \
  &
do_sleep

env \
  DUBS_TERMNAME="" \
  DUBS_STARTIN=/srv/excensus \
  DUBS_STARTUP="" \
  $script_path/termdub.py -t bigl \
  &
do_sleep

env \
  DUBS_TERMNAME="" \
  DUBS_STARTIN=~/.fries \
  DUBS_STARTUP="" \
  $script_path/termdub.py -t dbms \
  &
do_sleep

#
env \
  DUBS_TERMNAME="" \
  DUBS_STARTIN=/srv/excensus \
  DUBS_STARTUP="" \
  $script_path/termdub.py -t bigc \
  &
do_sleep

env \
  DUBS_TERMNAME="" \
  DUBS_STARTIN=~/.fries \
  DUBS_STARTUP="" \
  $script_path/termdub.py -t rhs \
  &
do_sleep

env \
  DUBS_TERMNAME="" \
  DUBS_STARTIN=/srv/excensus \
  DUBS_STARTUP="cli_gk12.sh go" \
  $script_path/termdub.py -t bigr \
  &
do_sleep

# =====================================================
# +++++++++++++++ END OF ACTIVE WINDOWS +++++++++++++++
# =====================================================

if false;

  #
  env \
    DUBS_TERMNAME="Psql-v3" \
    DUBS_STARTIN="" \
    DUBS_STARTUP="psql -U cycling ccpv3_lite" \
    $script_path/termdub.py -t logs \
    &
  do_sleep

  env \
    DUBS_TERMNAME="Psql-v2" \
    DUBS_STARTIN="" \
    DUBS_STARTUP="psql -U cycling ccpv3_lite" \
    $script_path/termdub.py -t logc \
    &
  do_sleep

  #
  env \
    DUBS_TERMNAME="rLogs" \
    DUBS_STARTIN="" \
    DUBS_STARTUP="sss runic" \
    $script_path/termdub.py -t logs \
    &
  do_sleep

  env \
    DUBS_TERMNAME="rPsql" \
    DUBS_STARTIN="" \
    DUBS_STARTUP="sss runic" \
    $script_path/termdub.py -t logc \
    &
  do_sleep

  #
  env \
    DUBS_TERMNAME="rLogs_Rd" \
    DUBS_STARTIN="" \
    DUBS_STARTUP="sss runic" \
    $script_path/termdub.py -t logs \
    &
  do_sleep

  env \
    DUBS_TERMNAME="rPsql2" \
    DUBS_STARTIN="" \
    DUBS_STARTUP="sss runic" \
    $script_path/termdub.py -t logc \
    &
  do_sleep

  #
  env \
    DUBS_TERMNAME="" \
    DUBS_STARTIN="" \
    DUBS_STARTUP="sss runic" \
    $script_path/termdub.py -t dbms \
    &
  do_sleep

  env \
    DUBS_TERMNAME="" \
    DUBS_STARTIN="" \
    DUBS_STARTUP="" \
    $script_path/termdub.py -t dbms \
    &
  do_sleep

  #
  env \
    DUBS_TERMNAME="" \
    DUBS_STARTIN="" \
    DUBS_STARTUP="sss runic" \
    $script_path/termdub.py -t dbms \
    &
  do_sleep

  env \
    DUBS_TERMNAME="" \
    DUBS_STARTIN="/ccp/etc/cp_confs" \
    DUBS_STARTUP="" \
    $script_path/termdub.py -t dbms \
    &
  do_sleep

  #
  env \
    DUBS_TERMNAME="" \
    DUBS_STARTIN="" \
    DUBS_STARTUP="sss runic" \
    $script_path/termdub.py -t dbms \
    &
  do_sleep

  env \
    DUBS_TERMNAME="" \
    DUBS_STARTIN="" \
    DUBS_STARTUP="" \
    $script_path/termdub.py -t dbms \
    &
  do_sleep

  #
  env \
    DUBS_TERMNAME="" \
    DUBS_STARTIN="/ccp/dev/cp/pyserver" \
    DUBS_STARTUP="sss runic" \
    $script_path/termdub.py -t dbms \
    &
  do_sleep

  env \
    DUBS_TERMNAME="py" \
    DUBS_STARTIN="/ccp/dev/cp/pyserver" \
    DUBS_STARTUP="python" \
    $script_path/termdub.py -t dbms \
    &
  do_sleep

fi

#
# Skipping: $script_path/termdub.py -t mini


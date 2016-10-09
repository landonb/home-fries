# File: util.sh
# Author: Landon Bouma (landonb &#x40; retrosoft &#x2E; com)
# Last Modified: 2016.10.09
# Project Page: https://github.com/landonb/home-fries
# Summary: Dumping ground for unused Bash functions, apparently.
# License: GPLv3
# vim:tw=0:ts=2:sw=2:et:norl:

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


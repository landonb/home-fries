#!/bin/bash

# File: setup.sh
# Author: Landon Bouma (landonb &#x40; retrosoft &#x2E; com)
# Last Modified: 2017.10.03
# Project Page: https://github.com/landonb/home-fries
# License: GPLv3

# Expects: bashrc* files in current directory

# Results: adds link from ~/.bashrc to local ${BASHRC},
#          i.e., ~/.fries/.bashrc/bashrc.base.sh

# Why: To keep bash profile scripts in their own directory
#      and not scattered amongst the chaos of a user's home.

# The name of the one bash profile to rule them all.
BASHRC="bashrc.base.sh"

# Complain if this script is not run from same directory as the profiles.
if [[ ! -e ${BASHRC} ]]; then
  echo "ERROR: Expecting script to be run from same dir. as new ${BASHRC}."
  exit 1
fi

# Complain if user's .bashrc already exists.
if [[ -e ~/.bashrc ]]; then
  echo "ERROR: Your .bashrc already exists."
  echo
  echo "This script is too basic to help you interactively."
  echo "It'll give you advice, though. Try one of the following:"
  echo
  echo "1. Compare the two files and merge whatever you"
  echo "   want to keep into the new profile file."
  echo
  echo "   meld ${BASHRC} ~/.bashrc"
  echo
  echo "2. Or, remove ~/.bashrc and rerun this script."
  echo
  echo "3. Or, create the symlink forcefully."
  echo
  echo "   /bin/ls -rsf ${BASHRC} ~/.bashrc"
  echo
  echo "4. Or, move your .bashrc to this directory, renaming"
  echo "   it something like bashrc.{choose-a-name}.base.sh"
  echo "   and it'll get sourced automatically by ${BASHRC}."
  echo
  exit 1
fi

/bin/ln --relative --symbolic ${BASHRC} ~/.bashrc


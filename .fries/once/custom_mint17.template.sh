#!/bin/bash

###########################################################
## DO NOT CHECKIN #########################################
###########################################################

# Usage: You can either call setup_mint17.sh directly
#        to configure a new guest OS, or you can customize
#        some options herein and then call this script.
#        Copy custom_mint17.template.sh and customize,
#        and then execute it.

###########################################################

# Load the setup script first, and then overwrite some variables it set.
# ----------------------------------------------------------------------

script_relbase=$(dirname $0)
script_absbase=`pwd $script_relbase`

# Tell the setup script not to run the setup process but just to be sourced.
SETUP_WRAPPERED=true
source ${script_absbase}/setup_mint17.sh

# Customize the setup script variables.
# -------------------------------------

# DEVS: Expose and set any of the variables below that interest you.

if false; then

  # Set the name of the shared folder you've setup from your host machine.
  USE_MOUNTPT="C_DRIVE"

  # To better mimic a deployed server installation, set a domain name.
  # Whatever name you use will obscure any real domain name of the same
  # domain name, so choose a name that won't conflict with anything.
  USE_DOMAIN="${USER}.tld" # Not an actual domain.

  # Create OS groups and add to them the users $USER, postgres, and www-data.
  USE_PROJECT_USERGROUPS+=("clientA" "projectB")

  # Create postgres users.
  USE_PROJECT_PSQLGROUPS+=("projectA" "clientB")

  # Install MediaWiki if you want, otherwise reST + git is pretty neat.
  DO_INSTALL_MEDIAWIKI=false
  #USE_TIMEZONE=""
  #USE_WIKINAME=""
  #USE_WIKIUSERNAME=""
  #USE_WIKISITELOGO=""
  #USE_WIKIDB_DUMP=""

  # Install Cyclopath. Go ahead. You know you want to.
  DO_INSTALL_CYCLOPATH=true

fi

# -- Run the setup script.

setup_mint_17_go


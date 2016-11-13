#!/bin/bash

###########################################################

# Usage: You can either call setup_ubuntu.sh directly
#        to configure a new guest OS, or you can customize
#        some options herein and then call this script.
#        Copy custom_setup.template.sh and customize,
#        and then execute it.

###########################################################

# Customize the setup script variables.
# -------------------------------------

# DEVS: Expose and set any of the variables below that interest you.

if false; then

  # Set the name of the shared folder you've setup from your host machine.
  export USE_MOUNTPT="C_DRIVE"
  export DST_MOUNTPT="/win"

  # To better mimic a deployed server installation, set a domain name.
  # Whatever name you use will obscure any real domain name of the same
  # domain name, so choose a name that won't conflict with anything.
  export USE_DOMAIN="${USER}.tld" # Not an actual domain.

  # Create OS groups and add to them the users $USER, postgres, and www-data.
  export USE_PROJECT_USERGROUPS+=("clientA" "projectB")

  # Create postgres users.
  export USE_PROJECT_PSQLGROUPS+=("projectA" "clientB")

  # Install MediaWiki if you want, otherwise reST + git is pretty neat.
  # 2016-11-12: I haven't run the MediaWiki install in years/ages.
  export DO_INSTALL_MEDIAWIKI=false
  #export USE_TIMEZONE=""
  #export USE_WIKINAME=""
  #export USE_WIKIUSERNAME=""
  #export USE_WIKISITELOGO=""
  #export USE_WIKIDB_DUMP=""

  # Install Cyclopath. Go ahead. You know you want to.
  export DO_INSTALL_CYCLOPATH=true

fi

# -- Run the setup script.

./setup_ubuntu.sh


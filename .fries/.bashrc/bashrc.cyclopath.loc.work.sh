# File: bashrc.cyclopath.loc.work.sh
# Author: Landon Bouma (landonb &#x40; retrosoft &#x2E; com)
# Last Modified: 2016.04.04
# Project Page: https://github.com/landonb/home_fries
# Summary: Cyclopath bash startup script for CS machines.
# License: GPLv3

# This script is loaded by bashrc.cyclopath.base.sh.

# In a chroot, [lb] sees "hostname: Name or service not known"
#  MACHINE_DOMAIN=`hostname --domain`
# so use the domainname command instead.
if [[ $(domainname) != "(none)" ]]; then
  MACHINE_DOMAIN=$(domainname)
fi
if [[ -z "$MACHINE_DOMAIN" ]]; then
   MACHINE_DOMAIN="FIXME"
fi
if [[ "${MACHINE_DOMAIN}" == "${CS_HOSTDOMAIN}" ]]; then
  # == Running on remote/work machine. ==
  return
fi

# == Running on local/home machine ==

# Initialize the terminal prompt and terminal titlebar name.
dubs_set_terminal_prompt

# Add GroupLens scripts to path.
#export PATH=/ccp/bin/grpbin:/ccp/opt/usr/bin:$PATH
# Er, the GroupLens scripts are now in the Ccp source.
export PATH=/ccp/bin/ccpdev/bin:/ccp/opt/usr/bin:$PATH

# `ssh` wrapper (`sss` maps ports and sets terminal window title).

sss () {

  if [[ -z "$1" ]]; then
    echo "Usage: sss machine_name"
    return 1
  fi

  # Change the titlebar name.
  # FIXME: This doesn't work: gnome-terminal doesn't apply the change until
  #        after we exit this fcn. But we reset the title before exiting the
  #        fcn., so the title never changes.
  # NOTE: Setting COMMAND_PROMPT instead of PS1 has the same delayed effect.
  # Don't bother:
  #   dubs_set_terminal_prompt $1
  # NOTE: wmctrl -N just sets the name (long title) of the window,
  #       and wmctrl -I sets the icon name (short title), and wmctrl -T
  #       does both (since wmctrl only accepts one action at a time).
  wmctrl -r :ACTIVE: -T "On ${1}"

  # 2013.04.24: Added 4666 for remote routed debugging.
  ssh \
    $2 \
    -L 8080:localhost:80 \
    -L 8081:localhost:8081 \
    -L 8082:localhost:8082 \
    -L 8083:localhost:8083 \
    -L 8084:localhost:8084 \
    -L 8085:localhost:8085 \
    -L 8086:localhost:8086 \
    -L 8087:localhost:8087 \
    -L 8088:localhost:8088 \
    -L 8089:localhost:8089 \
    -L 8099:localhost:8099 \
    -L 4444:localhost:4444 \
    -L 4666:localhost:4666 \
    -L 7432:localhost:5432 \
    $CS_USERNAME@$1.$CS_HOSTDOMAIN

  # Reset the titlebar name.
  # CAVEAT: The icon name is reflected in the task bar immediately, but the
  # long title won't be refreshed until the user changes directories. I've
  # tried but failed to force the window title to change, but it's not a big
  # biggee.
  # MAYBE: We might be able to get the title of the window above and reset it
  # here, but all I found was an ASCII escape that always returns "lTerminal":
  #   echo -ne "\033[21t"
  # 2013.01.30: Hahaha, the problem is that this needs to be called from the
  #   remote machine on its bash startup.
  wmctrl -r :ACTIVE: -T ""
  dubs_set_terminal_prompt

  echo "All done byebyenow."
}

ssx () {
  # -X Enables X11 forwarding.
  sss $1 -X
}

# Connect to development machine
#  alias sshcs='ssh -L 8080:localhost:80 \
#                   -L 8081:localhost:8081 \
#                   -L 8082:localhost:8082 \
#                   -L 8083:localhost:8083 \
#                   -L 8099:localhost:8099 \
#                   $CS_USERNAME@$CS_MACHINEDEV'
if [[ -n $CS_HOSTNAME ]]; then
  alias sshcs='sss $CS_HOSTNAME'
fi

# Control processes

## Kill all processes: SSH clients
killss () {
  ${DUBS_TRACE} && echo "killss"
  ps aux | grep ssh | grep \.cs\.umn\.edu | awk '{print $2}' | xargs sudo kill -s 9
  return 0
}

# Env. vars. and aliases.

if [[ -n $CS_MACHINEDEV ]]; then
   # Shortcuts to remote directories
   # Usage example: scp -r $mycs/ccp/dev/cp /ccp/dev/cp-from-server
   # String is, e.g., your_name@your_machine.cs.umn.edu.
   export mycs="$CS_USERNAME@$CS_MACHINEDEV"
fi
if [[ -n $CS_PRODUCTION ]]; then
   # 2013.04.20: [lb]'s been scp'ing to the production server a lot recently...
   export mypr="$CS_USERNAME@$CS_PRODUCTION"
fi

# 2013.05.12: For copying the daily cron jobs easily...
alias scpd='scp /ccp/bin/ccpdev/daily/* $mypr:/ccp/bin/ccpdev/daily'

# Pull and push source code working directories.

# 2011.08.14: cpget is destructive without asking, [so it's been removed].
#  function cpget () {
#    rsync ... remote local
#  }
# 2015.01.25: Use a better tool, like `unison`, if you want
#             to sync files in lieu of using a code repository.

function cpput_ () {
  ########
  # 2015.01.25: Deprecated: Consider using `unison` instead, to prevent
  #             you from overwriting remote changes not reflected locally.
  echo "This command is deprecated. Buzz off, buzzard!";
  return 0;
  ######## The following code is unreachable:
  if [[ "$1" == "" ]]; then
    echo "Please specify the bug number or directory to push."
    echo "Usage: cpput 1234 [-r machine]"
    return 1
  else
    dest=$1
    if [[ ! -d "$CCP_DEV_DIR/$dest" ]]; then
      # Try cp_ prefix.
      dest=cp_$1
      if [[ ! -d "$CCP_DEV_DIR/$dest" ]]; then
        echo "Error: No such directory ${1} or cp_${1} in ${CCP_DEV_DIR}."
        return 1
      fi
    fi
    DEBUG_TRACE=true
    MACHINE_ADDR=""
    while [[ -n "$2" ]]; do
      if [[ "-r" == "$2" ]]; then
        if [[ -n "$3" ]]; then
          MACHINE_ADDR=$3.$CS_HOSTDOMAIN
          shift # Shift $3
        else
          echo "Error: -r requires a machine name";
          return 1
        fi
      elif [[ "-q" = "$2" || "--quiet" = "$2" ]]; then
        DEBUG_TRACE=false
      else
        echo "Error: unrecognized parameter: $2";
        return 1
      fi
      shift # Shift $2
    done
    if [[ -z "$MACHINE_ADDR" ]]; then
      MACHINE_ADDR=$CS_MACHINEDEV
    fi
    $DEBUG_TRACE && echo \
      "Copying to $CS_USERNAME@$MACHINE_ADDR:$CCP_DEV_DIR"
    QUIET_SWITCH=""
    if ! $DEBUG_TRACE; then
      QUIET_SWITCH="--quiet"
    fi
    # 2013.04.25: tilecache.cfg is now generated, but its presence is okay.
    # 2013.05.14: Per the man rsync, make both src and dest "$dest/" (with
    #             trailing slash) so we can copy symbolic links (though they
    #             won't be symbolic on the remote).
    rsync -t -a -v -z \
      --exclude='*.svn' \
      --exclude='*.pyc' \
      --exclude='pyserver/CONFIG' \
      --exclude='flashclient/Conf_Instance.as' \
      --exclude='flashclient/Makefile' \
      --exclude='mapserver/database.map' \
      --exclude='mapserver/tilecache.cfg' \
      --exclude='mapserver/check_cache_now.sh' \
      --exclude='mapserver/kill_cache_check.sh' \
      --exclude='pyserver/VERSION.py' \
      --exclude='flashclient/build/*' \
      --exclude='flashclient/build-print/*' \
      --exclude='flashclient/FW.build_main.mxml.pid' \
      $CCP_DEV_DIR/$dest/ \
      $CS_USERNAME@$MACHINE_ADDR:$CCP_DEV_DIR/$dest/ \
      $QUIET_SWITCH
    $DEBUG_TRACE && echo "rsync exit value: $?"
    $DEBUG_TRACE && echo ""
  fi
  return 0
}

function cpput () {
  # From home, usually only every other rysnc command works.
  # The every other rsync gripes,
  #   protocol version mismatch -- is your shell clean?
  #   (see the rsync man page for an explanation)
  #   rsync error: protocol incompatibility (code 2) at compat.c(173) [sender=3.0.7]
  # So try it twice, always.
  cpput_ $*
  if [[ 0 == $? ]]; then
    cpput_ $*
  fi
}


# File: bashrc.base.sh
# Author: Landon Bouma (landonb &#x40; retrosoft &#x2E; com)
# Last Modified: 2017.10.04
# Project Page: https://github.com/landonb/home-fries
# Summary: Smart Bash Startup Script
# License: GPLv3
# vim:tw=0:ts=2:sw=2:et:norl:

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
#                 ./bashrx.private.$LOGNAME.sh
#                 ./bashrc.core.sh
#                    (which may source additional files)
# And finally:    ./bashrc.*.base.sh
#                    (so you can add project-specific profiles)

# Do Nothing Unless Interactive
# =============================

# Copied from /etc/bash.bashrc [Ubuntu 18.04]:
[ -z "$PS1" ] && return
# (One could also check [[ $- != *i* ]],
# but not $(shopt login_shell), which is
# false via mate-terminal.

# Script Setup
# ============

bashrc_time_0=$(date +%s.%N)

export DUBS_TRACE=${DUBS_TRACE:-false}
#export DUBS_TRACE=${DUBS_TRACE:-true}

# DEVS: Uncomment to show progress times.
DUBS_PROFILING=${DUBS_PROFILING:-false}
#DUBS_PROFILING=${DUBS_PROFILING:-true}
[[ -n "${TMUX}" ]] && DUBS_PROFILING=true

# DEVS: Uncomment to show progress times.
DUBS_PROFILING=${DUBS_PROFILING:-false}

$DUBS_TRACE && echo "User's EUID is $EUID"

# Get the path to this script's parent directory.
# Doesn't work?!:
#   hard_path=$(dirname $(readlink -f -- "$0"))
# Carnally related:
#   hard_path=$(dirname $(readlink -f ~/.bashrc))
# Universally Bashy:
hard_path=$(dirname $(readlink -f -- "${BASH_SOURCE}"))

# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #

# *** Profiling.

print_elapsed_time () {
  ! ${DUBS_PROFILING} && return
  local time_0="$1"
  local detail="$2"
  local prefix="${3:-Elapsed: }"
  local time_n=$(date +%s.%N)
  # local elapsed_fract_mins="$(echo "(${time_n} - ${time_0}) / 60" | bc -l)"
  local elapsed_fract_secs="$(echo "(${time_n} - ${time_0})" | bc -l)"
  if [[ $(echo "${elapsed_fract_secs} >= 0.05" | bc -l) -eq 1 ]]; then
    local elapsed_secs=$(echo ${elapsed_fract_secs} | xargs printf "%.2f")
    echo "${prefix}${elapsed_secs} secs. / ${detail}"
  fi
}

# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #

ensure_pathed () {
  # HACK!
  # - Unset BASH_VERSION so ~/.profile doesn't load *us*!
  #   But updates PATH and LD_LIBRARY_PATH instead.
  local wasver
  wasver="${BASH_VERSION}"
  BASH_VERSION=""
  source ${HOME}/.profile
  BASH_VERSION="${wasver}"
}

# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #

# System-wide Profile
# ===================

source_deps () {
  local time_0=$(date +%s.%N)

  # Source global definitions.
  if [[ -f "/etc/bashrc" ]]; then
    # Fedora.
    . /etc/bashrc
    print_elapsed_time "${time_0}" "Source: /etc/bashrc"
  elif [[ -f "/etc/bash.bashrc" ]]; then
    # Debian/Ubuntu.
    . /etc/bash.bashrc
    print_elapsed_time "${time_0}" "Source: /etc/bash.bashrc"
  fi
}

# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #

# This Developer's Basic Bash Profile
# ===================================

source_fries () {
  local time_0=$(date +%s.%N)

  # Load the basic script. Defines aliases, configures things,
  # adjusts the terminal prompt, and adds a few functions.
  source ${hard_path}/bashrc.core.sh

  print_elapsed_time "${time_0}" "Source: bashrc.core.sh" "==FRIES: "
}

# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #

# Machine-specific Profiles
# =========================

source_private () {
  # Load the machine-specific scripts first so their exports are visible.

  if [[ $EUID -ne 0 ]]; then
    $DUBS_TRACE && echo "User is not root"

    # Load a private, uncommitted bash profile script, maybe.

    # Rather than assuming we're in the user's home, e.g.,
    #  if [[ -f "./somefile" ]] ...
    # use the `echo` trick:
    if [[ -f `echo ${hard_path}/bashrx.private.sh` ]]; then
      $DUBS_TRACE && echo "Loading private resource script: bashrx.private.sh"
      local time_0=$(date +%s.%N)
      source ${hard_path}/bashrx.private.sh
      print_elapsed_time "${time_0}" "Source: ${hard_path}/bashrx.private.sh"
    fi

    # Load a machine-specific, private, uncommitted script, maybe.

    # EXPLAIN: Is there a difference between $(hostname) and $HOSTNAME?
    #          One is a command and one is an environment variable.
    #          But does it matter which one we use?
    machfile=`echo ${hard_path}/bashrx.private.$HOSTNAME.sh`

    if [[ -f "${machfile}" ]]; then
      $DUBS_TRACE && echo "Loading machine-specific resource script: ${machfile}"
      local time_0=$(date +%s.%N)
      source "${machfile}"
      print_elapsed_time "${time_0}" "Source: ${machfile}"
    else
      $DUBS_TRACE && echo "Did not find a machine-specific resource: ${machfile}"
    fi

    userfile=`echo ${hard_path}/bashrx.private.${LOGNAME}.sh`

    if [[ -f "${userfile}" ]]; then
      $DUBS_TRACE && echo "Loading user-specific resource script: ${userfile}"
      local time_0=$(date +%s.%N)
      source "${userfile}"
      print_elapsed_time "${time_0}" "Source: ${userfile}"
    else
      $DUBS_TRACE && echo "Did not find a user-specific resource: ${userfile}"
    fi
  else
    # If the user is root, we'll just load the core script, and nothing fancy.
    $DUBS_TRACE && echo "User is root"
  fi
}

# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #

# Additional Fancy -- Project Specific Profiles
# =============================================

source_projects () {
  if [[ $EUID -ne 0 ]]; then
    # CONVENTION: Load scripts named like bashrc.*.base.sh
    #
    #             This lets the user define a bunch of
    #             project-specific scripts; the *.base.sh
    #             files will be sourced from here, and then
    #             those scripts can source whatever else they
    #             wants, and you, the user, can keep all your
    #             bash profiles neatly (alphabetically) organized.
    #
    # Load all bash scripts that are named thusly: bashrc.*.base.sh
    local rcfile=""
    for rcfile in $(find ${hard_path} \
        -maxdepth 1 -type f -name "bashrc.*.base.sh" \
                -or -type l -name "bashrc.*.base.sh"); do
      $DUBS_TRACE && echo "Loading project-specific Bash resource script: ${rcfile}"
      local time_0=$(date +%s.%N)
      source "${rcfile}"
      print_elapsed_time "${time_0}" "Source: ${rcfile}"
    done
  fi
}

source_projects0 () {
  # Load scripts named like bashrc0.*.base.sh, even for root.
  local rcfile=""
  for rcfile in $(find ${hard_path} -maxdepth 1 \
          -type f -name "bashrc0.*.base.sh" \
      -or -type l -name "bashrc0.*.base.sh"); do
    # Avoid stderr message if symlink points at naught.
    if [[ -e "${rcfile}" ]]; then
      $DUBS_TRACE && echo "Loading project-specific Bash resource script: $rcfile"
      if [[ ! -d "${rcfile}" ]]; then
        local time_0=$(date +%s.%N)
        source "${rcfile}"
        print_elapsed_time "${time_0}" "Source: ${rcfile}"
      else
        $DUBS_TRACE && echo "Is a directory: ${rcfile}"
      fi
    else
      $DUBS_TRACE && echo "No such file: ${rcfile}"
    fi
  done
}

# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #

# Additional Fancy -- Starting Directory and Kickoff Command
# ==========================================================

start_somewhere_something () {
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
    # See: ${hard_path}/.fries/bin/openterms.sh for usage.
    if [[ -n "$DUBS_STARTUP" ]]; then
      # Add the command we're about to execute to the command history (so if the
      # user Ctrl-C's the process, then can easily re-execute it).
      # See also: history -c, which clears the history.
      history -s $DUBS_STARTUP
      # Run the command.
      # FIXME: Does this hang the startup script? I.e., we're running the command
      #        from this script... so this better be the last command we run!
      #$DUBS_STARTUP
      local time_0=$(date +%s.%N)
      eval "${DUBS_STARTUP}"
      print_elapsed_time "${time_0}" "eval: DUBS_STARTUP"
    fi

    # The variables have served us well; now whack 'em.
    export DUBS_STARTIN=''
    export DUBS_STARTUP=''
    export DUBS_TERMNAME=''
  fi
}

# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #

# Cleanup
# =======

home_fries_bashrc_cleanup () {
  local time_0=$(date +%s.%N)

  # I thought you had to `export` variables for them to persist,
  # but I guess that's not the case when variables are defined
  # in a sourced Bash profile and not defined within a function.

  unset -v hard_path
  unset -v machfile
  unset -v userfile

  # Run the sourced-scripts' cleanup functions, to un-declare functions
  # (and remove cruft from user's environment).
  for unset_f in $(declare -F | grep '^declare -f unset_f_' | /bin/sed 's/^declare -f //'); do
    # Call, e.g., unset_f_alias_util, unset_f_apache_util, etc.
    eval "${unset_f}"
  done

  # Show startup stats if we already polluted console with ``expect`` stuff,
  # or if being run in tmuxinator/tmux/screen,
  # or if user is profiling bashrc, or already tracing.
  if ( [[ ! -z ${SSH_ENV_FRESH+x} ]] && ${SSH_ENV_FRESH} ) || \
     ( [[ "${TERM}" == "screen" || "${TERM}" == "screen-256color" ]] && \
       [[ -n "${TMUX}" ]] ) || \
     ( ${DUBS_TRACE} || ${DUBS_PROFILING} ) \
  then
    bashrc_time_n=$(date +%s.%N)
    time_elapsed=$(\
      echo "${bashrc_time_n} - ${bashrc_time_0}" | bc -l | xargs printf "%.2f" \
    )

    source 'logger.sh'
    local old_level=${LOG_LEVEL}
    export LOG_LEVEL=${LOG_LEVEL_NOTICE}
    notice "home-fries start-up: ${time_elapsed} secs."
    export LOG_LEVEL=${old_level}

    unset -v bashrc_time_n
    unset -v time_elapsed
  fi
  unset -v bashrc_time_0

  # Tell user when running non-standard Bash.
  # E.g., when on local terminal invoked by launcher and running mate-terminal,
  #   $0 == '/user/home/.local/bin/bash'
  # and when on remote terminal over ssh,
  #   $0 == '-bash'
  local custom_bash
  custom_bash=false
  if [[ "$0" == 'bash' || "$0" == '-bash' ]]; then
    if $(alias bash &> /dev/null); then
      if [[ $(readlink -f "$(alias bash | /bin/sed -E 's/^.* ([^ ]+\/bash\>).*/\1/')") != '/bin/bash' ]]; then
        custom_bash=true
      fi
    elif [[ $(readlink -f "$(command -v bash)") != '/bin/bash' ]]; then
      custom_bash=true
    fi
  elif [[ $(readlink -f "$0") != '/bin/bash' ]]; then
    custom_bash=true
  fi
  if ${custom_bash}; then
    notice "This bash is a ${FG_LIGHTGREEN}${MK_LINE}special${RESET_UNDERLINED} bash!${MK_NORM}" \
      "Version: ${FG_LIGHTYELLOW}${MK_LINE}${MK_BOLD}${BASH_VERSION}"
  fi

  print_elapsed_time "${time_0}" "cleanup"
}

# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #

# Thanks, Amir Rachum, for the magic!
#   https://amir.rachum.com/blog/2015/11/28/terminator-multiple-custom-commands/
# This gets past a Terminator behavior where it's hard to run a custom
# command that sets up an interactive shell. So you can, e.g., use this
# as your Terminator custom command:
#   env INIT_CMD="cd bla; export PYTHONPATH=/tmp; workon project" zsh
#
# NOTE: (lb): I copied a zsh function and updated it.
home_fries_run_terminator_init_cmd () {
  local time_0=$(date +%s.%N)

  if [[ -n "${INIT_CMD}" ]]; then
    echo ${INIT_CMD}
    OLD_IFS=$IFS
    # (lb): setopt, and shwordsplit, and Z Shell-specific, to emulate Bash behavior.
    #setopt shwordsplit
    IFS=';'
    local cmd
    for cmd in ${INIT_CMD}; do
      # (lb): Is `print` how you add to history in Z Shell? I get an error.
      #
      #   $ /usr/bin/print
      #   Unescaped left brace in regex is deprecated, passed through in regex;
      #   marked by <-- HERE in m/%{ <-- HERE (.*?)}/ at /usr/bin/print line 528.
      #
      #print -s "${cmd}"  # add to history
      history -s "${cmd}"  # add to history
      eval "${cmd}"
    done
    unset -v INIT_CMD
    IFS=${OLD_IFS}
  fi

  print_elapsed_time "${time_0}" "terminator-init"
}

# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #

# Prevent creationix/nvm/install.sh from appending this file.
# Just be sure that its grep commands find "/nvm.sh" and "$NVM_DIR/bash_completion" [so meta].

# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #

main () {
  local time_0=$(date +%s.%N)

  # Add ~/.local/bin to PATH, and ~/.local/lib to LD_LIBRARY_PATH,
  # which we need because that's where my custom tmux et al is at.
  ensure_pathed
  unset -f ensure_pathed
  # Maybe don't startup and reuse existing tmux session, eh.
  if source ${hard_path}/prepare-tmux-or-bust; then
    return  # Will have run switch-client and user will be on another session.
  fi

  source_deps
  unset -f source_deps

  # FIXME/2018-04-04: This is a hack until I figure out something better.
  # - It exports an environment variable I need in source_fries.
  export HOME_FRIES_PRELOAD=true
  source_private

  source_fries
  unset -f source_fries

  export HOME_FRIES_PRELOAD=false
  source_private
  unset -f source_private

  source_projects
  unset -f source_projects

  source_projects0
  unset -f source_projects0

  start_somewhere_something
  unset -f start_somewhere_something

  home_fries_run_terminator_init_cmd
  unset -f home_fries_run_terminator_init_cmd

  home_fries_bashrc_cleanup
  unset -f home_fries_bashrc_cleanup

  print_elapsed_time "${time_0}" "bashrc.bash.sh" "==TOTAL: "
}

main "$@"

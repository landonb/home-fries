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

# Speedier startup using existing tmux session
# ============================================

# (lb): In tmux, each session can have one or more windows. The window names
# appear in a list in the middle of the bottom status bar. Each window name
# defaults to 'bash', but I've got ~/.tmux.conf.local configured to show the
# circled window number and the current directory basename instead; or to show
# the name of the active command (w/ args). See, e.g.,
#   tmux_conf_theme_window_status_format=
#     '#{circled_window_index} #{b:pane_current_path}/'

# (lb): In tmux, the session name (one per client) appears in the lower left
# of the screen, leftmost on the bottom status bar. Each session name defaults
# to a number, incrementing from 0 (which I don't think can be changed, unlike
# the window number, which is influenced by, e.g., `set -g base-index 1`).

# Here, we set a more memorable session name, using either today's date (YYYY-MM-DD),
# or a random English first name that's the same length as a date, 10 characters.
# However, if there are many tmux sessions already running, we try attaching to an
# existing session.

# You might want to set the session name deliberately for different projects,
# especially if you end up configuring panes and windows specially.

fries_tmux_session_entitle_unless_attach_existing () {
  local currsess
  local sname="$(date +%Y-%m-%d)"
  local FRIES_TMUX_LIMIT=99

  _fries_tmux_session_entitle_unless_attach_existing () {
    # Check the TMUX environ and return now if this is not tmux starting.
    # NOTE: Return falsey indicating did not attach existing, so home-fries
    #       continues loading.
    [[ -z "${TMUX}" ]] && return 1

    # If the session is not a plain number (which indicates that the user
    # ran a plain `tmux`, and did not specify a session name), return 1 to
    # tell home-fries to stop loading, because something else afoot.
    _fries_tmux_is_unnamed_session || return 1

    # For plain tmux startup, assign session names deliberately
    _fries_tmux_entitle_or_reattach_session
  }

  _fries_tmux_is_unnamed_session () {
    # NOTE: From non-tmux terminal, display-message shows name of
    #       session with most recent activity! I.e., switch to one
    #       session and ``ls``, display-message from another term.
    #       will show that session.
    currsess=$(tmux display-message -p '#S')
    # tmux defaults to naming new sessions with a number (0, 1, 2, ...)
    # which is how we "know" if the 
    if ! echo "$currsess" | grep '^[0-9]\+$' > /dev/null; then
      # Session name not an expected number, so bail (user might be doing
      # something else?). Return 1 to continue home-fries startup.
      return 1
    fi
    return 0
  }

  _fries_tmux_entitle_or_reattach_session () {
    # First see if there's a session named with today's date;
    # if not, rename this session to today's date and done.
    if ! tmux has -t "${sname}" &> /dev/null; then
      tmux rename-session "${sname}"
      return 1  # Tell home-fries to continue loading.
    fi
    _fries_tmux_entitle10_or_reattach_session
  }

  _fries_tmux_entitle10_or_reattach_session() {
    # 2020-01-03: Getting weird: At n session or more, try using existing.
    # NOTE: The tmux-ls count is still 0 on first tmux session startup.

    local nsessns
    nsessns=$(tmux ls 2> /dev/null | wc -l)
    # From: Moby Word Lists by Grady Ward
    #   https://www.gutenberg.org/ebooks/3201
    if [[ ${nsessns} -gt ${FRIES_TMUX_LIMIT} ]] \
      || [[ ! -f ${HOME}/.fries/var/first-names-lengthX.txt ]] \
    ; then
      _fries_too_many_clients_tmux_switch_client
      # Don't continue Bash startup, we're good!
      # (Because we switched to existing client).
      return 0
    else
      _fries_tmux_rename_session_10lettername
      # We merely renamed the new, loading tmux session,
      # so tell home-fries to keep loading, too.
      return 1
    fi
  }

  _fries_too_many_clients_tmux_switch_client () {
    # Switch to existing tmux client.
    # NOTE: Cannot *attach* to session from within client, lest warning:
    #   $ tmux attach-session -t "${sname}"
    #   sessions should be nested with care, unset $TMUX to force
    # However, you can *switch* the client to the desired session, e.g.:
    #   $ tmux switch-client -t "${sname}"
    # PSA: You can also <C-b (> and <C-b )> to switch sessions
    #      (aka "switch client" -p/-n previous/next).
    # - Also, <C-b D>   to use interactive choose-client, or
    #         <C-b C-f> to enter fuzzy-findable session name, or
    #         <C-b L>   to toggle between most recent sessions.
    # NOTE: Because switching, any echoes herein go... where?
    echo "If you're reading this, I should be dead!"
    tmux switch-client -t "${sname}"
    # NOTE: (lb): Not sure why/how this works, but even after
    #       switch-client, echo goes to old terminal. So, e.g.,
    #         echo "Welcome to the Thunderdome!"
    #       would still print to the "${currsess}" session.
    tmux kill-session -t "${currsess}"
  }

  _fries_tmux_rename_session_10lettername () {
    # Get a random first name from the ten-character name list,
    # so the random name is as long as when we use a YYYY-MM-DD.
    local randname sname
    randname=$(shuf -n 1 ${HOME}/.fries/var/first-names-lengthX.txt)
    # To lower.
    sname=$(echo ${randname} | tr '[:upper:]' '[:lower:]')
    # Alternatively, to lower with awk:
    #   sname=$(echo ${randname} | awk '{print tolower($0)}')
    tmux rename-session "${sname}"
  }

  _fries_tmux_session_entitle_unless_attach_existing
}

tmux_jump_ship () {
  local retcode=1

  # Check the TMUX environ and return now if this is not tmux starting.
  # (Return falsey, because name of function implies "jump ship" if true/0.)
  [[ -z "${TMUX}" ]] && return ${retcode}

  fries_tmux_session_entitle_unless_attach_existing
  retcode=$?

  unset -f fries_tmux_session_entitle_unless_attach_existing

  return ${retcode}
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
  for unset_f in $(declare -F | grep '^declare -f unset_f_' | sed 's/^declare -f //'); do
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
      if [[ $(readlink -f "$(alias bash | sed 's/^.* ([^ ]+\/bash\>).*/\1/')") != '/bin/bash' ]]; then
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

  # Maybe don't startup and reuse existing tmux session, eh.
  if tmux_jump_ship; then
    return  # Will have run switch-client and user will be on another session.
  fi
  unset -f tmux_jump_ship

  source_deps
  unset -f source_deps

  # FIXME/2018-04-04: This is a hack until I figure out something better.
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


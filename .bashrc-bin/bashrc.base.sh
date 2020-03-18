# vim:tw=0:ts=2:sw=2:et:norl:ft=sh
# Author: Landon Bouma (landonb &#x40; retrosoft &#x2E; com)
# Project: https://github.com/landonb/home-fries#🍟
# License: MIT

# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #

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

# Ref: Copied from /etc/bash.bashrc [Ubuntu 18.04].
#  "If not running interactively, don't do anything"
[ -z "$PS1" ] && return

# (One could also check [[ $- != *i* ]],
# but not $(shopt login_shell), which is
# false via mate-terminal.

# Script Setup
# ============

bashrc_time_0=$(date +%s.%N)

# YOU: Uncomment to enable logging to stdout:
#  export DUBS_TRACE=${DUBS_TRACE:-true}
export DUBS_TRACE=${DUBS_TRACE:-false}

# YOU: Uncomment to show progress times.
#  DUBS_PROFILING=${DUBS_PROFILING:-true}
export DUBS_PROFILING=${DUBS_PROFILING:-false}
[ -n "${TMUX}" ] && DUBS_PROFILING=true

${DUBS_TRACE} && echo "User's EUID is ${EUID}"

# Get the path to this script's parent directory.
# Doesn't work?!:
#   hard_path=$(dirname $(readlink -f -- "$0"))
# Carnally related:
#   hard_path=$(dirname $(readlink -f ~/.bashrc))
# Universally Bashy:
hard_path="$(dirname $(readlink -f -- "${BASH_SOURCE[0]}"))"

# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #

# *** Profiling.

print_elapsed_time () {
  "${hard_path}/../bin/echo-elapsed" "$@"
}

# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #

ensure_pathed () {
  # HACK!
  # - Unset BASH_VERSION so ~/.profile doesn't load *us*!
  #   But updates PATH and LD_LIBRARY_PATH instead.
  local was_version
  was_version="${BASH_VERSION}"
  BASH_VERSION=""
  . "${HOME}/.profile"
  BASH_VERSION="${was_version}"
}

# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #

# System-wide Profile
# ===================

source_system_rc () {
  local time_0=$(date +%s.%N)

  # Source global definitions.
  if [ -f "/etc/bashrc" ]; then
    # Fedora.
    . /etc/bashrc
    print_elapsed_time "${time_0}" "Source: /etc/bashrc"
  elif [ -f "/etc/bash.bashrc" ]; then
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
  . "${hard_path}/bashrc.core.sh"

  print_elapsed_time "${time_0}" "Source: bashrc.core.sh" "==FRIES: "
}

# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #

# Machine-specific Profiles
# =========================

source_privately () {
  local srcfile="$1"
  local srctype="$2"
  if [ -f "${srcfile}" ]; then
    ${DUBS_TRACE} && echo "Loading ${srctype} resource script: ${srcfile}"
    local time_0=$(date +%s.%N)
    . "${srcfile}"
    print_elapsed_time "${time_0}" "Source: ${srcfile}"
  else
    ${DUBS_TRACE} && echo "Did not find a ${srctype} resource: ${srcfile}"
  fi
}

source_private_scripts () {
  # If present, local a private (uncommitted; symlinked?) bash profile script.
  local privsrc="${hard_path}/bashrx.private.sh"
  source_privately "${privsrc}" "private"

  # If present, load a machine-specific script.
  local privhost="${hard_path}/bashrx.private.$(hostname).sh"
  source_privately "${privhost}" "host-specific"

  # If present, load a user-specific script.
  local privuser="${hard_path}/bashrx.private.${LOGNAME}.sh"
  source_privately "${privuser}" "user-specific"
}

source_private () {
  # Load the machine-specific scripts first so their exports are visible.
  if [ ${EUID} -eq 0 ]; then
    # If the user is root, we'll just load the core script, and nothing fancy.
    ${DUBS_TRACE} && echo "User is root"
    return
  fi

  ${DUBS_TRACE} && echo "User is not root"
  source_private_scripts
}

# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #

# Additional Fancy -- Starting Directory and Kickoff Command
# ==========================================================

start_somewhere_something () {
  # Unless root, then boot.
  [ ${EUID} -eq 0 ] && return

  # See the script:
  #
  #   ~/.homefries/bin/termdub.py
  #
  # which sets the DUBS_* environment variables to tell us what
  # to do once a new terminal is ready. The three options are:
  #
  #   DUBS_STARTIN  -- Where to `cd`.
  #   DUBS_STARTUP  -- Some command to run.
  #   DUBS_TERMNAME -- Title of the terminal window.

  # Start out in the preferred development directory.
  if [ -n "${DUBS_STARTIN}" ]; then
    cd "${DUBS_STARTIN}"
  elif [ -d "${DUBS_STARTIN_DEFAULT}" ]; then
    cd "${DUBS_STARTIN_DEFAULT}"
  fi

  # See: ${hard_path}/.homefries/bin/openterms.sh for usage.
  if [ -n "${DUBS_STARTUP}" ]; then
    # Add the command we're about to execute to the command history (so if the
    # user Ctrl-C's the process, then can easily re-execute it).
    # See also: history -c, which clears the history.
    history -s "${DUBS_STARTUP}"
    # Run the command.
    # FIXME: Does this hang the startup script? I.e., we're running the command
    #        from this script... so this better be the last command we run!
    local time_0=$(date +%s.%N)
    eval "${DUBS_STARTUP}"
    print_elapsed_time "${time_0}" "eval: DUBS_STARTUP"
  fi

  # The variables have served us well; now whack 'em.
  export DUBS_STARTIN=''
  export DUBS_STARTUP=''
  export DUBS_TERMNAME=''
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
  if ( [ ! -z ${SSH_ENV_FRESH+x} ] && ${SSH_ENV_FRESH} ) \
     || ( ( [ "${TERM}" = "screen" ] || \
            [ "${TERM}" = "screen-256color" ] ) \
          && [ -n "${TMUX}" ] ) \
     || ( ${DUBS_TRACE} || ${DUBS_PROFILING} ) \
  then
    bashrc_time_n=$(date +%s.%N)
    time_elapsed=$(\
      echo "${bashrc_time_n} - ${bashrc_time_0}" | bc -l | xargs printf "%.2f" \
    )

    # NOTE: Startup scripts will have wired PATH so logger will be found.
    . logger.sh
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
  if [ "$0" = 'bash' ] || [ "$0" = '-bash' ]; then
    if $(alias bash &> /dev/null); then
      if [ "$(readlink -f "$(alias bash | /bin/sed -E 's/^.* ([^ ]+\/bash\>).*/\1/')")" != '/bin/bash' ]; then
        custom_bash=true
      fi
    elif [ "$(readlink -f "$(command -v bash)")" != '/bin/bash' ]; then
      custom_bash=true
    fi
  elif [ "$(readlink -f "$0")" != '/bin/bash' ]; then
    custom_bash=true
  fi
  if ${custom_bash}; then
    notice "This bash is a ${FG_LIGHTGREEN}${MK_LINE}special${RESET_UNDERLINED} bash!${MK_NORM}" \
      "Version: ${FG_LIGHTYELLOW}${MK_LINE}${MK_BOLD}${BASH_VERSION}"
  fi

  print_elapsed_time "${time_0}" "cleanup"
}

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

  source_system_rc
  unset -f source_system_rc

  # FIXME/2018-04-04: This is a hack until I figure out something better.
  # - It exports an environment variable I need in source_fries.
  export HOME_FRIES_PRELOAD=true
  source_private

  source_fries
  unset -f source_fries

  export HOME_FRIES_PRELOAD=false
  source_private
  unset -f source_private

  start_somewhere_something
  unset -f start_somewhere_something

  home_fries_bashrc_cleanup
  unset -f home_fries_bashrc_cleanup

  print_elapsed_time "${time_0}" "bashrc.bash.sh" "==TOTAL: "
}

main "$@"


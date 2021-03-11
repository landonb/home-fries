# vim:tw=0:ts=2:sw=2:et:norl:ft=bash
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
# System first:    /etc/bash.bashrc
# Then private:   ./bashrx.private.sh
#  (optional)     ./bashrx.private.$HOSTNAME.sh
#                 ./bashrx.private.$LOGNAME.sh
# Lib is last:    ./bashrc.core.sh
#                    (which sources ../lib/*.sh files)

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

home_fries_nanos_now () {
  if command -v gdate > /dev/null 2>&1; then
    # macOS (brew install coreutils).
    gdate +%s.%N
  elif date --version > /dev/null 2>&1; then
    # Linux/GNU.
    date +%s.%N
  else
    # macOS pre-coreutils.
    python -c 'import time; print("{:.9f}".format(time.time()))'
  fi
}

HOMEFRIES_TIME0="$(home_fries_nanos_now)"

# YOU: Uncomment to enable logging to stdout:
#  export HOMEFRIES_TRACE=${HOMEFRIES_TRACE:-true}
export HOMEFRIES_TRACE=${HOMEFRIES_TRACE:-false}

# YOU: Uncomment to show progress times.
#  export HOMEFRIES_PROFILING=${HOMEFRIES_PROFILING:-true}
export HOMEFRIES_PROFILING=${HOMEFRIES_PROFILING:-false}
# YOU: Uncomment to show all or more startup function timings, otherwise
#      only tasks that take longer than it (e.g., 0.12 secs.) are traced.
#      - Note also the `export`, because echo-elapsed is its own fcn.
#  export HOMEFRIES_PROFILE_THRESHOLD=${HOMEFRIES_PROFILE_THRESHOLD:-0}
#  # Or perhaps with a tiny bit of filtering:
#  export HOMEFRIES_PROFILE_THRESHOLD=${HOMEFRIES_PROFILE_THRESHOLD:-0.01}

# 2020-03-19: (lb): For tmux, which already has bells and whistles
# of its own, like a status bar, show a series of dots for each
# bashrc task performed, than reset the line before showing the
# prompt (so if user looked away during logon they wouldn't see
# any evidence or trace of the dots afterwards).
# - Note that I tried non ASCII here, the `Sb` digraph, '∙',
#   but the for unknown reasons I ended up with 2 newlines
#   before prompt. So sticking with a simple dot, '.', here.
[ -n "${TMUX}" ] && HOMEFRIES_LOADINGDOTS=${HOMEFRIES_LOADINGDOTS:-true}
export HOMEFRIES_LOADINGDOTS=${HOMEFRIES_LOADINGDOTS:-false}
HOMEFRIES_LOADEDDOTS=''
HOMEFRIES_LOADINGSEP='.'

${HOMEFRIES_TRACE} && echo "─ Welcome, User (EUID=${EUID})"

# Get the path to this script's parent directory.
# Note that macOS's readlink is wicked old.
# INTEREST/2020-09-23: From `man readlink`:
#   Note realpath(1) is the preferred command to use for canonicalization functionality.
# but also realpath is from Homebrew... so question is, how much do we care
# to support Bash 3.x (or to work on vanilla macOS). Though maybe Zsh is the
# answer if we want to support vanilla macOS, and for our Bash scripts we
# should just assume 4.x+ and use `realpath`.
readlink_f () {
  local resolve_path="$1"
  local ret_code=0
  if [ "$(readlink --version 2> /dev/null)" ]; then
    # Linux: Modern readlink.
    resolve_path="$(readlink -f -- "${resolve_path}")"
  else
    # macOHHHH-ESS/macOS: No `readlink -f`.
    local before_cd="$(pwd -L)"
    local just_once=true
    while [ -n "${resolve_path}" ] && ( [ -h "${resolve_path}" ] || ${just_once} ); do
      just_once=false
      local basedir_link="$(dirname -- "${resolve_path}")"
      # `readlink -f` checks all but final component exist.
      # So if dir path leading to final componenet missing, return empty string.
      if [ ! -e "${basedir_link}" ]; then
        resolve_path=""
        ret_code=1
      else
        local resolve_file="${resolve_path}"
        local resolve_link="$(readlink -- "${resolve_path}")"
        if [ -n "${resolve_link}" ]; then
          case "${resolve_link}" in
            /*)
              # Absolute path.
              resolve_file="${resolve_link}"
              ;;
            *)
              # Relative path.
              resolve_file="${basedir_link}/${resolve_link}"
              ;;
          esac
        fi
        local resolved_dir="$(dirname -- "${resolve_file}")"
        if [ ! -d "${resolved_dir}" ]; then
          resolve_path=""
          ret_code=1
        else
          cd "${resolved_dir}" > /dev/null
          resolve_path="$(pwd -P)/$(basename -- "${resolve_file}")"
        fi
      fi
    done
    cd "${before_cd}"
  fi
  [ -n "${resolve_path}" ] && echo "${resolve_path}"
  return ${ret_code}
}

export HOMEFRIES_BASHRCBIN="$(dirname -- "$(readlink_f "${BASH_SOURCE[0]}")")"
${HOMEFRIES_TRACE} && echo "── HOMEFRIES_BASHRCBIN=${HOMEFRIES_BASHRCBIN}"

# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #

# *** Profiling.

print_elapsed_time () {
  "${HOMEFRIES_BASHRCBIN}/../bin/echo-elapsed" "$@"
}

print_loading_dot () {
  ${HOMEFRIES_LOADINGDOTS:-false} || return
  ${HOMEFRIES_TRACE:-false} && return
  # 2020-09-26: Try to avoid wrapping to a new line, because
  # then the '\r' later won't work as intended (it'll leave
  # previous lines of dots visible).
  # - Alt to `${#VAR}` → `expr length "${VAR}"`
  if [ ${#HOMEFRIES_LOADEDDOTS} -ge ${HOMEFRIES_LOADDOTSLIMIT:-77} ]; then
    cleanup_loading_dots
  fi
  printf %s "${HOMEFRIES_LOADINGSEP}"
  HOMEFRIES_LOADEDDOTS="${HOMEFRIES_LOADEDDOTS}${HOMEFRIES_LOADINGSEP}"
}

cleanup_loading_dots () {
  local time_0="$1"

  ${HOMEFRIES_LOADINGDOTS:-false} || return
  printf '\r'
  printf "${HOMEFRIES_LOADEDDOTS}" | tr "${HOMEFRIES_LOADINGSEP}" ' '
  printf '\r'
  HOMEFRIES_LOADEDDOTS=''

  flash_elapsed () {
    [ -n "${time_0}" ] || return
    local elapsed
    elapsed="$(HOMEFRIES_PROFILING= "${HOMEFRIES_BASHRCBIN}/../bin/echo-elapsed" "${time_0}")"
    printf "${elapsed} "
    sleep 0.666
    printf '\r'
    printf "${elapsed}" | /usr/bin/env sed 's/./ /'
    printf '\r'
  }
  # YOU: Uncomment for quick, forgettable elapsed display.
  #  flash_elapsed
}

# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #

ensure_pathed () {
  # HACK!
  # - Unset BASH_VERSION so ~/.profile doesn't load *us*!
  #   The script will update PATH and LD_LIBRARY_PATH instead.
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
  local time_0="$(home_fries_nanos_now)"

  # Source global definitions.
  local sys_rc
  if [ -f "/etc/bashrc" ]; then
    # Fedora.
    sys_rc="/etc/bashrc"
  elif [ -f "/etc/bash.bashrc" ]; then
    # Debian/Ubuntu.
    sys_rc="/etc/bash.bashrc"
  fi

  if [ -n "${sys_rc}" ]; then
    ${HOMEFRIES_TRACE} && echo "──┬ Loading OS system scripts"
    ${HOMEFRIES_TRACE} && echo "   . FRIES: ${sys_rc}"
    . "${sys_rc}"
    print_elapsed_time "${time_0}" "Source: ${sys_rc}"
    ${HOMEFRIES_TRACE} && echo "  └─"
  fi
}

# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #

# Bash Setup Included in This Repo (lib/)
# =======================================

source_fries () {
  local time_0="$(home_fries_nanos_now)"

  ${HOMEFRIES_TRACE} && echo "──┬ Loading Homefries scripts"

  # Common Bash standup. Defines aliases, configures things,
  # adjusts the terminal prompt, and adds a few functions.
  . "${HOMEFRIES_BASHRCBIN}/bashrc.core.sh"

  print_elapsed_time "${time_0}" "Source: bashrc.core.sh" "==FRIES: "

  ${HOMEFRIES_TRACE} && echo "  └─"
}

# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #

# Bash Setup You Provide (Private and/or User-/Machine-Specific)
# ==============================================================

source_privately () {
  local srcfile="$1"
  local srctype="$2"
  if [ -f "${srcfile}" ]; then
    ${HOMEFRIES_TRACE} && echo "  ├─ Loading from a ${srctype} resource: ✓ ${srcfile}"
    local time_0="$(home_fries_nanos_now)"
    . "${srcfile}"
    # To allow monkey-patching, private source can have us call its main.
    if declare -f _homefries_private_main > /dev/null; then
      _homefries_private_main
      unset -f _homefries_private_main
    fi
    print_elapsed_time "${time_0}" "Source: ${srcfile}"
  else
    ${HOMEFRIES_TRACE} && echo "  ├─ Did not find a ${srctype} resource: ✗ ${srcfile}"
  fi
}

source_private_scripts () {
  # If present, local a private (uncommitted; symlinked?) bash profile script.
  local privsrc="${HOMEFRIES_BASHRCBIN}/bashrx.private.sh"
  source_privately "${privsrc}" "non-exclusive"

  # If present, load a machine-specific script.
  local privhost="${HOMEFRIES_BASHRCBIN}/bashrx.private.$(hostname).sh"
  source_privately "${privhost}" "host-specific"

  # If present, load a user-specific script.
  local privuser="${HOMEFRIES_BASHRCBIN}/bashrx.private.${LOGNAME}.sh"
  source_privately "${privuser}" "user-specific"
}

source_private () {
  # Load the machine-specific scripts first so their exports are visible.
  if [ ${EUID} -eq 0 ]; then
    # If the user is root, we'll just load the core script, and nothing fancy.
    ${HOMEFRIES_TRACE} && echo "── Skipping private scripts (User is root)"
    return
  fi

  if ${HOMEFRIES_TRACE}; then
    local msg_adj
    ${HOME_FRIES_PRELOAD} && msg_adj='Preceding' || msg_adj='Following'
    echo "──┬ Loading ${msg_adj} scripts"
  fi

  # ${HOMEFRIES_TRACE} && echo "User is not root"
  source_private_scripts

  ${HOMEFRIES_TRACE} && echo "  └─"
}

# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #

# Additional Fancy -- Starting Directory and Kickoff Command
# ==========================================================

start_somewhere_something () {
  # Unless root, then boot. I.e., ${EUID} -eq 0.
  [ $(id -u) -eq 0 ] && return

  # See the script:
  #
  #   ~/.homefries/bin/termdub.py
  #
  # which sets the HOMEFRIES_* environment variables to tell us what
  # to do once the new session is ready. The three options are:
  #
  #   HOMEFRIES_CD  -- Where to `cd`.
  #   HOMEFRIES_EVAL  -- Some command to run.
  #   HOMEFRIES_TITLE -- Title of the terminal window.

  # Start out in the preferred development directory.
  if [ -n "${HOMEFRIES_CD}" ]; then
    cd "${HOMEFRIES_CD}"
  elif [ -d "${HOMEFRIES_CD_DEFAULT}" ]; then
    cd "${HOMEFRIES_CD_DEFAULT}"
  fi

  # See: ${HOMEFRIES_BASHRCBIN}/.homefries/bin/openterms.sh for usage.
  if [ -n "${HOMEFRIES_EVAL}" ]; then
    # Add the command we're about to execute to the command history (so if the
    # user Ctrl-C's the process, then can easily re-execute it).
    # See also: history -c, which clears the history.
    history -s "${HOMEFRIES_EVAL}"
    # Run the command.
    # FIXME: Does this hang the startup script? I.e., we're running the command
    #        from this script... so this better be the last command we run!
    local time_0="$(home_fries_nanos_now)"
    eval "${HOMEFRIES_EVAL}"
    print_elapsed_time "${time_0}" "eval: HOMEFRIES_EVAL"
  fi

  # The variables have served us well; now whack 'em.
  unset -v HOMEFRIES_CD
  unset -v HOMEFRIES_EVAL
  unset -v HOMEFRIES_TITLE
}

# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #

# Cleanup
# =======

home_fries_bashrc_cleanup () {
  local time_0="$(home_fries_nanos_now)"

  # Run the sourced-scripts' cleanup functions, to un-declare functions
  # (and remove cruft from user's environment).
  for unset_f in $(declare -F | grep '^declare -f unset_f_' | /usr/bin/env sed 's/^declare -f //'); do
    # Call all functions that begin with "unset_f_",
    # e.g., unset_f_alias_rg_tag, unset_f_alias_ohmyrepos, etc.
    eval "${unset_f}"
  done

  # Show startup stats if user already tracing, or if profiling bashrc.
  if ${HOMEFRIES_TRACE:-false} || ${HOMEFRIES_PROFILING:-false}; then
    local bashrc_time_n="$(home_fries_nanos_now)"
    local time_elapsed=$(\
      echo "${bashrc_time_n} - ${HOMEFRIES_TIME0}" | bc -l | xargs printf "%.2f" \
    )

    # NOTE: Startup scripts will have wired PATH so logger will be found.
    if command -v 'logger.sh' > /dev/null 2>&1; then
      local old_level=${LOG_LEVEL}
      export LOG_LEVEL=${LOG_LEVEL_NOTICE}
      notice "home-fries start-up: ${time_elapsed} secs."
      export LOG_LEVEL=${old_level}
    fi
  fi

  # Tell user when running non-standard Bash.
  # E.g., when on local terminal invoked by launcher and running mate-terminal,
  #   $0 == '/user/home/.local/bin/bash'
  # and when on remote terminal over ssh,
  #   $0 == '-bash'
  local custom_bash=false
  if [ "$0" = 'bash' ] || [ "$0" = '-bash' ]; then
    if $(alias bash &> /dev/null); then
      # if [ "$(readlink -f "$(alias bash | /usr/bin/env sed -E 's/^.* ([^ ]+\/bash\>).*/\1/')")" != '/bin/bash' ]; then
      if [ "$(readlink_f "$(alias bash | /usr/bin/env sed -E 's/^.* ([^ ]+\/bash\>).*/\1/')")" != '/bin/bash' ]; then
        custom_bash=true
      fi
    # elif [ "$(readlink -f "$(command -v bash)")" != '/bin/bash' ]; then
    elif [ "$(readlink_f "$(command -v bash)")" != '/bin/bash' ]; then
      custom_bash=true
    fi
  # elif [ "$(readlink -f "$0")" != '/bin/bash' ]; then
  elif [ "$(readlink_f "$0")" != '/bin/bash' ]; then
    custom_bash=true
  fi
  if ${custom_bash}; then
    if command -v 'logger.sh' > /dev/null 2>&1; then
      notice "This bash is a $(fg_lightgreen)$(attr_underline)special$(res_underline) bash!$(attr_reset)" \
        "Version: $(fg_lightyellow)$(attr_underline)$(attr_bold)${BASH_VERSION}$(attr_reset)"
    fi
  fi

  print_elapsed_time "${time_0}" "cleanup"
}

# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #

environ_cleanup () {
  # OCD cleanup to not pollute user's namespace (à la `env`, `set`, etc.).

  unset -v HOMEFRIES_TIME0

  unset -v HOMEFRIES_TRACE

  # Unset so calling echo-elapsed works without threshold being met.
  unset -v HOMEFRIES_PROFILING

  unset -v HOMEFRIES_LOADINGDOTS
  unset -v HOMEFRIES_LOADINGSEP
  unset -v HOMEFRIES_LOADEDDOTS
  unset -f print_loading_dot

  unset -v HOMEFRIES_BASHRCBIN

  # Self Disembowelment.
  unset -f main
  unset -f environ_cleanup
}

# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #

main () {
  local time_0="$(home_fries_nanos_now)"

  # Add ~/.local/bin to PATH, and ~/.local/lib to LD_LIBRARY_PATH,
  # which we need because that's where my custom tmux et al is at.
  ensure_pathed
  unset -f ensure_pathed
  # Maybe don't startup and reuse existing tmux session, eh.
  if source ${HOMEFRIES_BASHRCBIN}/prepare-tmux-or-bust; then
    return  # Will have run switch-client and user will be on another session.
  fi

  source_system_rc
  unset -f source_system_rc

  # FIXME/2018-04-04: This is a hack until I figure out something better.
  # - It exports an environment variable I need in source_fries.
  export HOME_FRIES_PRELOAD=true
  source_private

  # This sources bashrc.core.sh.
  source_fries
  unset -f source_fries

  export HOME_FRIES_PRELOAD=false
  source_private
  unset -f source_private
  unset -v HOME_FRIES_PRELOAD

  cleanup_loading_dots "${time_0}"
  unset -f cleanup_loading_dots

  start_somewhere_something
  unset -f start_somewhere_something

  home_fries_bashrc_cleanup
  unset -f home_fries_bashrc_cleanup

  print_elapsed_time "${time_0}" "bashrc.bash.sh" "==TOTAL: "
  unset -f print_elapsed_time

  # Cover our tracks!
  environ_cleanup
}

main "$@"


# vim:tw=0:ts=2:sw=2:et:norl:ft=bash
# Author: Landon Bouma (landonb &#x40; retrosoft &#x2E; com)
# Project: https://github.com/landonb/home-fries#🍟
# License: MIT

# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #

# *** Overview
#
# This script loads bashrc startup/profile scripts.

# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #

# *** Load order FYI
#
# First system:   /etc/bash.bashrc
# Then private:   ./bashrx.private.sh
#  (optional)     ./bashrx.private.$HOSTNAME.sh
#                 ./bashrx.private.$LOGNAME.sh
# Lastly libs:    ./bashrc.core.sh
#                    (which sources ../lib/*.sh files)

# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #

# *** Do nothing unless interactive

# Ref: Copied from /etc/bash.bashrc [Ubuntu 18.04].
#  "If not running interactively, don't do anything"

# (One could also check [[ $- != *i* ]],
#  but not $(shopt login_shell),
#  which is false via mate-terminal.)

[ -z "$PS1" ] && return

# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #

# *** Developer options to enable trace and profiling

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

# YOU: Adjust this as necessary according to taste.
# - Homefries is quiet on startup (when nothing to alert), but
#   sometimes it's nice to receive a hello once loaded (and to
#   see the Bash version and how long Homefries took to load).
export HOMEFRIES_HELLO=${HOMEFRIES_HELLO:-true}

# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #

# *** Oh hi doggy

${HOMEFRIES_TRACE} && echo "─ Welcome, User (EUID=${EUID})"

# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #

# *** Prepare loading dots, if tmux

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

# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #

# In lieu of typical check_deps, alert_deps, because we're forgiving.
alert_deps () {
  maybe_alert_ancient_bash
  unset -f maybe_alert_ancient_bash

  maybe_alert_missing_realpath
  unset -f maybe_alert_missing_realpath
}

# *** Die → Warn → Echo → Do Nothing if Bash v3
#
# Historically, Homefries would "Die early, Die often!", it said, if
# started in Bash v3, because Homefries had been developed on Linux
# (where Bash v4 had been standard for eons, before v5), and if run on
# macOS (which ships with Bash v3), we could just demand Homefries Bash
# (which is v5). Then the author got an Apple Silicon/M1 MacBook through
# a contract gig [circa 2022] and found that Homebrew Bash v5 was con-
# foundingly underperforming, but that Bash v3 ran fast. So I began to
# backpatch Homefries to v3-compatibilty (and POSIX compliance!) as issues
# were discovered. (This was a reactive effort, where I fixed things when
# I tried to use them but they failed; it was not a proactive code audit.)
# Fortunately, most of the Homefries features that were Bash v4+ were just
# using associate arrays, which are easy to downcode using flat arrays,
# and whatever v4+ code might remain is hiding in rarely-used features.

# 2023-01-26: I'm confident we no longer should alert on Bash v3 -- and
# maybe someday I'll shake my code-hoarding tendencies and we'll remove
# the now-pointless `maybe_alert_ancient_bash` check.
HOMEFRIES_ALERT_BASH3_OR_LESSER=${HOMEFRIES_ALERT_BASH3_OR_LESSER:-false}

maybe_alert_ancient_bash () {
  ${HOMEFRIES_ALERT_BASH3_OR_LESSER:-false} || return 0

  # Note that we call `bash` itself rather than check ${BASH_VERSINFO[0]},
  # because macOS will load its own Bash 3, while Homebrew's Bash 5 might
  # be what's on PATH.
  # - I.e., the user called `eval $(/opt/homebrew/bin/brew shellenv)`
  #   and then called `bash` to load Homefries.
  # - Here's the naïve check, just FYÏ:
  #     [ ${BASH_VERSINFO[0]} -ge 4 ] && command -v realpath > /dev/null && return
  local bash_vers="$(bash --version | head -1 | sed -r 's/GNU bash, version ([0-9]+).*/\1/')"

  [ ${bash_vers} -lt 4 ] || return 0

  >&2 echo "ALERT: Running atop Bash v${bash_vers}" \
    "(where a few rarely-used Homefries features won't work)"
}

# ***

# Alert if realpath absent.
# - Homefries used to use `readlink -f`, but (basic) `realpath` is
#   more widely available now (just don't use `realpath -m` or
#   `realpath -s`, which don't work with newish macOS built-in
#   `realpath`, which was added to macOS 13 (Ventura)).

maybe_alert_missing_realpath () {
  if command -v realpath > /dev/null; then

    return 0
  fi

  # Expect errors during startup, but keep trying anyway.
  >&2 echo "BWARE: Missing \`realpath\`"
}

# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #

# *** Get the path to Homefries, so we can use relative paths

# Get the path to this script's parent directory.
# - Requires coreutils' `realpath`.
#   See previous Bash version and coreutils check-and-die.

export HOMEFRIES_BASHRCBIN="$(dirname -- "$(realpath -- "${BASH_SOURCE[0]}")")"
${HOMEFRIES_TRACE} && echo "── HOMEFRIES_BASHRCBIN=${HOMEFRIES_BASHRCBIN}"

# ***

# *** Load profiling function

source_dep_print_nanos_now () {
  local path="${HOMEFRIES_BASHRCBIN}/../deps/sh-print-nanos-now/bin/print-nanos-now.sh"

  if [ -f "${path}" ]; then
    . "${path}"
  else
    >&2 echo "ERROR: Where's the sh-print-nanos-now dependency?"
    # This is unlikely, because the dependency is packaged with Homefries.
    # But we might as well offer a shim, so the code can still load.
    print_nanos_now () { printf '0'; }
    export -f print_nanos_now
  fi
}

# ***

# *** Begin profiling

source_dep_print_nanos_now
unset -f source_dep_print_nanos_now

HOMEFRIES_TIME0="$(print_nanos_now)"

# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #

# *** Profiling.

print_elapsed_time () {
  # CXREF: ~/.kit/sh/home-fries/bin/echo-elapsed
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

# *** Update PATH and LD_LIBRARY_PATH (e.g., wire ~/.local/bin)

ensure_pathed () {
  # BWARE: Use HOMEFRIES_STARTUP so ~/.profile doesn't load *us*!
  # - Likewise, check if ~/.profile is calling us:
  #   - When opening new terminal, ~/.profile is not sourced,
  #     except here.
  #   - When `ssh <host>`, whether local or remote, ~/.profile
  #     is sourced first, which sources us.
  ! ${HOMEFRIES_STARTUP:-false} || return 0

  HOMEFRIES_STARTUP=true . "${HOME}/.profile"
}

# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #

# *** Load system profile

source_system_rc () {
  local time_0="$(print_nanos_now)"

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
    ${HOMEFRIES_TRACE} && echo "  └ . HFRIES: ${sys_rc}"
    . "${sys_rc}"
    print_elapsed_time "${time_0}" "Source: ${sys_rc}"
  fi
}

# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #

# *** Load Homefries scripts

source_fries () {
  local time_0="$(print_nanos_now)"

  ${HOMEFRIES_TRACE} && echo "──┬ Loading Homefries scripts"

  # Common Bash standup. Defines aliases, configures things,
  # adjusts the terminal prompt, and adds a few functions.
  # - CXREF: ~/.kit/sh/home-fries/.bashrc-bin/bashrc.core.sh
  _SOURCE_IT_FINIS_OUTER=true _hf_bashrc_core

  print_elapsed_time "${time_0}" "Source: bashrc.core.sh (total)" "==HFRIES: "
}

# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #

# *** Load private scripts (DEV's user- and machine-specific scripts)

source_privately () {
  local srcfile="$1"
  local srctype="$2"

  if [ -f "${srcfile}" ]; then
    ${HOMEFRIES_TRACE} && echo "  ├─ Loading private “${srctype}” file: ✓ ${srcfile}"
    local time_0="$(print_nanos_now)"

    . "${srcfile}"

    # To enable monkey-patching home-fries, private source can have us call it.
    # - See below for alternative mechanism that allows private Bashrc
    #   to monkey patch (override) other private Bashrc (not just HF).
    if declare -f _homefries_private_main > /dev/null; then
      _homefries_private_main
      unset -f _homefries_private_main
    fi

    print_elapsed_time "${time_0}" "Source: ${srcfile}"
  else
    ${HOMEFRIES_TRACE} && echo "  ├─ Lacking private “${srctype}” file: ✗ ${srcfile}"
  fi
}

# To give the client more control, here's another private function call hook.
# - After sourcing each of the private files, we'll call a special "main"
#   function for each file.
#   - This lets a later private Bashrc override or monkey-patch an earlier
#     one, e.g., the `bashrx.private.USER.sh` could redefine a function from
#     the upstream (so to speak) `bashrx.private.sh` to customize it.
#   - For a real-world example, see the DepoXy project, which uses the
#     'bashrx.private.sh' file, and installs a 'bashrx.private.USER.sh'
#     file for the user to customize.
invoke_privately () {
  local _srcfile="$1"  # ignored
  local srctype="$2"

  # E.g., _homefries_private_main_core
  #       _homefries_private_main_host
  #       _homefries_private_main_user
  local main_fcn="_homefries_private_main_${srctype}"

  local piping=" ├"

  if declare -f ${main_fcn} > /dev/null; then
    ${HOMEFRIES_TRACE} && echo " ${piping}─ Calling private “${srctype}” callback: ✓ ${main_fcn}"
    local time_0="$(print_nanos_now)"
    ${main_fcn}
    unset -f ${main_fcn}
    print_elapsed_time "${time_0}" "Invoked: ${srcfile}"
  else
    ! ${_SOURCE_IT_FINIS_OUTER:-false} || piping=" └"

    ${HOMEFRIES_TRACE} && echo " ${piping}─ Lacking private “${srctype}” callback: ✗ ${main_fcn}"
  fi
}

source_private_scripts () {
  # Private Bashrc, generally symlinked into Home-fries (and Git-ignored
  # via .git/exclude/info, which is also generally symlinked to the same
  # private repo that contains the private Bashrc being symlinked).

  # If present, load each of these private bash profile scripts.
  local privcore="${HOMEFRIES_BASHRCBIN}/bashrx.private.sh"
  local privhost="${HOMEFRIES_BASHRCBIN}/bashrx.private.$(hostname).sh"
  local privuser="${HOMEFRIES_BASHRCBIN}/bashrx.private.${LOGNAME}.sh"

  for func in source_privately invoke_privately; do
    ${func} "${privcore}" "core"
    ${func} "${privhost}" "host"
    _SOURCE_IT_FINIS_OUTER=$(test ${func} = "invoke_privately" && echo true || echo false) \
    ${func} "${privuser}" "user"
  done
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
}

# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #

# *** Optional final steps: Change to starting directory, and/or Run user command

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
    local time_0="$(print_nanos_now)"
    eval "${HOMEFRIES_EVAL}"
    print_elapsed_time "${time_0}" "eval: HOMEFRIES_EVAL"
  fi

  # The variables have served us well; now whack 'em.
  unset -v HOMEFRIES_CD
  unset -v HOMEFRIES_EVAL
  unset -v HOMEFRIES_TITLE
}

# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #

# *** Bashrc cleanup

home_fries_bashrc_cleanup () {
  local time_0="$(print_nanos_now)"

  # Run the sourced-scripts' cleanup functions, to un-declare functions
  # (and remove cruft from user's environment).
  for unset_f in $(declare -F | grep '^declare -f unset_f_' | /usr/bin/env sed 's/^declare -f //'); do
    # Call all functions that begin with "unset_f_",
    # e.g., unset_f_alias_rg_tag, unset_f_alias_ohmyrepos, etc.
    eval "${unset_f}"
  done

  # Show startup stats if user already tracing, or if profiling bashrc.
  if ${HOMEFRIES_TRACE:-false} || ${HOMEFRIES_PROFILING:-false}; then
    local bashrc_time_n="$(print_nanos_now)"
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
  #   $0 == '/home/user/.local/bin/bash'
  # and when on remote terminal over ssh,
  #   $0 == '-bash'
  local bash_path=""
  if [ "$0" = 'bash' ] || [ "$0" = '-bash' ]; then
    if $(alias bash &> /dev/null); then
      # Parse the alias, e.g.,
      #   alias bash='HOMEFRIES_CD="$(pwd)" PROMPT_COMMAND= bash'
      bash_path="$(alias bash | /usr/bin/env sed -E 's/^.* ([^ ]*\/?bash\>).*$/\1/')"
      # Note that if the alias uses a relative path, e.g.,
      # just `bash`, then `realpath bash` returns `$(pwd)/bash`.
      if [ "${bash_path}" = 'bash' ]; then
        # The first `bash` that `type` reports is the alias, and
        # the second `bash` reported is the one the alias calls.
        bash_path="$(type -a "${bash_path}" | head -2 | tail -1 | awk '{ print $3 }')"
      else
        bash_path="$(realpath -- "${bash_path}")"
      fi
    else
      bash_path="$(realpath -- "$(command -v bash)")"
    fi
  else
    bash_path="$(realpath -- "$0")"
  fi

  local print_msg_special=false
  local print_msg_version=${HOMEFRIES_HELLO:-false}
  local print_specially=echo

  # Alert user if "special" (probably custom-built) Bash by checking not
  # /bin/bash and not Homebrew Bash (which starts with /opt/homebrew, as
  # in, e.g., /opt/homebrew/Cellar/bash/5.2.15/bin/bash).
  if true \
    && [ "${bash_path}" != '/bin/bash' ] \
    && [ "${bash_path}" != '/usr/bin/bash' ] \
    && [ "${bash_path}" = "${bash_path#${HOMEBREW_PREFIX}}" ] \
  ; then
    print_msg_special=true

    print_specially=notice
    command -v 'logger.sh' > /dev/null 2>&1 || print_specially=echo
  fi

  if ${print_msg_special} || ${print_msg_version}; then
    # The BASH_VERSION includes an uninteresting prefix, e.g, consider
    #   $ echo ${BASH_VERSION}
    #   5.2.15(1)-release
    # Where "(1)-release" is probably always the same for Homebrew and
    # distro releases (I think the "(1)" is for the Homebrew/OS hotfix,
    # which would be rare; and "-release" is, I dunno, something related
    # to the release process).
    # - Bash release history shows up to just the first path, e.g.,
    #     Age         Commit message
    #     2022-12-13  Bash-5.2 patch 15: fix ...
    #   - CXREF: http://git.savannah.gnu.org/cgit/bash.git/log/
    # - SPIKE: What's the version for a local build look like?
    # - In any case, for brevity and noise-reduction, omit the postfix.
    local bash_version
    bash_version="$(echo "${BASH_VERSION}" | sed 's/(1)-release$//')"

    if ${print_msg_special}; then
      ${print_specially} \
        "This ${bash_path} is a $(fg_lightgreen)$(attr_underline)special$(res_underline) bash!$(attr_reset)" \
        "Version: $(fg_lightyellow)$(attr_underline)$(attr_bold)${bash_version}$(attr_reset)"
    fi

    if ${print_msg_version}; then
      local elapsed_time
      elapsed_time=$(HOMEFRIES_PROFILING=true HOMEFRIES_PROFILE_THRESHOLD=0 \
                     print_elapsed_time "${HOMEFRIES_TIME0}" "" "" "s")

      echo \
        "$(fg_lightgreen)Welcome to $(fg_yellow)Homefries on Bash" \
        "$(attr_underline)$(attr_bold)$(fg_blue)${bash_version}$(attr_reset)" \
        "$(fg_darkgray)${elapsed_time}$(attr_reset)"
    fi
  fi

  print_elapsed_time "${time_0}" "cleanup"
}

# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #

# *** Environment cleanup

environ_cleanup () {
  # OCD cleanup to not pollute user's namespace (à la `env`, `set`, etc.).

  # From ~/.kit/sh/home-fries/.bashrc-bin/bashrc.core.sh
  # - Waited until now so user can use in their private Bashrc.
  _hf_cleanup_core
  unset -f _hf_cleanup_core

  unset -v HOMEFRIES_TRACE

  # This unset also allows echo-elapsed to work without threshold being met.
  unset -v HOMEFRIES_PROFILING

  unset -v HOMEFRIES_HELLO

  unset -v HOMEFRIES_ALERT_BASH3_OR_LESSER

  unset -v HOMEFRIES_BASHRCBIN

  unset -v HOMEFRIES_TIME0

  unset -v HOMEFRIES_LOADINGDOTS
  unset -v HOMEFRIES_LOADINGSEP
  unset -v HOMEFRIES_LOADEDDOTS
  unset -f print_elapsed_time
  unset -f print_loading_dot

  # Self Disembowelment.
  unset -f main
  unset -f environ_cleanup
}

# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #

main () {
  alert_deps
  unset -f alert_deps

  # ***

  local time_0="$(print_nanos_now)"

  # Add ~/.local/bin to PATH, and ~/.local/lib to LD_LIBRARY_PATH,
  # which we need because that's where my custom tmux et al is at.
  ensure_pathed
  unset -f ensure_pathed
  # Maybe don't startup and reuse existing tmux session, eh.
  if . ${HOMEFRIES_BASHRCBIN}/prepare-tmux-or-bust; then
    return  # Will have run switch-client and user will be on another session.
  fi

  source_system_rc
  unset -f source_system_rc

  # Load source_it* fcns for client to use.
  . "${HOMEFRIES_BASHRCBIN}/bashrc.core.sh"

  # Load private Bashrc twice, once before sourcing all the Home-fries
  # Bashrc, and then again after. Typically, the first pass is used to
  # update PATH and set whatever environs might be needed in order for
  # the Home-fries source to load correctly.
  export HOME_FRIES_PRELOAD=true
  source_private

  # This sources bashrc.core.sh.
  source_fries
  unset -f source_fries

  export HOME_FRIES_PRELOAD=false
  source_private
  unset -f source_private
  unset -f source_private_scripts
  unset -f source_privately
  unset -v HOME_FRIES_PRELOAD

  cleanup_loading_dots "${time_0}"
  unset -f cleanup_loading_dots

  start_somewhere_something
  unset -f start_somewhere_something

  home_fries_bashrc_cleanup
  unset -f home_fries_bashrc_cleanup

  # This calls echo-elapsed, which only reports over a certain threshold.
  print_elapsed_time "${time_0}" "bashrc.bash.sh" "==TOTAL: "

  # Cover our tracks!
  environ_cleanup
}

main "$@"


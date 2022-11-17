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

# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #

# *** Die early, Die often!

# Require Bash 4+ and coreutils.
#
# - 2022-10-15: Two years ago, I had issues with stock macOS terminal
#   because the old version of macOS's `readlink` did not support the
#   `readlink -f` option to resolve relative paths.
#   - This is since resolved: macOS 12.6 with Bash 3.2.57(1) supports
#     the `readlink -f` option (manpage dated 2017-06-22).
#   - Nonetheless, I do not want to assume -- nor test! -- that macOS's
#     old Bash 3.x will work with Homefries. It's not like Homefries
#     doesn't rely on coreutils and a myriad other modern conventions.
#     - So let's *die here and now* if things don't pass muster.
#   - Note the current state of macOS: Supports `readlink -f`, but Bash 3.
#     - As I've said before: "you cannot load Homefries on vanilla macOS."
#   - If you're wondering how best to setup your macOS to run Homefries,
#     I refer you to my macOS onboarder:
#       https://github.com/depoxy/macOS-onboarder#🏂
#     Which will Homebrew-install everything you/I need, and even setup
#     macOS `defaults` appropriately, so, e.g., you can run iTerm2 and
#     it'll boot into a Bash 5 environment with coreutils at the ready.
#     - You might also be interested in the dev machine onboarder that
#       I use -- which uses macOS-onboarder -- that installs Homefries
#       and all my favorite Git and Vim utilities, and much more:
#         https://github.com/depoxy/depoxy#🍯
#     - Although if you run Linux (which I do @home), I haven't quite
#       squared the macOS installer with a comparable installer for
#       Linux. Rather, I have instead a series of complicated Ansible
#       playbooks, including but not limited to:
#         https://github.com/landonb/zoidy_mintyfresh
#         https://github.com/landonb/zoidy_home-fries
#         https://github.com/landonb/zoidy_matecocido
#         https://github.com/landonb/zoidy_panelsweet
#         https://github.com/landonb/zoidy_troglodyte
#       And unfortunately (for you, not me), I have not published
#       the grand installer that downloads and runs all those plays.
#       - Maybe someday I'll make an easier Linux installer, but I
#         find myself standing up new macOS machines (for contract
#         work) far more often than I standup new Linux machines
#         (for @home personal use).
#       - In any case, back to scheduled programming, die here and
#         now if we cannot identify Bash 4 or better, or coreutils:

fail_fast_fail_often () {
  # Note that we call `bash` itself rather than check ${BASH_VERSINFO[0]},
  # because macOS will load its own Bash 3, while Homebrew's Bash 5 might
  # be what's on PATH.
  # - I.e., the user called `eval $(/opt/homebrew/bin/brew shellenv)"
  #   and then called `bash` to load Homefries.
  # - Here's the naïve check, just FYÏ:
  #     [ ${BASH_VERSINFO[0]} -ge 4 ] && command -v realpath > /dev/null && return
  local bash_vers="$(bash --version | head -1 | sed -r 's/GNU bash, version ([0-9]+).*/\1/')"

  # If this `realpath --version` check passes, we'll assume that `coreutils`
  # is installed (because there's not an OS- and package-manager-agnostic
  # way to check that coreutils is installed otherwise, i.e., there's no
  # `coreutils` command, but rather all the commands that it installs).
  local assuming_corepath=false
  command -v realpath > /dev/null &&
    realpath --version | head -1 | grep -q -e "(GNU coreutils)" &&
      assuming_corepath=true

  [ ${bash_vers} -ge 4 ] && ${assuming_corepath} && return

  # 2022-10-28: I've been downcoding to Bash 3 for macOS, but not finished yet.
  >&2 echo "BWARE: A few pieces in Homefries may fail without Bash v4" \
    "(but for the most part you likely won't notice)."
  # 2022-11-16: Perform a hacky is-coreutils-available check. Though really,
  # each individual Homefries functions should check deps when they run, if
  # they have any. Each function could also check Bash v4, if that's a
  # requirement. Because the majority of Homefries works fine on Bash v3 (I
  # can't think of what fails on Bash v3, I just "know" there's something),
  # it'd be better to gripe about running on Bash v3 or "missing" coreutils
  # iff the user invokes a Bash v4 fcn or a fcn that expects a GNU app.
  ( readlink --version || greadlink --version ) > /dev/null 2>&1 ||
    >&2 echo "BWARE: Some of Homefries requires coreutils."

  if [ -z "${HOMEBREW_PREFIX}" ]; then
    # Apple Silicon (arm64) brew path is /opt/homebrew.
    local brew_bin="/opt/homebrew/bin"
    # Otherwise on Intel Macs it's under /usr/local.
    [ -d "${brew_bin}" ] || brew_bin="/usr/local/bin"
    local brew_path="${brew_bin}/brew"

    if [ -e "${brew_path}" ]; then
      echo "HINT: Try sourcing Homebrew environs, then try again."
      echo "  eval \"\$(${brew_path} shellenv)\""
      echo "  bash"
    fi
  fi
}

fail_fast_fail_often

# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #

# *** Get the path to Homefries, so we can use relative paths

# Get the path to this script's parent directory.
# - Requires coreutils' `realpath`.
#   See previous Bash version and coreutils check-and-die.

export HOMEFRIES_BASHRCBIN="$(dirname -- "$(realpath -- "${BASH_SOURCE[0]}")")"
${HOMEFRIES_TRACE} && echo "── HOMEFRIES_BASHRCBIN=${HOMEFRIES_BASHRCBIN}"

# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #

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

source_dep_print_nanos_now

# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #

# *** Begin profiling

HOMEFRIES_TIME0="$(print_nanos_now)"

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

# *** First trace message means ready to load more scripts

${HOMEFRIES_TRACE} && echo "─ Welcome, User (EUID=${EUID})"

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

# *** Update PATH and LD_LIBRARY_PATH (e.g., wire ~/.local/bin)

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
    ${HOMEFRIES_TRACE} && echo "   . FRIES: ${sys_rc}"
    . "${sys_rc}"
    print_elapsed_time "${time_0}" "Source: ${sys_rc}"
    ${HOMEFRIES_TRACE} && echo "  └─"
  fi
}

# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #

# *** Load Homefries scripts

source_fries () {
  local time_0="$(print_nanos_now)"

  ${HOMEFRIES_TRACE} && echo "──┬ Loading Homefries scripts"

  # Common Bash standup. Defines aliases, configures things,
  # adjusts the terminal prompt, and adds a few functions.
  . "${HOMEFRIES_BASHRCBIN}/bashrc.core.sh"

  print_elapsed_time "${time_0}" "Source: bashrc.core.sh" "==FRIES: "

  ${HOMEFRIES_TRACE} && echo "  └─"
}

# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #

# *** Load private scripts (DEV's user- and machine-specific scripts)

source_privately () {
  local srcfile="$1"
  local srctype="$2"
  if [ -f "${srcfile}" ]; then
    ${HOMEFRIES_TRACE} && echo "  ├─ Loading from a ${srctype} resource: ✓ ${srcfile}"
    local time_0="$(print_nanos_now)"
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
  # Private Bashrc, generally symlinked into Home-fries (and Git-ignored
  # via .git/exclude/info, which is also generally symlinked to the same
  # private repo that contains the private Bashrc being symlinked).

  # If present, load a private bash profile script.
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
  #   $0 == '/user/home/.local/bin/bash'
  # and when on remote terminal over ssh,
  #   $0 == '-bash'
  local custom_bash=false
  if [ "$0" = 'bash' ] || [ "$0" = '-bash' ]; then
    if $(alias bash &> /dev/null); then
      local bash_path
      bash_path="$(alias bash | /usr/bin/env sed -E 's/^.* ([^ ]+\/bash\>).*/\1/')"
      if [ "$(realpath -- "${bash_path}")" != '/bin/bash' ]; then
        custom_bash=true
      fi
    elif [ "$(realpath -- "$(command -v bash)")" != '/bin/bash' ]; then
      custom_bash=true
    fi
  elif [ "$(realpath -- "$0")" != '/bin/bash' ]; then
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

# *** Environment cleanup

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


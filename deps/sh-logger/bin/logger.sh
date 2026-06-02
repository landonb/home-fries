#!/bin/sh
# vim:tw=0:ts=2:sw=2:et:norl:ft=bash
# Project: https://github.com/landonb/sh-logger#🎮🐸
# License: MIT

# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #

# *** <beg boilerplate `source_deps`: ------------------------------|
#                                                                   |

_sh_logger_sh__this_filename="logger.sh"

_sh_logger_sh__source_deps() {
  local sourced_all=true

  # On Bash, user can source this file from anywhere.
  # - If not Bash, user must `cd` to this file's parent directory first.
  local prefix="$(dirname -- "${_sh_logger_sh__this_fullpath}")"

  # USAGE: Load dependencies using path relative to this file, e.g.:
  #   _source_file "${prefix}" "../deps/path/to/lib" "dependency.sh"

  #                                                                 |
  # *** stop boilerplate> ------------------------------------------|

  # https://github.com/landonb/sh-colors
  _sh_logger_sh__source_file "${prefix}" "../deps/sh-colors/bin" "colors.sh"

  # *** <more boilerplate: -----------------------------------------|
  #                                                                 |

  ${sourced_all}
}

_sh_logger_sh__smells_like_bash() { declare -p BASH_SOURCE >/dev/null 2>&1; }

# Note that ${BASH_SOURCE} is technically ${BASH_SOURCE[0]}, but for POSIX
# compatibility, avoid the array index (and note that ${BASH_SOURCE} returns
# the first array value).
# - TRYME: You can test the following to confirm:
#     foo_1 () { echo ${BASH_SOURCE}; echo ${BASH_SOURCE[0]}; echo ${BASH_SOURCE[1]}; }
#     foo_2 () { foo_1; }
#     foo_2

_sh_logger_sh__print_this_fullpath() {
  if _sh_logger_sh__smells_like_bash; then
    echo "$(realpath -- "${BASH_SOURCE}")"
  elif [ "$(basename -- "$0")" = "${_sh_logger_sh__this_filename}" ]; then
    # Assumes this script being executed, and $0 is its path.
    echo "$(realpath -- "$0")"
  else
    # Assumes cwd is this script's parent directory.
    echo "$(realpath -- "${_sh_logger_sh__this_filename}")"
  fi
}

_sh_logger_sh__this_fullpath="$(_sh_logger_sh__print_this_fullpath)"

# $0 might be path to this script, e.g.,
#   /Users/user/.kit/sh/sh-logger/bin/logger.sh
# Or:
#   /Users/user/.kit/sh/home-fries/deps/sh-logger/bin/logger.sh
# Or it might be path to Bash:
#   /opt/homebrew/bin/bash
# Or it might be "-bash", e.g., when shell started via tmux:
#   -bash
# Or even just "bash", e.g., when shell started via `bash -c bash`:
#   bash
_sh_logger_sh__shell_sourced() {
  [ "$0" = "-bash" ] ||
    [ "$0" = "bash" ] ||
    [ "$(realpath -- "$0" 2>/dev/null)" != "${_sh_logger_sh__this_fullpath}" ]
}

_sh_logger_sh__source_file() {
  local prfx="${1:-.}"
  local depd="${2:-.}"
  local file="${3:-.}"

  local deps_dir="${prfx}/${depd}"
  local deps_path="${deps_dir}/${file}"

  # Just in case sourced file overwrites top-level `_sh_logger_sh__this_filename`,
  # cache our copy, should we need it for an error message.
  local _this_file_name="${_sh_logger_sh__this_filename}"

  if [ -f "${deps_path}" ]; then
    # SAVVY: Source files from their dirs, so they can find their deps.
    local before_cd="$(pwd -L)"
    cd "${deps_dir}"
    # SAVVY: If errexit, error while sourcing kills process immediately,
    # and error you see might indicate this source file, but the line
    # number for the file being sourced. E.g.,
    #   /path/to/bin/myapp: 442: export: Illegal option -f
    # where `442` is line number from, e.g., 'deps/lib/dep.sh'.
    if ! . "${deps_path}"; then
      >&2 echo "ERROR: Dependency ‘${file}’ returned nonzero when sourced"
      sourced_all=false
    fi
    cd "${before_cd}"
  else
    local depstxt=""
    [ "${prfx}" = "." ] || depstxt="in ‘${deps_dir}’ or "
    >&2 echo "ERROR: ‘${file}’ not found under ‘${deps_dir}’"
    if _sh_logger_sh__smells_like_bash; then
      >&2 echo "- GAFFE: This looks like an error with the ‘_sh_logger_sh__source_file’ arguments"
    else
      >&2 echo "- HINT: You must source ‘${_this_file_name}’ from its parent directory"
    fi
    sourced_all=false
  fi
}

# BONUS: You can use these aliases instead of the uniquely-named functions,
# just be aware not to call any alias after calling _source_deps.
_shell_sourced() { _sh_logger_sh__shell_sourced; }
_source_deps() { _sh_logger_sh__source_deps; }

_sh_logger_sh__source_deps_unset_cleanup() {
  unset -v _sh_logger_sh__this_filename
  unset -f _sh_logger_sh__print_this_fullpath
  unset -f _sh_logger_sh__shell_sourced
  unset -f _shell_sourced
  unset -f _sh_logger_sh__smells_like_bash
  unset -f _sh_logger_sh__source_deps
  unset -f _source_deps
  unset -f _sh_logger_sh__source_deps_unset_cleanup
  unset -f _sh_logger_sh__source_file
}

# USAGE: When this file is being executed, before doing stuff, call:
#   _source_deps
# - When this file is being sourced, call both:
#   _source_deps
#   _sh_logger_sh__source_deps_unset_cleanup

#                                                                   |
# *** end boilerplate `source_deps`> -------------------------------|

# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #

# ***

export_log_levels() {
  # The Python logging library defines the following levels,
  # along with some levels I've slid in.
  export LOG_LEVEL_FATAL=50
  # export LOG_LEVEL_FATAL=186 # *sounds more like it
  export LOG_LEVEL_CRITICAL=50
  export LOG_LEVEL_ERROR=40
  # There's a warning() and a warn(), but only one level var.
  export LOG_LEVEL_WARNING=30
  export LOG_LEVEL_NOTICE=25
  export LOG_LEVEL_INFO=20
  export LOG_LEVEL_DEBUG=15
  # (lb): I added LOG_LEVEL_TRACE and LOG_LEVEL_VERBOSE.
  export LOG_LEVEL_TRACE=10
  export LOG_LEVEL_VERBOSE=5
  export LOG_LEVEL_NOTSET=0

  # BWARE/2022-10-13: Note that the first time a caller sources this
  # library, none of the LOG_LEVEL_* values are defined in their
  # environment, so it's not like the caller will have specified
  # LOG_LEVEL yet. Meaning: when sourced for the first time, this
  # library will always default to LOG_LEVEL_ERROR. It's only on
  # a second or subsequent source that this if-block will be
  # skipped (unless the caller unsets the LOG_LEVEL before source).
  # The basic use case is: caller sources this library, then sets
  # LOG_LEVEL, and then any commands they call after that also
  # source this library won't cause the LOG_LEVEL to change.
  if [ -z ${LOG_LEVEL+x} ]; then
    export LOG_LEVEL=${LOG_LEVEL_ERROR}
  fi
}

# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #

_sh_logger_log_msg() {
  local FCN_LEVEL="$1"
  local FCN_COLOR="$2"
  local FCN_LABEL="$3"

  shift 3

  # Verify LOG_LEVEL is an integer. Note the -eq spews when it fails, e.g.:
  #   bash: [: <foo>: integer expression expected
  if [ -n "${LOG_LEVEL}" ] &&
    ! [ "${LOG_LEVEL}" -eq "${LOG_LEVEL}" ] 2>/dev/null \
    ; then

    >&2 echo "WARNING: Resetting LOG_LEVEL, not an integer"

    export LOG_LEVEL=
  fi

  if [ ${FCN_LEVEL} -ge ${LOG_LEVEL:-${LOG_LEVEL_ERROR}} ]; then
    local RIGHT_NOW
    RIGHT_NOW=$(date "+%Y-%m-%d @ %T")

    local bold_maybe=''
    [ ${FCN_LEVEL} -lt ${LOG_LEVEL_WARNING} ] || bold_maybe=$(attr_bold)

    local invert_maybe=''
    [ ${FCN_LEVEL} -lt ${LOG_LEVEL_WARNING} ] || invert_maybe=$(bg_maroon)
    [ ${FCN_LEVEL} -lt ${LOG_LEVEL_ERROR} ] || invert_maybe=$(bg_red)

    local prefix
    prefix="${FCN_COLOR}$(attr_underline)[${FCN_LABEL}]$(attr_reset) ${RIGHT_NOW} ${bold_maybe}${invert_maybe}"

    local newline=''
    ${LOG_MSG_NO_NEWLINE:-false} || newline='\n'

    (
      local IFS=" "
      printf "${prefix}%b$(attr_reset)${newline}" "$*"
    )
  fi
}

# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #

# https://en.wikipedia.org/wiki/And_Now_for_Something_Completely_Different

# HSTRY/2026-06-01: This func. originated in Homefries, then later added
# separately 3+ times in DepoXy code, and also to myrepos-mredit-command.
# - It's a rare case of shell code I'd be "unable" (unwilling =) to DRY.
#   - But then I thought, Hey, ya know what almost every shell
#     project I write sources (and includes in deps/)? logger.sh!
#   - Not that I think we should start overloading logger.sh with
#     unrelated shell utility code... but this func. is *sorta*
#     related to logging, because I only use this func. to
#     prepare path strings for logging/printing to the terminal.
#     - So in this particular case, *IGTAT*:
#       https://www.reddit.com/r/futurama/comments/16ha2hr/im_going_to_allow_this/
#         https://futurama.fandom.com/wiki/Glab

# USAGE: Pass path as first arg., or pipe via stdin.
_sh_tilde_for_home() {
  (
    if test $# -gt 0; then
      echo "$1"
    else
      cat
    fi
  ) | $(gnu_sed) -E "s#^${HOME}(/|$)#~\1#"
}

# ***

_sh_first_command() {
  local match=""

  for cmd in $@; do
    if match="$(
      unset -f ${cmd}
      unalias ${cmd} 2>/dev/null || true
      command -v ${cmd} 2>/dev/null
    )"; then

      break
    fi
  done

  if test -z "${match}"; then
    >&2 echo "ERROR: Missing command(s): $@"

    # /shrug Gentle fallback?
    # - UCASE: So that users don't need to guard calls to this func.,
    #   e.g., so `$(gnu_sed) -e ...`  doesn't resolve to `-e` if
    #   gnu_sed prints an error — this should *always* print a valid
    #   pipeline command.
    #   - W/out (''):
    #     $ echo foo | $(gnu_sed) -e bar
    #     ERROR: (g)sed absent!
    #     bash: -e: command not found
    #   - With 'cat':
    #     $ echo foo | $(gnu_sed) -e bar
    #     ERROR: (g)sed absent!
    #     cat: bar: No such file or directory
    #   - With '_sh_cat_niladic':
    #     $ echo foo | $(gnu_sed) -e bar
    #     ERROR: (g)sed absent!
    #     foo
    echo "_sh_cat_niladic"

    return 1
  fi

  echo "${match}"
}

# cat, but no args.
# - Words: Niladic, or Nullary: "Of an op or f in a prog, having no args."
#   https://en.wiktionary.org/wiki/niladic
_sh_cat_niladic() {
  # ALTLY: Always prefers just echoing args:
  #   if test $# -gt 0; then
  #     echo "$@"
  #   else
  #     cat
  #   fi
  # - Instead: Prefer stdin when avail., fallback args.
  if read -t 0 notused; then
    cat
  else
    echo "$@"
  fi
}

gnu_sed() {
  if ! _sh_first_command "gsed" "sed" 2>/dev/null; then
    >&2 echo "ERROR: (g)sed absent!"

    # _sh_first_command has printed "_sh_cat_niladic" for a graceful
    # fallback (see comment above), so just propagate status.
    return 1
  fi
}

# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #

# BWARE/2023-12-26: There are two extreme log levels, both 50, but one
# is nonlethal (`critical`) while the other (`fatal`) returns nonzero
# and can be used to trip errexit.

# LOG_LEVEL_FATAL=50
fatal() {
  _sh_logger_log_msg "${LOG_LEVEL_FATAL}" "$(bg_white)$(fg_lightred)$(attr_bold)" FATL "$@"
  # So that errexit can be used to stop execution.
  return 1
}

# LOG_LEVEL_CRITICAL=50
critical() {
  _sh_logger_log_msg "${LOG_LEVEL_CRITICAL}" "$(bg_pink)$(fg_black)$(attr_bold)" CRIT "$@"
}

# ***

# LOG_LEVEL_ERROR=40
error() {
  # Same style as critical
  _sh_logger_log_msg "${LOG_LEVEL_CRITICAL}" "$(bg_red)$(fg_white)$(attr_bold)" ERRR "$@"
}

# ***

# LOG_LEVEL_WARNING=30
warning() {
  _sh_logger_log_msg "${LOG_LEVEL_WARNING}" "$(fg_hotpink)$(attr_bold)" WARN "$@"
}

# LOG_LEVEL_WARNING=30
warn() {
  warning "$@"
}

alert() {
  _sh_logger_log_msg "${LOG_LEVEL_WARNING}" "$(fg_hotpink)$(attr_bold)" ALRT "$@"
}

# ***

# LOG_LEVEL_NOTICE=25
notice() {
  _sh_logger_log_msg "${LOG_LEVEL_NOTICE}" "$(fg_lime)" NOTC "$@"
}

# ***

# MAYBE: This 'info' functions shadows /usr/bin/info
# - We could name it `infom`, or something.
# - The author almost never uses `info`.
# - Users can run just `command info ...`.
# - I don't care too much about this either way...
# LOG_LEVEL_INFO=20
info() {
  _sh_logger_log_msg "${LOG_LEVEL_INFO}" "$(fg_mintgreen)" INFO "$@"
}

# ***

# LOG_LEVEL_DEBUG=15
debug() {
  _sh_logger_log_msg "${LOG_LEVEL_DEBUG}" "$(fg_jade)" DBUG "$@"
}

# ***

# LOG_LEVEL_TRACE=10
trace() {
  _sh_logger_log_msg "${LOG_LEVEL_TRACE}" "$(fg_mediumgrey)" TRCE "$@"
}

# ***

# LOG_LEVEL_VERBOSE=5
verbose() {
  _sh_logger_log_msg "${LOG_LEVEL_VERBOSE}" "$(fg_mediumgrey)" VERB "$@"
}

# ***

# LOG_LEVEL_NOTSET=0

# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #

test_sh_logger() {
  (
    LOG_LEVEL=${LOG_LEVEL_NOTSET:-0}

    fatal "FATAL: I'm going down!"
    critical "CRITICAL: Take me to a hospital!"
    error "ERROR: Oops! I did it again!!"
    warn "WARN: This is your last warning."
    warning "WARNING: I lied, one more warning."
    notice "NOTICE: Hear ye, hear ye!!"
    info "INFO: Extra! Extra! Read all about it!!"
    debug "DEBUG: If anyone asks, you're my debugger."
    trace "TRACE: Not a trace."
    verbose "VERBOSE: I'M YELLING AT YOU"
    verbose "_sh_tilde_for_home: Home Sweet $(echo "${HOME}/sweet/home" | _sh_tilde_for_home)"
  )
}

# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #

export_log_funcs() {
  if ! _sh_logger_sh__smells_like_bash; then

    return
  fi

  # (lb): This function isn't necessary, but it's a nice list of
  # available functions.
  export -f fatal
  export -f critical
  export -f error
  export -f warning
  export -f warn
  export -f notice
  # NOTE: This 'info' shadows the builtin,
  #       now accessible at `command info`.
  export -f info
  export -f debug
  export -f trace
  export -f verbose
}

# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #

_sh_logger_sh__source_deps

if _sh_logger_sh__shell_sourced; then
  export_log_levels
  export_log_funcs
else
  # Being executed.
  LOG_LEVEL=0 test_sh_logger
fi

_sh_logger_sh__source_deps_unset_cleanup
unset -f export_log_levels
unset -f export_log_funcs

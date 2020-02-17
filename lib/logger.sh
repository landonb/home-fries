#!/bin/bash
# vim:tw=0:ts=2:sw=2:et:norl:
# Project: https://github.com/landonb/home-fries
# License: GPLv3

# Summary: Colorful Bash Logger

# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #

source_deps () {
  local curdir="${HOMEFRIES_LIB:-${HOME}/.homefries/lib}"
  if [ -n "${BASH_SOURCE}" ]; then
    curdir=$(dirname -- "${BASH_SOURCE[0]}")
  fi

  # Load colors.
  . ${curdir}/color_funcs.sh
}

# The Python logging library defines the following levels,
# along with some levels I've slid in.
LOG_LEVEL_FATAL=186 # [*probably what it really should be]
LOG_LEVEL_CRITICAL=50
LOG_LEVEL_FATAL=50 # [*aliases CRITICAL]
LOG_LEVEL_ERROR=40
LOG_LEVEL_WARNING=30 # [*also WARN]
LOG_LEVEL_NOTICE=25 # [*new]
LOG_LEVEL_INFO=20
LOG_LEVEL_DEBUG=15
LOG_LEVEL_TRACE=10 # [*new]
LOG_LEVEL_VERBOSE1=9 # [*new]
LOG_LEVEL_VERBOSE2=8 # [*new]
LOG_LEVEL_VERBOSE3=7 # [*new]
LOG_LEVEL_VERBOSE4=6 # [*new]
LOG_LEVEL_VERBOSE5=5 # [*new]
LOG_LEVEL_VERBOSE=5 # [*new]
LOG_LEVEL_NOTSET=0

if [ -z ${LOG_LEVEL+x} ]; then
  LOG_LEVEL=${LOG_LEVEL_ERROR}
fi

_echo () {
  [ "$(echo -e)" = '' ] && echo -e "${@}" || echo "${@}"
}

log_msg () {
  local FCN_LEVEL="$1"
  local FCN_COLOR="$2"
  local FCN_LABEL="$3"
  shift 3
  if [ ${FCN_LEVEL} -ge ${LOG_LEVEL} ]; then
    #echo "${FCN_COLOR} $@"
    local RIGHT_NOW
    #RIGHT_NOW=$(date +%Y-%m-%d.%H.%M.%S)
    RIGHT_NOW=$(date "+%Y-%m-%d @ %T")
    local bold_maybe=''
    [ ${FCN_LEVEL} -ge ${LOG_LEVEL_WARNING} ] && bold_maybe=$(attr_bold)
    local invert_maybe=''
    [ ${FCN_LEVEL} -ge ${LOG_LEVEL_WARNING} ] && invert_maybe=$(bg_maroon)
    [ ${FCN_LEVEL} -ge ${LOG_LEVEL_ERROR} ] && invert_maybe=$(bg_hotpink)
    local echo_msg
    echo_msg="${FCN_COLOR}$(attr_underline)[${FCN_LABEL}]$(attr_reset) ${RIGHT_NOW} ${bold_maybe}${invert_maybe}$@$(attr_reset)"
    _echo "${echo_msg}"
  fi
}

fatal () {
  #log_msg "${LOG_LEVEL_FATAL}" "$(bg_hotpink)$(attr_bold)" FATL "$@"
  #log_msg "${LOG_LEVEL_FATAL}" "$(bg_pink)$(fg_black)$(attr_bold)" FATL "$@"
  log_msg "${LOG_LEVEL_FATAL}" "$(bg_white)$(fg_lightred)$(attr_bold)" FATL "$@"
  # So that errexit can be used to stop execution.
  return 1
}

critical () {
  #log_msg "${LOG_LEVEL_CRITICAL}" "$(fg_hotpink)$(attr_bold)" CRIT "$@"
  log_msg "${LOG_LEVEL_CRITICAL}" "$(bg_pink)$(fg_black)$(attr_bold)" CRIT "$@"
}

error () {
  #log_msg "${LOG_LEVEL_ERROR}" "$(fg_orange)$(attr_bold)" ERRR "$@"
  critical "$@"
}

warning () {
  #log_msg "${LOG_LEVEL_WARNING}" "$(fg_lightred)$(attr_bold)" WARN "$@"
  log_msg "${LOG_LEVEL_WARNING}" "$(fg_hotpink)$(attr_bold)" WARN "$@"
}

warn () {
  #log_msg "${LOG_LEVEL_WARNING}" "$(fg_pink)$(attr_bold)" WARN "$@"
  warning "$@"
}

notice () {
  log_msg "${LOG_LEVEL_NOTICE}" "$(fg_lime)" NOTC "$@"
}

# FIXME: Shadows /usr/bin/info
#        Name it `infom`?
info () {
  log_msg "${LOG_LEVEL_INFO}" "$(fg_mintgreen)" INFO "$@"
}

debug () {
  log_msg "${LOG_LEVEL_DEBUG}" "$(fg_jade)" DBUG "$@"
}

trace () {
  log_msg "${LOG_LEVEL_TRACE}" "$(fg_mediumgrey)" TRCE "$@"
}

verbose () {
  log_msg "${LOG_LEVEL_VERBOSE}" "$(fg_mediumgrey)" VERB "$@"
}

test_logger () {
  fatal "FATAL: I'm gonna die!"
  critical "CRITICAL: Take me to a hospital!"
  error "ERROR: Oops! I did it again!!"
  warning "WARNING: You will die someday."
  warn "WARN: This is your last warning."
  notice "NOTICE: Hear ye, hear ye!!"
  info "INFO: Extra! Extra! Read all about it!!"
  debug "DEBUG: If anyone asks, you're my debugger."
  trace "TRACE: Not a trace."
  verbose "VERBOSE: I'M YELLING AT YOU"
}

main () {
  source_deps
  unset -f source_deps
}

main "$@"
unset -f main


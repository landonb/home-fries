#!/bin/bash
# File: setup.sh
# Author: Landon Bouma (landonb &#x40; retrosoft &#x2E; com)
# Last Modified: 2017.10.03
# Project Page: https://github.com/landonb/home-fries
# Summary: Colorful Bash Logger
# License: GPLv3
# vim:tw=0:ts=2:sw=2:et:norl:

SCRIPT_DIR=$(dirname -- "${BASH_SOURCE[0]}")

# Load colors.
source ${SCRIPT_DIR}/color_util.sh

# The Python logging library defines the following levels,
# along with some levels I've slid in.
LOG_LEVEL_FATAL=186 # [*probably what it really should be]
LOG_LEVEL_CRITICAL=50
LOG_LEVEL_FATAL=50 # [*aliases CRITICAL]
LOG_LEVEL_ERROR=40
LOG_LEVEL_WARNING=30 # [*also WARN]
LOG_LEVEL_NOTICE=25 # [*new]
LOG_LEVEL_INFO=20
LOG_LEVEL_TRACE=15 # [*new]
LOG_LEVEL_DEBUG=10
LOG_LEVEL_VERBOSE1=9 # [*new]
LOG_LEVEL_VERBOSE2=8 # [*new]
LOG_LEVEL_VERBOSE3=7 # [*new]
LOG_LEVEL_VERBOSE4=6 # [*new]
LOG_LEVEL_VERBOSE5=5 # [*new]
LOG_LEVEL_VERBOSE=5 # [*new]
LOG_LEVEL_NOTSET=0

if [[ -z ${LOG_LEVEL+x} ]]; then
  LOG_LEVEL=${LOG_LEVEL_ERROR}
fi

log_msg () {
  FCN_LEVEL=$1
  FCN_COLOR=$2
  FCN_LABEL=$3
  shift 3
  if [[ ${FCN_LEVEL} -ge ${LOG_LEVEL} ]]; then
    #echo "${FCN_COLOR} $@"
    #RIGHT_NOW=$(date +%Y-%m-%d.%H.%M.%S)
    RIGHT_NOW=$(date +%Y-%m-%d@%T)
    echo -e "${MINTGREEN}${font_underline_bash}[${FCN_LABEL}]${font_normal_bash} ${RIGHT_NOW} ${font_bold_bash}$*${font_normal_bash}"
  fi
}

fatal () {
  log_msg ${LOG_LEVEL_FATAL} ${HOTPINK} FATL $*
}

critical () {
  log_msg ${LOG_LEVEL_CRITICAL} ${HOTPINK} CRIT $*
}

error () {
  log_msg ${LOG_LEVEL_ERROR} ${ORANGE} ERRR $*
}

warning () {
  log_msg ${LOG_LEVEL_WARNING} ${LIGHTRED} WARN $*
}

warn () {
  log_msg ${LOG_LEVEL_WARNING} ${LIGHTRED} WARN $*
}

notice () {
  log_msg ${LOG_LEVEL_NOTICE} ${JADE} NOTC $*
}

info () {
  log_msg ${LOG_LEVEL_INFO} ${JADE} INFO $*
}

trace () {
  log_msg ${LOG_LEVEL_TRACE} ${JADE} TRCE $*
}

debug () {
  log_msg ${LOG_LEVEL_DEBUG} ${JADE} DBUG $*
}

verbose () {
  log_msg ${LOG_LEVEL_VERBOSE} ${JADE} VERB $*
}


#!/usr/bin/env bash
# vim:tw=0:ts=2:sw=2:et:norl:ft=sh
# Author: Landon Bouma (landonb &#x40; retrosoft &#x2E; com)
# Project: https://github.com/landonb/home-fries#🍟
# License: MIT

# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #

# FIXME/2022-12-05: I've never tested these where YEAR is included in `who -b` or `last reboot` output.

# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #

# SAVVY: Various methods to get the uptime:
#
#   # Linux-only: `uptime -s` is neither BSD nor GNU, so not an option @macOS.
#   uptime -s
#
#   # macOS or Linux: `last reboot` works on either OS, but with separate formats.
#   last reboot
#
#   # Either: `who -b` seems to be the most cross-platform'able.
#   who -b

# E.g., Linux Mint 21.3:
#
#   $ uptime
#    00:45:36 up 27 days,  8:00,  2 users,  load average: 0.93, 0.77, 0.86
#
#   $ uptime -s
#   2024-04-05 16:45:05
#
#   $ last reboot
#   reboot   system boot  5.15.0-101-gener Fri Apr  5 16:45   still running
#
#   wtmp begins Fri Apr  5 16:44:37 2024
#
#   $ who -b
#            system boot  2024-04-05 16:45
#
# E.g., macOS 14.4
#
#   $ uptime
#    0:45  up 12 days, 13:33, 4 users, load averages: 1.23 1.25 1.30
#
#   $ uptime -s
#   uptime: illegal option -- s
#   usage: uptime
#
#   $ last reboot
#   reboot time                                Sun Apr 14 23:49
#   shutdown time                              Sun Apr 14 23:49
#   reboot time                                Wed Apr 10 17:58
#   
#   wtmp begins Wed Apr 10 17:58:55 CDT 2024
#
#   $ who -b
#                    system boot  Apr 14 23:49 

# The simplest, Linux-only solution (and not supported by Brew `guptime`):
#
#   uptime_s_quiet () {
#     uptime -s 2>/dev/null
#   }
#
# Here's an alternative to the chosen solution (using `who -b`),
# using `last reboot`;
#
#   os_is_macos () { [ "$(uname)" = 'Darwin' ]; }
#
#   last_reboot_time () {
#     clear_fields=""
#     os_is_macos && clear_fields='$1=$2=""' || clear_fields='$1=$2=$3=$4=$9=$10=""'
#     local date_reboot_raw="$(
#       last reboot | \
#       head -n 1 | \
#       awk '{'${clear_fields}'; print $0}' | \
#       sed -r 's/(^ +| +$)//' \
#     )"
#     # local date_reboot_nrm="$(date -j -f "%a %b %e %H:%M:%S" "${date_reboot_raw}:00")"
#     local date_reboot_nrm="$(${gdate} -d "${date_reboot_raw}"  ${format})"
#
#     echo "${date_reboot_nrm}"
#   }
#
# - Note `awk` above used to clear fields (set to empty string), e.g.,
#           $ last reboot
#           reboot   system boot  5.15.0-101-gener Fri Apr  5 16:45   still running
# - Fields:      1        2    3                 4   5   6  7     8       9      10
# - Then, to clear all but date fields:
#     awk '{$1=$2=$3=$4=$9=$10=""'; print $0}'

uptime-s () {
  local format="$1"

  local gdate
  gdate="$(date-or-gdate)" || return 0

  who_b_time () {
    local date_system_boot_raw="$(
      who -b | \
      awk '{$1=$2=""; print $0}' | \
      sed -r 's/(^ +| +$)//' \
    )"
    # local date_system_boot_nrm="$(date -j -f "%b %e %H:%M:%S" "${date_system_boot_raw}:00")"
    local date_system_boot_nrm="$(${gdate} -d "${date_system_boot_raw}" ${format})"

    echo "${date_system_boot_nrm}"
  }

  who_b_time
}

# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #

main () {
  :
}

main "$@"
unset -f main


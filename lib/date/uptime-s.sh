#!/usr/bin/env bash
# vim:tw=0:ts=2:sw=2:et:norl:ft=sh
# Author: Landon Bouma (landonb &#x40; retrosoft &#x2E; com)
# Project: https://github.com/landonb/home-fries#🍟
# License: MIT

# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #

# FIXME/2022-12-05: I've never tested these where YEAR is included in `who -b` or `last reboot` output.

# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #

# LIKEN:
#
#   # Linux-only: `uptime -s` is neither BSD nor GNU, so not an option @macOS.
#   uptime -s
#
#   # macOS-only: `last reboot` is accurate on @macOS, but (at least for the
#                 author), `last reboot` is inaccurate on @linux.
#   last reboot
#
#   # Either: `who -b` seems to be the most cross-platform'able.
#   who -b

uptime-s () {
  local gdate
  gdate="$(date-or-gdate)" || return 0

  uptime_s_quiet () {
    uptime -s 2>/dev/null
  }

  last_reboot_time () {
    local date_reboot_raw="$(
      last reboot | \
      head -n 1 | \
      awk '{$1=$2=""; print $0}' | \
      sed -r 's/(^ +| +$)//' \
    )"
    # local date_reboot_nrm="$(date -j -f "%a %b %e %H:%M:%S" "${date_reboot_raw}:00")"
    local date_reboot_nrm="$(${gdate} -d "${date_reboot_raw}")"

    echo "${date_reboot_nrm}"
  }

  who_b_time () {
    local date_system_boot_raw="$(
      who -b | \
      awk '{$1=$2=""; print $0}' | \
      sed -r 's/(^ +| +$)//' \
    )"
    # local date_system_boot_nrm="$(date -j -f "%b %e %H:%M:%S" "${date_system_boot_raw}:00")"
    local date_system_boot_nrm="$(${gdate} -d "${date_system_boot_raw}")"

    echo "${date_system_boot_nrm}"
  }

  uptime_s_quiet
  [ $? -eq 0 ] || who_b_time
}

# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #

main () {
  :
}

main "$@"
unset -f main


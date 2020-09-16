#!/usr/bin/env bash
# vim:tw=0:ts=2:sw=2:et:norl:ft=sh
# Author: Landon Bouma (landonb &#x40; retrosoft &#x2E; com)
# Project: https://github.com/landonb/home-fries#🍟
# License: MIT

# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #

touch_datefile () {
  touch "$(date +%Y%m%d%H%M%S)$1"
}

# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #

# 2020-09-16: (lb): A little history:
#
# - 2016-07-12: Added TTT and TTTtt to Dubs Vim, after I realized
#               that I had started typing dates when taking notes.
#               I'm not sure how long I had been manually entering
#               dates, just that I was tired of doing so.
#
# - 2017-02-07: "Took you long enough!" I wrote. Apparently I found
#               it amusing that it took 6 months until I added TTT
#               et al to Homefries.
#
# - 2017-02-27: I added TTTtt here. Who knows why it took 20 days.
#
# - 2020-09-16: I finally noticed that the `tt` in Homefries adds
#               seconds ('%S'), which Dubs Vim does not do. I feel
#               that seeing the seconds is just noise, and it makes
#               the date time harder to comprehend at a glance, e.g.,
#               compare "2020-09-16 12:30:44" vs "2020-09-16 12:30".
#               The latter is much easier to grok at first glance.
#               Seeing the seconds makes my brain do more processing.
#
# - 2020-09-16: Over the years, I've developed these habits:
#               - I use the Dubs Vim TTT and TTTtt aliases all the time.
#               - I use $(TTT) often in shells, but rarely do I $(TTTtt).
#               - I don't use any of the alternatives, like TTT_, etc.

# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #

# Prints the date, e.g., "2020-09-16".
# Optional argument specifies date component separator character.
TTT () {
  local sep="${1:--}"
  echo "$(date "+%Y${sep}%m${sep}%d")"
}

# Prints the date time, e.g., "2020-09-16 12:25".
TTTtt () {
  TTT:tt
}

# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #

# The current date (year, month, day).

TTT- () {
  echo "$(date +%Y-%m-%d)"
}

TTT. () {
  echo "$(date +%Y.%m.%d)"
}

TTT_ () {
  echo "$(date +%Y_%m_%d)"
}

# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #

# The current time (hour and minute).

tt () {
  echo "$(date '+%H:%M')"
}

# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #

# The current date and time.

TTTtt0 () {
  echo "$(date '+%Y%m%d%H%M')"
}

TTT!tt () {
  echo "$(date '+%Y-%m-%d!%H:%M')"
}

TTT@tt () {
  echo "$(date '+%Y-%m-%d@%H:%M')"
}

TTT#tt () {
  echo "$(date '+%Y-%m-%d#%H:%M')"
}

TTT%tt () {
  echo "$(date '+%Y-%m-%d%%H:%M')"
}

TTT^tt () {
  echo "$(date '+%Y-%m-%d^%H:%M')"
}

TTT*tt () {
  echo "$(date '+%Y-%m-%d*%H:%M')"
}

TTT-tt () {
  echo "$(date '+%Y-%m-%d-%H:%M')"
}

# TTTtt- () {
#   echo "$(date '+%Y-%m-%d-%H-%M')"
# }

TTT-tt1 () {
  echo "$(date '+%Y-%m-%d %H:%M')"
}

TTT_tt () {
  echo "$(date '+%Y-%m-%d_%H:%M')"
}

TTT+tt () {
  echo "$(date '+%Y-%m-%d+%H:%M')"
}

TTT:tt () {
  echo "$(date '+%Y-%m-%d:%H:%M')"
}

# TTTtt: () {
#   echo "$(date '+%Y-%m-%d:%H:%M')"
# }

TTT/tt () {
  echo "$(date '+%Y-%m-%d/%H:%M')"
}

TTT?tt () {
  echo "$(date '+%Y-%m-%d?%H:%M')"
}

# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #

main () {
  :
}

main "$@"
unset -f main


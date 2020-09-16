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

# 2017-02-07: Took you long enough!
TTT- () {
  echo "$(date +%Y-%m-%d)"
}

TTT () {
  TTT-
}

TTT. () {
  echo "$(date +%Y.%m.%d)"
}

TTT_ () {
  echo "$(date +%Y_%m_%d)"
}

# 2017-02-27: Taking it even further.
TTTtt () {
  TTT:tt
}

# 2017-09-14: Let's complete this.
tt () {
  echo "$(date '+%H:%M')"
}

#TTTtt: () {
#  echo "$(date '+%Y-%m-%d:%H:%M')"
#}

#TTTtt- () {
#  echo "$(date '+%Y-%m-%d-%H-%M')"
#}

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

# Variable identifier.
#TTT$tt () {
#  echo "$(date '+%Y-%m-%d$%H:%M')"
#}

TTT%tt () {
  echo "$(date '+%Y-%m-%d%%H:%M')"
}

TTT^tt () {
  echo "$(date '+%Y-%m-%d^%H:%M')"
}

# Background process operator.
#TTT&tt () {
#  echo "$(date '+%Y-%m-%d&%H:%M')"
#}

TTT*tt () {
  echo "$(date '+%Y-%m-%d*%H:%M')"
}

TTT-tt () {
  echo "$(date '+%Y-%m-%d-%H:%M')"
}

TTT-tt1 () {
  echo "$(date '+%Y-%m-%d %H:%M')"
}

TTT_tt () {
  echo "$(date '+%Y-%m-%d_%H:%M')"
}

TTT+tt () {
  echo "$(date '+%Y-%m-%d+%H:%M')"
}

# Backslash is not gonna work.
#TTT\tt () {
#  echo "$(date '+%Y-%m-%d\%H:%M')"
#}

# Bash doesn't complain about this one, but spits on date only.
#TTT|tt () {
#  echo "$(date '+%Y-%m-%d|%H:%M')"
#}

# ; is statement delimiter.
#TTT;tt () {
#  echo "$(date '+%Y-%m-%d;%H:%M')"
#}

TTT:tt () {
  echo "$(date '+%Y-%m-%d:%H:%M')"
}

# Quotes not gonna work.
#TTT'tt () {
#  echo "$(date '+%Y-%m-%d'%H:%M')"
#}

# Quotes not gonna work.
#TTT"tt () {
#  echo "$(date '+%Y-%m-%d"%H:%M')"
#}

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


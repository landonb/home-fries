#!/bin/bash
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
  echo "$(date '+%H:%M:%S')"
}

#TTTtt: () {
#  echo "$(date '+%Y-%m-%d:%H:%M:%S')"
#}

#TTTtt- () {
#  echo "$(date '+%Y-%m-%d-%H-%M-%S')"
#}

TTTtt0 () {
  echo "$(date '+%Y%m%d%H%M%S')"
}

TTT!tt () {
  echo "$(date '+%Y-%m-%d!%H:%M:%S')"
}

TTT@tt () {
  echo "$(date '+%Y-%m-%d@%H:%M:%S')"
}

TTT#tt () {
  echo "$(date '+%Y-%m-%d#%H:%M:%S')"
}

# Variable identifier.
#TTT$tt () {
#  echo "$(date '+%Y-%m-%d$%H:%M:%S')"
#}

TTT%tt () {
  echo "$(date '+%Y-%m-%d%%H:%M:%S')"
}

TTT^tt () {
  echo "$(date '+%Y-%m-%d^%H:%M:%S')"
}

# Background process operator.
#TTT&tt () {
#  echo "$(date '+%Y-%m-%d&%H:%M:%S')"
#}

TTT*tt () {
  echo "$(date '+%Y-%m-%d*%H:%M:%S')"
}

TTT-tt () {
  echo "$(date '+%Y-%m-%d-%H:%M:%S')"
}

TTT-tt1 () {
  echo "$(date '+%Y-%m-%d %H:%M:%S')"
}

TTT_tt () {
  echo "$(date '+%Y-%m-%d_%H:%M:%S')"
}

TTT+tt () {
  echo "$(date '+%Y-%m-%d+%H:%M:%S')"
}

# Backslash is not gonna work.
#TTT\tt () {
#  echo "$(date '+%Y-%m-%d\%H:%M:%S')"
#}

# Bash doesn't complain about this one, but spits on date only.
#TTT|tt () {
#  echo "$(date '+%Y-%m-%d|%H:%M:%S')"
#}

# ; is statement delimiter.
#TTT;tt () {
#  echo "$(date '+%Y-%m-%d;%H:%M:%S')"
#}

TTT:tt () {
  echo "$(date '+%Y-%m-%d:%H:%M:%S')"
}

# Quotes not gonna work.
#TTT'tt () {
#  echo "$(date '+%Y-%m-%d'%H:%M:%S')"
#}

# Quotes not gonna work.
#TTT"tt () {
#  echo "$(date '+%Y-%m-%d"%H:%M:%S')"
#}

TTT/tt () {
  echo "$(date '+%Y-%m-%d/%H:%M:%S')"
}

TTT?tt () {
  echo "$(date '+%Y-%m-%d?%H:%M:%S')"
}

# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #

main () {
  :
}

main "$@"
unset -f main


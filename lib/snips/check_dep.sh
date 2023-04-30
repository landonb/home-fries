# vim:tw=0:ts=2:sw=2:et:norl:ft=sh
# Author: Landon Bouma (landonb &#x40; retrosoft &#x2E; com)
# Project: https://github.com/landonb/home-fries#🍟
# License: MIT

# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #

# For sourced files to ensure things setup as expected, too.
check_dep () {
  local cname="$1"
  local ahint="$2"

  if ! command -v "${cname}" > /dev/null 2>&1; then
    >&2 printf '\r%s\n' "WARNING: Missing dependency: ‘${cname}’"
    [ -n "${ahint}" ] \
      && >&2 echo "${ahint}"

    false
  else
    true
  fi
}


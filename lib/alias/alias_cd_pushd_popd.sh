#!/usr/bin/env bash
# vim:tw=0:ts=2:sw=2:et:norl:ft=sh
# Author: Landon Bouma (landonb &#x40; retrosoft &#x2E; com)
# Project: https://github.com/landonb/home-fries#🍟
# License: MIT

# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #

# *** pushd/popd/cd wrappers.

home_fries_aliases_wire_cd_pushd_popd () {
  # HINT: `dirs -c` to clear pushd/popd directory stack.

  # IDEA/MAYBE: Enhance completions on cdd (limit to directories).
  function cdd () {
    if [ -n "$2" ]; then
      echo 'You wish!' $*
      return 1
    fi
    if [ -n "$1" ]; then
      pushd "$1" &> /dev/null
      # Same as:
      #  pushd -n "$1" &> /dev/null
      #  cd "$1"
      if [ $? -ne 0 ]; then
        # Maybe the stupid user provided a path to a file.
        local pdir="$(dirname -- "$1")"
        if [ -n "${pdir}" ] && [ '.' != "${pdir}" ]; then
          pushd "${pdir}" &> /dev/null
          if [ $? -ne 0 ]; then
            echo "You're dumb."
          else
            # alias errcho='>&2 echo'
            # echo blah >&2
            >&2 echo "FYI: We popped you to a file's homedir, home skillet."
          fi
        else
          echo "No such place."
        fi
      fi
    else
      pushd "${HOME}" &> /dev/null
    fi
  }
  export -f cdd

  alias cdc='popd > /dev/null'

  # 2017-05-03: How is `cd -` doing a flip-between-last-dir news to me?!
  alias cddc='cd -'

  # 2020-12-04: Clear remembered directories stack.
  # 2020-12-16: Inbox zero, meet Bash directory history stack zero.
  alias popdocd='popd && dirs -c'
}

# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #

unset_f_alias_cd_pushd_popd () {
  unset -f home_fries_aliases_wire_cd_pushd_popd
  # So meta.
  unset -f unset_f_alias_cd_pushd_popd
}

# @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@ #

if [ "$0" = "${BASH_SOURCE[0]}" ]; then
  >&2 echo "ERROR: Trying sourcing the file instead: . $0" && exit 1
fi


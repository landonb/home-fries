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
    local target="$1"

    if [ -n "$2" ]; then
      echo 'You wish!' $*
      return 1
    fi

    # Cleanse the argument: remove "file://" prefix.
    # - Use case: If you open caja (file browser), click a file,
    #   press Ctrl-c or copy, it copies the file path with said
    #   prefix.
    target="$(echo "${target}" | sed 's#^file://##')"

    if [ -n "${target}" ]; then
      pushd "${target}" &> /dev/null
      # Same as:
      #  pushd -n "${target}" &> /dev/null
      #  cd "${target}"
      if [ $? -ne 0 ]; then
        # Maybe the stupid user provided a path to a file.
        local pdir="$(dirname -- "${target}")"
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

  # Move to the parent directory.
  alias ..='cd ..'
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


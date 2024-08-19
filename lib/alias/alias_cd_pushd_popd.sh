#!/usr/bin/env bash
# vim:tw=0:ts=2:sw=2:et:norl:ft=bash
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
      >&2 echo 'Too many args'

      return 1
    fi

    # Cleanse the argument: remove "file://" prefix.
    # - Use case: If you open caja (file browser), click a file,
    #   press Ctrl-c or copy, it copies the file path with said
    #   prefix.
    # - Use case: Copy-pasting browser location for local file.
    target="$(echo "${target}" | sed 's#^file://##')"
    # Because pushd below use quotes, resolve the tilde.
    target="$(echo "${target}" | sed "s*^\~*${HOME}*")"

    if [ -n "${target}" ]; then
      local retcode=0
      pushd "${target}" &> /dev/null
      retcode=$?
      # Same as:
      #  pushd -n "${target}" &> /dev/null
      #  cd "${target}"
      if [ ${retcode} -ne 0 ]; then
        # Maybe the stupid user provided a path to a file.
        local pdir="$(dirname -- "${target}")"
        if [ -n "${pdir}" ] && [ '.' != "${pdir}" ]; then
          pushd "${pdir}" &> /dev/null
          retcode=$?
          if [ ${retcode} -ne 0 ]; then
            >&2 echo "Not a directory: ${pdir}"
          else
            # >&2 echo "FYI: We popped you to a file's homedir, home skillet."
            >&2 echo "FYI: You're in a parent directory of the requested path"
          fi
        else
          >&2 echo "Not a path: ${target}"
        fi

        return ${retcode}
      fi
    else
      pushd "${HOME}" &> /dev/null
    fi
  }
  export -f cdd

  claim_alias_or_warn "cdc" "popd > /dev/null"

  # 2017-05-03: How is `cd -` doing a flip-between-last-dir news to me?!
  claim_alias_or_warn "cddc" "cd -"

  # 2020-12-04: Clear remembered directories stack.
  # 2020-12-16: Inbox zero, meet Bash directory history stack zero.
  claim_alias_or_warn "popdocd" "popd && dirs -c"

  # Move to the parent directory.
  claim_alias_or_warn ".." "cd .."
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


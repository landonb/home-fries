#!/usr/bin/env bash
# vim:tw=0:ts=2:sw=2:et:norl:ft=sh
# Author: Landon Bouma (landonb &#x40; retrosoft &#x2E; com)
# Project: https://github.com/landonb/home-fries#🍟
# License: MIT

# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #

# *** Directory listings.

home_fries_aliases_wire_ls () {
  local ls_cmd="$(ls-or-gls)"

  # 2015-01-20: Using --color=tty still works, but `man` says use --color=auto.
  local color_opt="--color=auto"

  # Human readable /bin/ls that classify files, shows almost
  # all entries (excludes ./ and ../), and uses colour.
  alias ls="${ls_cmd} -hFA ${color_opt}"

  # Compact /bin/ls listing (same as -hFA, really), but list
  # directories first, which seems to make the output cleaner.
  # - See `l` function, below, so we can pipe to tail and get rid of "total" line.
  #  alias l="${ls_cmd} -lhFA ${color_opt} --group-directories-first"

  # ***

  # Long /bin/ls listing, which includes ./ and ../ (perhaps
  # so you can check permissions).
  claim_alias_or_warn "ll" "${ls_cmd} -lhFa ${color_opt}"

  # 2017-07-10: Show timestamps always. [2022-11-04: I never use this.]
  claim_alias_or_warn "lll" "ll --time-style=long-iso"

  # Reverse sort by time. [2022-11-04: I use this very often.]
  claim_alias_or_warn "lo" "ll -rt"

  # 2017-07-10: You get the ideaa. [2022-11-04: I never use this.]
  claim_alias_or_warn "llo" "lo --time-style=long-iso"

  # Sort by size, from largest (empties last). [2022-11-04: I use this sometimes.]
  # - Huh, this conflicts with /bin/lS on macOS, some alternative `ls`, not sure.
  #  claim_alias_or_warn "lS" "${ls_cmd} ${color_opt} -lhFaS"
  alias lS="${ls_cmd} ${color_opt} -lhFaS"

  # Sort by size, largest last. [2022-11-04: I'd forgotten about this one.]
  claim_alias_or_warn "lS-" "${ls_cmd} ${color_opt} -lFaS | sort -n -k5"

  # ***

  # L* aliases do not list owner (replace -l with -g),
  # and do not list group name (add -G).

  # Long listing, which includes ./ and ../
  claim_alias_or_warn "LL" "${ls_cmd} -gGhFa ${color_opt}"

  # Reverse sort by time.
  claim_alias_or_warn "LO" "LL -rt"
}

# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #

function l () {
  # ls, but omit the . and .. directories, and chop the "total" line,
  # e.g., omit the first three lines from a basic listing:
  #   $ /usr/bin/env ls -la
  #   total 20K
  #   drwxrwxr-x  4 landonb landonb 4.0K Dec 17 02:32 ./
  #   drwxr-xr-x  3 landonb landonb 4.0K Apr  9 17:08 ../
  # (the --almost-all/-A will omit the current and parent directories,
  #  and then pipe to tail to strip the "total", which ls includes with
  #  the -l[ong] listing format).
  $(ls-or-gls) -lhFA \
    --color=always \
    --hide-control-chars \
    --group-directories-first \
    "$@" \
    | tail +2
    # | tail --lines=+2
}

# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #

ls-or-gls () {
  command -v gls
  [ $? -eq 0 ] || echo "/usr/bin/env ls"
}

# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #

unset_f_alias_ls () {
  unset -f home_fries_aliases_wire_ls
  # So meta.
  unset -f unset_f_alias_ls
}

# @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@ #

if [ "$0" = "${BASH_SOURCE[0]}" ]; then
  >&2 echo "ERROR: Trying sourcing the file instead: . $0" && exit 1
fi


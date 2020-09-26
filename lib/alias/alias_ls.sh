#!/usr/bin/env bash
# vim:tw=0:ts=2:sw=2:et:norl:ft=sh
# Author: Landon Bouma (landonb &#x40; retrosoft &#x2E; com)
# Project: https://github.com/landonb/home-fries#🍟
# License: MIT

# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #

# *** Directory listings.

home_fries_aliases_wire_ls () {
  local color_opt="--color=auto"

  # 2015.01.20: Used to use --color=tty (which still works), but man says =auto.
  alias ls="/usr/bin/env ls -hFA ${color_opt}"  # Human readable, classify files, shows
                                        #   almost all (excludes ./ and ../),
                                        #   and uses colour.
  # See `l` function, below, so we can pipe to tail and get rid of "total" line.
  # alias l="/usr/bin/env ls -lhFA ${color_opt} --group-directories-first"
                                        # Compact listing (same as -hFA, really),
                                        #   but list directories first which
                                        #   seems to make the output cleaner.
  alias ll="/usr/bin/env ls -lhFa ${color_opt}" # Long listing; includes ./ and ../
                                        #   (so you can check permissions)
  alias lll="ll --time-style=long-iso"  # 2017-07-10: Show timestamps always.
  alias lo="ll -rt"                     # Reverse sort by time.
  alias llo="lo --time-style=long-iso"  # 2017-07-10: You get the ideaa.
  alias lS="/usr/bin/env ls ${color_opt} -lhFaS" # Sort by size, from largest (empties last).
  alias lS-="/usr/bin/env ls ${color_opt} -lFaS | sort -n -k5" # Sort by size, largest last.
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
  /usr/bin/env ls -lhFA \
    --color=always \
    --hide-control-chars \
    --group-directories-first \
    "$@" \
    | tail +2
    # | tail --lines=+2
}

# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #

unset_f_alias_ls () {
  unset -f home_fries_aliases_wire_ls
  # So meta.
  unset -f unset_f_alias_ls
}

# @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@ #

main () {
  :
}

main ""
unset -f main


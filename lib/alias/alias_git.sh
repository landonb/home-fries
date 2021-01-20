#!/usr/bin/env bash
# vim:tw=0:ts=2:sw=2:et:norl:ft=sh
# Author: Landon Bouma (landonb &#x40; retrosoft &#x2E; com)
# Project: https://github.com/landonb/home-fries#🍟
# License: MIT

# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #

home_fries_aliases_wire_git () {
  # I run `git diff` fairly often. Make it even easier to run.
  # 2020-02-13: See also, via git-smart/.gitconfig:
  #   `git dc`, `git df`, `git dff`.
  alias dff='git diff'

  # 2020-02-17: Will it be confusing to have a similar alias
  #             ('d'-double-consonant) but without the pager?
  #  alias dcc='git --no-pager diff --cached'
  alias dcd='git --no-pager diff --cached'
  alias dcc='git diff --cached'

  # 2020-12-01: Why not.
  alias gap='git add -p'
}

# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #

unset_f_alias_git () {
  unset -f home_fries_aliases_wire_git
  # So meta.
  unset -f unset_f_alias_git
}

# @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@ #

if [ "$0" = "${BASH_SOURCE[0]}" ]; then
  >&2 echo "ERROR: Trying sourcing the file instead: . $0" && exit 1
fi


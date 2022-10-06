#!/usr/bin/env bash
# vim:tw=0:ts=2:sw=2:et:norl:ft=sh
# Author: Landon Bouma (landonb &#x40; retrosoft &#x2E; com)
# Project: https://github.com/landonb/home-fries#🍟
# License: MIT

# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #

# Note that some of these aliases duplicate commands from git-smart:
#   https://github.com/landonb/git-smart
# So, perhaps, we could instead just call Git, e.g.,
#   alias dff='git dff'
#   alias dfd='git dfd'
#   alias dcc='git dcc'
#   alias dcd='git dcd'
# But Homefries and Git Smart are separate projects.
# - If you want both together, check out DepoXy:
#   FIXME: Lint to DepoXy, after it's released... ;)
# SYNC_ME: See also the same git-smart definitions:
#   git-smart/.gitconfig
home_fries_aliases_wire_git () {
  # Aka `git dff`, if you use git-smart.
  alias dff='git diff'
  alias dfd='git --no-pager diff'

  # Aka `git dcc`, if you use git-smart.
  alias dcc='git diff --cached'
  alias dcd='git --no-pager diff --cached'

  # *** The following are not in git-smart. They're pure Bash shortcuts.

  # 2020-12-01: Why not.
  alias gap='git add -p'

  # 2021-01-25: Weeds. (Aka, `git ci -v`.)
  # 2022-10-05: This shows diff at bottom of commit message template.
  # - But I don't think I've ever used it. (I def. don't remember it.)
  #  alias gcv='git commit -v'
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


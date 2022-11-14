#!/usr/bin/env bash
# vim:tw=0:ts=2:sw=2:et:norl:ft=sh
# Author: Landon Bouma (landonb &#x40; retrosoft &#x2E; com)
# Project: https://github.com/landonb/home-fries#🍟
# License: MIT

# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #

# Note that some of these aliases duplicate commands from git-smart:
#   https://github.com/landonb/git-smart
# So, perhaps, we could instead just call Git, e.g.,
#   claim_alias_or_warn "dff" "git dff"
#   claim_alias_or_warn "dfd" "git dfd"
#   claim_alias_or_warn "dcc" "git dcc"
#   claim_alias_or_warn "dcd" "git dcd"
# But Homefries and Git Smart are separate projects.
# - If you want both together, check out DepoXy:
#   FIXME: Lint to DepoXy, after it's released... ;)
# SYNC_ME: See also the same git-smart definitions:
#   git-smart/.gitconfig
home_fries_aliases_wire_git () {
  # Aka `git dff`, if you use git-smart.
  claim_alias_or_warn "dff" "git diff"
  claim_alias_or_warn "dfd" "git --no-pager diff"

  # Aka `git dcc`, if you use git-smart.
  claim_alias_or_warn "dcc" "git diff --cached"
  claim_alias_or_warn "dcd" "git --no-pager diff --cached"

  # *** The following are not in git-smart. They're pure Bash shortcuts.

  # 2020-12-01: Why not.
  claim_alias_or_warn "gap" "git add -p"

  # 2022-10-05: This shows diff at bottom of commit message template.
  # - But I don't think I've ever used it. (I def. don't remember it.)
  claim_alias_or_warn "gcv" "git commit -v"

  # git-smart's `git upstream` aka git-nubs.sh's `git_tracking_branch`.
  claim_alias_or_warn "gup" "_hf_git_tracking_branch"
}

_hf_git_tracking_branch () {
  # 2> /dev/null
  git rev-parse --abbrev-ref --symbolic-full-name @{u}
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


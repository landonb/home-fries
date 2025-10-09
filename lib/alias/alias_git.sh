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
home_fries_aliases_wire_git() {
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

  claim_alias_or_warn "gab" "git absorb"
}

_hf_git_tracking_branch() {
  # 2> /dev/null
  git rev-parse --abbrev-ref --symbolic-full-name @{u}
}

# NOICE: A modified files picker:
#   git ls-files --modified | fzf --height 20% --reverse -m --ansi
# SAVVY: Use Tab/Shift-Tab to select multiple files (fzf -m).
# THANX:
# https://github.com/lukas-reineke/dotfiles/blob/02064d6dccb2e/bash/functions.sh
function gaf() {
  local files
  files="$(git ls-files --modified | fzf --height 20% --reverse -m --ansi)"
  if [ -n "$files" ]; then
    local file
    for file in $files; do
      git add --verbose "$file"
    done
  fi
}

# Open single modified file using FZF picker.
# FIXME/2025-02-16 10:38: Move to DXY, becuase gvim-open-kindness.
function gof() {
  git ls-files --modified |
    fzf --height 20% --reverse --ansi |
    xargs gvim-open-kindness "" "" ""
}

# THANX:
# https://github.com/lukas-reineke/dotfiles/blob/02064d6dccb2e/bash/functions.sh

# GIT_REF_FORMAT="%(refname:short)@[0;90m[[0;31m%(committername)[0;90m]@[0;37m%(contents:subject)[0m"
# GIT_REF_FORMAT='%(refname:short)@\e[0;90m[\e[0;31m%(committername)\e[0;90m]@\e[0;37m%(contents:subject)\e[0m'
# GIT_REF_FORMAT="%(refname:short)@${RED}%(committername)${DGR}@${LGR}%(contents:subject)${NC}"
# DUNNO/2025-02-16: Color codes not working (printing literally).
GIT_REF_FORMAT="%(refname:short)@%(committername)@%(contents:subject)"

function b() {
  . ${SHOILERPLATE:-${HOME}/.kit/sh}/sh-git-nubs/lib/git-nubs.sh

  # is_in_git_repo || return 0
  git_insist_git_repo || return 0

  local BRANCHES BRANCH

  BRANCHES=$(
    git for-each-ref --sort=-committerdate refs/heads/ --format="$GIT_REF_FORMAT" |
      awk '! a[$0]++'
  )

  BRANCH=$(
    echo "$BRANCHES" |
      column -t -s '@' |
      fzf --no-hscroll --height 20% --reverse --ansi |
      awk '{print $1}'
  )

  if [[ -n $BRANCH ]]; then
    git checkout "${BRANCH//.* //}"
  fi
}
# bind '"\C-b":" b\n"'

function ba() {
  . ${SHOILERPLATE:-${HOME}/.kit/sh}/sh-git-nubs/lib/git-nubs.sh

  # is_in_git_repo || return 0
  git_insist_git_repo || return 0

  local BRANCHES BRANCH BRANCHES_REMOTE

  BRANCHES=$(git for-each-ref --sort=-committerdate refs/heads/ --format="$GIT_REF_FORMAT" | awk '! a[$0]++')
  BRANCHES_REMOTE=$(git for-each-ref --sort=-committerdate refs/remotes --format="$GIT_REF_FORMAT@[0;90m[[0;33m" | perl -pe 's|(^[^@]*?)/(.*)|\2\1[0;90m][0m|' | awk '! a[$0]++')

  BRANCH=$(printf '%s\n%s' "$BRANCHES" "$BRANCHES_REMOTE" | column -t -s '@' | fzf --no-hscroll --height 40% --reverse --ansi | awk '{print $1}')

  if [[ -n $BRANCH ]]; then
    git checkout $(echo "$BRANCH" | sed "s/.* //")
  fi
}

# THANX: This almost looks like tig!
# https://github.com/lukas-reineke/dotfiles/blob/02064d6dccb2e/scripts/fzf-git-log.sh
function git-log-fzf() {
  git log --graph --color=always --abbrev-commit \
    --format='%Cred%h%Creset -%C(yellow)%d%Creset %s %Cgreen(%cr) %C(bold blue)<%an>%Creset' |
    fzf --ansi --no-sort --reverse --tiebreak=index --bind=ctrl-s:toggle-sort \
      --header $(basename $(git rev-parse --show-toplevel)) \
      --bind "ctrl-n:preview-down,ctrl-p:preview-up" \
      --bind "ctrl-m:execute:
      (grep -o '[a-f0-9]\{7\}' | head -1 |
      xargs -I % bash -c 'git show --color=always % | diff-so-fancy | less -R') << 'FZF-EOF'
      {}
      FZF-EOF" \
      --expect=ctrl-o \
      --preview "
      (grep -o '[a-f0-9]\{7\}' | head -1 |
      xargs -I % bash -c 'git show --color=always % | diff-so-fancy') << 'FZF-EOF'
      {}
      FZF-EOF"
}

# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #

unset_f_alias_git() {
  unset -f home_fries_aliases_wire_git
  # So meta.
  unset -f unset_f_alias_git
}

# @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@ #

if [ "$0" = "${BASH_SOURCE[0]}" ]; then
  >&2 echo "ERROR: Trying sourcing the file instead: . $0" && exit 1
fi

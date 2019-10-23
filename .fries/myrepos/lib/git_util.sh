#!/bin/bash
# vim:tw=0:ts=2:sw=2:et:norl:
# Project: https://github.com/landonb/home-fries
# License: GPLv3

# Summary: Git Helpers: Check if Dirty/Untracked/Behind; and Auto-commit.

# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #

source_deps () {
  local curdir="${HOME}/.fries/lib"
  if [ -n "${BASH_SOURCE}" ]; then
    curdir=$(dirname -- "${BASH_SOURCE[0]}")
  fi

  source "${curdir}/git-auto-commit.sh"
  source "${curdir}/git-check-status.sh"

  source "${HOME}/.fries/lib/logger.sh"
}

# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #
# @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@ #
# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #

_echo () {
  [ "$(echo -e)" = '' ] && echo -e "${@}" || echo "${@}"
}

_echon () {
  [ "$(echo -e)" = '' ] && echo -e -n "${@}" || echo -n "${@}"
}

# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #

_git_echo_cyclones_forange () {
  # Atrocious:
  #  echo -e "$(bg_forest)$(fg_lightred)$(printf '🌀 %.0s' {1..36})$(attr_reset)"
  #  echo -e "$(bg_forest)$(fg_lightorange)$(printf '🌀 %.0s' {1..36})$(attr_reset)"
  # Not too bad:
  #  echo -e "$(bg_forest)$(fg_lightorange)$(printf '🌀 %.0s' {1..36})$(attr_reset)"
  #  echo -e "$(bg_lightred)$(fg_lightorange)$(printf '🌀 %.0s' {1..36})$(attr_reset)"
  _echo "$(bg_forest)$(fg_lightorange)$(printf '🌀 %.0s' {1..36})$(attr_reset)"
}

_git_echo_cyclones_bmaroon () {
  _echo "$(bg_maroon)$(fg_lightorange)$(printf '🌀 %.0s' {1..36})$(attr_reset)"
}

_git_echo_cyclones_frgreen () {
  _echo "$(bg_orange)$(fg_lightgreen)$(printf '🌀 %.0s' {1..36})$(attr_reset)"
}

# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #

_git_echo_octothorpes_maroon_on_lime () {
  if [ "$(echo -e)" = '' ]; then
    _echo "$(bg_lime)$(fg_maroon)$(printf '#%.0s' {1..77})$(attr_reset)"
  else
    local ssots='#############################################################################'
    _echo "$(bg_lime)$(fg_maroon)${ssots}$(attr_reset)"
  fi
}

# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #
# @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@ #
# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #

git_dir_check () {
  REPO_PATH="$1"
  local dir_okay=0
  if [ "${REPO_PATH}" = ssh://* ]; then
    return ${dir_okay}
  elif [ ! -d "${REPO_PATH}" ]; then
    dir_okay=1
    fatal
    fatal "Not a directory: ${REPO_PATH}"
    fatal " In cwd: $(pwd -P)"
    fatal
    # FIXME/2019-10-23 16:54: travel.sh → myrepos: Fix UX and error messages.
    fatal "Have you run init_travel?"
    fatal
    exit 1
  elif [ ! -d "${REPO_PATH}/.git" && ! -f "${REPO_PATH}/HEAD" ]; then
    dir_okay=1
    local no_git_yo_msg="WARNING: No .git/ or HEAD found under: $(pwd -P)/${REPO_PATH}/"
    warn
    warn "${no_git_yo_msg}"
#    FRIES_GIT_ISSUES_RESOLUTIONS+=("${no_git_yo_msg}")
  else
    local before_cd="$(pwd -L)"
    cd "${REPO_PATH}"
    (git rev-parse --git-dir --quiet 2> /dev/null) && dir_okay=0 || dir_okay=1
    cd "${before_cd}"
  fi
  return ${dir_okay}
}

# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #

must_be_git_dirs () {
  local source_repo="$1"
  local target_repo="${2:-$(pwd)}"  # I.e., $MR_REPO

  local a_problem=0

  git_dir_check "${source_repo}"
  [ $? -ne 0 ] && a_problem=1

  git_dir_check "${target_repo}"
  [ $? -ne 0 ] && a_problem=1

  return ${a_problem}
}

# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #
# @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@ #
# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #

git_checkedout_branch_name () {
  # 2017-04-04: I unplugged the USB stick before ``popoff``
  #   (forgot to hit <CR>) and then got errors on unpack herein:
  #     error: git-status died of signal 7
  #   signal 7 is a bus error, meaning hardware or filesystem or something
  #   is corrupt, most likely. I made a new sync-stick.
  # 2018-03-22: Ha! How have I been so naive? Avoid porcelain!
  #   git status | head -n 1 | grep "^On branch" | /bin/sed -r "s/^On branch //"
  # And this magic!
  #   local branch_name=$(git branch --no-color | grep \* | cut -d ' ' -f2)
  # How many ways did I do it differently herein??
  #   local branch_name=$(git branch --no-color | head -n 1 | /bin/sed 's/^\*\? *//')
  local before_cd="$(pwd -L)"
  cd "$1"
  local branch_name=$(git rev-parse --abbrev-ref HEAD)
  cd "${before_cd}"
  echo "${branch_name}"
}

# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #

# I don't need this fcn. Reports the tracking branch, (generally 'upstream)
#   I think, because @{u}. [Not quite sure what that is; *tracking* remote?]
git_checkedout_remote_branch_name () {
  # Include the name of the remote, e.g., not just feature/foo,
  # but origin/feature/foo.
  local before_cd="$(pwd -L)"
  cd "$1"
  local remote_branch=$(git rev-parse --abbrev-ref --symbolic-full-name @{u})
  cd "${before_cd}"
  echo "${remote_branch}"
}

# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #
# @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@ #
# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #

git_set_remote_travel () {
  local source_repo="$1"
  local target_repo="${2:-$(pwd)}"

  local before_cd="$(pwd -L)"
  cd "${target_repo}"

  local extcd=0
  local remote_url
  remote_url=$(git remote get-url ${MR_REMOTE} 2> /dev/null) || extcd=$? || true

  #trace "  git_set_remote_travel:"
  #trace "   target: ${target_repo}"
  #trace "   remote: ${remote_url}"
  #trace "  git-url: ${extcd}"

  if [ ${extcd} -ne 0 ]; then
    trace "  Wiring the \"${MR_REMOTE}\" remote for first time!"
    git remote add ${MR_REMOTE} "${source_repo}"
  elif [ "${remote_url}" != "${source_repo}" ]; then
    trace "  Rewiring the \"${MR_REMOTE}\" remote url / was: ${remote_url}"
    git remote set-url ${MR_REMOTE} "${source_repo}"
  else
    #trace "  The \"${MR_REMOTE}\" remote url is already correct!"
    : # no-op
  fi

  cd "${before_cd}"
}

# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #

git_fetch_remote_travel () {
  local target_repo="${1:-$(pwd)}"

  local before_cd="$(pwd -L)"
  cd "${target_repo}"







# SKIP_INTERNETS
# NO_NETWORK_OKAY
#
#
#
#

  # Assuming git_set_remote_travel was called previously,
  # lest there is no travel remote.
  if ${SKIP_INTERNETS}; then
    git fetch ${MR_REMOTE} --prune
  else
    local extcd=0
    local git_says
    if ! ${NO_NETWORK_OKAY}; then
      git_says=$(git fetch --all --prune 2>&1) || extcd=$? || true
    else
      git_says=$(git fetch ${MR_REMOTE} --prune 2>&1) || extcd=$? || true
    fi
    local fetch_success=$?
    verbose "git fetch says:\n${git_says}"
    # Use `&& true` in case grep does not match anything,
    # so as not to tickle errexit.
    # 2018-03-23: Is the "has become dangling" message meaningful to me?
     local culled="$(echo "${git_says}" \
      | grep -v "^Fetching " \
      | grep -v "^From " \
      | grep -v "+\? *[a-f0-9]\{7,8\}\.\{2,3\}[a-f0-9]\{7,8\}.*->.*" \
      | grep -v -P '\* \[new branch\] +.* -> .*' \
      | grep -v -P '\* \[new tag\] +.* -> .*' \
      | grep -v "^ \?- \[deleted\] \+(none) \+-> .*" \
      | grep -v "(refs/remotes/origin/HEAD has become dangling)" \
    )"

    [ -n ${culled} ] && warn "git fetch wha?\n${culled}"
    [ -n ${culled} ] && [ ${LOG_LEVEL} -gt ${LOG_LEVEL_VERBOSE} ] && \
      notice "git fetch says:\n${git_says}"

    if [ ${fetch_success} -ne 0 ]; then
      error "Unexpected fetch failure! ${git_says}"
    fi
  fi

  cd "${before_cd}"
}

# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #
# @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@ #
# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #

git_is_rebase_in_progress () {
  local before_cd="$(pwd -L)"
  cd "$1"
  # During a rebase, git uses new directories, so we could check the filesystem:
  #   (test -d ".git/rebase-merge" || test -d ".git/rebase-apply") || die "No!"
  # Or we could be super naive, and porcelain, and git-n-grep:
  #   git -c color.ui=off status | grep "^rebase in progress" > /dev/null
  # Or we could use our plumbing knowledge and do it most rightly.
  #   (Note we use `&& test` so command does not tickle errexit.
  local extcd=0
  # MAYBE/2019-10-23 17:44: Do we need to redirect? 2> /dev/null
  (test -d "$(git rev-parse --git-path rebase-merge)" || \
   test -d "$(git rev-parse --git-path rebase-apply)" \
  ) || extcd=$? || true
  # Non-zero (1) if not rebasing, (0) otherwise.
  local is_rebasing=${extcd}
  cd "${before_cd}"
  return ${is_rebasing}
}

git_must_not_rebasing () {
  local source_branch="$1"
  local target_repo="${2:-$(pwd)}"
  # Caller already changed to appropriate director, so do not pass
  # directory to rebase check, else it'll change directories again,
  # which'll fail if ${target_repo} is a relative path.
  git_is_rebase_in_progress
  local in_rebase=$?
  if [ ${in_rebase} -eq 0 ]; then
    git_issue_complain_rebasing "${source_branch}" "${target_repo}"
    return 1
  fi
  return 0
}

git_issue_complain_rebasing () {
  local source_branch="$1"
  # WEIRD?: I thought to set default one needed colon, e.g., ${2:-default}
  #   but seems to work find without...
  local target_repo="${2:-$(pwd)}"
  local git_says="${3}"

  warn "Skipping branch in rebase, or with unstage commits!"
  warn " ${target_repo}"
}

# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #
# @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@ #
# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #

git_change_branches_if_necessary () {
  local source_branch="$1"
  local target_branch="$2"
  local target_repo="${3:-$(pwd)}"

  local before_cd="$(pwd -L)"
  cd "${target_repo}"

  if [ "${source_branch}" != "${target_branch}" ]; then
    _git_echo_octothorpes_maroon_on_lime
    notice "NOTE: \${source_branch} != \${target_branch}"
    echo
    echo " WRKD: “$(pwd -P)”"
    echo
    echo " Changing branches: “${target_branch}” 》“${source_branch}”"
    echo
    local extcd=0
    git checkout ${source_branch} 2> /dev/null) || extcd=$? || true
    if [ $extcd -ne 0 ]; then
# FIXME: On unpack, this might need/want to be origin/, not travel/ !
      git checkout --track ${MR_REMOTE}/${source_branch}
    fi
    echo "Changed!"
    echo
    _git_echo_octothorpes_maroon_on_lime
# FIXME/2018-03-22: Adding to this array may prevent travel from continuing? I.e., the -D workaround?
#   Or are these msgs printed after everything and do not prevent finishing?
#    FRIES_GIT_ISSUES_RESOLUTIONS+=( \
#      "JUST FYI: Changed branches: ${source_branch} / ${target_repo}"
#    )
  fi

  cd "${before_cd}"
}

# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #
# @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@ #
# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #

git_merge_ff_only () {
  local source_branch="$1"
  local target_repo="${2:-$(pwd)}"

  local before_cd="$(pwd -L)"
  cd "${target_repo}"

  # For a nice fast-forward vs. --no-ff article, see:
  #   https://ariya.io/2013/09/fast-forward-git-merge

  # Ha! 2019-01-24: Seeing:
  #   "fatal: update_ref failed for ref 'ORIG_HEAD': could not write to '.git/ORIG_HEAD'"
  # because my device is full. Guh.

  local extcd=0
  local git_says
  git_says=$(git merge --ff-only ${MR_REMOTE}/${source_branch} 2> /dev/null) || extcd=$? || true
  local merge_success=${extcd}

  # 2018-03-26 16:41: Weird: was this directory moved, hence the => ?
  #    src/js/{ => solutions}/settings/constants.js       |  85 ++-
  #local pattern_txt='^ \S* *\| +\d+ ?[+-]*$'
  local pattern_txt='^ [^\|]+\| +\d+ ?[+-]*$'
  #local pattern_bin='^ \S* *\| +Bin \d+ -> \d+ bytes$'
  #  | grep -P -v " +\S+ +\| +Bin$" \
  #local pattern_bin='^ \S* *\| +Bin( \d+ -> \d+ bytes)?$'
  #local pattern_bin='^ \S*( => \S*)? *\| +Bin( \d+ -> \d+ bytes)?$'
  local pattern_bin='^ [^\|]+\| +Bin( \d+ -> \d+ bytes)?$'

  verbose "git merge says:\n${git_says}"
  # NOTE: The checking-out-files line looks like this would work:
  #         | grep -P -v "^Checking out files: 100% \(\d+/\d+\), done.$" \
  #       but it doesn't, I think because the "100%" was updated live,
  #       so there are other digits and then backspaces, I'd guess.
  #       Though this doesn't work:
  #         | grep -P -v "^Checking out files: [\d\b]+" \
  local culled="$(echo "${git_says}" \
    | grep -v "^Already up to date.$" \
    | grep -v "^Updating [a-f0-9]\{7,10\}\.\.[a-f0-9]\{7,10\}$" \
    | grep -v "^Fast-forward$" \
    | grep -P -v "^Checking out files: " \
    | grep -P -v "^ \d+ files? changed, \d+ insertions?\(\+\), \d+ deletions?\(-\)$" \
    | grep -P -v "^ \d+ files? changed, \d+ insertions?\(\+\)$" \
    | grep -P -v "^ \d+ files? changed, \d+ deletions?\(-\)$" \
    | grep -P -v "^ \d+ insertions?\(\+\), \d+ deletions?\(-\)$" \
    | grep -P -v "^ \d+ files? changed$" \
    | grep -P -v " rename .* \(\d+%\)$" \
    | grep -P -v " create mode \d+ \S+" \
    | grep -P -v " delete mode \d+ \S+" \
    | grep -P -v " mode change \d+ => \d+ \S+" \
    | grep -P -v "^ \d+ insertions?\(\+\)$" \
    | grep -P -v "^ \d+ deletions?\(-\)$" \
    | grep -P -v "${pattern_txt}" \
    | grep -P -v "${pattern_bin}" \
  )"

  # FIXME/2018-03-23 21:30: YO!
# FIXME: need to grep for error here, before wha?
#error: Your local changes to the following files would be overwritten by merge:
#	cfg/sync_repos.sh
#	cfg/travel_tasks.sh
#Please commit your changes or stash them before you merge.
#Aborting

  [ -n ${culled} ] && warn "git merge wha?\n${culled}"
  [ -n ${culled} ] && [ ${LOG_LEVEL} -gt ${LOG_LEVEL_VERBOSE} ] && \
    notice "git merge says:\n${git_says}"

  # 2018-03-23: Would you like something more muted, or vibrant? Trying vibrant.
  #   2018-03-26: It's taking time to tweak the vibrant, colorful display to nice.
  # NOTE: The grep -P option only works on one pattern grep, so cannot use -e, eh?
  # 2018-03-26: First attempt, naive, first line has black bg between last char and NL,
  # but subsequent lines have changed background color to end of line, seems weird:
  #   local changes_txt="$(echo "${git_says}" | grep -P "${pattern_txt}")"
  #   local changes_bin="$(echo "${git_says}" | grep -P "${pattern_bin}")"
  # So use sed to sandwich each line with color changes.
  local grep_sed_sed='
    /bin/sed "s/\$/\\$(attr_reset)/g" \
    | /bin/sed "s/^/\\$(bg_blue)/g"
  '
  local changes_txt="$( \
    echo "${git_says}" | grep -P "${pattern_txt}" | eval "${grep_sed_sed}" \
  )"
  local changes_bin="$( \
    echo "${git_says}" | grep -P "${pattern_bin}" | eval "${grep_sed_sed}" \
  )"
  [ -n "${changes_txt}" ] && \
    info "Changes! in txt: $(fg_lavender)${MR_REPO}\n$(fg_white)$(attr_reset)${changes_txt}"
  [ -n "${changes_bin}" ] && \
    info "Changes! in bin: $(fg_lavender)${MR_REPO}\n$(fg_white)$(attr_reset)${changes_bin}"

  # (lb): Not quite sure why git_must_not_rebasing would not have failed first.
  #   Does this happen?
  if [ ${merge_success} -ne 0 ]; then
    git_issue_complain_rebasing "${source_branch}" "${target_repo}" "${git_says}"
  fi

  cd "${before_cd}"
}

# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #

git_pull_hush () {
  local source_repo="$1"
  local target_repo="${2:-$(pwd)}"

  must_be_git_dirs "${source_repo}" "${target_repo}"
  [ $? -ne 0 ] && return

  local source_branch
  local target_branch=$(git_checkedout_branch_name "${target_repo}")
  if [ "${source_repo}" = ssh://* ]; then
    source_branch=${target_branch}
  else
    source_branch=$(git_checkedout_branch_name "${source_repo}")
  fi

  # 2019-10-07: On handtram, source repo is /x/y/z, target repo is x/y/z, and cwd is /.
  # So source branch and target branch will be the same.

  local before_cd="$(pwd -L)"
  cd "${target_repo}"

  MR_REMOTE="${MR_REMOTE:-travel}"
  # 2018-03-22: Set a remote to the sync device. There's always only 1,
  # apparently. I think this'll work well.
  git_set_remote_travel "${source_repo}"
  git_fetch_remote_travel

  git_must_not_rebasing "${source_branch}" "${target_repo}" && true
  local okay=$?
  if [ ${okay} -ne 0 ]; then
    # The fcn. we just called that failed will have spit out a warning
#    # and added to the final FRIES_GIT_ISSUES_RESOLUTIONS array.
    cd "${before_cd}"
    return
  fi

  # There is a conundrum/enigma/riddle/puzzle/brain-teaser/problem/puzzlement
  # when it comes to what to do about clarifying branches -- should we check
  # every branch for changes, try to fast-forward, and complain if we cannot?
  # That actually seems like the most approriate thing to do!
  # It also feels really, really tedious.
  # FIXME/2018-03-22 22:07: Consider checking all branches for rebase needs!

  # Because `cd` above, do not need to pass "${target_repo}" (on $3).
  git_change_branches_if_necessary "${source_branch}" "${target_branch}"

  # Fast-forward merge (no new commits!) or complain (later).
  # Because `cd` above, passing "$(pwd)" same as "${target_repo}".
  git_merge_ff_only "${source_branch}" "$(pwd)"

  cd "${before_cd}"
} # end: git_pull_hush

# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #

git_merge_ffonly_ssh_mirror () {
  [ -z ${MR_REMOTE} ] && error 'You must set MR_REMOTE!' && exit 1
  [ -z ${MR_REPO} ] && error 'You must set MR_REPO!' && exit 1
  MR_FETCH_HOST=${MR_FETCH_HOST:-${MR_REMOTE}}
  local rel_repo="$(echo ${MR_REPO} | /bin/sed "s#^/##")"
  local ssh_path="ssh://${MR_FETCH_HOST}${rel_repo}"
  git_pull_hush "${ssh_path}" "${MR_REPO}"
}

# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #

main () {
  source_deps
}

main "$@"


#!/bin/bash
# vim:tw=0:ts=2:sw=2:et:norl:
# Project: https://github.com/landonb/home-fries
# License: GPLv3

# Summary: Git Helpers: Fetch from Remote; Merge --Ff-Only; and Update Mirror.

# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #

MR_APP_NAME='mr'

#GIT_BARE_REPO=''
# FIXME/2019-09-27 10:48: Make always --bare, but only to NEW sync stick!
GIT_BARE_REPO='--bare'
#GIT_BARE_REPO=${GIT_BARE_REPO:-}

# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #

source_deps () {
  local libdir="${HOME}/.fries/lib"
  if [ -n "${BASH_SOURCE}" ]; then
    libdir="$(dirname -- ${BASH_SOURCE[0]})../../lib/"
  fi

  . "${libdir}/logger.sh"
}

reveal_biz_vars () {
  # 2019-10-21: (lb): Because myrepos uses subprocesses, our best bet for
  # maintaining data across all repos is to use temporary files.
  MR_TMP_TRAVEL_HINT_FILE='/tmp/home-fries-myrepos.travel-ieWeich9kaph5eiR'
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
# @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@ #
# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #

is_ssh_path () {
  [ "${1#ssh://}" != "${1}" ] && return 0 || return 1
}

lchop_sep () {
  echo $1 | /bin/sed "s#^/##"
}

# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #
# @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@ #
# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #

warn_repo_problem_7char () {
  warn "$(attr_reset)   $(fg_mintgreen)$(attr_emphasis)${1}$(attr_reset)   " \
    "$(fg_mintgreen)${MR_REPO}$(attr_reset)"
}

warn_repo_problem_9char () {
  warn "$(attr_reset)  $(fg_mintgreen)$(attr_emphasis)${1}$(attr_reset)    " \
    "$(fg_mintgreen)${MR_REPO}$(attr_reset)"
}

git_dir_check () {
  local repo_path="$1"
  local repo_name="$2"
  local dir_okay=0
  if is_ssh_path "${repo_path}"; then
    return ${dir_okay}
  elif [ ! -d "${repo_path}" ]; then
    dir_okay=1
    info "No repo found: $(bg_maroon)$(attr_bold)${repo_path}$(attr_reset)"
    if [ "${repo_name}" = 'travel' ]; then
      touch ${MR_TMP_TRAVEL_HINT_FILE}
    else
      # (lb): This should be unreacheable, because $repo_path is $MR_REPO,
      # and `mr` will have failed before now.
      fatal
      fatal "UNEXPECTED: local repo missing?"
      fatal "  Path to pull from is missing:"
      fatal "    “${repo_path}”"
      fatal
    fi
    warn_repo_problem_9char 'notsynced'
  elif [ ! -d "${repo_path}/.git" ] && [ ! -f "${repo_path}/HEAD" ]; then
    dir_okay=1
    info "No .git/|HEAD: $(bg_maroon)$(attr_bold)${repo_path}$(attr_reset)"
    warn_repo_problem_7char 'gitless'
  else
    local before_cd="$(pwd -L)"
    cd "${repo_path}"
    (git rev-parse --git-dir --quiet >/dev/null 2>&1) && dir_okay=0 || dir_okay=1
    cd "${before_cd}"
    if [ ${dir_okay} -ne 0 ]; then
      info "Bad --git-dir: $(bg_maroon)$(attr_bold)${repo_path}$(attr_reset)"
      info "  “$(git rev-parse --git-dir --quiet 2>&1)”"
      warn_repo_problem_9char 'rev-parse'
    fi
  fi
  return ${dir_okay}
}

# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #

must_be_git_dirs () {
  local source_repo="$1"
  local target_repo="$2"
  local source_name="$3"
  local target_name="$4"

  local a_problem=0

  git_dir_check "${source_repo}" "${source_name}"
  [ $? -ne 0 ] && a_problem=1

  git_dir_check "${target_repo}" "${target_name}"
  [ $? -ne 0 ] && a_problem=1

  return ${a_problem}
}

# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #
# @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@ #
# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #

git_travel_cache_setup () {
  ([ "${MR_ACTION}" != 'travel' ] && return 0) || true
  /bin/rm -f "${MR_TMP_TRAVEL_HINT_FILE}"
}

git_travel_cache_teardown () {
  ([ "${MR_ACTION}" != 'travel' ] && return 0) || true
  local ret_code=0
  if [ -e ${MR_TMP_TRAVEL_HINT_FILE} ]; then
    info
    warn "One or more errors suggest that you need to setup the travel device."
    info
    info "You can setup the travel device easily by running:"
    info
    info "  $(fg_lightorange)MR_TRAVEL=${MR_TRAVEL} ${MR_APP_NAME} travel$(attr_reset)"
    ret_code=0
  fi
  /bin/rm -f ${MR_TMP_TRAVEL_HINT_FILE}
  return ${ret_code}
}

# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #
# @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@ #
# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #

travel_ops_reset_stats () {
  DID_CLONE_REPO=0
  DID_SET_REMOTE=0
  DID_FETCH_CHANGES=0
  DID_BRANCH_CHANGE=0
  DID_MERGE_FFWD=0
}

# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #
# @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@ #
# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #

git_ensure_or_clone_target () {
  local source_repo="$1"
  local target_repo="$2"

  # The caller will all `must_be_git_dirs` later to ensure that
  # the target is indeed a git repo, so all we care about here
  # is if the target is missing or an empty directory, then we
  # can clone (into) it.
  if [ -d "${target_repo}" ]; then
    # Check whether the target directory is nonempty and return if so.
    if [ -n "$(/bin/ls -A ${target_repo} 2>/dev/null)" ]; then
      return 0
    fi
  fi

  local retco=0
  local git_resp
  git_resp=$( \
    git clone ${GIT_BARE_REPO} -- "${source_repo}" "${target_repo}" 2>&1 \
  ) || retco=$?
  if [ ${retco} -ne 0 ]; then
    warn "Clone failed!"
    warn "  \$ git clone ${GIT_BARE_REPO} -- '${source_repo}' '${target_repo}'"
    warn "  ${git_resp}"
    warn_repo_problem_9char 'uncloned!'
    return 1
  fi

  DID_CLONE_REPO=1
  info "  $(fg_mintgreen)$(attr_emphasis)✓ cloned🖐$(attr_reset)  " \
    "$(fg_mintgreen)${MR_REPO}$(attr_reset)"
}

# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #
# @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@ #
# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #

git_checkedout_branch_name_direct () {
  local before_cd="$(pwd -L)"
  cd "$1"
  local branch_name=$(git rev-parse --abbrev-ref HEAD)
  cd "${before_cd}"
  echo "${branch_name}"
}

git_checkedout_branch_name_remote () {
  local target_repo="$1"
  local remote_name="${2:-${MR_REMOTE}}"

  local before_cd="$(pwd -L)"
  cd "${target_repo}"
  local branch_name=$( \
    git remote show ${remote_name} |
    grep "HEAD branch:" |
    /bin/sed -e "s/^.*HEAD branch:\s*//" \
  )
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

git_is_bare_repository () {
  [ $(git rev-parse --is-bare-repository) = 'true' ] && return 0 || return 1
}

git_must_be_clean () {
  # If a bare repository, no working status... so inherently clean, er, negative.
  git_is_bare_repository && return 0 || true
  [ -z "$(git status --porcelain)" ] && return 0 || true
  info "   $(fg_lightorange)$(attr_underline)✗ dirty$(attr_reset)   " \
    "$(fg_lightorange)$(attr_underline)${MR_REPO}$(attr_reset)  $(fg_hotpink)✗$(attr_reset)"
  exit 1
}

# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #
# @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@ #
# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #

git_set_remote_travel () {
  local source_repo="$1"
  local target_repo="${2:-$(pwd -L)}"
  # Instead of $(pwd), could use environ:
  #   local target_repo="${2:-${MR_REPO}}"

  local before_cd="$(pwd -L)"
  cd "${target_repo}"

  local extcd=0
  local remote_url
  remote_url=$(git remote get-url ${MR_REMOTE} 2>/dev/null) || extcd=$?

  #trace "  git_set_remote_travel:"
  #trace "   target: ${target_repo}"
  #trace "   remote: ${remote_url}"
  #trace "  git-url: ${extcd}"

  if [ ${extcd} -ne 0 ]; then
    #trace "  Fresh remote wired for “${MR_REMOTE}”"
    info "  $(fg_mintgreen)$(attr_emphasis)✓ remote👈$(attr_reset) " \
      "$(fg_mintgreen)${MR_REPO}$(attr_reset)"
    git remote add ${MR_REMOTE} "${source_repo}"
    DID_SET_REMOTE=1
  elif [ "${remote_url}" != "${source_repo}" ]; then
    info "  $(fg_mintgreen)$(attr_emphasis)✓ remote👆$(attr_reset) " \
      "$(fg_mintgreen)${MR_REPO}$(attr_reset)"
    debug "  Reset remote wired for “${MR_REMOTE}”" \
      "(was: $(attr_italic)${remote_url}$(attr_reset))"
    git remote set-url ${MR_REMOTE} "${source_repo}"
    DID_SET_REMOTE=1
  else
    #trace "  The “${MR_REMOTE}” remote url is already correct!"
    : # no-op
  fi

  cd "${before_cd}"
}

# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #

git_fetch_remote_travel () {
  local target_repo="${1:-$(pwd -L)}"
  # Instead of $(pwd), could use environ:
  #   local target_repo="${1:-${MR_REPO}}"
  local target_name="$2"

  local before_cd="$(pwd -L)"
  cd "${target_repo}"

  local extcd=0
  local git_resp
  git_resp="$(git fetch ${MR_REMOTE} --prune 2>&1)" || extcd=$?
  local fetch_success=${extcd}
  verbose "git fetch says:\n${git_resp}"
  # Use `&& true` in case grep does not match anything,
  # so as not to tickle errexit.
  # 2018-03-23: Is the "has become dangling" message meaningful to me?
   local culled="$(echo "${git_resp}" \
    | grep -v "^Fetching " \
    | grep -v "^From " \
    | grep -v "+\? *[a-f0-9]\{7,8\}\.\{2,3\}[a-f0-9]\{7,8\}.*->.*" \
    | grep -v -P '\* \[new branch\] +.* -> .*' \
    | grep -v -P '\* \[new tag\] +.* -> .*' \
    | grep -v "^ \?- \[deleted\] \+(none) \+-> .*" \
    | grep -v "(refs/remotes/origin/HEAD has become dangling)" \
  )"

  [ -n "${culled}" ] && warn "git fetch wha?\n${culled}" || true
  [ -n "${culled}" ] && [ ${LOG_LEVEL} -gt ${LOG_LEVEL_VERBOSE} ] && \
    notice "git fetch says:\n${git_resp}" || true

  if [ ${fetch_success} -ne 0 ]; then
    error "Unexpected fetch failure! ${git_resp}"
  fi

  if [ -n "${git_resp}" ]; then
    DID_FETCH_CHANGES=1
  fi
  if [ "${target_name}" = 'travel' ]; then
    if [ -n "${git_resp}" ]; then
      info "  $(fg_mintgreen)$(attr_emphasis)✓ fetched🤙$(attr_reset)" \
        "$(fg_mintgreen)${MR_REPO}$(attr_reset)"
    else
      debug "  $(fg_mediumgrey)fetchless$(attr_reset)  " \
        "$(fg_mediumgrey)${MR_REPO}$(attr_reset)"
    fi
  fi

  cd "${before_cd}"
}

# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #
# @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@ #
# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #

git_change_branches_if_necessary () {
  local source_branch="$1"
  local target_branch="$2"
  local target_repo="${3:-$(pwd -L)}"
  # Instead of $(pwd), could use environ:
  #   local target_repo="${3:-${MR_REPO}}"

  local before_cd="$(pwd -L)"
  cd "${target_repo}"

  if [ "${source_branch}" != "${target_branch}" ]; then
    info "  $(fg_mintgreen)$(attr_emphasis)✓ checkout $(attr_reset)" \
      "$(fg_lightorange)$(attr_underline)${target_branch}$(attr_reset)" \
      "》$(fg_lightorange)$(attr_underline)${source_branch}$(attr_reset)"
    if git_is_bare_repository; then
      git symbolic-ref HEAD refs/heads/${source_branch}
    else
      local extcd=0
      (git checkout ${source_branch} >/dev/null 2>&1) || extcd=$?
      if [ $extcd -ne 0 ]; then
  # FIXME: On unpack, this might need/want to be origin/, not travel/ !
        git checkout --track ${MR_REMOTE}/${source_branch}
      fi
    fi
    DID_BRANCH_CHANGE=1
  fi

  cd "${before_cd}"
}

# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #
# @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@ #
# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #

git_merge_ff_only () {
  local source_branch="$1"
  local target_repo="${2:-$(pwd -L)}"
  # Instead of $(pwd), could use environ:
  #   local target_repo="${2:-${MR_REPO}}"

  local before_cd="$(pwd -L)"
  cd "${target_repo}"

  # For a nice fast-forward vs. --no-ff article, see:
  #   https://ariya.io/2013/09/fast-forward-git-merge

  # Ha! 2019-01-24: Seeing:
  #   "fatal: update_ref failed for ref 'ORIG_HEAD': could not write to '.git/ORIG_HEAD'"
  # because my device is full. Guh.

  local extcd=0
  local git_resp
  git_resp=$(git merge --ff-only ${MR_REMOTE}/${source_branch} 2>&1) || extcd=$?
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

  verbose "git merge says:\n${git_resp}"
  # NOTE: The checking-out-files line looks like this would work:
  #         | grep -P -v "^Checking out files: 100% \(\d+/\d+\), done.$" \
  #       but it doesn't, I think because the "100%" was updated live,
  #       so there are other digits and then backspaces, I'd guess.
  #       Though this doesn't work:
  #         | grep -P -v "^Checking out files: [\d\b]+" \
  local culled="$(echo "${git_resp}" \
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

  [ -n "${culled}" ] && warn "git merge wha?\n${culled}" || true
  [ -n "${culled}" ] && [ ${LOG_LEVEL} -gt ${LOG_LEVEL_VERBOSE} ] && \
    notice "git merge says:\n${git_resp}" || true

  # NOTE: The grep -P option only works on one pattern grep, so cannot use -e, eh?
  # 2018-03-26: First attempt, naive, first line has black bg between last char and NL,
  # but subsequent lines have changed background color to end of line, seems weird:
  #   local changes_txt="$(echo "${git_resp}" | grep -P "${pattern_txt}")"
  #   local changes_bin="$(echo "${git_resp}" | grep -P "${pattern_bin}")"
  # So use sed to sandwich each line with color changes.
  local grep_sed_sed='
    /bin/sed "s/\$/\\$(attr_reset)/g" |
    /bin/sed "s/^/\\$(bg_blue)/g"
  '
  #
  local changes_txt="$( \
    echo "${git_resp}" | grep -P "${pattern_txt}" | eval "${grep_sed_sed}" \
  )"
  local changes_bin="$( \
    echo "${git_resp}" | grep -P "${pattern_bin}" | eval "${grep_sed_sed}" \
  )"
  #
  if [ -n "${changes_txt}" ]; then
    info "  $(fg_mintgreen)$(attr_emphasis)txt+$(attr_reset)       " \
      "$(fg_mintgreen)${MR_REPO}$(attr_reset)"
    info "${changes_txt}"
  fi
  if [ -n "${changes_bin}" ]; then
    info "       $(fg_mintgreen)$(attr_emphasis)bin+$(attr_reset)  " \
      "$(fg_mintgreen)${MR_REPO}$(attr_reset)"
    info "${changes_bin}"
  fi

  # We verified `git status --porcelain` indicated nothing before trying to merge,
  # so this could mean the branch diverged from remote, or something. Inform user.
  if [ ${merge_success} -ne 0 ]; then
    info "  $(fg_lightorange)$(attr_underline)mergefail$(attr_reset)  " \
      "$(fg_lightorange)$(attr_underline)${MR_REPO}$(attr_reset)  $(fg_hotpink)✗$(attr_reset)"
    warn "Merge failed! \`merge --ff-only ${MR_REMOTE}/${source_branch}\` says:"
    warn " ${git_resp}"
    # warn " target_repo: ${target_repo}"
  elif (echo "${git_resp}" | grep '^Already up to date.$' >/dev/null); then
    debug "  $(fg_mintgreen)up-2-date$(attr_reset)  " \
      "$(fg_mintgreen)${MR_REPO}$(attr_reset)"
  elif [ -z "${changes_txt}" ] && [ -z "${changes_bin}" ]; then
    # A warning, so you can update the grep above and recognize this output.
    warn "  $(fg_mintgreen)$(attr_emphasis)!familiar$(attr_reset)  " \
      "$(fg_mintgreen)${MR_REPO}$(attr_reset)"
  # else, ${merge_success} true, and either/or changes_txt/_bin,
  # so we've already printed multiple info statements.
  fi

  cd "${before_cd}"

  return ${merge_success}
}

# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #

git_fetch_n_cobr () {
  local source_repo="$1"
  local target_repo="$2"
  local source_name="$3"
  local target_name="$4"

  must_be_git_dirs "${source_repo}" "${target_repo}" "${source_name}" "${target_name}"
  [ $? -ne 0 ] && return $? || true  # Obviously unreacheable if caller used `set -e`.

  local source_branch
  if is_ssh_path "${source_repo}"; then
    source_branch=$(git_checkedout_branch_name_remote "${target_repo}" "${MR_REMOTE}")
  else
    source_branch=$(git_checkedout_branch_name_direct "${source_repo}")
  fi
  local target_branch=$(git_checkedout_branch_name_direct "${target_repo}")

  local before_cd="$(pwd -L)"
  cd "${target_repo}"  # (lb): Probably $MR_REPO, which is already cwd.

  local extcd=0
  (git_must_be_clean) || extcd=$?
  if [ ${extcd} -ne 0 ]; then
    cd "${before_cd}"
    exit ${extcd}
  fi

  # 2018-03-22: Set a remote to the sync device. There's always only 1,
  # apparently. I think this'll work well.
  git_set_remote_travel "${source_repo}"
  git_fetch_remote_travel "${target_repo}" "${target_name}"

  # Because `cd` above, do not need to pass "${target_repo}" (on $3).
  git_change_branches_if_necessary "${source_branch}" "${target_branch}"

  cd "${before_cd}"
}

# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #

git_fetch_n_cobr_n_merge () {
  local source_repo="$1"
  local target_repo="$2"
  local source_name="$3"
  local target_name="$4"
  travel_ops_reset_stats
  git_fetch_n_cobr "${source_repo}" "${target_repo}" "${source_name}" "${target_name}"
  # Fast-forward merge, so no new commits, and complain if cannot.
  git_merge_ff_only "${source_branch}" "${target_repo}"
}

git_pack_travel_device () {
  local source_repo="$1"
  local target_repo="$2"
  travel_ops_reset_stats
  git_ensure_or_clone_target "${source_repo}" "${target_repo}"
  git_fetch_n_cobr "${source_repo}" "${target_repo}" 'local' 'travel'
}

# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #

git_merge_check_env_remote () {
  [ -z "${MR_REMOTE}" ] && error 'You must set MR_REMOTE!' && exit 1 || true
}

git_merge_check_env_repo () {
  [ -z "${MR_REPO}" ] && error 'You must set MR_REPO!' && exit 1 || true
}

git_merge_check_env_travel () {
  [ -z "${MR_TRAVEL}" ] && >&2 echo 'You must set MR_TRAVEL!' && exit 1 || true
}

# The `mr ffssh` action.
git_merge_ffonly_ssh_mirror () {
  git_merge_check_env_remote
  git_merge_check_env_repo
  MR_FETCH_HOST=${MR_FETCH_HOST:-${MR_REMOTE}}
  local rel_repo=$(lchop_sep "${MR_REPO}")
  local ssh_path="ssh://${MR_FETCH_HOST}/${rel_repo}"
  git_fetch_n_cobr_n_merge "${ssh_path}" "${MR_REPO}" 'ssh' 'local'
}

# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #

git_update_ensure_ready () {
  git_merge_check_env_travel
  git_merge_check_env_repo
  local dev_path=$(readlink -m "${MR_TRAVEL}/${MR_REPO}")
  echo "${dev_path}"
}

# The `mr travel` action.
git_update_device_fetch_from_local () {
  MR_REMOTE=${MR_REMOTE:-$(hostname)}
  local dev_path=$(git_update_ensure_ready)
  git_pack_travel_device "${MR_REPO}" "${dev_path}"
}

# The `mr unpack` action.
git_update_local_fetch_from_device () {
  git_merge_check_env_remote
  local dev_path=$(git_update_ensure_ready)
  git_fetch_n_cobr_n_merge "${dev_path}" "${MR_REPO}" 'travel' 'local'
}

# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #

main () {
  source_deps
  reveal_biz_vars
}

main "$@"


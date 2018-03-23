#!/bin/bash
# Last Modified: 2017.10.16
# vim:tw=0:ts=2:sw=2:et:norl:

# File: .fries/lib/git_util.sh
# Author: Landon Bouma (landonb &#x40; retrosoft &#x2E; com)
# Project Page: https://github.com/landonb/home-fries
# Summary: Git Helpers: Check if Dirty/Untracked/Behind; and Auto-commit.
# License: GPLv3

# Usage: Source this script. Call its functions. Use its exports.

TRAVEL_REMOTE="travel"

source_deps() {
  # source defaults to the current directory, but the caller's,
  # so this won't always work:
  #   source bash_base.sh
  #   source process_util.sh
  local curdir=$(dirname -- "${BASH_SOURCE[0]}")
  source ${curdir}/bash_base.sh
  # Load: die, reset_errexit, tweak_errexit
  source ${curdir}/process_util.sh
  source ${curdir}/logger.sh
}

# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #
# find_git_parent

# FIXME/2017-06-24: When translating for Go, make generic/work on any target dir.
find_git_parent () {
  local file_path="$1"
  #echo "find_git_parent: file_path: ${1}"
  if [[ -z "${file_path}" ]]; then
    # Assume curdir, I suppose.
    file_path="."
  fi
  # Crap, if symlink, blows up, because prefix of git status doesn't match.
  local rel_path=$(dirname -- "${file_path}")
  REL_PREFIX=''
  #echo "find_git_parent: rel_path/2: ${rel_path}"
  local double_down=false
  if [[ ${rel_path} == '.' ]]; then
    double_down=true
    #echo "find_git_parent: rel_path/2b: ${rel_path}"
  fi
  REPO_PATH=""
  while [[ ${rel_path} != '/' || ${rel_path} != '.' ]]; do
    #echo "find_git_parent: rel_path/3: ${rel_path}"
    if [[ -d "${rel_path}/.git" ]]; then
      REPO_PATH=${rel_path}
      break
    else
      # Keep looping.
      if ! ${double_down}; then
        rel_path=$(dirname -- "${rel_path}")
      else
        local abs_path=$(readlink -f -- "${rel_path}")
        if [[ ${abs_path} == '/' ]]; then
          #warn "WARNING: find_git_parent: No parent found for ${file_path}"
          break
        fi
        rel_path=../${rel_path}
        REL_PREFIX=../${REL_PREFIX}
      fi
    fi
  done
  #echo "find_git_parent: REPO_PATH: ${REPO_PATH}"
  #echo "find_git_parent: rel_path: ${rel_path}"
  #echo "find_git_parent: REL_PREFIX: ${REL_PREFIX}"
}

# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #
# git_check_generic_file

git_check_generic_file () {
  # git_check_generic_file "file-path"

  local repo_file="$1"
  # Set REPO_PATH.
  find_git_parent ${repo_file}
  # Strip the git path from the absolute file path.
  repo_file=${repo_file#${REPO_PATH}/}

#  pushd ${REPO_PATH} &> /dev/null
  pushd_or_die "${REPO_PATH}"

  tweak_errexit
# FIXME/2018-03-22: Verify porcelain usage (vs. plumbing).
  git status --porcelain ${repo_file} | grep "^\W*M\W*${repo_file}" &> /dev/null
  local grep_result=$?
  reset_errexit

  if [[ ${grep_result} -eq 0 ]]; then
    # It's dirty.
    :
  fi

#  popd &> /dev/null
  popd_perhaps "${REPO_PATH}"
} # end: git_check_generic_file

# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #
# git_commit_generic_file

git_commit_generic_file () {
  # git_commit_generic_file "file-path" "commit-msg"

  # MEH: DRY: First part of this fcn is: git_check_generic_file

  local repo_file="$1"
  local commit_msg="$2"
  if [[ -z ${commit_msg} ]]; then
    echo "WRONG: git_commit_generic_file repo_file commit_msg"
    return 1
  fi
  # Set REPO_PATH.
  find_git_parent ${repo_file}
  # Strip the git path from the absolute file path.
  repo_file=${repo_file#${REPO_PATH}/}

  #echo "Repo base: ${REPO_PATH}"
  #echo "Repo file: ${repo_file}"

#  pushd ${REPO_PATH} &> /dev/null
  pushd_or_die "${REPO_PATH}"

  tweak_errexit
# FIXME/2018-03-22: Verify porcelain usage (vs. plumbing).
# FIXME/2018-03-23: Replace tweak_errexit/reset_errexit with && true.
  git status --porcelain ${repo_file} | grep "^\W*M\W*${repo_file}" &> /dev/null
  local grep_result=$?
  reset_errexit

  if [[ ${grep_result} -eq 0 ]]; then
    # It's dirty.
    local cur_dir=$(basename -- $(pwd -P))
    if ! ${AUTO_COMMIT_FILES}; then
      echo
      echo -n "HEY, HEY: Your ${cur_dir}/${repo_file} is dirty. Wanna check it in? [y/n] "
      read -e YES_OR_NO
    else
      info "Committing dirty file: ${FG_LAVENDER}${cur_dir}/${repo_file}"
      YES_OR_NO="Y"
    fi
    if [[ ${YES_OR_NO^^} == "Y" ]]; then
      git add ${repo_file}
      # FIXME/2017-04-13: Probably shouldn't redirect to netherspace here.
      #   U	source/landonb/Unfiled_Notes.rst
      #   error: Committing is not possible because you have unmerged files.
      #   hint: Fix them up in the work tree, and then use 'git add/rm <file>'
      #   hint: as appropriate to mark resolution and make a commit.
      #   fatal: Exiting because of an unresolved conflict.
      git commit -m "${commit_msg}" &> /dev/null
      # FIXME: travel fails on uncommitted changes!
      #        (Last night I had a conflict that I took home, because `packme`
      #        didn't complain, so at home I resolved it, but I forgot to do
      #        so at work, and now packme is failing....)
      #   U	cfg/sync_repos.sh
      #   error: Committing is not possible because you have unmerged files.
      #   hint: Fix them up in the work tree, and then use 'git add/rm <file>'
      #   hint: as appropriate to mark resolution and make a commit.
      #   fatal: Exiting because of an unresolved conflict.
      if ! ${AUTO_COMMIT_FILES}; then
        echo 'Committed!'
      fi
    fi
  fi

#  popd &> /dev/null
  popd_perhaps "${REPO_PATH}"
} # end: git_commit_generic_file

# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #
# git_commit_all_dirty_files

git_commit_all_dirty_files () {

  # 2016-10-18: I considered adding a `git add --all`, but that
  #             really isn't always desirable...

  REPO_PATH="$1"

  if [[ ! -e ${REPO_PATH} ]]; then
    warn
    warn "WARNING: Skipping ${REPO_PATH}: Not found"
    warn
# Is this right?
    return 1
  fi

  info "Checking for git dirtiness at: ${FG_LAVENDER}${REPO_PATH}"

  pushd_or_die "${REPO_PATH}"

  tweak_errexit

  # We ignore untracted files here because they cannot be added
  # by a generic `git add -u` -- in fact, git should complain.
  #
  # So auto-commit works on existing git files, but not on new ones.
  #
  # (However, `git add --all` adds untracked files, but rather than
  # automate this, don't. Because user might really want to update
  # .gitignore instead, or might still be considering where an un-
  # tracked file should reside.)

  # Also, either grep pattern should work:
  #
  #   git status --porcelain | grep "^\W*M\W*" &> /dev/null
  #   git status --porcelain | grep "^[^\?]" &> /dev/null
  #
  # but I'm ignorant of anything other than the two codes,
  # '?? filename', and ' M filename', so let's be inclusive and
  # just ignore new files, rather than being exclusive and only
  # looking for modified files. If there are untracted files, a
  # later call to git_status_porcelain on the same repo will die.
  #git status --porcelain | grep "^\W*M\W*" &> /dev/null
# FIXME/2018-03-22: Verify porcelain usage (vs. plumbing).
  git status --porcelain | grep "^[^\?]" &> /dev/null
  local grep_result=$?
  reset_errexit

  if [[ ${grep_result} -eq 0 ]]; then
    # It's dirty.
    if ! ${AUTO_COMMIT_FILES}; then
      echo
      echo -n "HEY, HEY: Your ${REPO_PATH} is dirty. Wanna check it all in? [y/n] "
      read -e YES_OR_NO
      echo
    else
#      notice "HEY, HEY:" \
#        "Your ${FONT_UNDERLINE}${FG_LAVENDER}${REPO_PATH}${FONT_NORMAL} is dirty." \
#        "Let's check that in for ya."
#  #[[ -n ${changes} ]] && notice " ${BG_DARKGRAY}${changes}"
#        "Auto-commit dirty file(s): ${FONT_UNDERLINE}${FG_LAVENDER}${REPO_PATH}${FONT_NORMAL}"
      notice \
        "Auto-commit dirty file(s): ${FONT_UNDERLINE}${BG_DARKGRAY}${REPO_PATH}${FONT_NORMAL}"
      YES_OR_NO="Y"
    fi
    if [[ ${YES_OR_NO^^} == "Y" ]]; then
      git add -u
      git commit -m "Auto-commit by Curly." &> /dev/null
      verbose 'Committed!'
    fi
  fi
  popd_perhaps "${REPO_PATH}"
} # end: git_commit_all_dirty_files

# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #

echo_cyclones_light_on_light () {
  #echo -e "${BG_FOREST}${FG_LIGHTRED}$(printf '🌀 %.0s' {1..36})${FONT_NORMAL}"
  #echo -e "${BG_FOREST}${FG_LIGHTORANGE}$(printf '🌀 %.0s' {1..36})${FONT_NORMAL}"
  echo -e "${BG_LIGHTRED}${FG_LIGHTORANGE}$(printf '🌀 %.0s' {1..36})${FONT_NORMAL}"
}

echo_cyclones_forange () {
  #echo -e "${BG_FOREST}${FG_LIGHTRED}$(printf '🌀 %.0s' {1..36})${FONT_NORMAL}"
  echo -e "${BG_FOREST}${FG_LIGHTORANGE}$(printf '🌀 %.0s' {1..36})${FONT_NORMAL}"
  #echo -e "${BG_LIGHTRED}${FG_LIGHTORANGE}$(printf '🌀 %.0s' {1..36})${FONT_NORMAL}"
}

# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #
# git_status_porcelain

# *** Git: check 'n commit, maybe

# FIXME/2018-03-22: This function is obnoxiously long. And complex.
#   And why is it porcelain and not plumbing?
# FIXME/2018-03-22: Verify porcelain usage (vs. plumbing).

# NOTE: This fcn. expects to be run from the root of the git repo.
git_status_porcelain () {
  local working_dir="$1"
  local skip_remote_check=$2

  # MAYBE: Don't be a stickler?
  #  local working_dir="${1-$(pwd)}"
#  #  pushd "${working_repo}" &> /dev/null
  #  popd &> /dev/null
  #  pushd_or_die "${working_repo}"

  # ***

  # MAYBE: Does this commits of known knowns feel awkward here?
  #   [2018-03-23 00:08: I think perhaps I meant, use an infuser/plugin?]

  # Be helpful! We can take care of the known knowns.
# FIXME/2018-03-23: This is an obnoxious side effect. Shouldn't get committed here.

  git_commit_generic_file \
    ".ignore" \
    "Update .ignore."
    #"Update .ignore during packme."

  git_commit_generic_file \
    ".agignore" \
    "Update .agignore."
    #"Update .agignore during packme."

  git_commit_generic_file \
    ".gitignore" \
    "Update .gitignore."
    #"Update .gitignore during packme."

  # ***

  local dirty_repo=false

# FIXME/2018-03-23: Replace `git status --porcelain` with proper plumbing.

# FIX THIS
  # Use eval's below because of the GREPPERS.

  unstaged_changes_found=false
  # ' M' is modified but not added.
  tweak_errexit
  eval git status --porcelain ${GREPPERS} | grep "^ M " &> /dev/null
  if [[ $? -eq 0 ]]; then
    unstaged_changes_found=true
  fi
  reset_errexit
  if ${unstaged_changes_found}; then
    dirty_repo=true
    warn "WARNING: Unstaged changes found in $working_dir"
  fi

  local grep_result

  # 'M ' is added but not committed!
  tweak_errexit
  eval git status --porcelain ${GREPPERS} | grep "^M  " &> /dev/null
  grep_result=$?
  reset_errexit
  if [[ ${grep_result} -eq 0 ]]; then
    dirty_repo=true
    warn "WARNING: Uncommitted changes found in $working_dir"
  fi

  # '^?? ' is untracked.
  tweak_errexit
  eval git status --porcelain ${GREPPERS} | grep "^?? " &> /dev/null
  grep_result=$?
  reset_errexit
  if [[ ${grep_result} -eq 0 ]]; then
    dirty_repo=true
    warn "WARNING: Untracked files found in $working_dir"
  fi

  tweak_errexit
  if ! ${dirty_repo}; then
    if [[ -n ${GREPPERS} ]]; then
      eval git status --porcelain ${GREPPERS} &> /dev/null
      if [[ $? -eq 0 ]]; then
        warn "WARNING: git status --porcelain: non-zero exit"
        dirty_repo=true
      fi
    else
      local n_bytes=$(git status --porcelain | wc -c)
      if [[ ${n_bytes} -gt 0 ]]; then
        warn "WARNING: git status --porcelain: n_bytes > 0"
        dirty_repo=true
      fi
    fi
  else
    eval git status --porcelain ${GREPPERS} | grep -v "^ M " &> /dev/null
    if [[ $? -eq 0 ]]; then
        warn "WARNING: git status --porcelain: grepped"
      dirty_repo=true
    fi
  fi
  reset_errexit

  if ${dirty_repo}; then
#echo_octothorpes_maroon_on_lime
#info "🌀🌀🌀🌀🌀🌀🌀🌀🌀🌀🌀🌀🌀🌀🌀🌀🌀🌀🌀🌀🌀🌀🌀🌀🌀🌀🌀🌀🌀🌀🌀🌀🌀🌀🌀🌀🌀🌀"
#echo_cyclones_white_on_red
echo
#echo_cyclones_light_on_light
echo_cyclones_forange
echo
    warn "SKIPPING REPO: Dirty things found in ${working_dir}"
    # Although we print this copy-pasta later, at end of script,
    # it's nice to do so at runtime so user can get started resolving
    # conflicts before travel.sh finishes running.
#    warn "========================================="
    echo
    echo "  cdd $(pwd) && git add -p"
#    warn "========================================="
    if ! ${SKIP_GIT_DIRTY}; then
      # FIXME: This message pertains to travel.sh.
#      warn "Please fix. Or run with -D (skip all git warnings)"
#      warn "            or run with -DD (skip warnings about $0)"
      FRIES_GIT_ISSUES_DETECTED=true
      export FRIES_GIT_ISSUES_DETECTED
      FRIES_GIT_ISSUES_RESOLUTIONS+=("cdd $(pwd) && git add -p")
#      export FRIES_GIT_ISSUES_RESOLUTIONS
      if ${FRIES_FAIL_ON_GIT_ISSUE}; then
        return 1
      fi
    else
      echo
      warn "This is your only warning, per your -D'esire!"
#      warn
    fi
echo
#echo_octothorpes_maroon_on_lime
#echo_cyclones_white_on_red
echo_cyclones_forange
echo
    GIT_DIRTY_FILES_FOUND=true
    export GIT_DIRTY_FILES_FOUND
  fi

  # Is this branch behind its remote?
  # E.g.s,
  #  Your branch is up-to-date with 'origin/master'.
  # and
  #  Your branch is ahead of 'origin/master' by 281 commits.

  # But don't care if not really a remote, i.e., local origin.
  tweak_errexit
  # Need to use grep's [-P]erl-defined regex that includes the tab character.
  #






# FIXME/2018-03-23 00:28: Using 'origin' is wrong! See: TRAVEL_REMOTE
#





  git remote -v | grep -P "^origin\t\/" > /dev/null
  grep_result=$?
  reset_errexit

  if [[ ${grep_result} -ne 0 ]]; then
    # Not a local origin.

    if [[ -n $(git remote -v) ]]; then
      # Not a remote-less repo.

      #local branch_name=$(git branch --no-color | head -n 1 | /bin/sed 's/^\*\? *//')
      local branch_name=$(git branch --no-color | grep \* | cut -d ' ' -f2)
      #echo "branch_name: ${branch_name}"

      # git status always compares against origin/master, or at least I
      # think it's stuck doing that. So this method only works if the
      # local branch is also master:
      if false; then
        tweak_errexit
        git status | grep "^Your branch is up-to-date with" &> /dev/null
        grep_result=$?
        reset_errexit
        if [[ ${grep_result} -ne 0 ]]; then
          warn "WARNING: Branch is behind origin/${branch_name} at $working_dir"
          echo "============================================================"
          echo
          echo "  cdd $(pwd) && git push origin ${branch_name} && popd"
          echo
          echo "============================================================"
          if ! ${SKIP_GIT_DIRTY}; then
            # FIXME: This message pertains to travel.sh.
            echo "Please fix. Or run with -D (skip all git warnings)"
            FRIES_GIT_ISSUES_DETECTED=true
            export FRIES_GIT_ISSUES_DETECTED
            FRIES_GIT_ISSUES_RESOLUTIONS+=( \
              "cdd $(pwd) && git push origin ${branch_name} && popd"
            )
#            export FRIES_GIT_ISSUES_RESOLUTIONS
            if ${FRIES_FAIL_ON_GIT_ISSUE}; then
              return 1
            fi
          else
            echo "Skipping."
            echo
          fi
          GIT_DIRTY_FILES_FOUND=true
          export GIT_DIRTY_FILES_FOUND
        fi
      fi

      # So instead we use git remote. E.g.,
      #
      # $ git remote show origin
      # * remote origin
      #   Fetch URL: ssh://git@github.com/someuser/some-project
      #   Push  URL: ssh://git@github.com/someuser/some-project
      #   HEAD branch: master
      #   Remote branches:
      #     develop           tracked
      #     feature/CLIENT-77 tracked
      #     feature/CLIENT-86 tracked
      #     master            tracked
      #   Local branches configured for 'git pull':
      #     feature/CLIENT-86 merges with remote master
      #     master            merges with remote master
      #   Local refs configured for 'git push':
      #     feature/CLIENT-86 pushes to feature/CLIENT-86 (up to date)
      #     master            pushes to master            (local out of date)
      if ! ${skip_remote_check} && [[ -n ${skip_remote_check} ]]; then

        tweak_errexit
        # If we didn't --no-color the branch_name, we'd have to strip-color.
        #  stripcolors='/bin/sed -r "s/\x1B\[([0-9]{1,2}(;[0-9]{1,2})?)?[mGK]//g"'
        local git_push_staleness=$(git remote show origin \
          | grep "^\W*${branch_name}\W\+pushes to\W\+${branch_name}\W\+")

        grep_result=$?
        reset_errexit
        if [[ ${grep_result} -ne 0 ]]; then

          tweak_errexit
          git remote show origin 2>&1 | grep "^ssh: Could not resolve hostname "
          grep_result=$?
          reset_errexit
          if [[ ${grep_result} -eq 0 ]]; then
            echo "ERROR: It looks like you're offline."
            return 2
          fi

          echo "ERROR: Unexpected: Could not find \"${branch_name} pushes to ${branch_name}\""
          echo "                   in the output of"
          echo "                      git remote show origin"
          echo
          echo "cwd: $(pwd -P)"
          echo "branch_name=\"${branch_name}\""
          echo "git remote show origin | grep \"^\\W*\${branch_name}\\W\\+pushes to\\W\\+\${branch_name}\\W\\+\""
          where
          # AHAHAHA/2017-09-08: This happened because I hadn't pushed yet.
          #   A simple `git push origin` finished wiring the remote....
          return 1
        fi

        tweak_errexit
        echo ${git_push_staleness} | grep "(up to date)" &> /dev/null
        grep_result=$?
        reset_errexit
        if [[ ${grep_result} -ne 0 ]]; then

          tweak_errexit
          echo ${git_push_staleness} | grep "(local out of date)" &> /dev/null
          grep_result=$?
          reset_errexit
          if [[ ${grep_result} -eq 0 ]]; then
            echo "WHATEVER: Branch is behind origin/${branch_name} at $working_dir"
            echo "          You can git pull if you want to."
            echo "          But this script don't care."
            echo
          else
            warn "WARNING: Branch is ahead of origin/${branch_name} at $working_dir"
# FIXME/2018-03-23: This looks like a block of code elsewhere in this self-same file!
            echo "=============================================================="
            echo
            echo "  cdd $(pwd) && git push origin ${branch_name} && popd"
            echo
            echo "=============================================================="
            if ! ${SKIP_GIT_DIRTY}; then
              # FIXME: This message pertains to travel.sh.
              echo "Please fix. Or run with -D (skip all git warnings)"
              FRIES_GIT_ISSUES_DETECTED=true
              export FRIES_GIT_ISSUES_DETECTED
              FRIES_GIT_ISSUES_RESOLUTIONS+=( \
                "cdd $(pwd) && git push origin ${branch_name} && popd"
              )
#              export FRIES_GIT_ISSUES_RESOLUTIONS
              if ${FRIES_FAIL_ON_GIT_ISSUE}; then
                return 1
              fi
            else
              echo "Skipping."
              echo
            fi
          fi
          GIT_DIRTY_FILES_FOUND=true
          export GIT_DIRTY_FILES_FOUND
        fi
      fi
    fi
  fi

} # end: git_status_porcelain

# FIXME/2018-03-22: END VERY LONG FUNCTION!!! WAY TOO LONG! tldrdon'tgetit!

# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #

# @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@ #
# @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@ #
# @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@ #

# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #

git_dir_check () {
  REPO_PATH="$1"
  local dir_okay=0
  if [[ ! -d "${REPO_PATH}" ]]; then
    dir_okay=1
    fatal
    fatal "Not a directory: ${REPO_PATH}"
    fatal " In cwd: $(pwd -P)"
    # This code path is inconceivable!
    die "I died!"
    exit 123 # unreachable. But just in case.
  elif [[ ! -d "${REPO_PATH}/.git" ]]; then
    dir_okay=1
    local no_git_yo_msg="WARNING: No .git/ found at: $(pwd -P)/${REPO_PATH}/.git"
    warn
    warn "${no_git_yo_msg}"
    FRIES_GIT_ISSUES_RESOLUTIONS+=("${no_git_yo_msg}")
  else
#    pushd "${REPO_PATH}" &> /dev/null
    pushd_or_die "${REPO_PATH}"
    git rev-parse --git-dir &> /dev/null && dir_okay=0 || dir_okay=1
    popd &> /dev/null
  fi
  return ${dir_okay}
}

# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #

must_be_git_dirs () {
  local source_repo="$1"
  local target_repo="${2-$(pwd)}"

  local a_problem=0

  git_dir_check "${source_repo}"
  [[ $? -ne 0 ]] && a_problem=1

  git_dir_check "${target_repo}"
  [[ $? -ne 0 ]] && a_problem=1

  return ${a_problem}
}

# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #

git_checkedout_branch_name () {
  # 2017-04-04: I unplugged the USB stick before ``popoff``
  #   (forgot to hit <CR>) and then got errors on unpack herein:
  #     error: git-status died of signal 7
  #   signal 7 is a bus error, meaning hardware or filesystem or something
  #   is corrupt, most likely. I made a new sync-stick.
  # 2018-03-22: Ha! How have I been so naive? Avoid porcelain!
  #   git status | head -n 1 | grep "^On branch" | /bin/sed -r "s/^On branch //"
#  [[ -n "$1" ]] && pushd "$1" &> /dev/null
  pushd_or_die "$1"
  local branch_name=$(git rev-parse --abbrev-ref HEAD)
  [[ -n "$1" ]] && popd &> /dev/null
  echo "${branch_name}"
}

# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #

# I don't need this fcn. Reports the tracking branch, (generally 'upstream)
#   I think, because @{u}. [Not quite sure what that is; *tracking* remote?]
git_checkedout_remote_branch_name () {
  # Include the name of the remote, e.g., not just feature/foo,
  # but origin/feature/foo.
#  [[ -n "$1" ]] && pushd "$1" &> /dev/null
  pushd_or_die "$1"
#  # FIXME/2018-03-22: Remove tweak_errexit/reset_errexit; don't think you need.
#  #tweak_errexit
  local remote_branch=$(git rev-parse --abbrev-ref --symbolic-full-name @{u})
#  #reset_errexit
  [[ -n "$1" ]] && popd &> /dev/null
  echo "${remote_branch}"
}

# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #

git_set_remote_travel () {
  local source_repo="$1"
  local target_repo="${2-$(pwd)}"

#  [[ -n ${target_repo} ]] && pushd "${target_repo}" &> /dev/null
  pushd_or_die "${target_repo}"

  # (lb): Minder to self: a $(subprocess) failure does not tickle +e errexit.
  #
  # (lb): Anecdotal reminders:
  #
  #   The use of `local` disables errexit for the subprocess,
  #   but the return value is not captured, e.g.,
  #
  #     set -e
  #     local remote_url=$(git remote get-url unknown_name 2> /dev/null)
  #     local remote_exists=$?
  #     echo ${remote_exists}
  #     # OUTPUT: 0
  #
  #   Because the return value is that of the `local` command.
  #
  #   Whereas if you don't use local, e.g., the exit code is nonzero, and
  #   since errexit is on, our script exits!
  #
  #     set -e
  #     remote_url=$(git remote get-url unknown_name 2> /dev/null)
  #     echo "Unreachable!"
  #
  #   The trick is to declare `local` first, then to set the variable,
  #   and to also use `&& true` which will disable errexit for the subshell.
  local remote_url
  remote_url=$(git remote get-url ${TRAVEL_REMOTE} 2> /dev/null) && true
  local remote_exists=$?

  #debug "  git_set_remote_travel:"
  #debug "   target: ${target_repo}"
  #debug "   remote: ${remote_url}"
  #debug "   exists: ${remote_exists}"

  if [[ ${remote_exists} -ne 0 ]]; then
    debug '  Wiring the "travel" remote for first time!'
    git remote add travel "${source_repo}"
  elif [[ "${remote_url}" != "${source_repo}" ]]; then
    debug "  Rewiring the \"travel\" remote url / was: ${remote_url}"
    git remote set-url travel "${source_repo}"
  else
    #debug '  The "travel" remote url is already correct!'
    : # no-op
  fi

#  [[ -n ${target_repo} ]] && popd &> /dev/null
  popd_perhaps "${target_repo}"
}

# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #

git_fetch_remote_travel () {
  local target_repo="${1-$(pwd)}"

  pushd_or_die "${target_repo}"

  # Assuming git_set_remote_travel was called previously,
  # lest there is no travel remote.
  if ${SKIP_INTERNETS}; then
    git fetch ${TRAVEL_REMOTE} --prune
  else
#    local git_says=$(git fetch --all --prune 2>&1 > /dev/null)
    local git_says=$(git fetch --all --prune 2>&1) && true
    local fetch_success=$?
    verbose "git fetch says:\n${git_says}"
    # Use `&& true` in case grep does not match anything,
    # so as not to tickle errexit.
     local culled="$(echo "${git_says}" \
      | grep -v "^Fetching " \
      | grep -v "^From " \
      | grep -v " \+[a-f0-9]\{7\}\.\.[a-f0-9]\{7\}.*->.*" \
    )"
    [[ -n ${culled} ]] && notice "git fetch wha?\n${culled}"

    if [[ ${fetch_success} -ne 0 ]]; then
      error "Unexpected fetch failure! ${git_says}"
    fi
  fi

  popd_perhaps "${target_repo}"
}

# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #

# A note on errexit: If you call this fcn. (or a fcn. that calls this fcn.)
#   and if you use `&& true` or `|| true`, errexit will be disabled (though
#   you'll still see it in SHELLOPTS). Which means that a `cd` or `pushd` that
#   fails will not stop the function from proceeding.
# Consequently, we either need to check for error on pushd, so that we don't
#   call popd later when we didn't change directories in the first place; or
#   we need to store the current working directory and use cd instead of popd.

# FIXME/2018-03-23 13:13: Verify all pushd usage in git_util.sh and travel.sh.

pushd_or_die () {
  [[ -z "$1" ]] && return
  pushd "$1" &> /dev/null
  [[ $? -ne 0 ]] && error "No such path: $1" && error " working dir: $(pwd -P)" && die
  # Be sure to return a zero success value: If we left the `$? -ne 0`
  # as the last line, it'll trigger errexit!
  return 0
}

popd_perhaps () {
  [[ -z "$1" ]] && return
  popd &> /dev/null
  [[ $? -ne 0 ]] && error "Unexpected popd failure in: $(pwd -P)" && die
  return 0
}

git_is_rebase_in_progress () {
  pushd_or_die "$1"

  # During a rebase, git uses new directories, so we could check the filesystem:
  #   (test -d ".git/rebase-merge" || test -d ".git/rebase-apply") || die "No!"
  # Or we could be super naive, and porcelain, and git-n-grep:
  #   git -c color.ui=off status | grep "^rebase in progress" > /dev/null
  # Or we could use our plumbing knowledge and do it most rightly.
  #   (Note we use `&& test` so command does not tickle errexit.
  (test -d "$(git rev-parse --git-path rebase-merge)" || \
   test -d "$(git rev-parse --git-path rebase-apply)" \
  ) && true
  # Non-zero (1) if not rebasing, (0) otherwise.
  local is_rebasing=$?

  popd_perhaps "$1"

  return ${is_rebasing}
}

git_must_not_rebasing () {
  local source_branch="$1"
  local target_repo="${2-$(pwd)}"
#  git_is_rebase_in_progress "${target_repo}"
  git_is_rebase_in_progress
  local in_rebase=$?
  if [[ ${in_rebase} -eq 0 ]]; then
    git_issue_complain_rebasing "${source_branch}" "${target_repo}"
    return 1
  fi
  return 0
}

git_issue_complain_rebasing () {
  local source_branch="$1"
  local target_repo="${2-$(pwd)}"
  FRIES_GIT_ISSUES_RESOLUTIONS+=("==============================================")
  FRIES_GIT_ISSUES_RESOLUTIONS+=("✗ ✗ ✗ ERROR DETECTOROMETER! ★ ☆ ☆ ☆ ☆ 1 STAR!!")
  FRIES_GIT_ISSUES_RESOLUTIONS+=("Whoa! Under __rebase__, try again, foo!")
  FRIES_GIT_ISSUES_RESOLUTIONS+=("  SKIPPING: ${target_repo}")
  FRIES_GIT_ISSUES_RESOLUTIONS+=("  If you want what's being travelled, abort-n-force!")
# FIXME: Will I need to mount if I'm an running unpack??
  FRIES_GIT_ISSUES_RESOLUTIONS+=("    ./travel mount")
  #FRIES_GIT_ISSUES_RESOLUTIONS+=("    cdd ${target_repo}")
  FRIES_GIT_ISSUES_RESOLUTIONS+=("    cdd $(pwd -P)")
  FRIES_GIT_ISSUES_RESOLUTIONS+=("    git status # sanity check")
  FRIES_GIT_ISSUES_RESOLUTIONS+=("    git rebase --abort")
  FRIES_GIT_ISSUES_RESOLUTIONS+=("    git fetch ${TRAVEL_REMOTE} --prune")
# FIXME/2018-03-23 14:17: This is not always correct: rebase could be against different branch.
# FIXME/2018-03-23 14:18: What about checking all branches??
  FRIES_GIT_ISSUES_RESOLUTIONS+=("    git reset --hard ${TRAVEL_REMOTE}/${source_branch}")
  FRIES_GIT_ISSUES_RESOLUTIONS+=("==============================================")
  warn "Skipping branch in rebase!"
  warn " ${target_repo}"
}

# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #

echo_octothorpes_maroon_on_lime () {
  echo -e "${BG_LIME}${FG_MAROON}$(printf '#%.0s' {1..77})${FONT_NORMAL}"
}

git_change_branches_if_necessary () {
  local source_branch="$1"
  local target_branch="$2"
  local target_repo="${3-$(pwd)}"

  pushd_or_die "${target_repo}"

  if [[ "${source_branch}" != "${target_branch}" ]]; then
    echo_octothorpes_maroon_on_lime
    #info "🌀🌀🌀🌀🌀🌀🌀🌀🌀🌀🌀🌀🌀🌀🌀🌀🌀🌀🌀🌀🌀🌀🌀🌀🌀🌀🌀🌀🌀🌀🌀🌀🌀🌀🌀🌀🌀🌀"
    #echo_octothorpes_maroon_on_lime
    notice "NOTE: \${source_branch} != \${target_branch}"
    echo
    echo " WRKD: $(pwd -P)"
    echo
    echo " Changing branches: ${target_branch} => ${source_branch}"
    echo
    /usr/bin/git checkout ${source_branch} &> /dev/null && true
    if [[ $? -ne 0 ]]; then
# FIXME: On unpack, this might need/want to be origin/, not travel/ !
      /usr/bin/git checkout --track ${TRAVEL_REMOTE}/${source_branch}
    fi
    echo "Changed!"
    echo
    #echo_octothorpes_maroon_on_lime
    #info "🌀🌀🌀🌀🌀🌀🌀🌀🌀🌀🌀🌀🌀🌀🌀🌀🌀🌀🌀🌀🌀🌀🌀🌀🌀🌀🌀🌀🌀🌀🌀🌀🌀🌀🌀🌀🌀🌀"
    echo_octothorpes_maroon_on_lime
# FIXME/2018-03-22: Adding to this array may prevent travel from continuing? I.e., the -D workaround?
#   Or are these msgs printed after everything and do not prevent finishing?
    FRIES_GIT_ISSUES_RESOLUTIONS+=( \
      "JUST FYI: Changed branches: ${source_branch} / ${target_repo}"
    )
  fi

#  [[ -n "${target_repo}" ]] && popd &> /dev/null
  popd_perhaps "${target_repo}"
}

# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #

git_merge_ff_only () {
  local source_branch="$1"
  local target_repo="${2-$(pwd)}"

  pushd_or_die "${target_repo}"

  # For a nice fast-forward vs. --no-ff article, see:
  #   https://ariya.io/2013/09/fast-forward-git-merge

  local git_says=$(git merge --ff-only ${TRAVEL_REMOTE}/${source_branch} 2>&1) && true
  local merge_success=$?

  verbose "git merge says:\n${git_says}"
  local culled="$(echo "${git_says}" \
    | grep -v "^Already up to date.$" \
    | grep -v "^Updating [a-f0-9]\{7\}\.\.[a-f0-9]\{7\}$" \
    | grep -v "^Fast-forward$" \
    | grep -P -v " \| \d+ \+?-?" \
    | grep -P -v "^ \d+ file changed, \d+ insertion\(\+\), \d+ deletion\(-\)$" \
    | grep -P -v "^ \d+ file changed, \d+ insertion\(\+\)$" \
    | grep -P -v "^ \d+ file changed, \d+ deletion\(-\)$" \
    | grep -P -v "^ \d+ insertion\(\+\), \d+ deletion\(-\)$" \
    | grep -P -v "^ \d+ file changed$" \
    | grep -P -v "^ \d+ insertion\(\+\)$" \
    | grep -P -v "^ \d+ deletion\(-\)$" \
  )"
  [[ -n ${culled} ]] && notice "git merge wha?\n${culled}"
  local changes="$(echo "${git_says}" | grep -P " \| \d+ \+?-?")"
  # 2018-03-23: Would you like something more muted, or vibrant? Trying vibrant.
  #[[ -n ${changes} ]] && notice " ${BG_DARKGRAY}${changes}"
  [[ -n ${changes} ]] && notice " ${BG_BLUE}${changes}"

  # (lb): Not quite sure why git_must_not_rebasing would not have failed first.
  #   Does this happen?
  if [[ ${merge_success} -ne 0 ]]; then
    git_issue_complain_rebasing "${source_branch}" "${target_repo}"
  fi

#  [[ -n "${target_repo}" ]] && popd &> /dev/null
  popd_perhaps "${target_repo}"
}

# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #

git_pull_hush () {
  local source_repo="$1"
  local target_repo="${2-$(pwd)}"

  must_be_git_dirs "${source_repo}" "${target_repo}"
  [[ $? -ne 0 ]] && return

  local source_branch=$(git_checkedout_branch_name "${source_repo}")
  # The target_branch is obviously changing, if we can do so nondestructively.
  local target_branch=$(git_checkedout_branch_name "${target_repo}")

#  pushd "${target_repo}" &> /dev/null
  pushd_or_die "${target_repo}"

  # 2018-03-22: Set a remote to the sync device. There's always only 1,
  # apparently. I think this'll work well.
  git_set_remote_travel "${source_repo}"

  git_fetch_remote_travel

#echo "source_branch: ${source_branch}"
#echo "target_repo: ${target_repo}"
#echo "cwd: $(pwd -P)"
## FIXME/2018-03-23 12:50: Should this be && true, or should it be || true?? latter seems correct
## THE && true means errexit not working from this fcn. or any it calls??
##### IT DEPENDS! Use && true so errcode is preserved...
##  git_must_not_rebasing "${source_branch}" "${target_repo}" && true
##  git_must_not_rebasing "${source_branch}" "${target_repo}" && false
##  git_must_not_rebasing "${source_branch}" "${target_repo}"
  git_must_not_rebasing "${source_branch}" "${target_repo}" && true
  local okay=$?
#echo FOO
#  [[ ${okay} -ne 0 ]] && echo FAIL || echo OKAY
  if [[ ${okay} -ne 0 ]]; then
    # The fcn. we just called that failed will have spit out a warning
    # and added to the final FRIES_GIT_ISSUES_RESOLUTIONS array.
#    popd &> /dev/null
    popd_perhaps "${target_repo}"
    return
  fi

##popd &> /dev/null
#popd_perhaps "${target_repo}"
#return
#exit

  # There is a conundrum/enigma/riddle/puzzle/brain-teaser/problem/puzzlement
  # when it comes to what to do about clarifying branches -- should we check
  # every branch for changes, try to fast-forward, and complain if we cannot?
  # That actually seems like the most approriate thing to do!
  # It also feels really, really tedious.
  # FIXME/2018-03-22 22:07: Consider checking all branches for rebase needs!

#  git_change_branches_if_necessary "${source_branch}" "${target_branch}" "${target_repo}"
  git_change_branches_if_necessary "${source_branch}" "${target_branch}"

#popd_perhaps "${target_repo}"
#return
#exit

  # Fast-forward merge (no new commits!) or complain (later).
#  git_merge_ff_only "${source_branch}" "${target_repo}"
  git_merge_ff_only "${source_branch}"

#  popd &> /dev/null
  popd_perhaps "${target_repo}"
} # end: git_pull_hush

# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #

# @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@ #
# @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@ #
# @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@ #

# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #

check_git_clone_or_pull_error () {
  local ret_code=$1
  local git_resp="$2"
  if [[ ${ret_code} -ne 0 ]]; then
    local failed=true
    if ${NO_NETWORK_OKAY}; then
      # On git submodule update, e.g.,
      #   fatal: unable to access 'https://github.com/vim-scripts/AutoAdapt.git/':
      #     Could not resolve host: github.com Unable to fetch in submodule path 'bundle/AutoAdapt'
      # On git clone, e.g.,
      #   Cloning into '/exo/clients/openshift/origin'... ssh: Could not resolve hostname github.com:
      #     Temporary fa fatal: Could not read from remote repository. Please make sure you have the
      #     correct access rights and the repository exists.
      #echo ${git_resp} | grep "ssh: Could not resolve hostname" > /dev/null && failed=false
      echo ${git_resp} | grep "Could not resolve host" > /dev/null && failed=false
    fi
    if ${failed}; then
      echo ${git_resp}
      echo
      echo "FATAL: git operation failed."
      exit 1
    else
      echo
      warn "WARNING: git operation failed:"
      echo
      echo ${git_resp}
    fi
  fi
} # end: check_git_clone_or_pull_error

# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #

git-flip-master () {

  # If your scheme is project/ and master+project/, then we got this, boo.

  # Tell Bash to echo command lines, sort of:
  # -v      Print shell input lines as they are read.
  # -x      After expanding each simple command, for command, case command, select command,
  #         or arithmetic for command, display the expanded value of PS4, followed by the
  #         command and its expanded arguments or associated word list.
  #  set -x
  #  set -v
  # I though -v might work (echo each line) but it doesn't echo the git commands.

  # Walk up from curdir looking for .git/ so you can call from subdir.
  find_git_parent
  # FIXME: From root of project, cd'ing into subfolder??
  echo "git-flip-master: \${REL_PREFIX}: ${REL_PREFIX}"
  # sets: REL_PREFIX
#  if [[ -n ${REL_PREFIX} ]]; then
#    pushd ${REL_PREFIX} &> /dev/null
#  fi
  pushd_or_die "${REL_PREFIX}"

  local project_name=$(basename -- $(pwd -P))

  local branch_name=$(git branch --no-color | head -n 1 | /bin/sed 's/^\*\? *//')

  local master_path="master+${project_name}"

  echo "Merging \"${branch_name}\" into ${master_path} and pushing to origin."

  if [[ ! -d ../${master_path}/.git ]]; then
      echo "FATAL: Cannot suss paths, ya dingus."
#      [[ -n ${REL_PREFIX} ]] && popd &> /dev/null
      popd_perhaps "${REL_PREFIX}"
      return 1
  fi

  echo git push origin ${branch_name}
  git push origin ${branch_name}

  echo "pushd_or_die ../${master_path}"
#  pushd ../${master_path} &> /dev/null
  pushd_or_die "../${master_path}"

  # Since the master branch is published, don't rebase or you'll
  # rewrite history.
  #  Don't: git pull --rebase --autostash
  # But if you were pulling into a feature branch, it might be
  # desirable to rebase to avoid a merge commit. In any case...
  echo git pull
  git pull

  echo git merge origin/${branch_name}
  git merge origin/${branch_name}

  echo git push origin master
  git push origin master

  if [[ -f Rakefile ]]; then
    if rake --task | grep "rake tagGitRepo" &> /dev/null; then
      echo "Running: \`rake tagGitRepo\`"
# FIXME/2017-06-12: This needs to wait on the build...
echo "FIXME: \`rake tagGitRepo\` should wait for build to complete..."
      #rake tagGitRepo
      echo "!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!"
      echo
      echo "Watch build in OpenShift and tag when complete:"
      echo
      echo "  rake tagGitRepo"
      echo
      echo "!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!"
    fi
  fi

#  echo popd
#  popd &> /dev/null
  popd_perhaps "../${master_path}"

#  [[ -n ${REL_PREFIX} ]] && popd &> /dev/null
  popd_perhaps "${REL_PREFIX}"
}

# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #
# git-jockey

git-jockey () {
  find_git_parent .
  #echo "REPO_PATH: $REPO_PATH"
  if [[ -n $REPO_PATH ]]; then
    # Just the basics, I suppose.
    local toplevel_common_file=()
    toplevel_common_file+=(".ignore")
    toplevel_common_file+=(".agignore")
    toplevel_common_file+=(".gitignore")
    toplevel_common_file+=("README.rst")
    #echo "Checking single dirty files..."
    for ((i = 0; i < ${#toplevel_common_file[@]}; i++)); do
      DIRTY_BNAME=$(basename -- "${toplevel_common_file[$i]}")
      if [[ -f $REPO_PATH/${DIRTY_BNAME} ]]; then
        echo "Checking ${DIRTY_BNAME}"
        AUTO_COMMIT_FILES=true \
          git_commit_generic_file \
            "${toplevel_common_file[$i]}" \
            "Update ${DIRTY_BNAME}."
      else
        echo "Skipping ${DIRTY_BNAME}"
      fi
    done
  fi
}

# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #
# git-status-all

# git subdirectory statusr

# I maintain a bunch of Vim plugins,
# published at https://github.com/landonb/dubs_*,
# that are loaded as submodules in an uber-project
# that makes it easy to share my plugins and makes
# it simple to deploy them to a new machine, found
# at https://github.com/landonb/dubsacks_vim.
#
# However, git status doesn't work like, say, svn status:
# you can't postpend a directory path and have it search
# that. For example, from the parent directory of the plugins,
# e.g., from ~/.vim/bundle_/, using git status doesn't
# work, e.g., running `git status git_ignores_this` no matter
# what the third token is always reports on the git status of
# the working directory, which in my case is ~/.vim.

git_status_all () {
  local subdir
  for subdir in $(find . -name ".git" -type d); do
    local gitst=$(git --git-dir=$subdir --work-tree=$subdir/.. status --short)
    if [[ -n ${gitst} ]]; then
      echo
      echo "====================================================="
      echo "Dirty project: $subdir"
      echo
      # We could just echo, but the we've lost any coloring.
      # Ok: echo ${gitst}
      # Better: run git again.
      #git --git-dir=$subdir --work-tree=$subdir/.. status
      git --git-dir=$subdir --work-tree=$subdir/.. status --short
      echo
    fi
  done
}

# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #

# 2017-06-06 22:11 You've got a /bin/rm monkey patch, why not another
# dastardly accidentally typed command! Sometimes when I mean to type
# `git reset HEAD blurgh`, sometimes I start typing `git co -- blurgh`
# oh no!
function cis_git() {
  # "co" is a home frites `co = checkout` alias.
  # I'm not concerned with the long-form [2017-06-06: Boo, still hyphenated]
  # counterpart, "checkout". I just don't want to `git co -- oops` without
  # an undo, like home 🍟
  local gitted=false
  if [[ "$1" == "co" ]]; then
    if [[ "$2" == "--" ]]; then
      echo -n "Are you sure this is absolutely what you want? [Y/n] "
      read -e YES_OR_NO
      if [[ ${YES_OR_NO^^} =~ ^Y.* || -z ${YES_OR_NO} ]]; then
        # FIXME/2017-06-06: Someday soon I'll remove this sillinessmessage.
        echo "YASSSSSSSSSSSSS"
      else
        echo "I see"
        gitted=true
      fi
    fi
  fi
  if ! ${gitted}; then
    # FIXME/2017-06-06: So that Home-fries is universal,
    #                    need to get git's locale another way.

    # exec creates a new process, so if you `git log` and hit q,
    # the terminal gets an exit!
    # WRONG: exec /usr/bin/git "$@"

    # With eval, e.g., git ci -m "Blah (blugh)" responds
    # bash: syntax error near unexpected token `('
    # WRONG: eval /usr/bin/git "$@"
    # WRONG: eval /usr/bin/git "$*"
    # WRONG: eval "/usr/bin/git $@"
    # WRONG: eval "/usr/bin/git $*"

    # 2017-06-12: If this works, why was I trying to use exec??
    /usr/bin/git "$@"
  fi
}

# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #

# 2017-10-03: An infuse function, for overlaying private files atop a repo.
git_infuse_gitignore_local() {
  [[ -z "$1" ]] && echo "${FUNCNAME[0]}: missing param" && exit 1
  if [[ ! -d .git/info ]]; then
    warn "WARNING: Cannot infuse .gitignore.local under $(pwd -P): no .git/info"
    return
  fi
  if [[ -f .git/info/exclude || -h .git/info/exclude ]]; then
#    pushd .git/info &> /dev/null
    pushd_or_die ".git/info"
    /bin/rm exclude
    /bin/ln -sf "$1" "exclude"
#    popd &> /dev/null
    popd_perhaps ".git/info"
  fi
  /bin/ln -sf .git/info/exclude .gitignore.local
}

git_infuse_assume_unchanging() {
  local fpath
  local fname
  local opath
  local do_sym
  [[ -z "$1" ]] && (echo "${FUNCNAME[0]}: missing param" && exit 1) || opath="$1"
  if [[ -z "$2" ]]; then
    fpath='.'
    fname=$(basename -- "${opath}")
  else
    fpath="$2"
    fname=$(basename -- "${fpath}")
  fi
  [[ "$3" == "1" ]] && do_sym=false || do_sym=true

#  pushd $(dirname -- "${fpath}") &> /dev/null
  local pdir=$(dirname -- "${fpath}")
  pushd_or_die "${pdir}"

  # Only do this if file not already being ignored, else after --no-assume-unchanged,
  # we detect file is dirty and exit 1, ugly.
  if ! $(git ignored | grep "${fname}" > /dev/null); then
    #git update-index --no-assume-unchanged "${fname}"
    if [[ ! $(git ls-files --error-unmatch "${fname}" 2>/dev/null ) ]]; then
      echo "${FUNCNAME[0]}: file not in git: ${fname}"
      exit 1
    fi
    if [[ "${do_sym}" == true && ! -h "${fname}" ]]; then
# FIXME/2018-03-22: Verify porcelain usage (vs. plumbing).
      local dirty_status=$(git status --porcelain "${fname}")
      if [[ -n "${dirty_status}" ]]; then
        echo "${FUNCNAME[0]}: git file is dirty: ${fname}"
        exit 1
      fi
    fi
    git update-index --assume-unchanged "${fname}"
  fi

  /bin/rm "${fname}"
  /usr/bin/git checkout -- "${fname}"
  /bin/cp "${fname}" "${fname}-COMMIT"
  if ${do_sym}; then
    /bin/ln -sf "${opath}" "${fname}"
  else
    /bin/cp -a "${opath}" "${fname}"
  fi

#  popd &> /dev/null
  popd_perhaps "${pdir}"
}

git_unfuse_symlink() {
  local fpath
  [[ -z "$1" ]] && (echo "${FUNCNAME[0]}: missing param" && exit 1) || fpath="$1"
  local fname=$(basename -- "${fpath}")
#  pushd $(dirname -- "${fpath}") &> /dev/null
#  pushd_or_die $(dirname -- "${fpath}")
  local pdir=$(dirname -- "${fpath}")
  pushd_or_die "${pdir}"

  if [[ -h "${fname}" ]]; then
    /bin/rm "${fname}"
    /bin/rm -f "${fname}-COMMIT"
    /usr/bin/git checkout -- "${fname}"
    /usr/bin/git update-index --no-assume-unchanged "${fname}"
  fi
#  popd &> /dev/null
  popd_perhaps "${pdir}"
}

git_unfuse_hardcopy() {
  local fpath
  [[ -z "$1" ]] && (echo "${FUNCNAME[0]}: missing param" && exit 1) || fpath="$1"
  local fname=$(basename -- "${fpath}")
#  pushd $(dirname -- "${fpath}") &> /dev/null
#  pushd_or_die $(dirname -- "${fpath}")
  local pdir=$(dirname -- "${fpath}")
  pushd_or_die "${pdir}"
  if [[ -f "${fname}" ]]; then
    #/bin/rm "${fname}"
    /bin/rm -f "${fname}-COMMIT"
    /usr/bin/git checkout -- "${fname}"
    git update-index --no-assume-unchanged "${fname}"
  fi
#  popd &> /dev/null
  popd_perhaps "${pdir}"
}

# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #
# git-remote-v-all

# Recursively find all git repos in a directory and print their path and remote URLs.
git-remote-v-all() {
  [[ ! -d "$1" ]] && >&2 echo "Please specify a directory!" && return 1
  local git_path
  local once=false
  for git_path in $(find "$1" -type d -iname ".git"); do
    ${once} && echo
    local repo_path=$(dirname ${git_path})
    echo ${repo_path}
#    pushd ${repo_path} &> /dev/null
    pushd_or_die ${repo_path}
    git remote -v
#    popd &> /dev/null
    popd_perhaps "${pdir}"
    once=true
  done
}

# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #

main() {
  source_deps

  SKIP_GIT_DIRTY=false
  export SKIP_GIT_DIRTY

  FRIES_GIT_ISSUES_DETECTED=false
  export FRIES_GIT_ISSUES_DETECTED

  FRIES_GIT_ISSUES_RESOLUTIONS=()
  export FRIES_GIT_ISSUES_RESOLUTIONS

  if [[ -z ${FRIES_FAIL_ON_GIT_ISSUE+x} ]]; then
    FRIES_FAIL_ON_GIT_ISSUE=false
  fi

  alias git_st_all='git_status_all'
  # Hrmm... gitstall? I'm not sold on any alias yet...
  alias gitstall='git_status_all'

  alias git='cis_git'
  #unalias git
}

main "$@"


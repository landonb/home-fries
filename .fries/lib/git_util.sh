#!/bin/bash
# Last Modified: 2017.10.04
# vim:tw=0:ts=2:sw=2:et:norl:

# File: .fries/lib/git_util.sh
# Author: Landon Bouma (landonb &#x40; retrosoft &#x2E; com)
# Project Page: https://github.com/landonb/home-fries
# Summary: Git Helpers: Check if Dirty/Untracked/Behind; and Auto-commit.
# License: GPLv3

# Usage: Source this script. Call its functions. Use its exports.

source_deps() {
  # source defaults to the current directory, but the caller's,
  # so this won't always work:
  #   source bash_base.sh
  #   source process_util.sh
  local curdir=$(dirname -- "${BASH_SOURCE[0]}")
  source ${curdir}/bash_base.sh
  # Load: die
  source ${curdir}/process_util.sh
}

# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #
# find_git_parent

# FIXME/2017-06-24: When translating for Go, make generic/work on any target dir.
find_git_parent () {
  FILE_PATH=$1
  #echo "find_git_parent: FILE_PATH: ${1}"
  if [[ -z ${FILE_PATH} ]]; then
    # Assume curdir, I suppose.
    FILE_PATH="."
  fi
  # Crap, if symlink, blows up, because prefix of git status doesn't match.
  REL_PATH=$(dirname -- "${FILE_PATH}")
  REL_PREFIX=""
  #echo "find_git_parent: REL_PATH/2: ${REL_PATH}"
  DOUBLE_DOWN=false
  if [[ ${REL_PATH} == '.' ]]; then
    DOUBLE_DOWN=true
    #echo "find_git_parent: REL_PATH/2b: ${REL_PATH}"
  fi
  REPO_PATH=""
  while [[ ${REL_PATH} != '/' || ${REL_PATH} != '.' ]]; do
    #echo "find_git_parent: REL_PATH/3: ${REL_PATH}"
    if [[ -d "${REL_PATH}/.git" ]]; then
      REPO_PATH=${REL_PATH}
      break
    else
      # Keep looping.
      if ! ${DOUBLE_DOWN}; then
        REL_PATH=$(dirname -- "${REL_PATH}")
      else
        ABS_PATH=$(readlink -f -- "${REL_PATH}")
        if [[ ${ABS_PATH} == '/' ]]; then
          #echo "WARNING: find_git_parent: No parent found for ${FILE_PATH}"
          break
        fi
        REL_PATH=../${REL_PATH}
        REL_PREFIX=../${REL_PREFIX}
      fi
    fi
  done
  #echo "find_git_parent: REPO_PATH: ${REPO_PATH}"
  #echo "find_git_parent: REL_PATH: ${REL_PATH}"
  #echo "find_git_parent: REL_PREFIX: ${REL_PREFIX}"
}

# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #
# git_check_generic_file

git_check_generic_file () {
  # git_check_generic_file "file-path"

  REPO_FILE=$1
  # Set REPO_PATH.
  find_git_parent ${REPO_FILE}
  # Strip the git path from the absolute file path.
  REPO_FILE=${REPO_FILE#${REPO_PATH}/}

  pushd ${REPO_PATH} &> /dev/null

  set +e
  git status --porcelain ${REPO_FILE} | grep "^\W*M\W*${REPO_FILE}" &> /dev/null
  grep_result=$?
  reset_errexit

  if [[ $grep_result -eq 0 ]]; then
    # It's dirty.
    :
  fi

  popd &> /dev/null

} # end: git_check_generic_file

# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #
# git_commit_generic_file

git_commit_generic_file () {
  # git_commit_generic_file "file-path" "commit-msg"

  # MEH: DRY: First part of this fcn is: git_check_generic_file

  REPO_FILE=$1
  COMMITMSG=$2
  if [[ -z ${COMMITMSG} ]]; then
    echo "WRONG: git_commit_generic_file REPO_FILE COMMITMSG"
    return 1
  fi
  # Set REPO_PATH.
  find_git_parent ${REPO_FILE}
  # Strip the git path from the absolute file path.
  REPO_FILE=${REPO_FILE#${REPO_PATH}/}

  #echo "Repo base: ${REPO_PATH}"
  #echo "Repo file: ${REPO_FILE}"

  pushd ${REPO_PATH} &> /dev/null

  set +e
  git status --porcelain ${REPO_FILE} | grep "^\W*M\W*${REPO_FILE}" &> /dev/null
  grep_result=$?
  reset_errexit

  if [[ $grep_result -eq 0 ]]; then
    # It's dirty.
    CUR_DIR=$(basename -- $(pwd -P))
    if ! ${AUTO_COMMIT_FILES}; then
      echo
      echo -n "HEY, HEY: Your ${CUR_DIR}/${REPO_FILE} is dirty. Wanna check it in? [y/n] "
      read -e YES_OR_NO
    else
      echo "Committing dirty file: ${CUR_DIR}/${REPO_FILE}"
      YES_OR_NO="Y"
    fi
    if [[ ${YES_OR_NO^^} == "Y" ]]; then
      git add ${REPO_FILE}
      # FIXME/2017-04-13: Probably shouldn't redirect to netherspace here.
      #   U	source/landonb/Unfiled_Notes.rst
      #   error: Committing is not possible because you have unmerged files.
      #   hint: Fix them up in the work tree, and then use 'git add/rm <file>'
      #   hint: as appropriate to mark resolution and make a commit.
      #   fatal: Exiting because of an unresolved conflict.
      git commit -m "${COMMITMSG}" &> /dev/null
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

  popd &> /dev/null

} # end: git_commit_generic_file

# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #
# git_commit_all_dirty_files

git_commit_all_dirty_files () {

  # 2016-10-18: I considered adding a `git add --all`, but that
  #             really isn't always desirable...

  REPO_PATH=$1

  if [[ -e ${REPO_PATH} ]]; then

    echo "Checking for git dirtiness at: ${REPO_PATH}"

    pushd ${REPO_PATH} &> /dev/null
    set +e

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
    git status --porcelain | grep "^[^\?]" &> /dev/null

    grep_result=$?
    reset_errexit

    if [[ $grep_result -eq 0 ]]; then
      # It's dirty.
      echo
      if ! ${AUTO_COMMIT_FILES}; then
        echo -n "HEY, HEY: Your ${REPO_PATH} is dirty. Wanna check it all in? [y/n] "
        read -e YES_OR_NO
      else
        echo "HEY, HEY: Your ${REPO_PATH} is dirty. Let's check that in for ya."
        YES_OR_NO="Y"
      fi
      if [[ ${YES_OR_NO^^} == "Y" ]]; then
        git add -u
        git commit -m "Auto-commit by Curly." &> /dev/null
        echo 'Committed!'
      fi
      echo
    fi
    popd &> /dev/null
  else
    echo
    echo "WARNING: Skipping ${REPO_PATH}: Not found"
    echo
  fi

} # end: git_commit_all_dirty_files

# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #
# git_status_porcelain

# *** Git: check 'n commit, maybe

# NOTE: This fcn. expects to be at the root of the git repo.
git_status_porcelain () {

  GIT_REPO=$1
  SKIP_REMOTE_CHECK=$2

  # NOTE: It's not super easy to pass associative arrays in Bash.
  #       Instead, pass via GTSTOK_GIT_REPOS.

  #echo "GIT_REPO: ${GIT_REPO}"

  # Caller can set GREPPERS to ignore specific dirty files, e.g.,
  #    GREPPERS='| grep -v " travel.sh$"'
  #echo "GREPPERS: ${GREPPERS}"

  USE_ALT_GIT_ST=false
  if [[ ${#GTSTOK_GIT_REPOS[@]} -gt 0 ]]; then
    #echo "No. of GTSTOK_GIT_REPOS: ${#GTSTOK_GIT_REPOS[@]}"
    #echo "Checking for: GIT_REPO: ${GIT_REPO}"
    if [[ ${GTSTOK_GIT_REPOS[${GIT_REPO}]} == true ]]; then
      # Haha, this is so wrong:
      #   GREPPERS='| grep -v ".GTSTOK$"'
      USE_ALT_GIT_ST=true
    fi
  fi
  #echo "GREPPERS: ${GREPPERS}"
  #echo "USE_ALT_GIT_ST: ${USE_ALT_GIT_ST}"

  # ***

  # MAYBE: Does this commits of known knowns feel awkward here?

  # Be helpful! We can take care of the known knowns.

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

  DIRTY_REPO=false

  # Use eval's below because of the GREPPERS.

  unstaged_changes_found=false
  set +e
  if ! ${USE_ALT_GIT_ST}; then
    # ' M' is modified but not added.
    eval git status --porcelain ${GREPPERS} | grep "^ M " &> /dev/null
    if [[ $? -eq 0 ]]; then
      unstaged_changes_found=true
    fi
  else
    git-st.sh &> /dev/null
    if [[ $? -ne 0 ]]; then
      unstaged_changes_found=true
    fi
  fi
  reset_errexit
  if ${unstaged_changes_found}; then
    DIRTY_REPO=true
    echo "WARNING: Unstaged changes found in $GIT_REPO"
  fi

  set +e
  # 'M ' is added but not committed!
  eval git status --porcelain ${GREPPERS} | grep "^M  " &> /dev/null
  grep_result=$?
  reset_errexit
  if [[ $grep_result -eq 0 ]]; then
    DIRTY_REPO=true
    echo "WARNING: Uncommitted changes found in $GIT_REPO"
  fi

  set +e
  eval git status --porcelain ${GREPPERS} | grep "^?? " &> /dev/null
  grep_result=$?
  reset_errexit
  if [[ $grep_result -eq 0 ]]; then
    DIRTY_REPO=true
    echo "WARNING: Untracked files found in $GIT_REPO"
  fi

  set +e
  if ! ${USE_ALT_GIT_ST} && ! ${DIRTY_REPO}; then
    if [[ -n ${GREPPERS} ]]; then
      eval git status --porcelain ${GREPPERS} &> /dev/null
      if [[ $? -eq 0 ]]; then
        echo "WARNING: git status --porcelain: non-zero exit"
        DIRTY_REPO=true
      fi
    else
      n_bytes=$(git status --porcelain | wc -c)
      if [[ ${n_bytes} -gt 0 ]]; then
        echo "WARNING: git status --porcelain: n_bytes > 0"
        DIRTY_REPO=true
      fi
    fi
  else
    eval git status --porcelain ${GREPPERS} | grep -v "^ M " &> /dev/null
    if [[ $? -eq 0 ]]; then
        echo "WARNING: git status --porcelain: grepped"
      DIRTY_REPO=true
    fi
  fi
  reset_errexit
  if ${DIRTY_REPO}; then
    echo "STOPPING: Dirty things found in $GIT_REPO"
    echo "========================================="
    echo
    echo "  cdd $(pwd) && git add -p"
    echo
    echo "========================================="
    if ! ${SKIP_GIT_DIRTY}; then
      # FIXME: This message pertains to travel.sh.
      echo "Please fix. Or run with -D (skip all git warnings)"
      echo "            or run with -DD (skip warnings about $0)"
      FRIES_GIT_ISSUES_DETECTED=true
      export FRIES_GIT_ISSUES_DETECTED
      FRIES_GIT_ISSUES_RESOLUTIONS+=("cdd $(pwd) && git add -p")
      export FRIES_GIT_ISSUES_RESOLUTIONS
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

  # Is this branch behind its remote?
  # E.g.s,
  #  Your branch is up-to-date with 'origin/master'.
  # and
  #  Your branch is ahead of 'origin/master' by 281 commits.

  # But don't care if not really a remote, i.e., local origin.
  set +e
  # Need to use grep's [-P]erl-defined regex that includes the tab character.
  git remote -v | grep -P "^origin\t\/" > /dev/null
  grep_result=$?
  reset_errexit

  if [[ $grep_result -ne 0 ]]; then
    # Not a local origin.

    if [[ -n $(git remote -v) ]]; then
      # Not a remote-less repo.

      #branch_name=$(git branch --no-color | head -n 1 | /bin/sed 's/^\*\? *//')
      branch_name=$(git branch --no-color | grep \* | cut -d ' ' -f2)
      #echo "branch_name: ${branch_name}"

      # git status always compares against origin/master, or at least I
      # think it's stuck doing that. So this method only works if the
      # local branch is also master:
      if false; then
        set +e
        git status | grep "^Your branch is up-to-date with" &> /dev/null
        grep_result=$?
        reset_errexit
        if [[ $grep_result -ne 0 ]]; then
          echo "WARNING: Branch is behind origin/${branch_name} at $GIT_REPO"
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
            FRIES_GIT_ISSUES_RESOLUTIONS+=("cdd $(pwd) && git push origin ${branch_name} && popd")
            export FRIES_GIT_ISSUES_RESOLUTIONS
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
      if ! ${SKIP_REMOTE_CHECK} && [[ -n ${SKIP_REMOTE_CHECK} ]]; then

        set +e
        # If we didn't --no-color the branch_name, we'd have to strip-color.
        #  stripcolors='/bin/sed -r "s/\x1B\[([0-9]{1,2}(;[0-9]{1,2})?)?[mGK]//g"'
        GIT_PUSH_STALENESS=$(git remote show origin \
          | grep "^\W*${branch_name}\W\+pushes to\W\+${branch_name}\W\+")

        grep_result=$?
        reset_errexit
        if [[ $grep_result -ne 0 ]]; then

          set +e
          git remote show origin 2>&1 | grep "^ssh: Could not resolve hostname "
          grep_result=$?
          reset_errexit
          if [[ $grep_result -eq 0 ]]; then
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
          # AHAHAHA/2017-09-08: This happened because I hadn't pushed yet.
          #   A simple `git push origin` finished wiring the remote....
          return 1
        fi

        set +e
        echo ${GIT_PUSH_STALENESS} | grep "(up to date)" &> /dev/null
        grep_result=$?
        reset_errexit
        if [[ $grep_result -ne 0 ]]; then

          set +e
          echo ${GIT_PUSH_STALENESS} | grep "(local out of date)" &> /dev/null
          grep_result=$?
          reset_errexit
          if [[ $grep_result -eq 0 ]]; then
            echo "WHATEVER: Branch is behind origin/${branch_name} at $GIT_REPO"
            echo "          You can git pull if you want to."
            echo "          But this script don't care."
            echo
          else
            echo "WARNING: Branch is ahead of origin/${branch_name} at $GIT_REPO"
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
              FRIES_GIT_ISSUES_RESOLUTIONS+=("cdd $(pwd) && git push origin ${branch_name} && popd")
              export FRIES_GIT_ISSUES_RESOLUTIONS
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

# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #
# git_dir_check

git_dir_check () {
  REPO_PATH=$1
  if [[ ! -d ${REPO_PATH} ]]; then
    SKIP_GIT_PULL=true
    echo
    echo "WARNING: Not a directory: ${REPO_PATH}"
    echo " In cwd: $(pwd -P)"
    die "WARNING: Not a directory: ${REPO_PATH}"
  elif [[ ! -d ${REPO_PATH}/.git ]]; then
    SKIP_GIT_PULL=true
    echo
    echo "WARNING: No .git/ found at: $(pwd -P)/${REPO_PATH}/.git"
  fi
}

# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #
# git_pull_hush

git_pull_hush () {
  SOURCE_REPO=$1
  TARGET_REPO=$2

  SKIP_GIT_PULL=false
  git_dir_check ${SOURCE_REPO}
  git_dir_check ${TARGET_REPO}
  if ${SKIP_GIT_PULL}; then
    if ${SKIP_GIT_DIRTY}; then
      echo "Skipping"
      echo
      return 0
    else
      return 1
    fi
  fi

  # 2017-04-04: I did not hit <CR> after ``popoff`` and plugged the USB stick,
  #   then started getting errors (where signal 7 is a bus error, meaning the
  #   hardware or the filesystem or something is corrupt, most likely...).
  #     error: git-status died of signal 7

  # FIXME/2017-09-07: This fcn. should really just try to do a fast-forward
  # merge, and if that fails, then bug the user.
  # - Either the user forgot to unpack, so their local branch is diverged
  #   from what's on the stick; or
  # - The user packme'ed, rebased locally, and packme'ed again, in which
  #   case the branches have diverged; or
  # - The user switched branches locally, so the branches don't match; or
  # - The user switched branches on one machine, packme'ed, forgot to
  #   unpack, and then packme's -- the branches won't match.

  pushd ${SOURCE_REPO} &> /dev/null
  SOURCE_BRANCH=$(\
    git status | head -n 1 | grep "^On branch" | /bin/sed -r "s/^On branch //" \
  )
  popd &> /dev/null

  pushd ${TARGET_REPO} &> /dev/null

  TARGET_BRANCH=$(\
    git status | head -n 1 | grep "^On branch" | /bin/sed -r "s/^On branch //" \
  )
  #echo "TARGET_BRANCH: ${TARGET_BRANCH}"

  set +e
  TARGET_REFNAME_BRANCH_NAME=$(git rev-parse --abbrev-ref --symbolic-full-name @{u})
  reset_errexit
  #echo "TARGET_REFNAME_BRANCH_NAME: ${TARGET_REFNAME_BRANCH_NAME}"

  # This is empty string and errexit 1 on stick.
  #TARGET_REFNAME=$(git config branch.`git name-rev --name-only HEAD`.remote)
  #TARGET_REFNAME=$(dirname -- "${TARGET_REFNAME_BRANCH_NAME}")
  TARGET_REFNAME=$(echo "$TARGET_REFNAME_BRANCH_NAME" | cut -d "/" -f2)
  #echo "TARGET_REFNAME: ${TARGET_REFNAME}"

  # 2016-09-28: Being extra paranoid because if the branches don't match,
  #             pull don't care! This is really confusing/worrying to me.
  if [[ -z ${SOURCE_BRANCH} ]]; then
    echo "FATAL: What?! No \$SOURCE_BRANCH for SOURCE_REPO: ${SOURCE_REPO}"
    pushd ${SOURCE_REPO} &> /dev/null
    set +e
    git -c color.ui=off status | grep "^rebase in progress" > /dev/null
    rebase_in_progress=$?
    reset_errexit
    if [[ ${rebase_in_progress} -eq 0 ]]; then
      echo "Looks like a rebase is in progress"
      echo
      echo "  cdd ${SOURCE_REPO}"
      echo "  git rebase --abort"
    else
      git st
    fi
    popd &> /dev/null
    return 1
  fi
  if [[ -z ${TARGET_BRANCH} ]]; then
    echo "FATAL: What?! No \$TARGET_BRANCH for TARGET_REPO: ${TARGET_REPO}"
    return 1
  fi
  if false; then
    if [[ ${SOURCE_BRANCH} != ${TARGET_BRANCH} ]]; then
      echo "FATAL: \${SOURCE_BRANCH} != \${TARGET_BRANCH}"
      echo " SOURCE_BRANCH: ${SOURCE_BRANCH}"
      echo " TARGET_BRANCH: ${TARGET_BRANCH}"
      echo
      echo "You may need to change branches:"
      echo
      #echo "  #pushd $(pwd -P) && git checkout --track origin/${SOURCE_BRANCH}"
      #echo " or maybe it's the other one"
      #echo "  #pushd ${SOURCE_REPO} && git checkout --track origin/${SOURCE_BRANCH}"
      #echo " but really it might be this"
      echo "  pushd $(pwd -P)"
      #echo "  git remote set-url origin /${SOURCE_REPO}"
      #echo "  git pull -a"
      echo "  git pull"
      #echo "  git checkout -b feature/${SOURCE_BRANCH} --track origin/master"
      #echo "   or maybe just"
      #echo "  git checkout -b ${SOURCE_BRANCH} --track origin/master"
      # Using `--track origin/` is archaic (<1.6.6?) usage.
      #echo "  git checkout --track origin/${SOURCE_BRANCH}"
      echo "  git checkout ${SOURCE_BRANCH}"
      return 1
    fi
  fi

  # 2017-09-25: ...
  # --all doesn't work if your stick mounts at different locations, e.g.,
  #   /media/$USER/at_work and /media/$USER/at_home...
#  echo "\${SOURCE_BRANCH}: ${SOURCE_BRANCH}"
#  echo "\${TARGET_REPO}: ${TARGET_REPO}"
#  echo "\${EMISSARY}: ${EMISSARY}"
  # Argh... also, only do on local repos pointing at stick;
  #   the repos on the stick point to the locals, sans EMISSARY/gooey
  # Also, not all repo's remote is on the stick -- for many, it's github, dummy.
#  git remote set-url origin ${EMISSARY}/gooey/${TARGET_REPO}
  # Disable errexit because grep returns 1 if nothing matches.
  set +e
#  git fetch ${SOURCE_REPO} 2>&1 \
#      | grep -v "^Fetching [a-zA-Z0-9]*$" \
#      | grep -v "^From " \
#      | grep -v "^ \* branch "
  git fetch --all \
      | grep -v "^Fetching [a-zA-Z0-9]*$" \
      | grep -v "^ \* branch "
  reset_errexit
##  git remote update
  # This could be dangerous if you're pulling in the wrong direction...
  #git remote prune origin

  if [[ ${SOURCE_BRANCH} != ${TARGET_BRANCH} ]]; then
    echo "############################################################################"
    echo "🌀🌀🌀🌀🌀🌀🌀🌀🌀🌀🌀🌀🌀🌀🌀🌀🌀🌀🌀🌀🌀🌀🌀🌀🌀🌀🌀🌀🌀🌀🌀🌀🌀🌀🌀🌀🌀🌀"
    echo "############################################################################"
    echo "NOTE: \${SOURCE_BRANCH} != \${TARGET_BRANCH}"
    echo
    echo "  ... changing branches..."
    echo
    git checkout ${SOURCE_BRANCH}
    echo
    echo "Changed!"
    echo "############################################################################"
    echo "🌀🌀🌀🌀🌀🌀🌀🌀🌀🌀🌀🌀🌀🌀🌀🌀🌀🌀🌀🌀🌀🌀🌀🌀🌀🌀🌀🌀🌀🌀🌀🌀🌀🌀🌀🌀🌀🌀"
    echo "############################################################################"
  fi

  #echo "cd $(pwd) && git pull --rebase --autostash $SOURCE_REPO"

  # Disable the glob (noglob), or the '*' that git prints will
  # be turned into a directory listing of the current directory. Ha!
  if false; then
    # Argh, I wanted to record the output so that I could leave `set -e`
    # on for the git pull -- IN CASE IT FAILS! -- but want happened to
    # my newlines? They're gone! Or maybe that's the fault of `set +f`,
    # but with noglob, the '*' in the git reponse gets expanded. Not funny.
    set +f
    GIT_OUTPUT=$(git pull --rebase --autostash $SOURCE_REPO 2>&1)
    set -f
    set +e
    #echo ${GIT_OUTPUT}
    echo ${GIT_OUTPUT} \
      | grep -v "^ \* branch            HEAD       -> FETCH_HEAD$" \
      | grep -v "^Already up-to-date.$" \
      | grep -v "^Current branch [a-zA-Z0-9]* is up to date.$" \
      | grep -v "^From .*${TARGET_REPO}$"
    reset_errexit
  fi

  if true; then
    set +e
    #echo git pull --rebase --autostash $SOURCE_REPO 2>&1
    # NOTE: The Current branch grep doesn't work if like "feature/topic".
    #       But I kinda like seeing that.
    #       I wonder if just ignoring master is ok (normally show branch?).

    # 2017-08-04: Until I figure this out better, so two git pulls.
    # The first is in the clear, so it's output goes to the terminal,
    # minus some of the normal blather (really, just the list of files
    # that get pulled (followed by pluses and minuses) and any errors.
    git pull --rebase --autostash ${SOURCE_REPO} 2>&1 \
          | grep -v "^ \* branch            HEAD       -> FETCH_HEAD$" \
          | grep -v "^Already up-to-date.$" \
          | grep -v "^Current branch [a-zA-Z0-9]* is up to date.$" \
          | grep -v "^From .*${TARGET_REPO}$"

    # Next, we'll run git pull again but capture the output, to check for "error".

    # Cool, dog!
    #  https://stackoverflow.com/questions/962255/
    #   how-to-store-standard-error-in-a-variable-in-a-bash-script
    # For some reason, the semicolon is needed.
    #  "The '{}' does I/O redirection over the enclosed commands."
    PULLOUT=$(
      {
        git pull --rebase --autostash ${SOURCE_REPO} 2>&1
      } 2>&1
    )
    # Note: We cannot just capture stderr, e.g.,
    #         } 2>&1 >/dev/null
    #       because git seems to dump normal messages to stderr,
    #       hence the 2>&1 in the git command (at least I think
    #       that's what's going on).
    #       So rather than saying, if nothing is on stderr, there's
    #       no error, we just combine all output, look for what we
    #       know about, and hope we don't miss anything (because, on
    #       2017-08-04, I realized `unpack` was not working on two
    #       different repos, but I wasn't being informed (though the
    #       error appeared on the terminal, but mixed in with evertyhing
    #       else).

    if [[ `echo ${PULLOUT} | grep -i "error" -` ]]; then
      echo "=============================================="
      echo "✗ ✗ ✗ ERROR DETECTOROMETER! ★ ☆ ☆ ☆ ☆ 1 STAR!!"
      echo
      echo "${ERROR}"
      echo
      echo "ERROR: You lose!"
      echo "=============================================="
    fi
    # 2016-11-05: Check afterwards to see if there was an unresolved merge conflict.
    git -c color.ui=off status | grep "^rebase in progress" > /dev/null
    rebase_in_progress=$?
    if [[ ${rebase_in_progress} -ne 0 ]]; then
      git -c color.ui=off status | grep "^You are currently rebasing.$" > /dev/null
      rebase_in_progress=$?
    fi
    reset_errexit
    if [[ ${rebase_in_progress} -eq 0 ]]; then
      echo
      echo "WARNING: rebase problem in ${TARGET_REPO}"
      echo
      FRIES_GIT_ISSUES_DETECTED=true
      export FRIES_GIT_ISSUES_DETECTED
      # FIXME/2017-09-07: Address this is new Travel project.
      FRIES_GIT_ISSUES_RESOLUTIONS+=("travel mount && cdd $(pwd) && git st")
      FRIES_GIT_ISSUES_RESOLUTIONS+=("# Did you packme and then rebase and then packme again?")
      FRIES_GIT_ISSUES_RESOLUTIONS+=("# - Or did you forget to unpack first?")
      FRIES_GIT_ISSUES_RESOLUTIONS+=("# Maybe just chuck the conflict?:")
      FRIES_GIT_ISSUES_RESOLUTIONS+=("   ./travel mount")
      FRIES_GIT_ISSUES_RESOLUTIONS+=("   cdd $(pwd)")
      FRIES_GIT_ISSUES_RESOLUTIONS+=("   git st")
      FRIES_GIT_ISSUES_RESOLUTIONS+=("   git rebase --abort")
      FRIES_GIT_ISSUES_RESOLUTIONS+=("   git fetch ${TARGET_REFNAME}")
      FRIES_GIT_ISSUES_RESOLUTIONS+=("   git reset --hard ${TARGET_REFNAME_BRANCH_NAME}")
      export FRIES_GIT_ISSUES_RESOLUTIONS
      if ${FRIES_FAIL_ON_GIT_ISSUE}; then
        return 1
      fi
    fi
  fi

  popd &> /dev/null

} # end: git_pull_hush

# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #

check_git_clone_or_pull_error () {
  ret_code=$1
  git_resp=$2
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
      #echo $git_resp | grep "ssh: Could not resolve hostname" > /dev/null && failed=false
      echo $git_resp | grep "Could not resolve host" > /dev/null && failed=false
    fi
    if $failed; then
      echo ${git_resp}
      echo
      echo "FATAL: git operation failed."
      exit 1
    else
      echo
      echo "WARNING: git operation failed:"
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
  if [[ -n ${REL_PREFIX} ]]; then
    pushd ${REL_PREFIX} &> /dev/null
  fi

  project_name=$(basename -- $(pwd -P))

  branch_name=$(git branch --no-color | head -n 1 | /bin/sed 's/^\*\? *//')

  master_path="master+${project_name}"

  echo "Merging \"${branch_name}\" into ${master_path} and pushing to origin."

  if [[ ! -d ../${master_path}/.git ]]; then
      echo "FATAL: Cannot suss paths, ya dingus."
      [[ -n ${REL_PREFIX} ]] && popd &> /dev/null
      return 1
  fi

  echo git push origin ${branch_name}
  git push origin ${branch_name}

  echo pushd ../${master_path}
  pushd ../${master_path} &> /dev/null

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

  echo popd
  popd &> /dev/null

  [[ -n ${REL_PREFIX} ]] && popd &> /dev/null
}

# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #
# git-jockey

git-jockey () {
  find_git_parent .
  #echo "REPO_PATH: $REPO_PATH"
  if [[ -n $REPO_PATH ]]; then
    # Just the basics, I suppose.
    TOPLEVEL_COMMON_FILE=()
    TOPLEVEL_COMMON_FILE+=(".ignore")
    TOPLEVEL_COMMON_FILE+=(".agignore")
    TOPLEVEL_COMMON_FILE+=(".gitignore")
    TOPLEVEL_COMMON_FILE+=("README.rst")
    #echo "Checking single dirty files..."
    for ((i = 0; i < ${#TOPLEVEL_COMMON_FILE[@]}; i++)); do
      DIRTY_BNAME=$(basename -- "${TOPLEVEL_COMMON_FILE[$i]}")
      if [[ -f $REPO_PATH/${DIRTY_BNAME} ]]; then
        echo "Checking ${DIRTY_BNAME}"
        AUTO_COMMIT_FILES=true \
          git_commit_generic_file \
            "${TOPLEVEL_COMMON_FILE[$i]}" \
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
    gitst=$(git --git-dir=$subdir --work-tree=$subdir/.. status --short)
    if [[ -n $gitst ]]; then
      echo
      echo "====================================================="
      echo "Dirty project: $subdir"
      echo
      # We could just echo, but the we've lost any coloring.
      # Ok: echo $gitst
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
  if [[ $1 == "co" ]]; then
    if [[ $2 == "--" ]]; then
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
  if ! $gitted; then
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
  if [[ ! -e .git/info/exclude ]]; then
    echo "WARNING: Cannot infuse .gitignore.local under $(pwd -P)"
    return
  fi
  if [[ -f .git/info/exclude ]]; then
    pushd .git/info &> /dev/null
    /bin/rm exclude
    /bin/ln -sf "$1" "exclude"
    popd &> /dev/null
  fi
  /bin/ln -sf .git/info/exclude .gitignore.local
}

git_infuse_assume_unchanging() {
  [[ -z "$1" ]] && (echo "${FUNCNAME[0]}: missing param" && exit 1) || local opath="$1"
  if [[ -z "$2" ]]; then
    local fpath='.'
    local fname=$(basename -- "${opath}")
  else
    local fpath="$2"
    local fname=$(basename -- "${fpath}")
  fi
  [[ "$3" == "1" ]] && local do_sym=false || local do_sym=true

  pushd $(dirname -- "${fpath}") &> /dev/null

  git update-index --no-assume-unchanged "${fname}"
  if [[ ! $(git ls-files --error-unmatch "${fname}" 2>/dev/null ) ]]; then
    echo "${FUNCNAME[0]}: file not in git: ${fname}"
    exit 1
  fi
  if [[ "${do_sym}" == true && ! -h "${fname}" ]]; then
    local dirty_status=$(git status --porcelain "${fname}")
    if [[ -n "${dirty_status}" ]]; then
      echo "${FUNCNAME[0]}: git file is dirty: ${fname}"
      exit 1
    fi
  fi
  git update-index --assume-unchanged "${fname}"

  /bin/rm "${fname}"
  /usr/bin/git checkout -- "${fname}"
  /bin/cp "${fname}" "${fname}-COMMIT"
  if $do_sym; then
    /bin/ln -sf "${opath}" "${fname}"
  else
    /bin/cp -a "${opath}" "${fname}"
  fi

  popd &> /dev/null
}

git_unfuse_symlink() {
  [[ -z "$1" ]] && (echo "${FUNCNAME[0]}: missing param" && exit 1) || local fpath="$1"
  local fname=$(basename -- "${fpath}")
  pushd $(dirname -- "${fpath}") &> /dev/null
  if [[ -h "${fname}" ]]; then
    /bin/rm "${fname}"
    /bin/rm "${fname}-COMMIT"
    /usr/bin/git checkout -- "${fname}"
    git update-index --no-assume-unchanged "${fname}"
  fi
  popd &> /dev/null
}

git_unfuse_hardcopy() {
  [[ -z "$1" ]] && (echo "${FUNCNAME[0]}: missing param" && exit 1) || local fpath="$1"
  local fname=$(basename -- "${fpath}")
  pushd $(dirname -- "${fpath}") &> /dev/null
  if [[ -f "${fname}" ]]; then
    /bin/rm "${fname}"
    /bin/rm "${fname}-COMMIT"
    /usr/bin/git checkout -- "${fname}"
    git update-index --no-assume-unchanged "${fname}"
  fi
  popd &> /dev/null
}

# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #

main() {
  source_deps

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


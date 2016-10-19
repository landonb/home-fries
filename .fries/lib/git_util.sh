# File: .fries/lib/git_util.sh
# Author: Landon Bouma (landonb &#x40; retrosoft &#x2E; com)
# Last Modified: 2016.10.19
# Project Page: https://github.com/landonb/home-fries
# Summary: Git Helpers: Check if Dirty/Untracked/Behind; and Auto-commit.
# License: GPLv3
# vim:tw=0:ts=2:sw=2:et:norl:

GIT_ISSUES_DETECTED=false
export GIT_ISSUES_DETECTED

if [[ -z ${FAIL_ON_GIT_ISSUE+x} ]]; then
  FAIL_ON_GIT_ISSUE=false
fi

# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #
# find_git_parent

find_git_parent () {
  FILE_PATH=$1
  #echo "find_git_parent: FILE_PATH: ${1}"
  # Crap, if symlink, blows up, because prefix of git status doesn't match.
  REL_PATH="$(dirname ${FILE_PATH})"
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
        REL_PATH=$(dirname ${REL_PATH})
      else
        ABS_PATH="$(readlink -f ${REL_PATH})"
        if [[ ${ABS_PATH} == '/' ]]; then
          echo "WARNING: find_git_parent: No parent found for ${FILE_PATH}"
          break
        fi
        REL_PATH=../${REL_PATH}
      fi
    fi
  done
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
  set -e

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
  set -e

  if [[ $grep_result -eq 0 ]]; then
    # It's dirty.
    CUR_DIR=$(basename $(pwd -P))
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
      git commit -m "${COMMITMSG}" &> /dev/null
      if ! ${AUTO_COMMIT_FILES}; then
        echo 'Committed!'
      fi
    fi
  fi

  popd &> /dev/null

} # end: git_commit_generic_file

# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #
# git_commit_all_dirty_files

function git_commit_all_dirty_files () {

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
    set -e

    if [[ $grep_result -eq 0 ]]; then
      # It's dirty.
      echo
      if ! ${AUTO_COMMIT_FILES}; then
        echo -n "HEY, HEY: Your ${REPO_PATH} is dirty. Wanna check it all in? [y/n] "
        read -e YES_OR_NO
      else
        echo "HEY, HEY: Your ${REPO_PATH} is dirty. Ley's check that in for ya."
        YES_OR_NO="Y"
      fi
      if [[ ${YES_OR_NO^^} == "Y" ]]; then
        git add -u
        git commit -m "Auto-commit by Curly." &> /dev/null
        echo 'Committed!'
      fi
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
function git_status_porcelain () {

  GIT_REPO=$1

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

  # ***

  # MAYBE: Does this commits of known knowns feel awkward here?

  # Be helpful! We can take care of the known knowns.

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
    #git-st.sh &> /dev/null
    git-st.sh
    if [[ $? -ne 0 ]]; then
      unstaged_changes_found=true
    fi
  fi
  set -e
  if ${unstaged_changes_found}; then
    DIRTY_REPO=true
    echo "WARNING: Unstaged changes found in $GIT_REPO"
  fi

  set +e
  # 'M ' is added but not committed!
  eval git status --porcelain ${GREPPERS} | grep "^M  " &> /dev/null
  grep_result=$?
  set -e
  if [[ $grep_result -eq 0 ]]; then
    DIRTY_REPO=true
    echo "WARNING: Uncommitted changes found in $GIT_REPO"
  fi

  set +e
  eval git status --porcelain ${GREPPERS} | grep "^?? " &> /dev/null
  grep_result=$?
  set -e
  if [[ $grep_result -eq 0 ]]; then
    DIRTY_REPO=true
    echo "WARNING: Untracked files found in $GIT_REPO"
  fi

  set +e
  if ! ${USE_ALT_GIT_ST} && ! ${DIRTY_REPO}; then
    eval git status --porcelain ${GREPPERS} &> /dev/null
    if [[ $? -ne 0 ]]; then
      DIRTY_REPO=true
    fi
  else
    eval git status --porcelain ${GREPPERS} | grep -v "^ M " &> /dev/null
    if [[ $? -eq 0 ]]; then
      DIRTY_REPO=true
    fi
  fi
  set -e
  if ${DIRTY_REPO}; then
    echo "STOPPING: Dirty things found in $GIT_REPO"
    echo
    echo "  cdd $(pwd) && git add -p"
    echo
    if ! ${SKIP_GIT_DIRTY}; then
      echo "Please fix. Or run with -D (skip all git warnings)"
      echo "            or run with -DD (skip warnings about $0)"
      GIT_ISSUES_DETECTED=true
      export GIT_ISSUES_DETECTED
      if ${FAIL_ON_GIT_ISSUE}; then
        exit 1
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
  git remote -v | grep -P "^origin\t\/"
  grep_result=$?
  set -e

  if [[ $grep_result -ne 0 ]]; then
    # Not a local origin.

    if [[ -n $(git remote -v) ]]; then
      # Not a remote-less repo.

      branch_name=$(git branch --no-color | head -n 1 | /bin/sed 's/^\*\? *//')
      #echo "branch_name: ${branch_name}"

      # git status always compares against origin/master, or at least I
      # think it's stuck doing that. So this method only works if the
      # local branch is also master:
      if false; then
        set +e
        git status | grep "^Your branch is up-to-date with" &> /dev/null
        grep_result=$?
        set -e
        if [[ $grep_result -ne 0 ]]; then
          echo "WARNING: Branch is behind origin/${branch_name} at $GIT_REPO"
          echo
          echo "  cdd $(pwd) && git push origin ${branch_name} && popd"
          echo
          if ! ${SKIP_GIT_DIRTY}; then
            echo "Please fix. Or run with -D (skip all git warnings)"
            GIT_ISSUES_DETECTED=true
            export GIT_ISSUES_DETECTED
            if ${FAIL_ON_GIT_ISSUE}; then
              exit 1
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
      if true; then

        set +e
        # If we didn't --no-color the branch_name, we'd have to strip-color.
        #  stripcolors='/bin/sed -r "s/\x1B\[([0-9]{1,2}(;[0-9]{1,2})?)?[mGK]//g"'
        GIT_PUSH_STALENESS=$(git remote show origin \
          | grep "^\W*${branch_name}\W\+pushes to\W\+${branch_name}\W\+")
        grep_result=$?
        set -e
        if [[ $grep_result -ne 0 ]]; then
          echo "ERROR: Unexpected: Could not find \"${branch_name} pushes to ${branch_name}\""
          echo "                   in the output of"
          echo "                      git remote show origin"
          echo
          echo "branch_name=\"${branch_name}\""
          echo "git remote show origin | grep \"^\\W*\${branch_name}\\W\\+pushes to\\W\\+\${branch_name}\\W\\+\""
          exit 1
        fi

        set +e
        echo ${GIT_PUSH_STALENESS} | grep "(up to date)" &> /dev/null
        grep_result=$?
        set -e
        if [[ $grep_result -ne 0 ]]; then

          set +e
          echo ${GIT_PUSH_STALENESS} | grep "(local out of date)" &> /dev/null
          grep_result=$?
          set -e
          if [[ $grep_result -eq 0 ]]; then
            echo "WHATEVER: Branch is behind origin/${branch_name} at $GIT_REPO"
            echo "          You can git pull if you want to."
            echo "          But this script don't care."
            echo
          else
            echo "WARNING: Branch is ahead of origin/${branch_name} at $GIT_REPO"
            echo
            echo "  cdd $(pwd) && git push origin ${branch_name} && popd"
            echo
            if ! ${SKIP_GIT_DIRTY}; then
              echo "Please fix. Or run with -D (skip all git warnings)"
              GIT_ISSUES_DETECTED=true
              export GIT_ISSUES_DETECTED
              if ${FAIL_ON_GIT_ISSUE}; then
                exit 1
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
# git_pull_hush

function git_pull_hush () {
  SOURCE_REPO=$1
  TARGET_REPO=$2

  SKIP_GIT_PULL=false
  git_dir_check ${SOURCE_REPO}
  git_dir_check ${TARGET_REPO}
  if ${SKIP_GIT_PULL}; then
    if ${SKIP_GIT_DIRTY}; then
      echo "Skipping"
      echo
      return
    else
      exit 1
    fi
  fi

  pushd ${SOURCE_REPO} &> /dev/null
  SOURCE_BRANCH=$(git st | grep "^On branch" | /bin/sed -r "s/^On branch //")
  popd &> /dev/null

  pushd ${TARGET_REPO} &> /dev/null
  TARGET_BRANCH=$(git st | grep "^On branch" | /bin/sed -r "s/^On branch //")

  # 2016-09-28: Being extra paranoid because if the branches don't match,
  #             pull don't care! This is really confusing/worrying to me.
  if [[ -z ${SOURCE_BRANCH} ]]; then
    echo "FATAL: What?! No \$SOURCE_BRANCH"
    exit 1
  fi
  if [[ -z ${TARGET_BRANCH} ]]; then
    echo "FATAL: What?! No \$TARGET_BRANCH"
    exit 1
  fi
  if [[ ${SOURCE_BRANCH} != ${TARGET_BRANCH} ]]; then
    echo "FATAL: \${SOURCE_BRANCH} != \${TARGET_BRANCH}"
    echo " SOURCE_BRANCH: ${SOURCE_BRANCH}"
    echo " TARGET_BRANCH: ${TARGET_BRANCH}"
    echo "You may need to change branches:"
    echo "  #pushd $(pwd -P) && git checkout --track origin/${SOURCE_BRANCH}"
    echo " or maybe it's the other one"
    echo "  #pushd ${SOURCE_REPO} && git checkout --track origin/${SOURCE_BRANCH}"
    echo " but really it might be this"
    echo "  pushd $(pwd -P)"
    echo "  git remote set-url origin /${SOURCE_REPO}"
    echo "  git pull -a"
    echo "  git checkout -b feature/${SOURCE_BRANCH} --track origin/master"
    echo "   or maybe just"
    echo "  git checkout -b ${SOURCE_BRANCH} --track origin/master"
    exit 1
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
    set -e
  fi

  if true; then
    set +e
    #echo git pull --rebase --autostash $SOURCE_REPO 2>&1
    # NOTE: The Current branch grep doesn't work if like "feature/topic".
    #       But I kinda like seeing that.
    #       I wonder if just ignoring master is ok (normally show branch?).
    git pull --rebase --autostash $SOURCE_REPO 2>&1 \
      | grep -v "^ \* branch            HEAD       -> FETCH_HEAD$" \
      | grep -v "^Already up-to-date.$" \
      | grep -v "^Current branch [a-zA-Z0-9]* is up to date.$" \
      | grep -v "^From .*${TARGET_REPO}$"
    set -e
  fi

  popd &> /dev/null

} # end: git_pull_hush

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

  project_name=$(basename $(pwd -P))

  branch_name=$(git branch --no-color | head -n 1 | /bin/sed 's/^\*\? *//')

  master_path="master+${project_name}"

  echo "Merging \"${branch_name}\" into ${master_path} and pushing to origin."

  if [[ ! -d ../${master_path}/.git ]]; then
      echo "FATAL: Cannot suss paths, ya dingus."
      return 1
  fi

  echo git push origin ${branch_name}
  git push origin ${branch_name}

  echo pushd ../${master_path}
  pushd ../${master_path} &> /dev/null

  # If you were to be working in master, you'd want to rebase:
  #   pull --rebase --autostash
  # but you don't touch master other than as a hopper repo.
  echo git pull
  git pull

  echo git merge origin/${branch_name}
  git merge origin/${branch_name}

  echo git push origin master
  git push origin master

  echo popd
  popd &> /dev/null

  # FIXME: You want to log the *new* build, and then that should die, right?
  #        And then you can log the new deployment.
  #        Also, none of this works if you're not in the correct `oc project`.
  if false; then

    command -v oc &> /dev/null
    if [[ $? -eq 0 ]]; then

      # Get the remote url to get the project name.
      # We could get this with `git remote -v` but that
      # prints multiple lines and is more verbose, e.g.,
      #
      #   $ git remote -v
      #   origin  ssh://git@github.com/user/division-client-project (fetch)
      #   origin  ssh://git@github.com/user/division-client-project (push)
      #
      #   $ git remote get-url origin
      #   ssh://git@github.com/user/division-client-project
      #
      #   $ url_origin=$(git remote get-url origin)
      #   $ echo ${url_origin#*-}
      #   client-project
      #
      #   $ echo $url_origin | sed s/^.*-\([^-]\+\)/\\1/
      #   project

      # Get the remote name, usually 'origin'.
      remote_name=$(git remote)
      echo "remote_name: ${remote_name}"

      url_origin=$(git remote get-url ${remote_name})
      echo "url_origin: ${url_origin}"

      project_name=$(echo $(basename $url_origin) | sed s/^.*-\([^-]\+\)/\\1/)
      echo "project_name: ${project_name}"

      project_pod=$(oc get pods | grep ${project_name} | grep Running | head -n 1 | awk '{print $1}')
      echo "project_pod: ${project_pod}"

      oc logs -f ${project_pod}

    fi

  fi

}

# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #
# git-jockey

git-jockey () {

  find_git_parent .

  #echo "REPO_PATH: $REPO_PATH"

  if [[ -n $REPO_PATH ]]; then

    # Just the basics, I suppose.
    TOPLEVEL_COMMON_FILE=()
    TOPLEVEL_COMMON_FILE+=(".agignore")
    TOPLEVEL_COMMON_FILE+=(".gitignore")
    TOPLEVEL_COMMON_FILE+=("README.rst")

    #echo "Checking single dirty files..."
    for ((i = 0; i < ${#TOPLEVEL_COMMON_FILE[@]}; i++)); do
      DIRTY_BNAME=$(basename ${TOPLEVEL_COMMON_FILE[$i]})
      if [[ -f $REPO_PATH/.agignore ]]; then
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


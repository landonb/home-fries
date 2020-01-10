# vim:tw=0:ts=2:sw=2:et:norl:nospell:ft=sh

source_deps () {
  # Load: warn, etc.
  . ${HOME}/.fries/lib/logger.sh
}

reveal_biz_vars () {
  MR_GIT_AUTO_COMMIT_SAID_HELLO=false
}

git_auto_commit_parse_args () {
  MR_GIT_AUTO_COMMIT_MSG="${MR_GIT_AUTO_COMMIT_MSG:-""}"
  # Assume first param the commit message unless an -o/--option.
  if [ -n "${1}" ] && [ "${1#-}" = "$1" ]; then
    MR_GIT_AUTO_COMMIT_MSG="${1}"
    shift
  fi

  # Note that both `shift` and `set -- $@` are scoped to this function,
  # so we'll process all args in one go (rather than splitting into two
  # functions, because myrepostravel_opts_parse complains on unknown args).
  myrepostravel_opts_parse "${@}"
  [ ${MRT_AUTO_YES} -eq 0 ] && MR_AUTO_COMMIT=true || true
}

git_auto_commit_hello () {
  # Only pring the "examining" message once, e.g., affects calls such as:
  #     autocommit =
  #       git_auto_commit_one 'some/file' "${@}"
  #       git_auto_commit_one 'ano/ther' "${@}"
  if ! ${MR_GIT_AUTO_COMMIT_SAID_HELLO}; then
    MR_GIT_AUTO_COMMIT_BEFORE_CD="$(pwd -L)"
    cd "${MR_REPO}"
    debug "  $(fg_mintgreen)$(attr_emphasis)examining$(attr_reset)  " \
      "$(fg_mintgreen)${MR_REPO}$(attr_reset)"
  fi
  MR_GIT_AUTO_COMMIT_SAID_HELLO=true
}

git_auto_commit_seeya () {
  cd "${MR_GIT_AUTO_COMMIT_BEFORE_CD}"
}

git_auto_commit_noop () {
  debug "  $(fg_mintgreen)$(attr_emphasis)excluding$(attr_reset)  " \
    "$(fg_mintgreen)${MR_REPO}$(attr_reset)"
}

git_auto_commit_one () {
  local repo_file="$1"
  shift

  # 2019-10-28: (lb): Trying just base filename, for shorter message.
  # MR_GIT_AUTO_COMMIT_MSG="Myrepos: Autocommit: “${repo_file}” [@$(hostname)]."
  # MR_GIT_AUTO_COMMIT_MSG="Myrepos: Autocommit: “$(basename ${repo_file})” [@$(hostname)]."
  MR_GIT_AUTO_COMMIT_MSG="myrepos: autoci: Add Favorite: [@$(hostname)] “$(basename ${repo_file})”."
  git_auto_commit_parse_args "${@}"
  git_auto_commit_hello

  local extcd
  (git status --porcelain "${repo_file}" |
    grep "^\W*M\W*${repo_file}" >/dev/null 2>&1) || extcd=$?

  if [ -z ${extcd} ]; then
    local yorn
    if [ -z ${MR_AUTO_COMMIT} ] || ! ${MR_AUTO_COMMIT}; then
      echo
      echo "Yo! This file is dirty: $(fg_lightorange)${MR_REPO}/${repo_file}$(attr_reset)"
      echo -n "Commit the file changes? [y/n] "
      read yorn
    else
      debug "Committing dirty file: $(fg_lavender)${MR_REPO}/${repo_file}$(attr_reset)"
      yorn="Y"
    fi

    if [ ${yorn#y} != ${yorn#y} ] || [ ${yorn#Y} != ${yorn#Y} ]; then
      git add "${repo_file}"
      # FIXME/2017-04-13: Handle errors better (and maybe don't send to /dev/null).
      # E.g., I saw errors on uncommitted changes here years ago:
      #   U	path/to/my.file
      #   error: Committing is not possible because you have unmerged files.
      #   hint: Fix them up in the work tree, and then use 'git add/rm <file>'
      #   hint: as appropriate to mark resolution and make a commit.
      #   fatal: Exiting because of an unresolved conflict.
      # (but it could be that the code won't make it here anymore on
      # those conditions, e.g., maybe merge conflicts are seen earlier).
      git commit -m "${MR_GIT_AUTO_COMMIT_MSG}" >/dev/null 2>&1
      if [ -z ${MR_AUTO_COMMIT} ] || ! ${MR_AUTO_COMMIT}; then
        echo 'Committed!'
      fi
    elif [ -z ${MR_AUTO_COMMIT} ] || ! ${MR_AUTO_COMMIT}; then
      echo 'Skipped!'
    fi

  # else, the file is not dirty.
  fi

  git_auto_commit_seeya
}

git_auto_commit_all () {
  MR_GIT_AUTO_COMMIT_MSG="myrepos: autoci: Add All Dirty [@$(hostname)]."
  git_auto_commit_parse_args "${@}"
  git_auto_commit_hello

  # We ignore untracted files here because they cannot be added
  # by a generic `git add -u` -- in fact, git should complain.
  #
  # So auto-commit works on existing git files, but not on new ones.
  #
  # (However, `git add --all` adds untracked files, but rather than
  # automate this, don't. Because user might really want to update
  # .gitignore instead, or might still be considering where an un-
  # tracked file should reside, or maybe it's just a temp file, etc.)
  #
  # Also, either grep pattern should work:
  #
  #   git status --porcelain | grep "^\W*M\W*" >/dev/null 2>&1
  #   git status --porcelain | grep "^[^\?]" >/dev/null 2>&1
  #
  # but I'm ignorant of anything other than the two codes,
  # '?? filename', and ' M filename', so let's be inclusive and
  # just ignore new files, rather than being exclusive and only
  # looking for modified files. If there are untracted files, a
  # later call to git_status_porcelain on the same repo will die.
  #
  #  (git status --porcelain | grep "^\W*M\W*" >/dev/null 2>&1) || extcd=$?
  local extcd
  (git status --porcelain | grep "^[^\?]" >/dev/null 2>&1) || extcd=$?
  if [ -z ${extcd} ]; then
    local yorn
    if [ -z ${MR_AUTO_COMMIT} ] || ! ${MR_AUTO_COMMIT}; then
      echo
      echo "Yo! This repo is dirty: $(fg_lightorange)${MR_REPO}$(attr_reset)"
      echo -n "Commit *all* object changes? [y/n] "
      read yorn
    else
      local pretty_path="$(attr_underline)$(bg_darkgray)${MR_REPO}$(attr_reset)"
      notice "Auto-commit *all* objects: ${pretty_path}"
      yorn="Y"
    fi

    if [ ${yorn#y} != ${yorn#y} ] || [ ${yorn#Y} != ${yorn#Y} ]; then
      git add -u
      git commit -m "${MR_GIT_AUTO_COMMIT_MSG}" >/dev/null 2>&1
      if [ -z ${MR_AUTO_COMMIT} ] || ! ${MR_AUTO_COMMIT}; then
        echo 'Committed!'
      else
        verbose 'Committed!'
      fi
    elif [ -z ${MR_AUTO_COMMIT} ] || ! ${MR_AUTO_COMMIT}; then
      echo 'Skipped!'
    fi
  fi

  git_auto_commit_seeya
}

git_auto_commit_new () {
  MR_GIT_AUTO_COMMIT_MSG="myrepos: autoci: Add Untracked [@$(hostname)]."
  git_auto_commit_parse_args "${@}"
  git_auto_commit_hello

  local extcd
  (git status --porcelain . | grep "^[\?][\?]" >/dev/null 2>&1) || extcd=$?

  if [ -z ${extcd} ]; then
    local yorn
    if [ -z ${MR_AUTO_COMMIT} ] || ! ${MR_AUTO_COMMIT}; then
      echo
      echo "Yo! This repo has untracked paths: $(fg_lightorange)${MR_REPO}$(attr_reset)"
      echo -n "Add *untracked* paths therein? [y/n] "
      read yorn
    else
      local pretty_path="$(attr_underline)$(bg_darkgray)${MR_REPO}$(attr_reset)"
      notice "Auto-commit *new* objects: ${pretty_path}"
      yorn="Y"
    fi

    if [ ${yorn#y} != ${yorn#y} ] || [ ${yorn#Y} != ${yorn#Y} ]; then
      # Hilarious. There's one way to programmatically add only
      # untracked files, and it's using the interactive feature.
      # (Because `git add .` adds untracked files but also includes
      # edited files; but we provide git_auto_commit_all for edited
      # files.)
      # TOO INCLUSIVE: git add .
      echo "a\n*\nq\n" | git add -i >/dev/null 2>&1
      git commit -m "${MR_GIT_AUTO_COMMIT_MSG}" >/dev/null 2>&1
      if [ -z ${MR_AUTO_COMMIT} ] || ! ${MR_AUTO_COMMIT}; then
        echo 'Committed!'
      else
        verbose 'Committed!'
      fi
    elif [ -z ${MR_AUTO_COMMIT} ] || ! ${MR_AUTO_COMMIT}; then
      echo 'Skipped!'
    fi
  fi

  git_auto_commit_seeya
}

# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #

main () {
  source_deps
  reveal_biz_vars
}

main "$@"


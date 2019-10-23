# vim:tw=0:ts=2:sw=2:et:norl:nospell:ft=config

source_deps () {
  local curdir="${HOME}/.fries/lib"
  if [ -n "${BASH_SOURCE}" ]; then
    curdir=$(dirname -- "${BASH_SOURCE[0]}")
  fi

  # Use logger (which loads color_funcs.sh) for colorful, stylized output.
  # NOTE: So that this script is POSIX-compliant, use `.`, not `source`.
  . "${curdir}/logger.sh"
}

reveal_biz_vars () {
  MR_GIT_AUTO_COMMIT_SAID_HELLO=false
}

git_auto_commit_hello () {
  # Only pring the "examining" message once, e.g., affects calls such as:
  #     autocommit = git_auto_commit_one 'some/file' && git_auto_commit_one 'ano/ther'
  if ! ${MR_GIT_AUTO_COMMIT_SAID_HELLO}; then
    debug "  $(fg_mintgreen)$(attr_emphasis)examining$(attr_reset)  " \
      "$(fg_mintgreen)${MR_REPO}$(attr_reset)"
  fi
  MR_GIT_AUTO_COMMIT_SAID_HELLO=true
}

git_auto_commit_noop () {
  debug "  $(fg_mintgreen)$(attr_emphasis)excluding$(attr_reset)  " \
    "$(fg_mintgreen)${MR_REPO}$(attr_reset)"
}

git_auto_commit_one () {
  local repo_file="$1"
  local commit_msg="${2:-Auto-commit ${repo_file} [@$(hostname)].}"
  local extcd
  git_auto_commit_hello
  (git status --porcelain "${repo_file}" |
    grep "^\W*M\W*${repo_file}" 2> /dev/null) || extcd=$? || true
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
      git commit -m "${commit_msg}" 2> /dev/null
      if [ -z ${MR_AUTO_COMMIT} ] || ! ${MR_AUTO_COMMIT}; then
        echo 'Committed!'
      fi
    elif [ -z ${MR_AUTO_COMMIT} ] || ! ${MR_AUTO_COMMIT}; then
      echo 'Skipped!'
    fi
  # else, the file is not dirty.
  fi
}

git_auto_commit_all () {
  local commit_msg="${1:-Auto-commit *all* objects with myrepos [@$(hostname)].}"
  local extcd
  git_auto_commit_hello
  #
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
  #   git status --porcelain | grep "^\W*M\W*" 2> /dev/null
  #   git status --porcelain | grep "^[^\?]" 2> /dev/null
  #
  # but I'm ignorant of anything other than the two codes,
  # '?? filename', and ' M filename', so let's be inclusive and
  # just ignore new files, rather than being exclusive and only
  # looking for modified files. If there are untracted files, a
  # later call to git_status_porcelain on the same repo will die.
  #
  #  (git status --porcelain | grep "^\W*M\W*" 2> /dev/null) || extcd=$? || true
  (git status --porcelain | grep "^[^\?]" 2> /dev/null) || extcd=$? || true
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
      git commit -m "${commit_msg}" 2> /dev/null
      if [ -z ${MR_AUTO_COMMIT} ] || ! ${MR_AUTO_COMMIT}; then
        echo 'Committed!'
      else
        verbose 'Committed!'
      fi
    elif [ -z ${MR_AUTO_COMMIT} ] || ! ${MR_AUTO_COMMIT}; then
      echo 'Skipped!'
    fi
  fi
}

git_auto_commit_new () {
  local commit_msg="${1:-Auto-add *untracked* files via myrepos [@$(hostname)].}"
  local extcd
  git_auto_commit_hello
  (git status --porcelain . | grep "^[\?][\?]" 2> /dev/null) || extcd=$? || true
  if [ -z ${extcd} ]; then
    local yorn
    if [ -z ${MR_AUTO_COMMIT} ] || ! ${MR_AUTO_COMMIT}; then
      echo
      echo "Yo! This repo has untracked paths: $(fg_lightorange)${MR_REPO}$(attr_reset)"
      echo -n "Add *untracked* paths therein? [y/n] "
      read yorn
    else
      local pretty_path="$(attr_underline)$(bg_darkgray)${MR_REPO}$(attr_normal)"
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
      echo "a\n*\nq\n" | git add -i 2> /dev/null
      git commit -m "${commit_msg}" 2> /dev/null
      if [ -z ${MR_AUTO_COMMIT} ] || ! ${MR_AUTO_COMMIT}; then
        echo 'Committed!'
      else
        verbose 'Committed!'
      fi
    elif [ -z ${MR_AUTO_COMMIT} ] || ! ${MR_AUTO_COMMIT}; then
      echo 'Skipped!'
    fi
  fi
}

# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #

main () {
  source_deps
  reveal_biz_vars
}

main "$@"


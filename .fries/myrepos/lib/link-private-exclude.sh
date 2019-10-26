# vim:tw=0:ts=2:sw=2:et:norl:nospell:ft=sh

source_deps () {
  # Load: warn, etc.
  . ${HOME}/.fries/lib/logger.sh

  # Load: symlink_*
  #       ensure_source_file_exists
  #       ensure_target_writable
  #
  . "${MR_TRAVEL_LIB:-${HOME}/.fries/myrepos/lib}/overlay-symlink.sh"
}

# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #

# CONVENTION: Store .git/info/exclude files under a directory named
# .mrinfuse located in the same directory as the .mrconfig file whose
# repo config calls this function. Under the .mrinfuse directory, mimic
# the directory alongside the .mrconfig file. For instance, the exclude
# file for home-fries (linked from ~/.git/info/exclude) is stored at:
#   ~/.mrinfuse/_git/info/exclude
# As another example, suppose you had a config file at:
#   /my/work/projects/.mrconfig
# and you had a public repo underneath that project space at:
#   /my/work/projects/cool/product/
# you would store your private .gitignore file at:
#   /my/work/projects/.mrinfuse/cool/product/_git/info/exclude
# Also note that the .git/ directory is mirrored as _git, because git
#   will not let you add files from under a directory named .git/.

SOURCE_REL='_git/info/exclude'
TARGET_REL='.git/info/exclude'

# ***

_info_path_resolve () {
  local relative_path="$1"
  local exclude_fpath="$2"
  local canonicalized="$3"
  #
  local testing=false
  # Uncomment to spew vars and exit:
  # testing=true
  if $testing; then
    >&2 echo "MR_REPO=${MR_REPO}"
    >&2 echo "MR_CONFIG=${MR_CONFIG}"
    >&2 echo "repo_path_n_sep=${repo_path_n_sep}"
    >&2 echo "relative_path=${relative_path}"
    >&2 echo "exclude_fpath=${exclude_fpath}"
    >&2 echo "canonicalized=${canonicalized}"
    >&2 echo "current dir: $(pwd)"
    return 1
  fi
}

# ***

link_private_exclude () {
  local was_link_force="${MRT_LINK_FORCE}"
  local was_link_safe="${MRT_LINK_SAFE}"
  symlink_opts_parse "${@}"

  local before_cd="$(pwd -L)"
  cd "${MR_REPO}"

  local sourcep
  sourcep=$(path_to_mrinfuse_resolve "${SOURCE_REL}")

  # Check that the source file exists.
  # This may interrupt the flow if errexit.
  ensure_source_file_exists "${sourcep}"

  # Pass CLI params to check -s/--safe or -f/--force.
  ensure_target_writable '.gitignore.local'
  ensure_target_writable '.git/info/exclude'

  cd .git/info
  # MEH/2019-10-26 14:06: `git init` always puts a descriptive exclude
  # in place, which we could explicitly look for, and then if still a
  # file but unknown contents, complain to user and bail (and force them
  # to run `mr infuse --force` or `mr infuse --safe`. But what's the ROI?
  # Just clobber the target if a file.
  symlink_file_clobber "${sourcep}" 'exclude'
  cd ../..

  # 2019-10-26 14:06: Here we can be more gentle, and not clobber existing
  # file.
  symlink_overlay_file "${TARGET_REL}" '.gitignore.local'

  cd "${before_cd}"

  MRT_LINK_FORCE="${was_link_force}"
  MRT_LINK_SAFE="${was_link_safe}"
}

link_private_exclude_force () {
  link_private_exclude --force
}

# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #

main () {
  # Don't do anything other than source dependencies.
  # Caller will call functions explicitly as appropriate.
  source_deps
}

main "${@}"


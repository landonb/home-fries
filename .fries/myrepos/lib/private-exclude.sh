# vim:tw=0:ts=2:sw=2:et:norl:nospell:ft=sh

source_deps () {
  # Load: warn, etc.
  . ${HOME}/.fries/lib/logger.sh

  # Load:
  #   params_check_force
  #   ensure_source_exists
  #   ensure_target_writable
  #   symlink_file_informative
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
    info "MR_REPO=${MR_REPO}"
    info "MR_CONFIG=${MR_CONFIG}"
    info "repo_path_n_sep=${repo_path_n_sep}"
    info "relative_path=${relative_path}"
    info "exclude_fpath=${exclude_fpath}"
    info "canonicalized=${canonicalized}"
    info "current dir: $(pwd)"
    return 1
  fi
}

# ***

link_private_exclude () {
  local before_cd="$(pwd -L)"
  cd "${MR_REPO}"

  local sourcep
  sourcep=$(path_to_mrinfuse_resolve "${SOURCE_REL}")

  # Check that the source file exists.
  # This may interrupt the flow if errexit.
  ensure_source_exists "${sourcep}"

  # Pass CLI params to check -s/--safe or -f/--force.
  ensure_target_writable '.gitignore.local' "${@}"
  ensure_target_writable '.git/info/exclude' "${@}"

  cd .git/info
  symlink_file_informative "${sourcep}" 'exclude'
  cd ../..

  symlink_file_informative "${TARGET_REL}" '.gitignore.local'

  cd "${before_cd}"

# FIXME/2019-10-26 02:50: This might be redundant now!
  info "Wired .gitignore.local"
}

# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #

main () {
  # Don't do anything other than source dependencies.
  # Caller will call functions explicitly as appropriate.
  source_deps
}

main "$@"


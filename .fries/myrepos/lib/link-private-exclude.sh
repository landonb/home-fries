#!/bin/sh
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

_info_path_exclude () {
  local testing=false
  # Uncomment to spew vars and exit:
  testing=true
  if $testing; then
    >&2 echo "MR_REPO=${MR_REPO}"
    >&2 echo "MR_CONFIG=${MR_CONFIG}"
    >&2 echo "current dir: $(pwd)"
    >&2 echo "MRT_LINK_FORCE=${MRT_LINK_FORCE}"
    >&2 echo "MRT_LINK_SAFE=${MRT_LINK_SAFE}"
    return 1
  fi
}

# ***

# `git init` create a descriptive .git/info/exclude file that we can
# replace without asking if boilerplate.
#
# E.g., here's the file that git makes:
#
#   $ cat .git/info/exclude
#   git ls-files --others --exclude-from=.git/info/exclude
#   Lines that start with '#' are comments.
#   For a project mostly in C, the following would be a good set of
#   exclude patterns (uncomment them if you want to use them):
#   *.[oa]
#   *~
#
# We can use the file checksum to check for change:
#
#   $ sha256sum .git/info/exclude | awk '{print $1}'
#   6671fe83b7a07c8932ee89164d1f2793b2318058eb8b98dc5c06ee0a5a3b0ec1

try_clobbering_exclude_otherwise_try_normal_overlay () {
  local sourcep="$1"

  cd .git/info

  local clobbered=false
  local exclude_f='exclude'
  if [ -f "${exclude_f}" ]; then
    local xsum=$(sha256sum "${exclude_f}" | awk '{print $1}')
    if [ "$xsum" = '6671fe83b7a07c8932ee89164d1f2793b2318058eb8b98dc5c06ee0a5a3b0ec1' ]; then
      # info "Removed default: .git/info/exclude"
      symlink_file_clobber "${sourcep}" 'exclude'
      clobbered=true
    fi
  fi

  if ! $clobbered; then
    symlink_overlay_file "${sourcep}" 'exclude'
  fi

  cd ../..
}

# ***

link_exclude_resolve_source_and_overlay () {
  local targetf="${1:-".gitignore.local"}"

  local sourcep
  sourcep=$(path_to_mrinfuse_resolve "${SOURCE_REL}")

  # Clobber .git/info/exclude if `git init` boilerplate, otherwise try
  # updating normally (replace/update if symlink, or check --force or
  # --safe if regular file to decide what to do).
  try_clobbering_exclude_otherwise_try_normal_overlay "${sourcep}"

  # Place the ./.gitignore.local symlink.
  symlink_overlay_file "${TARGET_REL}" "${targetf}"
}

# ***

link_private_exclude () {
  local was_link_force="${MRT_LINK_FORCE}"
  local was_link_safe="${MRT_LINK_SAFE}"
  symlink_opts_parse "${@}"

  local before_cd="$(pwd -L)"
  cd "${MR_REPO}"

  # _info_path_exclude

  link_exclude_resolve_source_and_overlay

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

set -e

# main justs ensures the dependencies are loaded.
# Caller is expected to call link_private_exclude*
# as necessary.
main "${@}"


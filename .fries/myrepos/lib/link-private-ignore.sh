# vim:tw=0:ts=2:sw=2:et:norl:nospell:ft=sh

source_deps () {
# FIXME/2019-10-26 03:20: Improve sourcing...
  # Load: warn, etc.
  . ${HOME}/.fries/lib/logger.sh

  # Load: 
  . ${HOME}/.fries/myrepos/lib/overlay-symlink.sh
}

# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #

link_private_ignore () {
  local was_link_force="${MRT_LINK_FORCE}"
  local was_link_safe="${MRT_LINK_SAFE}"
  symlink_opts_parse "${@}"

  local before_cd="$(pwd -L)"
  cd "${MR_REPO}"

  symlink_mrinfuse_file '.ignore'

  cd "${before_cd}"

  MRT_LINK_FORCE="${was_link_force}"
  MRT_LINK_SAFE="${was_link_safe}"
}

# An alias, of sorts.
link_private_ignore_force () {
  link_private_ignore --force
}

# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #

main () {
  source_deps
}

main "$@"


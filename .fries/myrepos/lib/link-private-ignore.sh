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
  symlink_mrinfuse_file '.ignore' "${@}"
}

# An alias, of sorts.
link_private_ignore_force () {
  link_private_ignore --force "${@}"
}

# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #

main () {
  source_deps
}

main "$@"


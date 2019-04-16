#!/bin/bash

source_deps () {
  # Set USERS_CURLY and USERS_BNAME.
  source ${HOME}/.fries/lib/curly_util.sh
  setup_users_curly_path
}

use_shim () {
  while [[ "$1" != '' ]]; do
    case $1 in
      --no-shim)
        return 1
        shift
        ;;
      *)
        shift
        ;;
    esac
  done
  return 0
}

main () {
  set -e
  source_deps

  script_dir=$(dirname -- "${BASH_SOURCE[0]}")

  # If your travel location from which you're pulling has the new
  # travel.sh, you'll want to use that; do a little copy-run dance.
  ${script_dir}/travel prepare-shim "$@"

  if [[ $? -eq 0 ]]; then
    if use_shim "$@"; then
      info "Running latest travel.sh from syncstick"
      ${USERS_CURLY}/TBD-shim/travel_shim.sh unpack "$@"
    else
      info "Running legacy travel.sh from host machine"
      ${script_dir}/travel unpack "$@"
    fi
    if [[ -d "${USERS_CURLY}/TBD-shim" ]]; then
      /bin/rm -rf -- "${USERS_CURLY}/TBD-shim"
    fi
  else
    error "BURN: Failed to run prepare-shim!"
  fi
}

main "$@"


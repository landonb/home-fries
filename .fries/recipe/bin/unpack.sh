#!/bin/bash
SCRIPT_DIR=$(dirname -- "${BASH_SOURCE[0]}")
# If your travel location from which you're pulling has the new
# travel.sh, you'll want to use that; do a little copy-run dance.
${SCRIPT_DIR}/travel prepare-shim $*
source ${HOME}/.fries/lib/logger.sh
if [[ $? -eq 0 ]]; then
  info "Shim-town"
  source ${HOME}/.fries/lib/curly_util.sh
  # Set USERS_CURLY and USERS_BNAME.
  setup_users_curly_path
  ${USERS_CURLY}/TBD-shim/travel_shim.sh unpack $*
  /bin/rm -rf ${USERS_CURLY}/TBD-shim
else
  error "BURN: Something went wrong."
fi
unset SCRIPT_DIR


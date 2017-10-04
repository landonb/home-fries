#!/bin/bash
SCRIPT_DIR=$(dirname -- "${BASH_SOURCE[0]}")
#${SCRIPT_DIR}/travel packme $*
# 2016-11-02: That's the ticket! Auto checkin known dirty git.
${SCRIPT_DIR}/travel packme -WW $*
unset SCRIPT_DIR


#!/bin/bash
SCRIPT_DIR=$(dirname -- "${BASH_SOURCE[0]}")
${SCRIPT_DIR}/travel init_travel $*
unset SCRIPT_DIR


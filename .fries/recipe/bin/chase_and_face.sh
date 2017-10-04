#!/bin/bash
SCRIPT_DIR=$(dirname -- "${BASH_SOURCE[0]}")
${SCRIPT_DIR}/travel chase_and_face $*
unset SCRIPT_DIR


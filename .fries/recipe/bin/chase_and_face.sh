#!/bin/bash

main () {
  local script_dir=$(dirname -- "${BASH_SOURCE[0]}")
  ${script_dir}/travel chase_and_face "$@"
}

main "$@"


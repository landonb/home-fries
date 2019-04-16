#!/bin/bash

main () {
  local script_dir=$(dirname -- "${BASH_SOURCE[0]}")
  # 2016-11-02: -WW: Auto checkin known dirty git.
  ${script_dir}/travel packme -WW "$@"
}

main "$@"


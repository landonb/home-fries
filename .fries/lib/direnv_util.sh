#!/bin/bash
# vim:tw=0:ts=2:sw=2:et:norl:
# Project: https://github.com/landonb/home-fries
# License: GPLv3

# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #

source_deps () {
  local curdir=$(dirname -- "${BASH_SOURCE[0]}")
  # Load: path_prepend
  source ${curdir}/paths_util.sh
}

# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #

# "Picking up aliases and functions". Via:
#  https://github.com/direnv/direnv/issues/73
direnv_export () {
  local name=$1
  local alias_dir=$PWD/.direnv/aliases
  mkdir -p "$alias_dir"
  path_prepend "$alias_dir"
  local target="$alias_dir/$name"
  if declare -f "$name" >/dev/null; then
    echo "#!/usr/bin/env bash" > "$target"
    declare -f "$name" >> "$target" 2>/dev/null
    # Notice that we add shell variables to the function trigger.
    echo "$name \$*" >> "$target"
    chmod +x "$target"
  fi
}

# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #

main () {
  source_deps
  unset -f source_deps

  # 2019-09-16: (lb): I don't think direnv_export is used. Anymore.
  #   I had been using it for some client work a few years back. I think.
  #direnv_export
  unset -f direnv_export
}

main "$@"
unset -f main


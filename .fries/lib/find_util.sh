#!/bin/bash
# vim:tw=0:ts=2:sw=2:et:ft=sh:

# Walk up the path looking for a file with the matching name.
invursive_find () {
  local filepath=$1
  if [[ -z ${filepath} ]]; then
    echo "ERROR: Please specify a file."
    return 1
  fi

  local filename=$(basename -- "${filepath}")
  local dirpath=$(dirname -- "${filepath}")

  # Deal only in full paths.
  # Symlinks okay (hence not `pwd -P` or `readlink -f`).
  pushd ${dirpath} &> /dev/null
  dirpath=$(pwd)
  popd &> /dev/null

  local invursive_path=''
  # We don't return things from file system root. Because safer?
  while [[ ${dirpath} != '/' ]]; do
    if [[ -f ${dirpath}/${filename} ]]; then
      invursive_path="${dirpath}/${filename}"
      break
    fi
    dirpath=$(dirname -- "${dirpath}")
  done

  # Here's how chruby/auto.sh does the same:
  #   local dir="$PWD/"
  #   until [[ -z "$dir" ]]; do
  #       dir="${dir%/*}"
  #       if ... fi
  #   done

  if [[ -n "${invursive_path}" ]]; then
    echo "${invursive_path}"
    return 0
  else
    return 1
  fi
}


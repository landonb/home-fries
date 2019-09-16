#!/bin/bash
# vim:tw=0:ts=2:sw=2:et:norl:

# File: fffind_util.sh
# Author: Landon Bouma (landonb &#x40; retrosoft &#x2E; com)
# Project Page: https://github.com/landonb/home-fries
# Summary: Generic Bash function library.
# License: GPLv3

# Usage: Source this script. Call its functions. Use its exports.

# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #

source_deps () {
  :
}

# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #

# 2015.02.20: Fancy find: A linux find command that honors .*ignore,
#                         like .gitignore and .agignore.
# 2017-09-13: Hahaha, now Silver Search and new ripgrep honor .ignore.

# FIXME: For this to be really effective, you'd have to descend
#        into directories looking for the ignore files... so,
#        like, really tedious...
#        You could either descend into each directory to look
#        for the ignore file before `find`ing, or you could
#        `find` first and then cull the results (by going into
#        directories of each result and walking up the tree
#        looking for ignore files, which seems extremely teeds).
#        Ug. For now, I guess a find that honors ignores is still
#        a pipe dream... though maybe an easy solution is to descend
#        into all directories looking for ignore files, and then
#        making a big array of fuller paths of ignore rules, i.e.,
#        if starting in some/dir then *.pyc in some/dir/this/that/.gitignore
#        becomes some/dir/this/that/**/*.pyc... oy.
fffind () {

  local here_we_are=$(dir_resolve $(pwd -P))

  local big_ignore_list=()

  local ignore_f=""

  # Go up the hierarchy...
  while [[ ${here_we_are} != '/' ]]; do
    for ignore_f in ".agignore" ".gitignore" ".findignore"; do
      if [[ -e "${here_we_are}/${ignore_f}" ]]; then
        # Read line by line from the file.
        while read fline; do
          # Bash regular expressions, eh.
          if [[ ! "${fline}" =~ ^[[:space:]]*# ]]; then
            # Not a comment line.
            big_ignore_list+=("-path '${fline}' -prune -o")
          fi
        done < "${here_we_are}/${ignore_f}"
      fi
    done
    # Keep looping:
    here_we_are=$(dir_resolve ${here_we_are}/..)
  done

  # Go down the hierarchies...
  # Find all .agignore, .gitignore, and .anythingignore.
  for ignore_f in `find . -type f -name ".*ignore"`; do
    local ignore_p=$(dirname -- "${ignore_f}")
    while read fline; do
      # Bash regular expressions, eh.
      if [[ ! "${fline}" =~ ^[[:space:]]*# ]]; then
        # Not a comment line.
        big_ignore_list+=("-path '${ignore_p}/${fline}' -prune -o")
      fi
    done < "${ignore_f}"
  done

  # So, calling find on its own does not work, probably
  # because of the globbing. So eval the commmand.
  # Nope: find . ${big_ignore_list[@]} -name $*
  # eval "find . ${big_ignore_list[@]} -name $*"
    eval "find . ${big_ignore_list[@]} -name $* | grep -E $*"

} # fffind

# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #

main () {
  : #source_deps
  unset -f source_deps
}

main "$@"


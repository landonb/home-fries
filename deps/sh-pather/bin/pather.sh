#!/usr/bin/env bash
# vim:tw=0:ts=2:sw=2:et:norl:ft=sh
# Project: https://github.com/landonb/sh-pather#🛁
# License: MIT

# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #

# *** PATH builder commands.

# For the sake of vanity, keep PATH tight and narrow by checking if any path
# already added and not adding again; or by removing any path first before
# appending or prefixing it to PATH. (Otherwise, when you reload bash, say,
# by running /bin/bash from within a terminal, your PATH would otherwise
# grow with duplicate entries. Which is not harmful, just annoying. Sometimes.)

# If you're curious what paths are part of PATH, try:
#
#   $ echo $PATH | tr : '\n'

_sh_pather_path_part_remove () {
  local path_part="$1"
  # Substitute: s/^prefix://
  PATH="${PATH#${path_part}:}"
  # Substitute: s/:suffix$//
  PATH="${PATH%:${path_part}}"
  # Substitute: s/^sole-path$//
  if [ "${PATH}" = "${path_part}" ]; then
    PATH=''
  fi
  # Substitute: s/:inside:/:/
  PATH="${PATH/:${path_part}:/:}"
  # The caller should finalize the export::
  #   export PATH
}

if [ "${BASH_SOURCE[0]}" != "$0" ]; then
  export -f _sh_pather_path_part_remove
fi


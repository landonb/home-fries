#!/usr/bin/env bash
# vim:tw=0:ts=2:sw=2:et:norl:ft=sh
# Author: Landon Bouma (landonb &#x40; retrosoft &#x2E; com)
# Project: https://github.com/landonb/home-fries#🍟
# License: MIT

# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #

home_fries_aliases_wire_mv () {
  # HINT: You can easily force-mv (omit the -i flag)
  #       by calling `\mv` or `/bin/mv` or `env mv`.
  alias mv='mv -i'

  # Move a glob of files and include .dotted (hidden) files.
  alias mv_all='mv_dotglob'
  # Problem illustration:
  #   $ ls project
  #   .agignore
  #   $ mv project/* .
  #   mv: cannot stat ‘project/*’: No such file or directory
  # This fcn. uses shopt to include dot files.
  # Note: We've aliased `mv` to `/bin/mv -i`, so you'll be asked to
  #       confirm any overwrites, unless you call `mv_all -f` instead.
  #
  # NOTE: You have to escape wildcards so that are not expanded too soon, e.g.,
  #
  #         mv. '*' some/place
  #
  mv_dotglob () {
    if [ -z "$1" ] && [ -z "$2" ]; then
      echo "mv_gotglob: missing args weirdo"
    fi
    shopt -s dotglob
    # or,
    #  set -f
    if [ "$1" = '-f' ]; then
      /bin/mv $*
    else
      mv $*
    fi
    shopt -u dotglob
    # or,
    #  set +f
  }

  alias mv.='mv_dotglob'
}

# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #

unset_f_alias_mv () {
  unset -f home_fries_aliases_wire_mv
  # So meta.
  unset -f unset_f_alias_mv
}

# @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@ #

if [ "$0" = "${BASH_SOURCE[0]}" ]; then
  >&2 echo "ERROR: Trying sourcing the file instead: . $0" && exit 1
fi


#!/usr/bin/env bash
# vim:tw=0:ts=2:sw=2:et:norl:ft=sh
# Author: Landon Bouma (landonb &#x40; retrosoft &#x2E; com)
# Project: https://github.com/landonb/home-fries#🍟
# License: MIT

# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #

home_fries_aliases_wire_mv () {
  # HINT: You can easily force-mv (omit the -i flag)
  #       by calling the builtin, e.g.,
  #         \mv ...
  #         command mv ...
  #         /bin/mv ...
  #         env mv ...
  #         /usr/bin/env mv ...
  #         "mv" ...
  #         'mv' ...
  #         bash -c "mv ..."
  #         mv -f ...
  alias mv="${SHOILERPLATE:-${HOME}/.kit/sh}/sh-rm_safe/bin/mv_safe"

  # Move a glob of files and include .dotted (hidden) files.
  # - The dotglob option performs parameters expansion, so it has to
  #   happen before parameters are expanded, so it has to happen from
  #   the alias. (Otherwise, if dotglob is not on, then `mv foo/*`
  #   passes `foo/*` as the arg if it doesn't match any files, and if
  #   dotglob is then enabled, you cannot use, e.g., `command mv "$@"`,
  #   because quoted args are not expanded. But `command mv $*` won't
  #   work either, because then an arg with spaces is split apart, e.g.,
  #   `mv "foo bar"` becomes `command mv foo bar`, not the same thing.)
  # - dotglob ($BASHOPTS) won't work unless noglob ($SHELLOPTS) is off,
  #   but Homefries leaves noglob off. So we'll ensure noglob disabled
  #   here, and we won't enable it after.
  # - Note this odd alias hack: Adjust BASHOPTS first, then end
  #   with the shim function call. The shim function will receive
  #   the glob-expanded args, pass those to `mv_safe`, and then
  #   reset dotglob.
  # - INERT: We could add functions to cache options and restore
  #   original values, e.g.,
  #     claim_alias_or_warn "mv." "mv_prepare_opts ; mv_dotglob"
  #     mv_prepare_opts { # Remember current settings; }
  #     mv_dotglob { mv "$@"; mv_restore_opts; }
  #     mv_restore_opts { # Restore previous settings; }
  #   But Homefries runs without dotglob set (it only ever temporarily
  #   enables it before disabling it), so there should be no reason to
  #   worry that dotglob was originally set.
  claim_alias_or_warn "mv." "set +f ; shopt -s dotglob ; mv_dotglob"
  claim_alias_or_warn "mv_all" "set +f ; shopt -s dotglob ; mv_dotglob"
}

# Passes args to `mv_safe` and disables dotglob.
#
# Useful when called after setting dotglob from an alias,
# so that expanded glob args include dotfiles, and so that
# we can unset the dotglob setting that the alias set.
#
# UCASE: Problem illustration:
#
#   $ mkdir foo
#   $ touch foo/.bar
#   $ mv foo/* .
#   mv: cannot stat ‘foo/*’: No such file or directory
#
# SAVVY: To compare dotglob behavior when enabled or not, try, e.g.,
#   $ touch .foo
#
#   $ shopt -s dotglob
#   $ ls -d -- *
#   .foo
#
#   $ shopt -u dotglob
#   $ ls -d -- *
#   ls: cannot access '*': No such file or directory

mv_dotglob () {
  ${SHOILERPLATE:-${HOME}/.kit/sh}/sh-rm_safe/bin/mv_safe "$@"

  # Leave noglob unset (set +f)
  #  set -f

  shopt -u dotglob
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


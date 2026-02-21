#!/usr/bin/env bash
# vim:tw=0:ts=2:sw=2:et:norl:ft=sh
# Author: Landon Bouma (landonb &#x40; retrosoft &#x2E; com)
# Project: https://github.com/landonb/home-fries#🍟
# License: MIT

# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #

check_deps() {
  # Verify .homefries/lib/distro_util.sh loaded.
  check_dep 'os_is_macos'
}

# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #

# Show resource usage, and default to human readable figures.
# - REFER:
#   df -h: BSD: "Human-readable" output [Not sure why BSD man uses quotes].
#          GNU: print sizes in powers of 1024 (e.g., 1023M).
#   df -T: GNU: print file system type.
#   df -Y: BSD: Include file system type.
#
# E.g., without -h:
#         Filesystem  1K-blocks      Used Available Use% Mounted on
#         /foo/bar    926199176 628671508 250409540  72% /baz/bat
# and then with -h:
#         Filesystem  Size  Used Avail Use% Mounted on
#         /foo/bar    884G  600G  239G  72% /baz/bat
#
# FEATR/2026-02-06: Truncate long filesystem and path names.
# - On author's Linux host, tomb filesystems have long names, e.g.,
#     /dev/mapper/tomb.mydevice.a1234b12cd123ed1ab123cd12e12f12ab1cd12e1f123a12b112cde123f12a12b.loop9
#   and the tmpfs mount path is also a long value, e.g.,
#     /run/credentials/systemd-cryptsetup@luks\x2a2b3c4567\x2a123b\x2c45d6\x2e78f9\x2a0123456bcde7.service
#   which makes the first column very wide and wraps every line unless
#   the output window is wider than you're likely to have it.
# - One solution uses `column` to truncate those 2 columns, e.g.,:
#     df | tail +2 | column -t \
#       --table-columns FS,Type,Size,Used,Avail,Use%,"Mounted on" \
#       --table-truncate 1,7 --output-width 120
#   - Note that --output-width is necessary: because pipes, column
#     doesn't sense the terminal window width.
# - A better option is to target the long names specifically.
#   - We use `sed` to look for long (at least 6 character) hex values,
#     maybe preceded by \x2 (or just \x, because 2 matches hex values).
#   - Then we fix column formatting using column.
#     - Note because the final column name contains a space ("Mounted on")
#       we have to explicitly define it, otherwise column thinks "on" is
#       its own column -- and if the terminal width is too narrow, it'll
#       print the "on" column on a new line, which has the effect of
#       printing a blank line between all the rows (because there is no
#       "on" cell value for any row).
#     - Actually, better yet, strip the header (tail +2), or you'll see
#       double headers; and then column prints the header line.

home_fries_aliases_wire_df() {
  claim_alias_or_warn "df" "_hf_df" ${_force:-true}
}

_hf_df() {
  if [ $# -ne 0 ]; then
    command df "$@"

    return
  fi

  local file_types
  local table_cols
  if os_is_linux; then
    file_types="-T"
    table_cols="Filesystem,Type,Size,Used,Avail,Use%,'Mounted on'"
  elif os_is_macos; then
    file_types="-Y"
    # Default macOS `command df -h` (no Type, because no -Y):
    #  table_cols="Filesystem,Size,Used,Avail,Capacity,iused,ifree,%iused,'Mounted on'"
    table_cols="Filesystem,Type,Size,Used,Avail,Capacity,iused,ifree,%iused,'Mounted on'"
  fi

  command df -h ${file_types} |
    tail +2 |
    sed 's/\(\(\\x\)\?[a-f0-9]\{6,\}\)\+/__TRUNC__/g' |
    column -t --table-columns "${table_cols}"
}

# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #

unset_f_alias_df() {
  unset -f check_deps
  unset -f home_fries_aliases_wire_df
  # So meta.
  unset -f unset_f_alias_df
}

# @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@ #

_homefries_warn_on_execute() {
  >&2 echo "ERROR: Trying sourcing the file instead: . $0" && exit 1
}

main() {
  check_deps
  unset -f check_deps
}

if [ "$0" = "${BASH_SOURCE[0]}" ]; then
  _homefries_warn_on_execute
else
  main "$@"
fi
unset -f _homefries_warn_on_execute
unset -f main

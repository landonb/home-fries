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

# REFER: These are the components of the `df` pipeline:
# - tail -n +2:   Trim `df` headers line;
# - 1st sed:      Preserve macOS Filesystem names that include spaces,
#                   e.g., "map auto_home" and "map -static", otherwise
#                   `column` will split apart to separate columns;
# - 2nd sed:      Truncate long names/path with UUIDs;
# - column ...:   Add column name header line (and format table output).
# - Final seds:   Color specific output rows:
#   - We'll color specific mount paths:
#     - On Linux, color all ext4 disks, which is probably all the disks
#       whose available space you'd want to monitor (vs., e.g., tmpfs or
#       squashfs filesystems that you don't care about, or fuse.gocryptfs
#       which probably live on the ext4 filesystems being highlighted);
#       - We'll also color fuse.sshfs filesystems, e.g., for when you
#         mount a drive connected to another host; and
#     - On macOS, color /System/Volumes/Data, which is the main data store;
#       - We'll also color nfs filesystems (similar to fuse.sshfs highlights).
#   - Altly: Instead of all ext4 filesystems, we could target specific
#     mountpoints, such as /home and any /media* mount:
#       sed "s/^\(.* \/home\)\$/"$(attr_bold)$(fg_skyblue)"\1"$(attr_reset)"/g" |
#       sed "s/^\(.* \/media\/.*\)\$/"$(attr_bold)$(fg_skyblue)"\1"$(attr_reset)"/g" |
#   - Altly: Highlight /media paths, but only /media/${USER} paths:
#       sed "s/^\(.* \/media\/${LOGNAME}\/[^ ]\+\)\$/"$(attr_bold)$(fg_skyblue)"\1"$(attr_reset)"/g" |

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
    replace_single_spaces_with_em_space() {
      # Only replaces first space, because GNU `fd` only uses single
      # spaces between column values (so cannot easily detect space
      # in filesystem path vs. space between values).
      # - Note the replacement string, `\1 \2`, uses em space.
      sed 's/^\([^ ]\) \([^ ]\)/\1 \2/g'
    }
    table_cols="Filesystem,Type,Size,Used,Avail,Use%,'Mounted on'"
    table_trunc="7"
  elif os_is_macos; then
    file_types="-Y"
    replace_single_spaces_with_em_space() {
      # See comment above; same sed, except no start-of-line (^) match.
      sed 's/\([^ ]\) \([^ ]\)/\1 \2/g'
    }
    # Default macOS `command df -h` (no Type, because no -Y):
    #  table_cols="Filesystem,Size,Used,Avail,Capacity,iused,ifree,%iused,'Mounted on'"
    table_cols="Filesystem,Type,Size,Used,Avail,Capacity,iused,ifree,%iused,'Mounted on'"
    table_trunc="10"
  fi

  # Specify max column width — because `column` output piped (to
  # highlight `sed`s), `column` uses default column width (80).
  local terminal_column_width="$(tput cols)"

  command df -h ${file_types} |
    tail +2 |
    replace_single_spaces_with_em_space |
    sed 's/\(\(\\x\)\?[a-f0-9]\{6,\}\)\+/__TRUNC__/g' |
    column -t --table-columns "${table_cols}" \
      --table-truncate ${table_trunc} \
      --output-width ${terminal_column_width} |
    sed "s/^\([^ ]\+ \+\<\(ext4\|fuse.sshfs\|nfs\)\>.*\)\$/"$(attr_bold)$(fg_skyblue)"\1"$(attr_reset)"/g" |
    sed "s/^\(.* \/System\/Volumes\/Data\)\$/"$(attr_bold)$(fg_skyblue)"\1"$(attr_reset)"/g"
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

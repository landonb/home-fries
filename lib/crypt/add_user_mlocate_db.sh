#!/usr/bin/env bash
# vim:tw=0:ts=2:sw=2:et:norl:ft=sh
# Author: Landon Bouma (landonb &#x40; retrosoft &#x2E; com)
# Project: https://github.com/landonb/home-fries#🍟
# License: MIT

# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #

# *** Override findutils' `locate` to use our private locate.db.
#
# - The system `updatedb` does not include user home files, because
#   any user can access the system mlocate.db, and that would expose
#   your private filenames.
#
# - You'll need to run `updatedb` yourself, ideally on a scheduled
#   basis.
#
#   - CXREF: FIXME
#
# - Note that `locate` is the legacy implementation, which is replaced
#   by `plocate` (there's also `mlocate`, a transitional package).
#
#   - On Debian: `apt install plocate` installs `plocate`
#
#     - Below we alias `locate` to `plocate` on Linux.
#
#   - On macOS: `brew install findutils` installs `glocate`
#
#     - Below we alias `locate` to `glocate` on macOS.
#
#     - There's also a Rust re-write,
#       `brew install uutils-findutils`
#
#         https://github.com/uutils/findutils
#
#       Though it doesn't (yet [2024-07-15]) implement
#       `locate` and `updatedb`:
#
#         https://github.com/uutils/findutils/issues/60
#
#     - See also `plocate` project
#
#         https://plocate.sesse.net/
#
#       But there doesn't seem to be a macOS installation.
#
#       Fortunately, in the author's experience, Brew's `locate`
#       works fast enough.
#
#     - And then there's Apple Spotlight's `mdfind`, but the
#       author has been unable to determine how to index their
#       home directory files using Spotlight. (And gurgling the
#       answer doesn's yield good results. Mostly comments about
#       using `find / -name <foo>` or `fd <foo> /`, but neither
#       of those is very fast, and neither are the results
#       ordered as nicely as the results from `locate`.)
#       Spotlight also doesn't index hidden (dot) files or
#       enter hidden directories (and author also could not
#       figure out how to configure the Spotlight database).

# SAVVY: The `locate` command has some nuances we work around in order
#        to store our mlocate.db under our home directory (on an
#        encrytped mount, if you want another layer of security).
#
# 1.  Use stdin to specify (feed) database to locate, not -d/--database.
#
#     The `locate` command has a -d/--database option, or equivalently
#     LOCATE_PATH, that you can set to add your own database — but note
#     that locate just appends your database to its list, e.g.,
#
#       $ LOCATE_PATH=~/.mlocate/mlocate.db locate -S
#       Database /var/lib/mlocate/mlocate.db:
#         ...
#       Database /home/user/.mlocate/mlocate.db:
#         ...
#
#     But with multiple database inputs, you might end up with
#     duplicate results.
#
#     - On macOS, /var/db/locate.database is the system mlocate.db
#       - To make the db, run `sudo /usr/libexec/locate.updatedb`
#
#     However, trying to create a user mlocate.db without duplicate
#     results is difficult unless all user files are under the user's
#     home directory (because then you can just call `updatedb -U $HOME`).
#     - But I've got stuff elsewhere (e.g., under /media/${LOGNAME} on
#       Linux, or under /Volumes on macOS) that I want to index.
#
#     And as mentioned earlier, if you use two databases, you'll
#     probably see duplicate entries for system items.
#
#     E.g.,
#
#       @macOS $ LOCATE_PATH= glocate fsck_apfs.log
#       /private/var/log/fsck_apfs.log
#       /private/var/log/fsck_apfs.log
#
#       @macOS $ LOCATE_PATH=~/.cache/glocate/glocate.db locate fsck_apfs.log
#       /private/var/log/fsck_apfs.log
#
#     Anyway, tl;dr, send the database over stdin; problem solved.
#     (On stdin, locate will ignore the system db, and LOCATE_PATH.)
#     E.g,
#
#       $ cat ~/.cache/glocate/glocate.db | glocate -S -d-
#       Database <stdin> is in the GNU LOCATE02 format.
#     	...
#
# 2.  Use stdin to feed database, as -d/--database cannot see all mounts.
#
#     Another reason to use the `-` database-on-stdin feature:
#     `locate` apparently cannot access files on my fuse mount.
#     E.g.,
#
#       @debian $ LOCATE_PATH=/media/user/mount/.mlocate/mlocate.db locate -S
#       Database /var/lib/mlocate/mlocate.db:
#       	...
#       locate: can not stat () `/media/user/mount/.mlocate/mlocate.db': Permission denied
#
#     However:
#
#       @debian $ cat /media/user/mount/.mlocate/mlocate.db | locate -S -d-
#       Database -:
#         ...
#
#     - DUNNO/2024-07-14: Linux `locate -S` is not (no longer?) an option.
#       - However, macOS glocate (brew install findutils) has it.

home_fries_locate_wire_private_db () {
  alias locate="_hf_locate"
}

_hf_locate () {
  # USAGE: User can set custom db path any time before calling `locate`.
  local db_path="${LOCATEDB_PATH:-${HOME}/.cache/locate/locate.db}"

  if [ -f "${db_path}" ]; then
    if command -v plocate > /dev/null; then
      # Linux
      command plocate --database "${db_path}" "$@"
    elif command -v glocate > /dev/null; then
      # macOS
      command glocate --database "${db_path}" "$@"
    else
      echo "CHORE: Please install \`plocate\` (Linux) or \`glocate\` (macOS)"

      command locate "$@"
    fi
  else
    echo "CHORE: Please create (or mount) ${db_path} (or set LOCATEDB_PATH)"

    command locate "$@"
  fi
}

# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #

main () {
  :
}

main "$@"
unset -f main


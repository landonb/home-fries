#!/usr/bin/env bash
# vim:tw=0:ts=2:sw=2:et:norl:ft=sh
# Author: Landon Bouma (landonb &#x40; retrosoft &#x2E; com)
# Project: https://github.com/landonb/home-fries#🍟
# License: MIT

# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #

# *** Override findutils' `locate` to use private mlocate.db made by updatedb.

# (lb): The `locate` command has some nuances we work around in order
#       to store our mlocate.db on an arbitrary encrytped drive.
#
# 1.  Use stdin to specify (feed) database to locate, not -d/--database.
#
#     The `locate` command has a -d/--database option, or equivalently
#     LOCATE_PATH, that you can set to add your own database -- but note
#     that locate just appends your database to its list, e.g.,
#
#       $ LOCATE_PATH=~/.mlocate/mlocate.db locate -S
#       Database /var/lib/mlocate/mlocate.db:
#         ...
#       Database /home/user/.mlocate/mlocate.db:
#         ...
#
#     Also, oddly, I see the system database listed twice otherwise:
#
#       $ LOCATE_PATH= locate -S
#       Database /var/lib/mlocate/mlocate.db:
#         ...
#       Database /var/lib/mlocate/mlocate.db:
#         ...
#
#     However, trying to create a user mlocate.db without overlapping (duplicate)
#     options is difficult unless all user files are under the user's home directory
#     (because then you can use the `updatedb -U $HOME` option).
#     - But I've got stuff under /media/${LOGNAME} that I want to index,
#       and that I do not what to link from $HOME (and also updatedb
#       resolves symlinks unless told otherwise, so there's that, too!),
#       so I am unable to utilize the `-U` option to solve this issue.
#
#     As such, if I use two databases, however I run `locate`, I see duplicate
#     entries for system items.
#
#     E.g.,
#
#       $ LOCATE_PATH= locate /etc/updatedb.conf
#       /etc/updatedb.conf
#       /etc/updatedb.conf
#
#       $ LOCATE_PATH=~/.mlocate/mlocate.db locate /etc/updatedb.conf
#       /etc/updatedb.conf
#       /etc/updatedb.conf
#
#     Anyway, tl;dr, send the database over stdin; problem solved.
#     (On stdin, locate will ignore the system db, and LOCATE_PATH.)
#     E.g,
#
#       $ cat ~/.mlocate/mlocate.db | locate -S -d-
#       Database -:
#       	...
#
# 2.  Use stdin to feed database, as -d/--database cannot see all mounts.
#
#     Another reason to use the `-` database-on-stdin feature:
#     `locate` apparently cannot access files on my fuse mount.
#     E.g.,
#
#       $ LOCATE_PATH=/media/user/mount/.mlocate/mlocate.db locate -S
#       Database /var/lib/mlocate/mlocate.db:
#       	...
#       locate: can not stat () `/media/user/mount/.mlocate/mlocate.db': Permission denied
#
#     However:
#
#       $ cat /media/user/mount/.mlocate/mlocate.db | locate -S -d-
#       Database -:
#         ...
#
home_fries_mlocate_wire_private_db () {
  if command -v plocate > /dev/null; then
    if [ -f "${HOME}/.plocate/plocate.db" ]; then
      alias locate="plocate --database ${HOME}/.plocate/plocate.db"
    elif [ -f "${HOME}/.mlocate/mlocate.db" ]; then
      echo "CHORE: Update ~/.mlocate → ~/.plocate"
    fi
  elif command -v mlocate > /dev/null; then
    if [ -f "${HOME}/.mlocate/mlocate.db" ]; then
      alias locate="cat ${HOME}/.mlocate/mlocate.db | /usr/bin/locate -d-"
    fi
  fi
}

# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #

main () {
  :
}

main "$@"
unset -f main


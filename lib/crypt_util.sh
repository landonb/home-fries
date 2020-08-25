#!/bin/bash
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
#     Another reason to use the ``-`` database-on-stdin feature:
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
  if [ -f "${HOME}/.mlocate/mlocate.db" ]; then
    alias locate="cat ${HOME}/.mlocate/mlocate.db | /usr/bin/locate -d-"
  fi
}

# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #

# 2016-10-25: See stage_4_password_store
# Apparently not always so sticky.
# E.g., just now,
#   $ pass blah/blah
#   gpg: WARNING: The GNOME keyring manager hijacked the GnuPG agent.
#   gpg: WARNING: GnuPG will not work properly - please configure that tool
#                 to not interfere with the GnuPG system!
#   gpg: problem with the agent: Invalid card
#   gpg: decryption failed: No secret key
# and then I got the GUI prompt and not the curses prompt.
# So maybe we should always give this a go.
#
# 2016-11-01: FIXME: Broken again. I see a bunch of gpg-agents running, but GUI still pops...
#   Didn't work:
#    sudo dpkg-divert --local --rename \
#      --divert /etc/xdg/autostart/gnome-keyring-gpg.desktop-disable \
#      --add /etc/xdg/autostart/gnome-keyring-gpg.desktop\
#   Didn't work:
#     killall gpg-agent
#     gpg-agent --daemon
# What happened to pinentry-curses?
#   Didn't work:
#     gpg-agent --daemon > /home/landonb/.gnupg/gpg-agent-info-larry
#     ssh-agent -k
#     bash
#
daemonize_gpg_agent () {
  # 2018-06-26: (lb): Skip if in SSH session.
  if [ -n "${SSH_CLIENT}" ] || [ -n "${SSH_TTY}" ] || [ -n "${SSH_CONNECTION}" ]; then
      return
  fi
  # 2020-08-24: (lb): Skip if no gpg-agent (e.g., macOS Catalina).
  command -v gpg-agent > /dev/null || return
  # Check if gpg-agent is running, and start if not.
  ps -C gpg-agent &> /dev/null
  if [ $? -ne 0 ]; then
    local eff_off_gkr
    eff_off_gkr=$(gpg-agent --daemon 2> /dev/null)
    if [ $? -eq 0 ]; then
      eval "${eff_off_gkr}"
    else
      # else, do I care?
      echo 'Unable to start gpg-agent'
    fi
  fi
}

# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #

has_sudo () {
  sudo -n true &> /dev/null && echo YES || echo NOPE
}

# 2018-01-29: You could also do, e.g.,:
ensure_sudo () {
  if ! sudo -nv &> /dev/null; then
    echo "You may need sudo to proceed!"
    sudo -v
  fi
}

# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #

home_fries_configure_gpg_tty () {
  # For pinentry (for vim-gnupg):
  export GPG_TTY=`tty`
}

# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #

function is_mount_type_crypt () {
  local curious_path="$1"
  local is_crypt
  lsblk --output TYPE,MOUNTPOINT |
    grep crypt |
    grep "^crypt \\+${curious_path}\$" \
      > /dev/null \
  && is_crypt=0 || is_crypt=1

  return ${is_crypt}
}

# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #

main () {
  :
}

main "$@"
unset -f main


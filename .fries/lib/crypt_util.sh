#!/bin/bash
# vim:tw=0:ts=2:sw=2:et:norl:

# File: crypt_util.sh
# Author: Landon Bouma (landonb &#x40; retrosoft &#x2E; com)
# Project Page: https://github.com/landonb/home-fries
# Summary: Generic Bash function library.
# License: GPLv3

# Usage: Source this script. Call its functions. Use its exports.

# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #

source_deps() {
  :
}

# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #

# Encrypted Filesystem.

# 2016-12-07: Haven't used these in a long time.

# FIXME/2018-01-29: Remove these? Seem kinda you-specific.

mount_guard () {
  if [[ -n $(/bin/ls -A ~/.waffle/.guard) ]]; then
    encfs ~/.waffle/.guard ~/.waffle/guard
  fi
}

umount_guard () {
  fusermount -u ~/.waffle/guard
}

#mount_sepulcher () {
#  if [[ -z $(/bin/ls -A ~/.fries/sepulcher) ]]; then
#    encfs ~/.fries/.sepulcher ~/.fries/sepulcher
#  fi
#}

#umount_sepulcher () {
#  fusermount -u ~/.fries/sepulcher
#}

# To manage the encfs (change pwd, etc.), see: encfsctl

# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #

# Secure ``locate`` with ``ecryptfs``

# https://askubuntu.com/questions/20821/using-locate-on-an-encrypted-partition

# 2016-12-27: Always use the local locate db if it exists.
# Funny: If you specify the normal db, e.g.,
#   export LOCATE_PATH="/var/lib/mlocate/mlocate.db:$HOME/.mlocate/mlocate.db"
# it gets searched twice and you get double the results.
# So just indicate the user's mlocate.db.
if [[ -f /var/lib/mlocate/mlocate.db && -f $HOME/.mlocate/mlocate.db ]]; then
  export LOCATE_PATH="$HOME/.mlocate/mlocate.db"
fi
# See also:
#   /etc/updatedb.conf
# And you could also specify the dbs to locate
#   locate -d /var/lib/mlocate/mlocate.db -d $HOME/.mlocate/mlocate.db
# (and note that if you use -d, you need to specify both for both to be searched).

updatedb_ecryptfs () {
  /bin/mkdir -p ~/.mlocate
  export LOCATE_PATH="$HOME/.mlocate/mlocate.db"
  updatedb -l 0 -o $HOME/.mlocate/mlocate.db -U $HOME
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
  ps -C gpg-agent &> /dev/null
  if [[ $? -ne 0 ]]; then
    # 2018-04-03 00:23: On the 14.04 Desktop with Issues:
    #   gpg-agent[17654]: Fatal: libgcrypt is too old (need 1.7.0, have 1.6.1)
    local eff_off_gkr
    eff_off_gkr=$(gpg-agent --daemon 2>&1 /dev/null)
    if [[ $? -eq 0 ]]; then
      eval "$eff_off_gkr"
    else
      # else, do I care?
      echo 'Unable to start gpg-agent'
    fi
  fi
}

# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #

#has_sudo () {
#  if sudo -n true 2>/dev/null; then
#    echo "I got sudo"
#  else
#    echo "I don't have sudo"
#  fi
#}

has_sudo () {
  sudo -n true &> /dev/null && echo YES || echo NOPE
}

# 2018-01-29: You could also do, e.g.,:
ensure_sudo() {
  if ! sudo -nv &> /dev/null; then
    echo "You may need sudo to proceed!"
    sudo -v
  fi
}

# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #

home_fries_configure_gpg_tty() {
  # For pinentry (for vim-gnupg):
  export GPG_TTY=`tty`
}

# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #

main() {
  : #source_deps
}

main "$@"


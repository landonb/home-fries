#!/usr/bin/env bash
# vim:tw=0:ts=2:sw=2:et:norl:ft=sh
# Author: Landon Bouma (landonb &#x40; retrosoft &#x2E; com)
# Project: https://github.com/landonb/home-fries#🍟
# License: MIT

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

_homefries_ps_check_if_running () {
  local process_name="$1"
  # Check if GNU ps or not, which returns a version of, e.g.,
  #   ps from procps-ng 3.3.12
  # And where non-GNU ps, specifically macOS, fails on:
  #   ps: illegal option -- -
  if ps --version > /dev/null 2>&1; then
    ps -C "${process_name}" &> /dev/null
  else
    ps axc | grep "${process_name}" > /dev/null
  fi
}

daemonize_gpg_agent () {
  # 2018-06-26: (lb): Skip if in SSH session.
  if [ -n "${SSH_CLIENT}" ] || [ -n "${SSH_TTY}" ] || [ -n "${SSH_CONNECTION}" ]; then
      return
  fi
  # 2020-08-24: (lb): Skip if no gpg-agent (e.g., macOS Catalina).
  command -v gpg-agent > /dev/null || return
  # Check if gpg-agent is running, and start if not.
  if ! _homefries_ps_check_if_running "gpg-agent"; then
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

main () {
  :
}

main "$@"
unset -f main


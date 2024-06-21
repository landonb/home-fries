#!/usr/bin/env bash
# vim:tw=0:ts=2:sw=2:et:norl:ft=sh
# Author: Landon Bouma (landonb &#x40; retrosoft &#x2E; com)
# Project: https://github.com/landonb/home-fries#🍟
# License: MIT

# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #

# 2021-05-31: The function below starts gpg-agent as a daemon process.
#
# - It's not necessary to start gpg-agent explicitly, as running `gpg`
#   will load it on-demand. But it's nice to get it going anyway if
#   you're more than likely to use it at some point during your session.
#
# - You'll want to configure you ~/.gnupg/gpg-agent.conf appropriately.
#
#   - Historically, I had just one entry:
#
#       pinentry-program /usr/bin/pinentry-curses
#
#     which tells GPG to prompt for your password in the terminal session.
#
#     (I had trouble in 2016 with the GNOME keyring manager spewing errors
#      when I'd run `pass`, and prompting me through the GUI (and not the
#      ncurses terminal prompt). But after specifying pinentry-program, my
#      woes went away.)
#
#   - But recently, I've added a few more options to `gpg-agent.conf`:
#
#       allow-preset-passphrase
#       default-cache-ttl 1200
#       max-cache-ttl 34560000
#
#     The `allow-preset-passphrase` option enables `gpg-preset-passphrase`,
#     which I use to cache my Git/GitHub commit signing key, so that I'm
#     not constantly being prompted for the passphrase when I commit.
#
#     And the default maximum cache timeout is 2 hours, so I also jacked up
#     the `max-cache-ttl` (to a whopping 400 days, 4 times longer than my
#     machine's current uptime). This means I should only have to enter the
#     Git signing key passphrase once per session, after a reboot.
#
#     And because that's the only key that I preset, I'm not concerned that
#     it lives so long in cache — I'm not expecting anyone to gain access
#     to my terminal and then to start committing code surreptitiously. If
#     someone accesses my terminal, they're not their to push commits.
#
#     Finally, I doubled the default cache timeout, from 10 minutes to 20,
#     just so I can avoid having to enter my passphrase too frequently when
#     I'm at my terminal and working on tasks that require multiple, but
#     somewhat infrequent calls to `pass` (where `pass` is really the only
#     GPG use I have other than Git signing).
#
# - If you've edited `gpg-agent.conf`, it's easiest just to restart it:
#
#       gpgconf --reload gpg-agent
#
#       # Or, alternatively:
#       $ gpg-connect-agent reloadagent /bye
#       OK
#
#       # Or even:
#       $ echo RELOADAGENT | gpg-connect-agent > /dev/null
#       OK
#
# - If you want to kill the agent, avoid `killall gpg-agent` (it doesn't
#   do anything when I use it), and use `gpgconf` or `pkill` instead:
#
#       gpgconf --kill gpg-agent
#
#       # Or:
#       pkill gpg-agent
#
#   And verify with `ps aux | grep gpg`.
#
#   Note that after killing the agent and restarting it, I see a
#   misleading "error":
#
#       $ gpg-agent --daemon
#       gpg-agent: a gpg-agent is already running - not starting a new one
#
#   Which I call "misleading" because a `ps` beforehand shows nothing
#   running, and another `ps` afterward shows one process running. So
#   I am not sure what is up with the message. But I just ignored it.

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

  # 2020-08-24: Skip if no gpg-agent (e.g., macOS Catalina).
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


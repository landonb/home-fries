#!/usr/bin/env bash
# vim:tw=0:ts=2:sw=2:et:norl:ft=sh
# Author: Landon Bouma (landonb &#x40; retrosoft &#x2E; com)
# Project: https://github.com/landonb/home-fries#🍟
# License: MIT

# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #

# Not by the hair of my shimmy-shim-shim!
ssh-agent () {
  if [ $# -eq 1 ] && [ "$1" = '-k' ]; then
    # Rather than call `ssh-agent -k`, which (AFAIK, or just what I assume)
    # only kills the agent with a matching SSH_AGENT_PID pid, use `ps` to
    # find and kill all agents.
    # - I mean, you've come this far, might as well be complete about it.
    # NOTE: Expects ${HOMEFRIES_BIN} to be on PATH.
    ssh-agent-kill
  else
    /usr/bin/ssh-agent "$@"
  fi
}

# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #

main () {
  :
}

main "$@"
unset -f main


#!/usr/bin/env bash
# vim:tw=0:ts=2:sw=2:et:norl:ft=bash
# Author: Landon Bouma <https://tallybark.com/>
# Project: https://github.com/landonb/home-fries#🍟
# License: MIT

# REFER/2025-11-11: Copied from Debian 13 stock ~/.bash_logout.
# - NTRST: This is new to me! (When was ~/.bash_logout feature
#   added to Bash?)

# REFER: From `man bash`:
#   SHLVL — Incremented by one each time an instance of bash is started.
# - Starts at 1. / Running `bash` from within `bash` increments it.
# - CXREF: See also bexit, aka bash-exit-bash-hole, found in DepoXy env at:
#     ~/.kit/sh/home-fries/lib/session_util.sh @ 29

# REFER: Note that an Alacritty window is not a console:
#   $ clear_console
#   clear_console: terminal is not a console
# - DUNNO: What's an example where this is useful?

# ***

# ~/.bash_logout: executed by bash(1) when login shell exits.

# when leaving the console clear the screen to increase privacy

if [ "$SHLVL" = 1 ]; then
  [ -x /usr/bin/clear_console ] && /usr/bin/clear_console -q
fi

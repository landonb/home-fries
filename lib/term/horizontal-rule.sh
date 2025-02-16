#!/usr/bin/env bash
# vim:tw=0:ts=2:sw=2:et:norl:ft=bash
# Author: Landon Bouma <https://tallybark.com/>
# Project: https://github.com/landonb/home-fries#🍟
# License: MIT

# THANX:
# https://github.com/lukas-reineke/dotfiles/blob/02064d6dccb2e/bash/functions.sh

# Prints horizontal line, e.g., "───...", full width of terminal.
# - Not something I think I need, but it's an interesting incantation.
function hr {
  local start=$'\e(0' end=$'\e(B' line='qqqqqqqqqqqqqqqq'
  local cols=${COLUMNS:-$(tput cols)}
  while ((${#line} < cols)); do line+="$line"; done
  printf '%s%s%s\n' "$start" "${line:0:cols}" "$end"
}

